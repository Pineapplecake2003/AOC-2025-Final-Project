module GON_Bus #(
    parameter NUMS_MASTER = `NUMS_PE_COL,
    parameter ID_SIZE = `XID_BITS
)(
    input clk,
    input rst,
    input [ID_SIZE - 1:0] tag,

    input [NUMS_MASTER - 1:0] master_valid,
    input [NUMS_MASTER * `DATA_BITS - 1:0] master_data,
    output logic [NUMS_MASTER - 1:0] master_ready,

    output logic slave_valid,
    input slave_ready,
    output logic [`DATA_BITS - 1:0] slave_data,

    // Config
    input set_id,
    input [ID_SIZE - 1:0] ID_scan_in,
    output logic [ID_SIZE - 1 :0] ID_scan_out
);

logic [ID_SIZE-1:0] MC_id [NUMS_MASTER:0];
logic [NUMS_MASTER-1:0] MC_valid_out;
logic [`DATA_BITS - 1:0] master_data_array [NUMS_MASTER-1:0];

always_comb begin
    MC_id[0] = ID_scan_in;
    ID_scan_out = MC_id[NUMS_MASTER];
    slave_valid = |MC_valid_out;
end

genvar i;
generate;
    for(i = 0; i < NUMS_MASTER; i = i + 1) begin: MC_num
        GON_MulticastController #(
            .ID_SIZE(ID_SIZE)
        ) MC(
            .clk(clk),
            .rst(rst),
            .set_id(set_id),
            .id_in(MC_id[i]),
            .id(MC_id[i + 1]),
            .tag(tag),
            .valid_in(master_valid[i]),     // MC valid in (from master)
            .valid_out(MC_valid_out[i]),    // PE valid out (MC valid out)
            .ready_in(slave_ready),         // PE ready in (MC ready in)
            .ready_out(master_ready[i])     // MC ready out wire
        );
        assign master_data_array[i] = master_data[`DATA_BITS * (i+1) - 1 : `DATA_BITS * i];
    end
endgenerate

always_comb begin
    slave_data = 0;
    for(int j = 0; j < NUMS_MASTER; j = j + 1) begin
        if(MC_valid_out[j]) begin
            slave_data = master_data_array[j];
        end
    end
end

endmodule
