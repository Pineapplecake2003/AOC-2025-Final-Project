`include "src/PE_array/PE.sv"
`include "src/PE_array/GIN/GIN.sv"
`include "src/PE_array/GON/GON.sv"

module PE_array #(
    parameter NUMS_PE_ROW = `NUMS_PE_ROW,
    parameter NUMS_PE_COL = `NUMS_PE_COL,
    parameter XID_BITS = `XID_BITS,
    parameter YID_BITS = `YID_BITS,
    parameter DATA_SIZE = `DATA_BITS,
    parameter CONFIG_SIZE = `CONFIG_SIZE
)(
    input clk,
    input rst,

    /* Scan Chain */
    input set_XID,
    input [`XID_BITS-1:0] ifmap_XID_scan_in,
    input [`XID_BITS-1:0] filter_XID_scan_in,
    input [`XID_BITS-1:0] ipsum_XID_scan_in,
    input [`XID_BITS-1:0] opsum_XID_scan_in,
    // output [XID_BITS-1:0] XID_scan_out,

    input set_YID,
    input [`YID_BITS-1:0] ifmap_YID_scan_in,
    input [`YID_BITS-1:0] filter_YID_scan_in,
    input [`YID_BITS-1:0] ipsum_YID_scan_in,
    input [`YID_BITS-1:0] opsum_YID_scan_in,
    // output logic [YID_BITS-1:0] YID_scan_out,

    input set_LN,
    input [`NUMS_PE_ROW-2:0] LN_config_in,

    /* Controller */
    input [`NUMS_PE_ROW*`NUMS_PE_COL-1:0] PE_en,
    input [`CONFIG_SIZE-1:0] PE_config,
    input [`XID_BITS-1:0] ifmap_tag_X,
    input [`YID_BITS-1:0] ifmap_tag_Y,
    input [`XID_BITS-1:0] filter_tag_X,
    input [`YID_BITS-1:0] filter_tag_Y,
    input [`XID_BITS-1:0] ipsum_tag_X,
    input [`YID_BITS-1:0] ipsum_tag_Y,
    input [`XID_BITS-1:0] opsum_tag_X,
    input [`YID_BITS-1:0] opsum_tag_Y,

    /* GLB */
    input GLB_ifmap_valid,
    output logic GLB_ifmap_ready,
    input GLB_filter_valid,
    output logic GLB_filter_ready,
    input GLB_ipsum_valid,
    output logic GLB_ipsum_ready,
    input [DATA_SIZE-1:0] GLB_data_in,

    output logic GLB_opsum_valid,
    input GLB_opsum_ready,
    output logic [DATA_SIZE-1:0] GLB_data_out
);

// ifmap GIN
logic [`NUMS_PE_ROW * `NUMS_PE_COL - 1:0] ifmap_PE_ready, ifmap_PE_valid;
logic [`DATA_BITS - 1:0] ifmap_PE_data;
GIN ifmap_GIN(
    .clk(clk),
    .rst(rst),
    .GIN_valid(GLB_ifmap_valid),
    .GIN_ready(GLB_ifmap_ready),
    .GIN_data(GLB_data_in),
    .tag_X(ifmap_tag_X),
    .tag_Y(ifmap_tag_Y),
    .set_XID(set_XID),
    .XID_scan_in(ifmap_XID_scan_in),
    .set_YID(set_YID),
    .YID_scan_in(ifmap_YID_scan_in),
    .PE_ready(ifmap_PE_ready),
    .PE_valid(ifmap_PE_valid),
    .PE_data(ifmap_PE_data)
);

// filter GIN
logic [`NUMS_PE_ROW * `NUMS_PE_COL - 1:0] filter_PE_ready, filter_PE_valid;
logic [`DATA_BITS - 1:0] filter_PE_data;
GIN filter_GIN(
    .clk(clk),
    .rst(rst),
    .GIN_valid(GLB_filter_valid),
    .GIN_ready(GLB_filter_ready),
    .GIN_data(GLB_data_in),
    .tag_X(filter_tag_X),
    .tag_Y(filter_tag_Y),
    .set_XID(set_XID),
    .XID_scan_in(filter_XID_scan_in),
    .set_YID(set_YID),
    .YID_scan_in(filter_YID_scan_in),
    .PE_ready(filter_PE_ready),
    .PE_valid(filter_PE_valid),
    .PE_data(filter_PE_data)
);

// ipsum GIN
logic [`NUMS_PE_ROW * `NUMS_PE_COL - 1:0] ipsum_PE_ready, ipsum_PE_valid;
logic [`DATA_BITS - 1:0] ipsum_PE_data;
GIN ipsum_GIN(
    .clk(clk),
    .rst(rst),
    .GIN_valid(GLB_ipsum_valid),
    .GIN_ready(GLB_ipsum_ready),
    .GIN_data(GLB_data_in),
    .tag_X(ipsum_tag_X),
    .tag_Y(ipsum_tag_Y),
    .set_XID(set_XID),
    .XID_scan_in(ipsum_XID_scan_in),
    .set_YID(set_YID),
    .YID_scan_in(ipsum_YID_scan_in),
    .PE_ready(ipsum_PE_ready),
    .PE_valid(ipsum_PE_valid),
    .PE_data(ipsum_PE_data)
);

// opsum GON
logic [`NUMS_PE_ROW * `NUMS_PE_COL - 1:0] opsum_PE_valid, opsum_PE_ready;
logic [`DATA_BITS * `NUMS_PE_ROW * `NUMS_PE_COL - 1:0] opsum_PE_data;
GON opsum_GON(
    .clk(clk),
    .rst(rst),
    .GON_valid(GLB_opsum_valid),
    .GON_ready(GLB_opsum_ready),
    .GON_data(GLB_data_out),
    .tag_X(opsum_tag_X),
    .tag_Y(opsum_tag_Y),
    .set_XID(set_XID),
    .XID_scan_in(opsum_XID_scan_in),
    .set_YID(set_YID),
    .YID_scan_in(opsum_YID_scan_in),
    .PE_valid(opsum_PE_valid),
    .PE_ready(opsum_PE_ready),
    .PE_data(opsum_PE_data)
);

// LN_config
logic [`NUMS_PE_ROW - 2 : 0] LN_config;
always_ff @(posedge clk or posedge rst) begin
    if(rst) begin
        LN_config <= 0;
    end
    else begin
        LN_config <= (set_LN)? LN_config_in : LN_config;
    end
end

// setting LN

logic [`DATA_BITS - 1:0] ipsum_actual_data [`NUMS_PE_ROW * `NUMS_PE_COL - 1:0];
logic [`NUMS_PE_ROW * `NUMS_PE_COL - 1:0] ipsum_actual_valid;

always_comb begin
    for(int j = 0; j < `NUMS_PE_ROW * `NUMS_PE_COL; j = j + 1) begin
        if(j >= `NUMS_PE_COL * (`NUMS_PE_ROW - 1)) begin
            ipsum_actual_data[j] = ipsum_PE_data;
            ipsum_actual_valid[j] = ipsum_PE_valid[j];
        end
        else begin
            ipsum_actual_data[j] = (LN_config[j >> 3])? opsum_PE_data[`DATA_BITS*(j+`NUMS_PE_COL) +: `DATA_BITS] : ipsum_PE_data;
            ipsum_actual_valid[j] = (LN_config[j >> 3])? opsum_PE_valid[j+`NUMS_PE_COL] : ipsum_PE_valid[j];
        end
    end
end

logic [`NUMS_PE_ROW * `NUMS_PE_COL - 1:0] opsum_actual_ready;

always_comb begin
    for(int j = 0; j < `NUMS_PE_ROW * `NUMS_PE_COL; j = j + 1) begin
        if(j < `NUMS_PE_COL) begin
            opsum_actual_ready[j] = opsum_PE_ready[j];
        end
        else begin
            opsum_actual_ready[j] = (LN_config[(j >> 3) - 1])? ipsum_PE_ready[j-`NUMS_PE_COL] : opsum_PE_ready[j];
        end
    end
end

// PE
genvar i;
generate;
    for(i = 0; i < `NUMS_PE_ROW * `NUMS_PE_COL; i = i + 1) begin : PE_num
        PE pe(
            .clk(clk),
            .rst(rst),
            .PE_en(PE_en[i]),
            .i_config(PE_config),
            .ifmap(ifmap_PE_data),
            .filter(filter_PE_data),
            .ipsum(ipsum_actual_data[i]),
            .ifmap_valid(ifmap_PE_valid[i]),
            .filter_valid(filter_PE_valid[i]),
            .ipsum_valid(ipsum_actual_valid[i]),
            .opsum_ready(opsum_actual_ready[i]),
            .opsum(opsum_PE_data[`DATA_BITS*(i+1) - 1:`DATA_BITS*i]),
            .ifmap_ready(ifmap_PE_ready[i]),
            .filter_ready(filter_PE_ready[i]),
            .ipsum_ready(ipsum_PE_ready[i]),
            .opsum_valid(opsum_PE_valid[i])
        );
    end
endgenerate

endmodule