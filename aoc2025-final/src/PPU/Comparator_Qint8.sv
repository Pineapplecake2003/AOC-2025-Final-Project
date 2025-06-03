module Comparator_Qint8(
    input clk,
    input rst,
    input en,
    input init,
    input logic [7:0] data_in,
    output logic [7:0] data_out
);

logic [7:0] max_data;

always_comb begin
    data_out = (data_in > max_data)? data_in : max_data;
end

always_ff @(posedge clk or posedge rst) begin
    if(rst) begin
        max_data    <= 0;
    end
    else begin
        if(init) begin
            max_data <= data_in;
        end
        else begin
            max_data <= data_out;
        end
    end
end

endmodule
