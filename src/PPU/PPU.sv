`include "src/PPU/post_quant.sv"
`include "src/PPU/Comparator_Qint8.sv"
`include "src/PPU/ReLU_Qint8.sv"
`include "define.svh"

module PPU (
  input clk,
  input rst,
  input [`DATA_BITS-1:0] data_in,
  input [5:0] scaling_factor,
  input maxpool_en,
  input maxpool_init,
  input relu_sel,
  input relu_en,
  output logic[7:0] data_out
);
wire [`DATA_BITS-1:0] relu_out;
wire [8-1:0] quanted_value;
wire [8-1:0] maxpool_out;

ReLU_Qint8 ReLU_Qint8_0(
	.relu_en(relu_en),
	.relu_in(data_in),
	.relu_out(relu_out)
);

post_quant post_quant_0(
	.data_in(relu_out),
	.scaling_factor(scaling_factor),
	.quanted_value(quanted_value)
);

Comparator_Qint8 Comparator_Qint8_0(
	.clk(clk),
	.rst(rst),
	.maxpool_en(maxpool_en),
    .maxpool_init(maxpool_init),
	.maxpool_in(quanted_value),
	.maxpool_out(maxpool_out)
);

assign data_out = (relu_sel)?maxpool_out : quanted_value;
endmodule