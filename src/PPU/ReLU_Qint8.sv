`include "define.svh"

module ReLU_Qint8 (
	input relu_en,
	input [`DATA_BITS - 1 : 0]relu_in,
	output [`DATA_BITS - 1 : 0]relu_out
);
wire MSB_inverse;
assign MSB_inverse = ~relu_in[`DATA_BITS - 1];

// if en = 0, treat it as buffer.
assign relu_out = (relu_en) ? relu_in & {`DATA_BITS{MSB_inverse}} : relu_in;
endmodule