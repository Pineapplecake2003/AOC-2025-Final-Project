`include "src/PE_array/GIN/GIN_Bus.sv"
`include "src/PE_array/GIN/GIN_MulticastController.sv"

module GIN (
    input clk,
    input rst,

    // Master GLB <-> GIN
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

// set id wire
logic [`YID_BITS - 1:0] YID_scan_out; // (unconnected wire)
logic [`XID_BITS - 1:0] XID_scan_in_wire [`NUMS_PE_ROW:0];

always_comb begin
    XID_scan_in_wire[0] = XID_scan_in;
end

// PE <-> GIN wire
logic [`NUMS_PE_COL - 1:0] PE_ready_array [`NUMS_PE_ROW - 1:0];
logic [`NUMS_PE_COL - 1:0] PE_valid_array [`NUMS_PE_ROW - 1:0];

// X_bus <-> Y_bus wire
logic [`NUMS_PE_ROW - 1:0] Slave_X_to_Master_Y_valid;
logic [`NUMS_PE_ROW - 1:0] Slave_X_to_Master_Y_ready;
logic [`DATA_BITS - 1:0] Slave_X_to_Master_Y_data;

// Y bus
GIN_Bus #(
    .NUMS_SLAVE(`NUMS_PE_ROW),
    .ID_SIZE(`YID_BITS)
) GIN_Bus_Y(
    .clk(clk),
    .rst(rst),
    .tag(tag_Y),
    .master_valid(GIN_valid),
    .master_data(GIN_data),
    .master_ready(GIN_ready),
    .slave_valid(Slave_X_to_Master_Y_valid),
    .slave_ready(Slave_X_to_Master_Y_ready),
    .slave_data(Slave_X_to_Master_Y_data),
    .set_id(set_YID),
    .ID_scan_in(YID_scan_in),
    .ID_scan_out(YID_scan_out)
);

genvar i;
generate;
    for(i = 0; i < `NUMS_PE_ROW; i = i + 1) begin: GIN_BUS_X
        // PE <-> GIN wire
        assign PE_ready_array[i] = PE_ready[`NUMS_PE_COL*(i+1)-1:`NUMS_PE_COL*i];
        assign PE_valid[`NUMS_PE_COL*(i+1)-1:`NUMS_PE_COL*i] = PE_valid_array[i];
        // X bus
        GIN_Bus #(
            .NUMS_SLAVE(`NUMS_PE_COL),
            .ID_SIZE(`XID_BITS)
        ) GIN_BUS_X(
            .clk(clk),
            .rst(rst),
            .tag(tag_X),
            .master_valid(Slave_X_to_Master_Y_valid[i]),
            .master_data(Slave_X_to_Master_Y_data),
            .master_ready(Slave_X_to_Master_Y_ready[i]),
            .slave_valid(PE_valid_array[i]),
            .slave_ready(PE_ready_array[i]),
            .slave_data(PE_data),
            .set_id(set_XID),
            .ID_scan_in(XID_scan_in_wire[i]),
            .ID_scan_out(XID_scan_in_wire[i+1])
        );
    end
endgenerate

endmodule
