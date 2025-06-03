module GIN_MulticastController #(
    parameter ID_SIZE = `XID_BITS
)(
    input clk,
    input rst,

    input set_id,
    input [ID_SIZE - 1:0] id_in,
    output logic [ID_SIZE - 1:0] id,

    input [ID_SIZE - 1:0] tag,

    input valid_in,
    output logic valid_out,
    input ready_in,
    output logic ready_out
);

always_comb begin
    valid_out = (tag == id) & valid_in;
    ready_out = (tag == id) & ready_in;
end

always_ff @(posedge clk or posedge rst) begin
    if(rst) begin
        id <= 0;
    end
    else begin
        if(set_id) begin
            id <= id_in;
        end
        else begin
            id <= id;
        end
    end
end

endmodule
