/* verilator lint_off MULTITOP */
`include "../../src/PE_array/GIN/GIN_Bus.sv"
`include "../../src/PE_array/GIN/GIN_MulticastController.sv"
`include "../../include/define.svh"
module GIN (
  input clk,
  input rst,

  // Slave SRAM <-> GIN
  input GIN_valid,
  output logic GIN_ready,
  input [`DATA_BITS - 1:0] GIN_data,

  /* Controller <-> GIN */
  input [`XID_BITS - 1:0] tag_X,
  input [`YID_BITS - 1:0] tag_Y,

  /* config */
  input set_XID,
  input [`XID_BITS - 1:0] XID_scan_in,
  input set_YID,
  input [`YID_BITS - 1:0] YID_scan_in,

  // Master GIN <-> PE
  input [`NUMS_PE_ROW * `NUMS_PE_COL - 1:0] PE_ready,
  output logic [`NUMS_PE_ROW * `NUMS_PE_COL - 1:0] PE_valid,
  output logic [`DATA_BITS - 1:0] PE_data
);

logic [`YID_BITS - 1:0] YID_scan_out;
logic [`NUMS_PE_ROW - 1:0] X_Bus_ready;
logic [`NUMS_PE_ROW - 1:0] X_Bus_valid;
logic [`DATA_BITS-1:0] X_Bus_data;

GIN_Bus #(`NUMS_PE_ROW, `YID_BITS) Y_Bus (
  .clk(clk),
  .rst(rst),
  // Master I/O
  .tag(tag_Y),
  .master_valid(GIN_valid),
  .master_data(GIN_data),
  .master_ready(GIN_ready),
  // Slave I/O
  .slave_ready(X_Bus_ready),
  .slave_valid(X_Bus_valid),
  .slave_data(X_Bus_data),
  // Config
  .set_id(set_YID),
  .ID_scan_in(YID_scan_in),
  .ID_scan_out(YID_scan_out)
);

logic [`XID_BITS * (`NUMS_PE_ROW + 1) - 1:0] XID_chain;
logic [31:0] single_PE_data[`NUMS_PE_ROW-1:0];
assign PE_data = {
  single_PE_data[0] | single_PE_data[1] | single_PE_data[2] | 
  single_PE_data[3] | single_PE_data[4] | single_PE_data[5]
};

always_comb begin
    XID_chain[`XID_BITS-1:0] = XID_scan_in; 
end

genvar i;
generate
  for (i = 0; i < `NUMS_PE_ROW; i = i + 1) begin
    GIN_Bus #(`NUMS_PE_COL, `XID_BITS) X_Bus (
      .clk(clk),
      .rst(rst),
      // Master I/O
      .tag(tag_X),
      .master_valid(X_Bus_valid[i]),
      .master_data(X_Bus_data),
      .master_ready(X_Bus_ready[i]),
      // Slave I/O
      .slave_ready(PE_ready[`NUMS_PE_COL * i +: `NUMS_PE_COL]),
      .slave_valid(PE_valid[`NUMS_PE_COL * i +: `NUMS_PE_COL]),
      .slave_data(single_PE_data[i]),
      // Config
      .set_id(set_XID),
      .ID_scan_in(XID_chain[`XID_BITS * i +: `XID_BITS]),
      .ID_scan_out(XID_chain[`XID_BITS * (i + 1) +: `XID_BITS])
    );
  end
endgenerate

endmodule

