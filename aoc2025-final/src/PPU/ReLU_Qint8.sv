`include "define.svh"
module ReLU_Qint8 (
    input en,
    input [`DATA_BITS-1:0] data_in,
    output logic [`DATA_BITS-1:0] data_out
);

always_comb begin
    if(en) begin
        data_out = (data_in[`DATA_BITS-1])? 0 : data_in;
    end
    else begin
        data_out = data_in;
    end
end

endmodule