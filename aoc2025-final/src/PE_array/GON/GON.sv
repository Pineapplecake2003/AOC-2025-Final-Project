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

// set id wire
logic [`YID_BITS - 1:0] YID_scan_out; // (unconnected wire)
logic [`XID_BITS - 1:0] XID_scan_in_wire [`NUMS_PE_ROW:0];

always_comb begin
    XID_scan_in_wire[0] = XID_scan_in;
end

// PE <-> GON wire
logic [`NUMS_PE_COL - 1:0] PE_valid_array [`NUMS_PE_ROW - 1:0];
logic [`NUMS_PE_COL - 1:0] PE_ready_array [`NUMS_PE_ROW - 1:0];
logic [`NUMS_PE_COL * `DATA_BITS - 1:0] PE_data_array [`NUMS_PE_ROW - 1:0];

// X_bus <-> Y_bus wire
logic [`NUMS_PE_ROW - 1:0] Master_X_to_Slave_Y_valid;
logic [`NUMS_PE_ROW - 1:0] Master_X_to_Slave_Y_ready;
logic [`NUMS_PE_ROW*`DATA_BITS - 1:0] Master_X_to_Slave_Y_data;

// Y bus
GON_Bus #(
    .NUMS_MASTER(`NUMS_PE_ROW),
    .ID_SIZE(`YID_BITS)
) GON_Bus_Y(
    .clk(clk),
    .rst(rst),
    .tag(tag_Y),
    .master_valid(Master_X_to_Slave_Y_valid),
    .master_data(Master_X_to_Slave_Y_data),
    .master_ready(Master_X_to_Slave_Y_ready),
    .slave_valid(GON_valid),
    .slave_ready(GON_ready),
    .slave_data(GON_data),
    .set_id(set_YID),
    .ID_scan_in(YID_scan_in),
    .ID_scan_out(YID_scan_out)
);

genvar i;
generate;
    for(i = 0; i < `NUMS_PE_ROW; i = i + 1) begin: GON_BUS_X
        // PE <-> GON wire
        assign PE_valid_array[i] = PE_valid[`NUMS_PE_COL*(i+1)-1:`NUMS_PE_COL*i];
        assign PE_ready[`NUMS_PE_COL*(i+1)-1:`NUMS_PE_COL*i] = PE_ready_array[i];
        assign PE_data_array[i] = PE_data[`DATA_BITS*`NUMS_PE_COL*(i+1) - 1:`DATA_BITS*`NUMS_PE_COL*i];
        // X bus
        GON_Bus #(
            .NUMS_MASTER(`NUMS_PE_COL),
            .ID_SIZE(`XID_BITS)
        ) GON_BUS_X(
            .clk(clk),
            .rst(rst),
            .tag(tag_X),
            .master_valid(PE_valid_array[i]),
            .master_data(PE_data_array[i]),
            .master_ready(PE_ready_array[i]),
            .slave_valid(Master_X_to_Slave_Y_valid[i]),
            .slave_ready(Master_X_to_Slave_Y_ready[i]),
            .slave_data(Master_X_to_Slave_Y_data[`DATA_BITS*(i+1) - 1:`DATA_BITS*i]),
            .set_id(set_XID),
            .ID_scan_in(XID_scan_in_wire[i]),
            .ID_scan_out(XID_scan_in_wire[i + 1])
        );
    end
endgenerate

endmodule
