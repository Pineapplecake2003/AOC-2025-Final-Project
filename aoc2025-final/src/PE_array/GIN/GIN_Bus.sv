 module GIN_Bus #(
    parameter NUMS_SLAVE = `NUMS_PE_COL,
    parameter ID_SIZE = `XID_BITS
) (
    input clk,
    input rst,

   // Master I/O
    input [ID_SIZE-1:0] tag,
    input master_valid,
    input [`DATA_BITS-1:0] master_data,
    output logic master_ready,

   // Slave I/O
    input [NUMS_SLAVE-1:0] slave_ready,
    output logic [NUMS_SLAVE-1:0] slave_valid,
    output logic [`DATA_BITS-1:0] slave_data,

    // Config
    input set_id,
    input [ID_SIZE-1:0] ID_scan_in,
    output logic [ID_SIZE-1:0] ID_scan_out
 );

logic [ID_SIZE-1:0] MC_id [NUMS_SLAVE:0];
logic [NUMS_SLAVE-1:0] MC_ready_out;

always_comb begin
    MC_id[0] = ID_scan_in;
    ID_scan_out = MC_id[NUMS_SLAVE];
    slave_data = master_data;
    master_ready = |MC_ready_out;
end

genvar i;
generate;
    for(i = 0; i < NUMS_SLAVE; i = i + 1) begin: MC_num
        GIN_MulticastController #(
            .ID_SIZE(ID_SIZE)
        ) MC(
            .clk(clk),
            .rst(rst),
            .set_id(set_id),
            .id_in(MC_id[i]),
            .id(MC_id[i + 1]),
            .tag(tag),
            .valid_in(master_valid),    // MC valid in (from master)
            .valid_out(slave_valid[i]), // PE valid in (MC valid out)
            .ready_in(slave_ready[i]),  // PE ready out (MC ready in)
            .ready_out(MC_ready_out[i]) // MC ready out wire
        );
    end
endgenerate

endmodule
