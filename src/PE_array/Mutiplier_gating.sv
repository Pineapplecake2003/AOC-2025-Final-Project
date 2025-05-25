`include "./include/define.svh"
module Mutiplier_gating (
    input  logic                      clk,
    input  logic                      en,
    input  logic signed [`FILTER_SIZE - 1:0] a,     // filter spad
    input  logic signed [`IFMAP_SIZE - 1:0]  b,     // ifmap spad
    output logic signed [`PSUM_SIZE - 1:0]   result // psum spad
);
    always_comb begin
        if (!en)
            result = a * b;
        else
            result = `PSUM_SIZE'd0;
    end
endmodule