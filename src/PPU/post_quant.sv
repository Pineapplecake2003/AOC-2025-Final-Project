`include "define.svh"

module post_quant(
	input [`DATA_BITS - 1 : 0] data_in,
	input [5:0] scaling_factor,
	output [8 - 1 : 0] quanted_value
);
wire [8 - 1 : 0] product_scaling_factor_unclamp;
wire [8 - 1 : 0] product_scaling_factor;
assign product_scaling_factor_unclamp = {(data_in) >> scaling_factor}[7:0];

// overflow, 
// clamp it to (127)0111_1111, so that add 128(1000_0000) equals to (256)1111_1111
assign product_scaling_factor = (product_scaling_factor_unclamp[7]) ? 8'd127 : 
	product_scaling_factor_unclamp;

assign quanted_value = product_scaling_factor ^ 8'd128;
endmodule