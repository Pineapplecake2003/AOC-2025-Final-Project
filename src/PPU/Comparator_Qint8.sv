`include "../../include/define.svh"

module Comparator_Qint8 (
	input clk,
	input rst,
	input maxpool_en,
  input maxpool_init,
	input [8-1:0] maxpool_in,
	output[8-1:0] maxpool_out
);
	reg [8 - 1:0] buffer;
	reg [1:0] comparator_cnt;


reg [3:0] one_hot_state;
always @(posedge clk or posedge rst) begin
	if(rst)begin
		one_hot_state <= 4'b0;
	end
	else begin
		one_hot_state [0] <= maxpool_init;
		one_hot_state [1] <= one_hot_state [0];
		one_hot_state [2] <= one_hot_state [1];
		one_hot_state [3] <= one_hot_state [2];
	end
end

always @(posedge clk or posedge rst) begin
	if(rst)begin
		buffer <= 8'b0;
	end
	else if(one_hot_state[3])begin
		// 4 cycles times up, reset buffer.
		buffer <= 8'b0;
	end
	else begin
		buffer <= (maxpool_in > buffer) ? maxpool_in : buffer;
	end
end

// if not in busy or en = 0, treat it as buffer.
assign maxpool_out = (one_hot_state != 4'b0 && maxpool_en)? buffer : maxpool_in;

endmodule