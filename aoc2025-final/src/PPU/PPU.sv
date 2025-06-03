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

logic [`DATA_BITS-1:0] ReLU_out;
logic [7:0] pq_out, maxP_out;

ReLU_Qint8 ReLU_Qint8_unit(
    .en(relu_en),
    .data_in(data_in),
    .data_out(ReLU_out)
);

post_quant post_quant_unit(
    .data_in(ReLU_out),
    .scaling_factor(scaling_factor),
    .data_out(pq_out)
);

Comparator_Qint8 Comparator_Qint8_unit(
    .clk(clk),
    .rst(rst),
    .en(maxpool_en),
    .init(maxpool_init),
    .data_in(pq_out),
    .data_out(maxP_out)
);

always_ff @(posedge clk or posedge rst) begin
    if(rst) begin
        data_out <= 0;
    end
    else begin
        if(!relu_sel) begin
            data_out <= pq_out;
        end
        else begin
            data_out <= maxP_out;
        end
    end
end
endmodule