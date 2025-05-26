`include "define.svh"
module PE (
	input clk,
	input rst,
	input PE_en,
	input [`CONFIG_SIZE-1:0] i_config,
	input [`DATA_BITS-1:0] ifmap,
	input [`DATA_BITS-1:0] filter,
	input [`DATA_BITS-1:0] ipsum,
	input ifmap_valid,
	input filter_valid,
	input ipsum_valid,
	input opsum_ready,
	output reg [`DATA_BITS-1:0] opsum,
	output reg ifmap_ready,
	output reg filter_ready,
	output reg ipsum_ready,
	output reg opsum_valid
);
integer i;

// i_config
reg [`CONFIG_SIZE-1:0] i_config_reg;
reg  mode;
reg  [1:0] p_minus_1; // output channel
reg  [4:0] F; // output column
reg  [1:0] q_minus_1; // input channel
reg  [1:0] filter_rs;
reg depthwise;
// split config
always@(*) begin
	depthwise = i_config_reg[12];
	filter_rs = i_config_reg[11:10] + 2'b1;
	mode = i_config_reg[9];
	p_minus_1 = i_config_reg[8:7];
	F = i_config_reg[6:2];
	q_minus_1 = i_config_reg[1:0];
end

always @(posedge clk or posedge rst) begin
	if(rst)begin
		i_config_reg <= `CONFIG_SIZE'b0;
	end
	else if (PE_en)begin
		i_config_reg <= i_config;
	end
	else begin
		i_config_reg <= i_config_reg;
	end
end

//spad
reg signed [`IFMAP_SIZE - 1:0] ifmap_spad  [0:`IFMAP_SPAD_LEN - 1];
reg signed [`FILTER_SIZE - 1:0]filter_spad [0:`FILTER_SPAD_LEN - 1];
reg signed [`PSUM_SIZE - 1:0]	 psum_spad [0:`OFMAP_SPAD_LEN - 1];

//spad counter
reg [`IFMAP_INDEX_BIT - 1:0]  ifmap_spad_cnt;
reg [`FILTER_INDEX_BIT - 1:0] filter_spad_cnt;
reg [`OFMAP_INDEX_BIT - 1:0]  psum_spad_cnt;

reg [2:0] state_read_spad;
reg [2:0] next_state;

// state logic
parameter IDLE          	= 3'd0;
parameter READ_FILTER   	= 3'd1;
parameter READ_IFMAP		= 3'd2;
parameter READ_IPSUM    	= 3'd3;
parameter CONV				= 3'd4;
parameter WRITE_OPSUM   	= 3'd5;

always @(posedge clk or posedge rst) begin
	if(rst)
		state_read_spad <= 3'b0;
	else
		state_read_spad <= next_state;
end

always @(*) begin
	case (state_read_spad)
		IDLE: begin
			if(PE_en)
				next_state = READ_FILTER;
			else
				next_state = IDLE;
		end
		READ_FILTER:begin
			if({26'b0, filter_spad_cnt} == (((32'({1'b0, p_minus_1}) + 32'd1) * filter_rs) << 2))
				next_state = READ_IFMAP;
			else
				next_state = READ_FILTER;
		end
		READ_IFMAP: begin
			if(ifmap_spad_cnt == {2'b0, filter_rs}<<2)
				next_state = READ_IPSUM;
			else
				next_state = READ_IFMAP;
		end
		READ_IPSUM: begin
			if(depthwise)begin
				if((psum_spad_cnt == q_minus_1) && ipsum_valid)begin
					//readed all ipsum
					next_state = CONV;
				end
				else begin
					// not yet done
					next_state = READ_IPSUM;
				end
			end
			else begin
				if((psum_spad_cnt == p_minus_1) && ipsum_valid)begin
					//readed all ipsum
					next_state = CONV;
				end
				else begin
					// not yet done
					next_state = READ_IPSUM;
				end
			end
		end
		CONV: begin
			if(depthwise)begin
				if({26'b0, filter_spad_cnt} == ((32'({1'b0, p_minus_1}) + 32'd1) * filter_rs))begin
					// Go to at the waveform.
					next_state = WRITE_OPSUM;
				end
				else begin
					next_state = CONV;
				end
			end
			else begin
				if({26'b0, filter_spad_cnt} == ((filter_rs * p_minus_1) << 2) + 8 + {30'b0, q_minus_1})begin
					next_state = WRITE_OPSUM;
				end
				else begin
					next_state = CONV;
				end
			end
		end
		WRITE_OPSUM:
			if(depthwise)begin
				if((psum_spad_cnt == 0) && opsum_ready)begin
					if (output_col_cnt == F) begin
						next_state = IDLE;
					end
					else begin
						next_state = READ_IFMAP;
					end
				end
				else begin
					next_state = WRITE_OPSUM;
				end
			end
			else begin
				if((psum_spad_cnt == 0) && opsum_ready)begin
					if (output_col_cnt == F) begin
						next_state = IDLE;
					end
					else begin
						next_state = READ_IFMAP;
					end
				end
				else begin
					next_state = WRITE_OPSUM;
				end
			end 
		default: begin
			next_state = IDLE;
		end
	endcase
end
reg [4:0] output_col_cnt;
always @(posedge clk or posedge rst) begin
	if(rst)
		output_col_cnt <= 5'b0;
	else if(next_state == READ_IFMAP)
		output_col_cnt <= output_col_cnt + 5'b1;
end
/**
 * spad data structure
 *            spadn
 *              ^
 *            spadn-1
 *              ^
 *             ...
 *              ^
 *            spad1
 *              ^
 * input ---> spad0
 */

// READ_SPAD state
always @(posedge clk or posedge rst) begin
	if(rst)begin
		for (i = 0;i <`IFMAP_SPAD_LEN ; i = i + 1) begin
			ifmap_spad[i] <= `IFMAP_SIZE'b0;
		end
		for (i = 0;i <`FILTER_SPAD_LEN ; i = i + 1) begin
			filter_spad[i] <= `FILTER_SIZE'b0;
		end
		for (i = 0;i <`OFMAP_SPAD_LEN ; i = i + 1) begin
			psum_spad[i] <= `PSUM_SIZE'b0;
		end
	end
	else begin
		case (state_read_spad)
			READ_FILTER:begin
				if(filter_valid)begin
					{
						filter_spad[3], 
						filter_spad[2], 
						filter_spad[1], 
						filter_spad[0]
					} <= filter;
					for (i = 4; i <`FILTER_SPAD_LEN; i = i + 1) begin
						filter_spad[i] <= filter_spad[i-4];
					end
				end
			end
			READ_IFMAP:begin
				if(ifmap_valid)begin
					{
						ifmap_spad[3], 
						ifmap_spad[2], 
						ifmap_spad[1], 
						ifmap_spad[0]
					} <= ifmap ^ 32'b10000000_10000000_10000000_10000000;
					for (i = 4; i <`IFMAP_SPAD_LEN; i = i + 1) begin
						ifmap_spad[i] <= ifmap_spad[i-4];
					end
				end
			end
			READ_IPSUM:begin
				if(ipsum_valid)begin
					psum_spad[0] <= ipsum;
					psum_spad[1] <= psum_spad[0];
					psum_spad[2] <= psum_spad[1];
					psum_spad[3] <= psum_spad[2];
				end
			end
			default: begin
				for (i = 0;i <`IFMAP_SPAD_LEN ; i = i + 1) begin
					ifmap_spad[i] <= ifmap_spad[i];
				end
				for (i = 0;i <`FILTER_SPAD_LEN ; i = i + 1) begin
					filter_spad[i] <= filter_spad[i];
				end
				for (i = 0;i <`OFMAP_SPAD_LEN ; i = i + 1) begin
					psum_spad[i] <= psum_spad[i];
				end
				if(state_mul2 == CONV)
					psum_spad[psum_spad_cnt_mul2] <= psum_spad[psum_spad_cnt_mul2] + {16'b0, product_result};
			end
		endcase
	end
end

always @(posedge clk or posedge rst) begin
	if(rst)begin
		ifmap_spad_cnt <= `IFMAP_INDEX_BIT'b0;
		filter_spad_cnt <= `FILTER_INDEX_BIT'b0;
		psum_spad_cnt <= `OFMAP_INDEX_BIT'b0;
	end
	else begin
		case (state_read_spad)
			READ_FILTER:begin
				if(next_state == READ_IFMAP)
					filter_spad_cnt <= `FILTER_INDEX_BIT'b0;
				else if(filter_valid)
					filter_spad_cnt <= filter_spad_cnt + `FILTER_INDEX_BIT'd4;
				else
					filter_spad_cnt <= filter_spad_cnt;
			end
			READ_IFMAP:begin
				if(next_state == READ_IPSUM)
					ifmap_spad_cnt <= `IFMAP_INDEX_BIT'b0;
				else if(ifmap_valid)
					ifmap_spad_cnt <= ifmap_spad_cnt + `IFMAP_INDEX_BIT'd4;
				else
					ifmap_spad_cnt <= ifmap_spad_cnt;
			end
			READ_IPSUM:begin
				if(next_state == CONV)
					psum_spad_cnt <= 0;
				else if(ipsum_valid)
					psum_spad_cnt <= psum_spad_cnt + `OFMAP_INDEX_BIT'b1;
				else
					psum_spad_cnt <= psum_spad_cnt;
			end
			CONV:begin
				if(depthwise)begin
					if(next_state == WRITE_OPSUM)
						psum_spad_cnt <= p_minus_1;
					else if(psum_spad_cnt == p_minus_1)
						psum_spad_cnt <= 0;
					else
						psum_spad_cnt <=  psum_spad_cnt + `OFMAP_INDEX_BIT'b1;

					if(filter_spad_cnt[1:0] == q_minus_1)
						filter_spad_cnt <= {(filter_spad_cnt[5:2] + 4'd1), 2'b0};
					else
						filter_spad_cnt <= filter_spad_cnt + `FILTER_INDEX_BIT'b1;
					
					if(ifmap_spad_cnt[1:0] == q_minus_1)
						ifmap_spad_cnt <= {ifmap_spad_cnt[3:2] + 2'd1, 2'b0};
					else
						ifmap_spad_cnt <= ifmap_spad_cnt + `IFMAP_INDEX_BIT'b1;
				end else begin
					if(filter_spad_cnt[1:0] == q_minus_1)
						filter_spad_cnt <= {(filter_spad_cnt[5:2] + 4'd1), 2'b0};
					else
						filter_spad_cnt <= filter_spad_cnt + `FILTER_INDEX_BIT'b1;

					if(ifmap_spad_cnt == {{filter_rs - 2'b1}, q_minus_1})begin
						ifmap_spad_cnt <= 4'b0;
						if(next_state == WRITE_OPSUM)
							psum_spad_cnt <= p_minus_1;
						else
							psum_spad_cnt <=  psum_spad_cnt + `OFMAP_INDEX_BIT'b1;
					end else begin
						if(ifmap_spad_cnt[1:0] == q_minus_1)
							ifmap_spad_cnt <= {ifmap_spad_cnt[3:2] + 2'd1, 2'b0};
						else
							ifmap_spad_cnt <= ifmap_spad_cnt + `IFMAP_INDEX_BIT'b1;
					end
				end
			end
			//WRITE_OPSUM :begin
			//	if(next_state == READ_IFMAP)begin
			//		psum_spad_cnt <= 0;
			//		filter_spad_cnt <= 0;
			//		ifmap_spad_cnt <= {2'b0, (filter_rs - 2'b1)} * 4;
			//	end else if(opsum_ready && state_mul2 == WRITE_OPSUM)
			//		psum_spad_cnt <= psum_spad_cnt - `OFMAP_INDEX_BIT'b1;
			//end
			default:begin 
				if(state_mul2 == WRITE_OPSUM)begin
					if(next_state == READ_IFMAP)begin
						psum_spad_cnt <= 0;
						filter_spad_cnt <= 0;
						ifmap_spad_cnt <= {2'b0, (filter_rs - 2'b1)} * 4;
					end else if(opsum_ready)begin
						psum_spad_cnt <= psum_spad_cnt - `OFMAP_INDEX_BIT'b1;
					end
				end
			end
		endcase
	end
end

wire [2:0] state_mul1;
wire [7:0] mul_operand1_mul1;
wire [7:0] mul_operand2_mul1;
wire [1:0] psum_spad_cnt_mul1;
Reg_MUL1 reg_mul1(
	.clk(clk),
	.rst(rst),
	.state_read_spad(state_read_spad),
	.mul_operand1_read_spad(filter_spad[filter_spad_cnt]),
	.mul_operand2_read_spad(ifmap_spad[ifmap_spad_cnt]),
	.psum_spad_cnt(psum_spad_cnt),

	.state_mul1(state_mul1),
	.mul_operand1_mul1(mul_operand1_mul1),
	.mul_operand2_mul1(mul_operand2_mul1),
	.psum_spad_cnt_mul1(psum_spad_cnt_mul1)
);
// MUL1 state
reg [7:0] partial_sum[7:0];
always @(*) begin
	for (i = 0; i < 8; i=i+1) begin	
		partial_sum[i] = mul_operand1_mul1 & {8{mul_operand2_mul1[i]}};
	end
end

reg [8:0] temp_mul1 [2:0];
always_comb begin
    temp_mul1[0] = {1'b0, partial_sum[1]} + {2'b0, partial_sum[0][7:1]};
    temp_mul1[1] = {1'b0, partial_sum[2]} + {2'b0, temp_mul1[0][7:1]};
    temp_mul1[2] = {1'b0, partial_sum[3]} + {2'b0, temp_mul1[1][7:1]};
end
wire [2:0] state_mul2;
wire [11:0] middle_result_mul2;
wire [1:0] psum_spad_cnt_mul2;
wire [31:0] partial_sum_mul2;
Reg_MUL2 reg_mul2(
	.clk(clk),
	.rst(rst),
	.state_mul1(state_mul1),
	.middle_result_mul1({temp_mul1[2] ,temp_mul1[1][0] ,temp_mul1[0][0], partial_sum[0][0]}),
	.psum_spad_cnt_mul1(psum_spad_cnt_mul1),
	.partial_sum_mul1({partial_sum[7], partial_sum[6], partial_sum[5], partial_sum[4]}),

	.state_mul2(state_mul2),
	.middle_result_mul2(middle_result_mul2),
	.psum_spad_cnt_mul2(psum_spad_cnt_mul2),
	.partial_sum_mul2(partial_sum_mul2)
);
// MUL1 state
reg [8:0] temp_mul2 [3:0];
always_comb begin
    temp_mul2[0] = {1'b0, partial_sum_mul2[7:0]} + {1'b0, middle_result_mul2[11:4]};
    temp_mul2[1] = {1'b0, partial_sum_mul2[15:8]} + {2'b0, temp_mul2[0][7:1]};
    temp_mul2[2] = {1'b0, partial_sum_mul2[23:16]} + {2'b0, temp_mul2[1][7:1]};
    temp_mul2[3] = {1'b0, partial_sum_mul2[31:24]} + {2'b0, temp_mul2[2][7:1]};
end

wire [15:0] product_result;
assign product_result = {temp_mul2[3], temp_mul2[2][0], temp_mul2[1][0], temp_mul2[0][0], middle_result_mul2[3:0]};
always@(*) begin
	// output opsum
	opsum = psum_spad[psum_spad_cnt_mul2];

	// AXI signal
	filter_ready = (state_read_spad == READ_FILTER) ? 1'b1 : 1'b0;
	ifmap_ready = (state_read_spad == READ_IFMAP) ? 1'b1 : 1'b0;
	ipsum_ready = (state_read_spad == READ_IPSUM) ? 1'b1 : 1'b0;
	opsum_valid = (state_mul2 == WRITE_OPSUM)? 1'b1: 1'b0;
end
endmodule

module Reg_MUL1(
	input clk,
	input rst,
	input [2:0] state_read_spad,
	input [`FILTER_SIZE-1:0] mul_operand1_read_spad,
	input [`IFMAP_SIZE-1:0] mul_operand2_read_spad,
	input [`OFMAP_INDEX_BIT - 1:0] psum_spad_cnt,

	output reg [2:0] state_mul1,
	output reg [`FILTER_SIZE-1:0] mul_operand1_mul1,
	output reg [`IFMAP_SIZE-1:0] mul_operand2_mul1,
	output reg [`OFMAP_INDEX_BIT - 1:0] psum_spad_cnt_mul1
);
always @(posedge clk or posedge rst) begin
	if(rst)begin
		state_mul1 <= 3'b0;
		mul_operand1_mul1 <= `FILTER_SIZE'b0;
		mul_operand2_mul1 <= `IFMAP_SIZE'b0;
		psum_spad_cnt_mul1 <= `OFMAP_INDEX_BIT'b0;
	end
	else begin
		state_mul1 <= state_read_spad;
		mul_operand1_mul1 <= mul_operand1_read_spad;
		mul_operand2_mul1 <= mul_operand2_read_spad;
		psum_spad_cnt_mul1 <= psum_spad_cnt;
	end
end
endmodule

module Reg_MUL2(
	input clk,
	input rst,
	input [2:0] state_mul1,
	input [11:0] middle_result_mul1,
	input [`OFMAP_INDEX_BIT - 1:0] psum_spad_cnt_mul1,
	input [8*4-1:0] partial_sum_mul1,

	output reg [2:0] state_mul2,
	output reg [11:0] middle_result_mul2,
	output reg [`OFMAP_INDEX_BIT - 1:0] psum_spad_cnt_mul2,
	output reg [8*4-1:0] partial_sum_mul2
);
always @(posedge clk or posedge rst) begin
	if(rst)begin
		state_mul2 <= 3'b0;
		middle_result_mul2 <= 12'b0;
		psum_spad_cnt_mul2 <= `OFMAP_INDEX_BIT'b0;
		partial_sum_mul2 <= 32'b0;
	end
	else begin
		state_mul2 <= state_mul1;
		middle_result_mul2 <= middle_result_mul1;
		psum_spad_cnt_mul2 <= psum_spad_cnt_mul1;
		partial_sum_mul2 <= partial_sum_mul1;
	end
end

endmodule