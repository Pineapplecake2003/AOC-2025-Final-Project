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
  output logic [`DATA_BITS-1:0] opsum,
  output logic ifmap_ready,
  output logic filter_ready,
  output logic ipsum_ready,
  output logic opsum_valid
);
integer i;

// i_config
logic [`CONFIG_SIZE-1:0] i_config_reg;
logic  mode;
logic  [2:0] p; // output channel
logic  [4:0] F; // output column
logic  [2:0] q; // input channel
logic  [1:0] filter_rs;
always_comb begin
	filter_rs = i_config_reg[11:10];
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

//spad
logic signed [`IFMAP_SIZE - 1:0] ifmap_spad  [0:`IFMAP_SPAD_LEN - 1];
logic signed [`FILTER_SIZE - 1:0]filter_spad [0:`FILTER_SPAD_LEN - 1];
logic signed [`PSUM_SIZE - 1:0]	 psum_spad [0:`OFMAP_SPAD_LEN - 1];

//spad counter
logic [`IFMAP_INDEX_BIT - 1:0]  ifmap_spad_cnt;
logic [`FILTER_INDEX_BIT - 1:0] filter_spad_cnt;
logic [`OFMAP_INDEX_BIT - 1:0]  psum_spad_cnt;

// conv counter
logic [`IFMAP_INDEX_BIT - 1:0]  conv_ifmap_cnt;
logic [`FILTER_INDEX_BIT - 1:0] conv_filter_cnt;
logic [`OFMAP_INDEX_BIT - 1:0]  conv_result_cnt;

// push counter
logic [`IFMAP_INDEX_BIT - 1: 0] push_ifmap_cnt;

//split filter & ifmap 
logic [`FILTER_SIZE - 1:0] split_filter[0:3];
logic [`IFMAP_SIZE - 1:0] split_ifmap[0:3];

wire [3:0] shift;
assign shift = (q >= 1 && q <= 4) ? {1'b0, q} : 4'd12;
always@(*) begin
	{split_filter[3], split_filter[2], split_filter[1], split_filter[0]} = filter;
	{split_ifmap[3], split_ifmap[2], split_ifmap[1], split_ifmap[0]} = ifmap;
end

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
		ifmap_spad_cnt <= `IFMAP_INDEX_BIT'b0;
		filter_spad_cnt <= `FILTER_INDEX_BIT'b0;
		psum_spad_cnt <= `OFMAP_INDEX_BIT'b0;
    
    conv_ifmap_cnt <= `IFMAP_INDEX_BIT'b0;
		conv_filter_cnt <= `FILTER_INDEX_BIT'b0;
		conv_result_cnt <= `OFMAP_INDEX_BIT'b0;

		push_ifmap_cnt <= `IFMAP_INDEX_BIT'b0;
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
					filter_spad_cnt <= filter_spad_cnt + {3'b0, q};
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
					ifmap_spad_cnt <= ifmap_spad_cnt + {1'b0, q};
				end
			end
			READ_IPSUM:begin
				if(ipsum_valid)begin
					psum_spad[psum_spad_cnt] <= ipsum;
					psum_spad_cnt <= psum_spad_cnt + `OFMAP_INDEX_BIT'b1;
				end
			end
			CONV:begin
        //MAC
        psum_spad[conv_result_cnt] <= psum_spad[conv_result_cnt] + (
					filter_spad[conv_filter_cnt] * ifmap_spad[conv_ifmap_cnt]
				);
				// filter, ifmap, and psum pointer update.
        conv_filter_cnt <= conv_filter_cnt + `FILTER_INDEX_BIT'b1;
        if(conv_ifmap_cnt == ifmap_spad_cnt - `IFMAP_INDEX_BIT'b1)begin
          conv_ifmap_cnt <= `IFMAP_INDEX_BIT'b0;
          conv_result_cnt <= conv_result_cnt + `OFMAP_INDEX_BIT'b1;
        end
        else begin
          conv_ifmap_cnt <= conv_ifmap_cnt + `IFMAP_INDEX_BIT'b1;
        end
      end
      WRITE_OPSUM:begin
        if(opsum_ready)begin
          conv_result_cnt <= conv_result_cnt + `OFMAP_INDEX_BIT'b1;
				end
				if(next_state == READ_IFMAP)begin
					// push ifmap
					for (int i = 0; i < 12; i++) 
						ifmap_spad[i] <= (i[2:0] + shift < 12) ? 
							ifmap_spad[i[2:0] + shift] : 
							`IFMAP_SIZE'b0;

					//reset conv cnt
					//conv_result_cnt will overflow to 0 don't need to reset.
					conv_ifmap_cnt <= `IFMAP_INDEX_BIT'b0;
					conv_filter_cnt <= `FILTER_INDEX_BIT'b0;
        	//reset psum_cnt
					psum_spad_cnt <= `OFMAP_INDEX_BIT'b0;
					//reset push counter
					push_ifmap_cnt <= `IFMAP_INDEX_BIT'b0;
					// ifmap pointer decrease by q
					ifmap_spad_cnt <= ifmap_spad_cnt - {1'b0, q};
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

// check dont yet
reg [4:0] output_col_cnt;
always @(posedge clk or posedge rst) begin
	if(rst)begin
		output_col_cnt <= 5'b0;
	end
	else if(state == WRITE_OPSUM && next_state == READ_IFMAP)begin
		output_col_cnt <= output_col_cnt + 5'b1;
	end
end

// FSM controller
reg [2:0] state;
reg [2:0] next_state;
parameter IDLE          	= 3'd0;
parameter READ_FILTER   	= 3'd1;
parameter READ_IFMAP			= 3'd2;
parameter READ_IPSUM    	= 3'd3;
parameter CONV						= 3'd4;
parameter WRITE_OPSUM   	= 3'd5;

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
			else begin
				// not yet done
				next_state = READ_IFMAP;
			end
		end
		READ_IPSUM: begin
      if(({1'b0, psum_spad_cnt} == (p - 3'b1)) && ipsum_valid)begin
        //readed all ipsum
        next_state = CONV;
      end
      else begin
        // not yet done
        next_state = READ_IPSUM;
      end
		end
		CONV:begin
      if(conv_filter_cnt == filter_spad_cnt - `FILTER_INDEX_BIT'b1)begin
        next_state = WRITE_OPSUM;
      end
      else begin
				next_state = CONV;
      end
		end
		WRITE_OPSUM:begin
      if(({1'b0, conv_result_cnt} == (p - 3'b1)) && opsum_ready)begin
        next_state = READ_IFMAP;
      end
      else begin
        next_state = WRITE_OPSUM;
      end
    end
		default: next_state = IDLE;
	endcase
end

always_comb begin
	// output opsum
	opsum = psum_spad[conv_result_cnt];

	// AXI signal
	filter_ready = (state == READ_FILTER) ? 1'b1 : 1'b0;
	ifmap_ready = (state == READ_IFMAP) ? 1'b1 : 1'b0;
	ipsum_ready = (state == READ_IPSUM) ? 1'b1 : 1'b0;
	opsum_valid = (state == WRITE_OPSUM)? 1'b1: 1'b0;

end


endmodule