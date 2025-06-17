`include "../../include/define.svh"

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

logic [ID_SIZE * (NUMS_SLAVE + 1) - 1:0] MC_id_chain;
logic [NUMS_SLAVE - 1: 0] MC_ready;

always_comb begin
    MC_id_chain[ID_SIZE-1:0] = ID_scan_in;
    ID_scan_out = MC_id_chain[ID_SIZE * NUMS_SLAVE +: ID_SIZE]; 
    slave_data = master_data;
    master_ready = |MC_ready;
end

genvar i;
generate
  for (i = 0; i < NUMS_SLAVE; i = i + 1) begin: MC_dachi
    GIN_MulticastController #ID_SIZE MC(
      .clk(clk),
      .rst(rst),
      .set_id(set_id),
      .id_in(MC_id_chain[ID_SIZE * i +: ID_SIZE]),  
      .id(MC_id_chain[ID_SIZE * (i + 1) +: ID_SIZE]),
      .tag(tag),
      // form bus
      .ready_in(slave_ready[i]),
      .valid_out(slave_valid[i]),
      // to PE 
      .valid_in(master_valid),
      .ready_out(MC_ready[i])
    );
  end
endgenerate

endmodule
