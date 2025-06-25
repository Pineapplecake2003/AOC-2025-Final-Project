/* verilator lint_off MULTITOP */
`include "src/PE_array/GON/GON_Bus.sv"
`include "src/PE_array/GON/GON_MulticastController.sv"
module GON (
  input clk,
  input rst,

  /* Master GON <-> GLB */
  output logic GON_valid,
  input GON_ready,
  output logic [`DATA_BITS-1:0] GON_data,

  /* Controller <-> GON */
  input [`XID_BITS-1:0] tag_X,
  input [`YID_BITS-1:0] tag_Y,

  /* config */
  input set_XID,
  input [`XID_BITS - 1:0] XID_scan_in,
  input set_YID,
  input [`YID_BITS - 1:0] YID_scan_in,

  // Master PE <-> GON
  input [`NUMS_PE_ROW * `NUMS_PE_COL - 1:0] PE_valid,
  output logic [`NUMS_PE_ROW * `NUMS_PE_COL - 1:0] PE_ready,
  input [`DATA_BITS * `NUMS_PE_ROW * `NUMS_PE_COL - 1:0] PE_data
);

logic [`YID_BITS - 1:0] YID_scan_out;
logic [`NUMS_PE_ROW - 1:0] X_Bus_ready;
logic [`NUMS_PE_ROW - 1:0] X_Bus_valid;
logic [`DATA_BITS * `NUMS_PE_ROW - 1:0] X_Bus_data;

logic [`XID_BITS * (`NUMS_PE_ROW + 1) - 1:0] XID_chain;
GON_Bus #(`NUMS_PE_ROW, `YID_BITS) Y_Bus (
  .clk(clk),
  .rst(rst),
  // Master I/O
  .tag(tag_Y),
  .master_valid(X_Bus_valid),
  .master_data(X_Bus_data),
  .master_ready(X_Bus_ready),
  // Slave I/O
  .slave_ready(GON_ready),
  .slave_valid(GON_valid),
  .slave_data(GON_data),
  // Config
  .set_id(set_YID),
  .ID_scan_in(YID_scan_in),
  .ID_scan_out(YID_scan_out)
);


always_comb begin
  XID_chain[`XID_BITS-1:0] = XID_scan_in;
end

genvar i;
generate
  for (i = 0; i < `NUMS_PE_ROW; i = i + 1) begin
    GON_Bus #(`NUMS_PE_COL, `XID_BITS) X_Bus (
      .clk(clk),
      .rst(rst),
      // Master I/O
      .tag(tag_X),
      .master_valid(PE_valid[`NUMS_PE_COL * i +: `NUMS_PE_COL]),
      .master_data(PE_data[`DATA_BITS * `NUMS_PE_COL * i +: `DATA_BITS * `NUMS_PE_COL]),
      .master_ready(PE_ready[`NUMS_PE_COL * i +: `NUMS_PE_COL]),
      // Slave I/O
      .slave_ready(X_Bus_ready[i]),
      .slave_valid(X_Bus_valid[i]),
      .slave_data(X_Bus_data[`DATA_BITS * i +: `DATA_BITS]),
      // Config
      .set_id(set_XID),
      .ID_scan_in(XID_chain[`XID_BITS * i +: `XID_BITS]),
      .ID_scan_out(XID_chain[`XID_BITS * (i + 1) +: `XID_BITS])
    );
  end
endgenerate

endmodule
