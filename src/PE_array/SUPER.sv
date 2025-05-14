`include "define.svh"
module PE (
	input clk,
	input rst,
	input PE_en,
	input [`CONFIG_SIZE-1:0] i_config,
	input [`DATA_BITS-1:0] ifmap,
	input [`DATA_BITS-1:0] filter,
	input [`DATA_BITS-1:0] depthwise_ipsum,
	input [`DATA_BITS-1:0] pointwise_ipsum,
	input ifmap_valid,
	input filter_valid,
	input depthwise_ipsum_valid,
	input pointwise_ipsum_valid,
	input opsum_ready,
	output reg [`DATA_BITS-1:0] opsum,
	output reg ifmap_ready,
	output reg filter_ready,
	output reg depthwise_ipsum_ready,
	output reg pointwise_ipsum_ready,
	output reg opsum_valid
);
integer i;

// i_config
reg [`CONFIG_SIZE-1:0] i_config_reg;
reg  mode;
reg  [2:0] p; // output channel
reg  [4:0] F; // output column
reg  [2:0] q; // input channel
reg  [1:0] filter_rs;
reg depthwise;
always@(*) begin
	depthwise = i_config_reg[12];
	filter_rs = i_config_reg[11:10] + 2'b1;
	mode = i_config_reg[9];
	p = {1'b0, i_config_reg[8:7]} + 3'b1;
	F = i_config_reg[6:2];
	q = {1'b0, i_config_reg[1:0]} + 3'b1;
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

// MAC unit
wire signed [`DATA_BITS-1:0] MAC_result;
reg  signed [`IFMAP_SIZE-1:0]MAC_operand1;
reg  signed [`DATA_BITS-1:0]MAC_operand2;
assign MAC_result = MAC_operand1 * MAC_operand2;
always @(*) begin
	if(depthwise)begin
		if(state == DEPTH_CONV)begin
			MAC_operand1 = filter_spad[conv_filter_cnt];
			MAC_operand2 = {{24{ifmap_spad[conv_ifmap_cnt][7]}}, ifmap_spad[conv_ifmap_cnt]};
		end
		else if(state == CONV)begin
			MAC_operand1 = filter_spad[conv_filter_cnt];
			MAC_operand2 = psum_spad[conv_ifmap_cnt[2:0]];
		end
		else begin
			MAC_operand1 = 8'b0;
			MAC_operand2 = 32'b0;
		end
	end
	else begin
		if(state == CONV)begin
			MAC_operand1 = filter_spad[conv_filter_cnt];
			MAC_operand2 = {{24{ifmap_spad[conv_ifmap_cnt][7]}}, ifmap_spad[conv_ifmap_cnt]};
		end
		else begin
			MAC_operand1 = 8'b0;
			MAC_operand2 = 32'b0;
		end
	end
end


//spad
reg signed [`IFMAP_SIZE - 1:0] ifmap_spad  [0:`IFMAP_SPAD_LEN - 1];
reg signed [`FILTER_SIZE - 1:0]filter_spad [0:`FILTER_SPAD_LEN - 1];
reg signed [`PSUM_SIZE - 1:0]	 psum_spad [0:8 - 1];

// for debug
wire [7:0]debug_wire1 = ifmap_spad[conv_ifmap_cnt];
wire [7:0]debug_wire2 = filter_spad[conv_filter_cnt];
wire [7:0]debug_wire3 = split_ifmap[3];
wire [7:0]debug_wire4 = split_ifmap[3] ^ 128;
wire [31:0]debug_wire5 = filter_spad[conv_filter_cnt] * ifmap_spad[conv_ifmap_cnt];
wire [31:0]debug_wire6 =psum_spad[{1'b0, conv_result_cnt}];
// for debug

//spad counter
reg [`IFMAP_INDEX_BIT - 1:0]  ifmap_spad_cnt;
reg [`FILTER_INDEX_BIT - 1:0] filter_spad_cnt;
reg [`OFMAP_INDEX_BIT - 1:0]  psum_spad_cnt;
reg [`OFMAP_INDEX_BIT - 1:0]  point_psum_spad_cnt;
wire [2:0] point_psum_spad_pointer;
assign point_psum_spad_pointer = 3'd7-{1'b0 ,point_psum_spad_cnt};


// conv counter
reg [`IFMAP_INDEX_BIT - 1:0]  conv_ifmap_cnt;
reg [`FILTER_INDEX_BIT - 1:0] conv_filter_cnt;
reg [`OFMAP_INDEX_BIT - 1:0]  conv_result_cnt;

//split filter & ifmap 
reg [`FILTER_SIZE - 1:0] split_filter[0:3];
reg [`IFMAP_SIZE - 1:0] split_ifmap[0:3];

wire [3:0] shift;
assign shift = (q >= 1 && q <= 4) ? {1'b0, q} : 4'd12;
always@(*) begin
	{split_filter[3], split_filter[2], split_filter[1], split_filter[0]} = filter;
	{split_ifmap[3], split_ifmap[2], split_ifmap[1], split_ifmap[0]} = ifmap;
end
// counters logic
always @(posedge clk or posedge rst) begin
	if(rst)begin
		ifmap_spad_cnt <= `IFMAP_INDEX_BIT'b0;
		filter_spad_cnt <= `FILTER_INDEX_BIT'b0;
		psum_spad_cnt <= `OFMAP_INDEX_BIT'b0;
		conv_ifmap_cnt <= `IFMAP_INDEX_BIT'b0;
		conv_filter_cnt <= `FILTER_INDEX_BIT'b0;
		conv_result_cnt <= `OFMAP_INDEX_BIT'b0;
	end
	else begin
		case (state)
			IDLE:begin
				ifmap_spad_cnt <= `IFMAP_INDEX_BIT'b0;
				filter_spad_cnt <= `FILTER_INDEX_BIT'b0;
				psum_spad_cnt <= `OFMAP_INDEX_BIT'b0;
			end 
			READ_FILTER:begin
				psum_spad_cnt <= `OFMAP_INDEX_BIT'b0;
				if (filter_valid)
					filter_spad_cnt <= filter_spad_cnt + {3'b0, q};
			end
			READ_IFMAP:begin
				if(ifmap_valid)
					ifmap_spad_cnt <= ifmap_spad_cnt + {1'b0, q};
			end
			READ_IPSUM:begin
				if(depthwise_ipsum_valid)
					psum_spad_cnt <= psum_spad_cnt + `OFMAP_INDEX_BIT'b1;
				if(next_state == READ_POINT_IPSUM)
					point_psum_spad_cnt <= 2'd3;
			end
			READ_POINT_IPSUM: begin
				if(pointwise_ipsum_valid)
					point_psum_spad_cnt <= point_psum_spad_cnt - `OFMAP_INDEX_BIT'b1;
				if(next_state == DEPTH_CONV)
					point_psum_spad_cnt <= 2'd3;
			end
			DEPTH_CONV:begin
				if(conv_result_cnt == p[1:0]-2'b1)begin
					conv_result_cnt <= `OFMAP_INDEX_BIT'b0;
				end
				else begin
					conv_result_cnt <= conv_result_cnt + `OFMAP_INDEX_BIT'b1;
				end
				conv_filter_cnt <= conv_filter_cnt + `FILTER_INDEX_BIT'b1;
				conv_ifmap_cnt <= conv_ifmap_cnt + `IFMAP_INDEX_BIT'b1;
				if(next_state == CONV)begin
					conv_ifmap_cnt <= 4'b0;
				end
			end
			CONV: begin
				// filter, ifmap, and psum pointer update.
				if(depthwise)begin
					conv_filter_cnt <= conv_filter_cnt + `FILTER_INDEX_BIT'b1;
					if(conv_ifmap_cnt == {1'b0, p}-4'b1)begin
						conv_ifmap_cnt <= `IFMAP_INDEX_BIT'b0;
						point_psum_spad_cnt <= point_psum_spad_cnt - 1;
					end
					else begin
						conv_ifmap_cnt <= conv_ifmap_cnt + `IFMAP_INDEX_BIT'b1;
					end
					if(next_state == READ_IFMAP)begin
						//reset conv cnt
						conv_result_cnt <= `OFMAP_INDEX_BIT'b0;
						conv_ifmap_cnt <= `IFMAP_INDEX_BIT'b0;
						conv_filter_cnt <= `FILTER_INDEX_BIT'b0;
						//reset psum_cnt
						psum_spad_cnt <= `OFMAP_INDEX_BIT'b0;
						// ifmap pointer decrease by q
						ifmap_spad_cnt <= ifmap_spad_cnt - {1'b0, q};
						point_psum_spad_cnt <= 3;
					end
				end
				else begin
					conv_filter_cnt <= conv_filter_cnt + `FILTER_INDEX_BIT'b1;
					if(conv_ifmap_cnt == ifmap_spad_cnt - `IFMAP_INDEX_BIT'b1)begin
						conv_ifmap_cnt <= `IFMAP_INDEX_BIT'b0;
						conv_result_cnt <= conv_result_cnt + `OFMAP_INDEX_BIT'b1;
					end
					else begin
						conv_ifmap_cnt <= conv_ifmap_cnt + `IFMAP_INDEX_BIT'b1;
					end
				end
				if(next_state == WRITE_OPSUM)
					point_psum_spad_cnt <= 3;
			end
			WRITE_OPSUM:begin
				if(opsum_ready)
					conv_result_cnt <= conv_result_cnt + `OFMAP_INDEX_BIT'b1;
				if(next_state == READ_IFMAP)begin
					//reset conv cnt
					conv_result_cnt <= `OFMAP_INDEX_BIT'b0;
					conv_ifmap_cnt <= `IFMAP_INDEX_BIT'b0;
					conv_filter_cnt <= `FILTER_INDEX_BIT'b0;
					//reset psum_cnt
					psum_spad_cnt <= `OFMAP_INDEX_BIT'b0;
					// ifmap pointer decrease by q
					ifmap_spad_cnt <= ifmap_spad_cnt - {1'b0, q};
					point_psum_spad_cnt <= 0;
				end
			end
			default: begin
				ifmap_spad_cnt <= `IFMAP_INDEX_BIT'b0;
				filter_spad_cnt <= `FILTER_INDEX_BIT'b0;
				psum_spad_cnt <= `OFMAP_INDEX_BIT'b0;
				conv_ifmap_cnt <= `IFMAP_INDEX_BIT'b0;
				conv_filter_cnt <= `FILTER_INDEX_BIT'b0;
				conv_result_cnt <= `OFMAP_INDEX_BIT'b0;
			end
		endcase
	end
end

// spad logic
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
		case (state)
			READ_FILTER:begin
				if(filter_valid)begin
					filter_spad[
						filter_spad_cnt + `FILTER_INDEX_BIT'd0
					] <=  split_filter[0];
					filter_spad[
						filter_spad_cnt + `FILTER_INDEX_BIT'd1
					] <=  split_filter[1];
					filter_spad[
						filter_spad_cnt + `FILTER_INDEX_BIT'd2
					] <=  split_filter[2];
					filter_spad[
						filter_spad_cnt + `FILTER_INDEX_BIT'd3
					] <=  split_filter[3];
				end
			end
			READ_IFMAP:begin
				if(ifmap_valid)begin
					ifmap_spad[
						ifmap_spad_cnt + `IFMAP_INDEX_BIT'd0
					] <= split_ifmap[0]  ^ `IFMAP_SIZE'd128;
					ifmap_spad[
						ifmap_spad_cnt + `IFMAP_INDEX_BIT'd1
					] <= split_ifmap[1]  ^ `IFMAP_SIZE'd128;
					ifmap_spad[
						ifmap_spad_cnt + `IFMAP_INDEX_BIT'd2
					] <= split_ifmap[2]  ^ `IFMAP_SIZE'd128;
					ifmap_spad[
						ifmap_spad_cnt + `IFMAP_INDEX_BIT'd3
					] <= split_ifmap[3]  ^ `IFMAP_SIZE'd128;
				end
			end
			READ_IPSUM:begin
				if(depthwise_ipsum_valid)begin
					psum_spad[{1'b0, psum_spad_cnt}] <= depthwise_ipsum;
				end
			end
			READ_POINT_IPSUM:begin
				if(pointwise_ipsum_valid)begin
					psum_spad[point_psum_spad_pointer] <= pointwise_ipsum;
				end
			end
			DEPTH_CONV:begin
				psum_spad[{1'b0, conv_result_cnt}]<= psum_spad[{1'b0, conv_result_cnt}] + MAC_result;
			end
			CONV: begin
				if(depthwise)begin
					psum_spad[point_psum_spad_pointer]<= psum_spad[point_psum_spad_pointer] + MAC_result;
					if(next_state == READ_IFMAP)begin
						// push ifmap
						for (i = 0; i < 12; i++) 
							ifmap_spad[i] <= (i[2:0] + shift < 12) ? 
								ifmap_spad[i[2:0] + shift] : 
								`IFMAP_SIZE'b0;
					end
				end
				else
					psum_spad[{1'b0, conv_result_cnt}]<= psum_spad[{1'b0, conv_result_cnt}] + MAC_result;
			end
			WRITE_OPSUM:begin
				if(next_state == READ_IFMAP)begin
					// push ifmap
					for (i = 0; i < 12; i++) 
						ifmap_spad[i] <= (i[2:0] + shift < 12) ? 
							ifmap_spad[i[2:0] + shift] : 
							`IFMAP_SIZE'b0;
				end
			end
			default: begin
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
		endcase
	end
end

// check dont yet
reg [5:0] output_col_cnt;
always @(posedge clk or posedge rst) begin
	if(rst)begin
		output_col_cnt <= 6'b0;
	end
	else begin
		if(depthwise)begin
			if(state == CONV && next_state == READ_IFMAP)begin
				output_col_cnt <= output_col_cnt + 6'b1;
			end
		end
		else begin
			if(state == WRITE_OPSUM && next_state == READ_IFMAP)begin
				output_col_cnt <= output_col_cnt + 6'b1;
			end
		end
	end
end

// FSM controller
reg [2:0] state;
reg [2:0] next_state;
parameter IDLE          	= 3'd0;
parameter READ_FILTER   	= 3'd1;
parameter READ_IFMAP		= 3'd2;
parameter READ_IPSUM    	= 3'd3;
parameter READ_POINT_IPSUM  = 3'd4;
parameter DEPTH_CONV		= 3'd5;
parameter CONV				= 3'd6;
parameter WRITE_OPSUM   	= 3'd7;

always @(posedge clk or posedge rst) begin
	if(rst)begin
		state <= IDLE;
	end
	else begin
		state <= next_state;
	end
end

always @(*) begin
	case (state)
		IDLE: begin
			if(PE_en)begin
				next_state = READ_FILTER;
			end
			else begin
				next_state = IDLE;
			end
		end
		READ_FILTER: begin
			if({26'b0, filter_spad_cnt} == (p * q * filter_rs))begin
				// readed all filter
				next_state = READ_IFMAP;
			end
			else begin
				// not yet done
				next_state = READ_FILTER;
			end
		end
		READ_IFMAP: begin
			if({28'b0, ifmap_spad_cnt} == ({29'b0, q} * filter_rs))begin
				// readed all ifmap
				next_state = READ_IPSUM;
			end
			else if(output_col_cnt == {1'b0, F}+5'b1 && !opsum_valid)begin
				next_state = IDLE;
			end
			else begin
				// not yet done
				next_state = READ_IFMAP;
			end
		end
		READ_IPSUM: begin
			if(depthwise)begin
				if(({1'b0, psum_spad_cnt} == (q - 3'b1))&& depthwise_ipsum_valid && !opsum_valid)begin
					next_state = READ_POINT_IPSUM;
				end
				else if(output_col_cnt == {1'b0, F}+5'b1 && !opsum_valid)begin
					next_state = IDLE;
				end
				else begin
					next_state = READ_IPSUM;
				end
			end
			else begin
				if(({1'b0, psum_spad_cnt} == (p - 3'b1))&& depthwise_ipsum_valid)begin
					next_state = CONV;
				end
				else begin
					next_state = READ_IPSUM;
				end
			end
		end
		READ_POINT_IPSUM: begin
			if((3'd7 - {1'b0, point_psum_spad_cnt} == 3'd7) && pointwise_ipsum_valid)begin
				next_state = DEPTH_CONV;
			end
			else if(output_col_cnt == {1'b0, F}+5'b1 && !opsum_valid)begin
				next_state = IDLE;
			end
			else begin
				// not yet done
				next_state = READ_POINT_IPSUM;
			end
		end
		DEPTH_CONV:begin
			if({1'b0,conv_result_cnt} == (p-1) && conv_ifmap_cnt == ((filter_rs * q) -1))begin
				next_state = CONV;
			end
			else begin
				next_state = DEPTH_CONV;
			end
		end
		CONV:begin
			if(depthwise)begin
				if(conv_filter_cnt == filter_rs * q + p * q - 1)begin
					// all filter used
					next_state = READ_IFMAP;
				end
				else begin
					next_state = CONV;
				end
			end
			else begin
				if(conv_filter_cnt == filter_spad_cnt - `FILTER_INDEX_BIT'b1)begin
					// all filter used
					next_state = WRITE_OPSUM;
				end
				else begin
					next_state = CONV;
				end
			end
		end
		WRITE_OPSUM:begin
			if(({1'b0, conv_result_cnt} == (p - 3'b1)) && opsum_ready)begin
				if (output_col_cnt == {1'b0, F}) begin
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
		default: next_state = IDLE;
	endcase
end

// opsum valid different logic when depthwise
always @(posedge clk or posedge rst) begin
	if(rst)
		opsum_valid <= 1'b0;
	else if(depthwise)begin
		if(state == CONV && next_state == READ_IFMAP)begin
			opsum_valid <= 1'b1;
		end
		else if(({1'b0, point_psum_spad_cnt} == 3-(p-1)) && opsum_ready)begin
			opsum_valid <= 1'b0;
		end
	end
	else begin
		if(next_state == WRITE_OPSUM)begin
			opsum_valid <= 1'b1;
		end
		else if(next_state == READ_IFMAP)begin
			opsum_valid <= 1'b0;
		end
	end
end

always @(posedge clk or posedge rst) begin
	if(rst)begin
		point_psum_spad_cnt <= `OFMAP_INDEX_BIT'b0;
	end
	else begin
		if(depthwise)begin
			if(opsum_ready && opsum_valid)
				point_psum_spad_cnt <= point_psum_spad_cnt - `OFMAP_INDEX_BIT'b1;
		end
	end

end
always@(*) begin
	// output opsum
	opsum = (depthwise)? psum_spad[point_psum_spad_pointer] : psum_spad[{1'b0 ,conv_result_cnt}];

	// AXI signal
	filter_ready = (state == READ_FILTER) ? 1'b1 : 1'b0;
	ifmap_ready = (state == READ_IFMAP) ? 1'b1 : 1'b0;
	depthwise_ipsum_ready = (state == READ_IPSUM) ? 1'b1 : 1'b0;
	pointwise_ipsum_ready = (state == READ_POINT_IPSUM) ? 1'b1 : 1'b0;
	//opsum_valid = (state == WRITE_OPSUM)? 1'b1: 1'b0;
end


endmodule