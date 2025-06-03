`include "define.svh"
module post_quant (
    input [`DATA_BITS-1:0] data_in,
    input [5:0] scaling_factor,
    output logic [7:0] data_out
);

logic [`DATA_BITS-1:0] shifted_data;

always_comb begin
    shifted_data = $signed(data_in) >>> scaling_factor;
    data_out = (shifted_data[`DATA_BITS-1])?
        ((&shifted_data[`DATA_BITS-1:7])? 8'd0 : shifted_data[7:0]) : // clamp (neg num + 128)
        ((|shifted_data[`DATA_BITS-1:7])? 8'd255 : {1'b1, shifted_data[6:0]}); // clamp (pos_num + 128)
end

endmodule
