`include "src/PE_array/PE.sv"
`include "src/PE_array/SUPER.sv"
`include "src/PE_array/GIN/GIN.sv"
`include "src/PE_array/GON/GON.sv"
`include "src/PE_array/PE_array.sv"
`include "src/Controller/GLB.sv"
`include "src/Controller/Controller_pass.sv"
`include "define.svh"

module Top(
    input clk,
    input rst,
    input start,
    output done
);

// higher-level controller interface
wire bias_ipsum_sel;
wire [31:0] op_config, mapping_param, shape_param1, shape_param2;
wire [31:0] filter_baseaddr, ifmap_baseaddr, bias_baseaddr, opsum_baseaddr;

// PE array interface
wire set_XID;
wire [`XID_BITS-1:0] ifmap_XID_scan_in, filter_XID_scan_in, ipsum_XID_scan_in, opsum_XID_scan_in;

wire set_YID;
wire [`YID_BITS-1:0] ifmap_YID_scan_in, filter_YID_scan_in, ipsum_YID_scan_in, opsum_YID_scan_in;

wire set_LN;
wire [`NUMS_PE_ROW-2:0] LN_config_in;

wire [`NUMS_PE_ROW*`NUMS_PE_COL-1:0] PE_en;
wire [`CONFIG_SIZE-1:0] PE_config_out;
wire [`XID_BITS-1:0] ifmap_tag_X;
wire [`YID_BITS-1:0] ifmap_tag_Y;
wire [`XID_BITS-1:0] filter_tag_X;
wire [`YID_BITS-1:0] filter_tag_Y;
wire [`XID_BITS-1:0] ipsum_tag_X;
wire [`YID_BITS-1:0] ipsum_tag_Y;
wire [`XID_BITS-1:0] opsum_tag_X;
wire [`YID_BITS-1:0] opsum_tag_Y;

wire GLB_ifmap_ready;
wire GLB_filter_ready;
wire GLB_ipsum_ready;
wire GLB_opsum_valid;
wire [`DATA_SIZE-1:0] PE_data_out;

wire GLB_ifmap_valid;
wire GLB_filter_valid;
wire GLB_ipsum_valid;
wire GLB_opsum_ready;

wire [`DATA_SIZE-1:0] PE_data_in;

wire [3:0] glb_we;
wire [31:0] glb_w_addr;
wire [`DATA_SIZE-1:0] glb_w_data;
wire [3:0] glb_re;
wire [31:0] glb_r_addr;
wire [`DATA_SIZE-1:0] glb_r_data;

assign bias_ipsum_sel = 0;
assign op_config = (DEPTHWISE << 10) | (LINEAR << 3) | 1;
assign mapping_param = (e << 12) | (p << 9) | (q << 6) | (r << 3) | t;
assign shape_param1 = (1 << 26) | (STRIDE << 24) | (FILT_ROW << 22) | (FILT_COL << 20);
assign shape_param2 = (IFMAP_COL << 8) | (IFMAP_COL);
assign ifmap_baseaddr = 32'd0;
assign filter_baseaddr = q * r * (STRIDE * (e - 1) + FILT_ROW) * IFMAP_COL;
assign bias_baseaddr = filter_baseaddr + p * t * q * r * FILT_ROW * FILT_COL;
assign opsum_baseaddr = bias_baseaddr + p * t * 4;

Controller_pass #(
    .NUMS_PE_ROW(`NUMS_PE_ROW),
    .NUMS_PE_COL(`NUMS_PE_COL),
    .XID_BITS(`XID_BITS),
    .YID_BITS(`YID_BITS),
    .DATA_SIZE(`DATA_BITS),
    .CONFIG_SIZE(`CONFIG_SIZE)
) controller_pass (
    .clk(clk),
    .rst(rst),
    .bias_ipsum_sel(bias_ipsum_sel),
    .op_config(op_config),
    .mapping_param(mapping_param),
    .shape_param1(shape_param1),
    .shape_param2(shape_param2),
    .filter_baseaddr(filter_baseaddr),
    .ifmap_baseaddr(ifmap_baseaddr),
    .bias_baseaddr(bias_baseaddr),
    .opsum_baseaddr(opsum_baseaddr),
    .done(done),

    .set_XID(set_XID),
    .ifmap_XID_scan_in(ifmap_XID_scan_in),
    .filter_XID_scan_in(filter_XID_scan_in),
    .ipsum_XID_scan_in(ipsum_XID_scan_in),
    .opsum_XID_scan_in(opsum_XID_scan_in),

    .set_YID(set_YID),
    .ifmap_YID_scan_in(ifmap_YID_scan_in),
    .filter_YID_scan_in(filter_YID_scan_in),
    .ipsum_YID_scan_in(ipsum_YID_scan_in),
    .opsum_YID_scan_in(opsum_YID_scan_in),

    .set_LN(set_LN),
    .LN_config_in(LN_config_in),

    .PE_en(PE_en),
    .PE_config_out(PE_config_out),
    .ifmap_tag_X(ifmap_tag_X),
    .ifmap_tag_Y(ifmap_tag_Y),
    .filter_tag_X(filter_tag_X),
    .filter_tag_Y(filter_tag_Y),
    .ipsum_tag_X(ipsum_tag_X),
    .ipsum_tag_Y(ipsum_tag_Y),
    .opsum_tag_X(opsum_tag_X),
    .opsum_tag_Y(opsum_tag_Y),

    .GLB_ifmap_valid(GLB_ifmap_valid),
    .GLB_ifmap_ready(GLB_ifmap_ready),
    .GLB_filter_valid(GLB_filter_valid),
    .GLB_filter_ready(GLB_filter_ready),
    .GLB_ipsum_valid(GLB_ipsum_valid),
    .GLB_ipsum_ready(GLB_ipsum_ready),

    .PE_data_in(PE_data_in),

    .GLB_opsum_valid(GLB_opsum_valid),
    .GLB_opsum_ready(GLB_opsum_ready),

    .PE_data_out(PE_data_out),

    .glb_we(glb_we),
    .glb_w_addr(glb_w_addr),
    .glb_w_data(glb_w_data),
    .glb_re(glb_re),
    .glb_r_addr(glb_r_addr),
    .glb_r_data(glb_r_data)
);

GLB glb(
    .clk(clk),
    .rst(rst),
    /* read port */
    .re(glb_re),     // read enable
    .r_addr(glb_r_addr), // byte address
    .dout(glb_r_data),    // 32-bit read data
    /* write port */
    // write first
    .we(glb_we),     // write enable
    .w_addr(glb_w_addr), // byte address
    .din(glb_w_data)    // 32-bit write data
);

PE_array #(
    .NUMS_PE_ROW(`NUMS_PE_ROW),
    .NUMS_PE_COL(`NUMS_PE_COL),
    .XID_BITS(`XID_BITS),
    .YID_BITS(`YID_BITS),
    .DATA_SIZE(`DATA_BITS),
    .CONFIG_SIZE(`CONFIG_SIZE)
) pe_array_inst (
    .clk(clk),
    .rst(rst),

    // Scan Chain
    .set_XID(set_XID),
    .ifmap_XID_scan_in(ifmap_XID_scan_in),
    .filter_XID_scan_in(filter_XID_scan_in),
    .ipsum_XID_scan_in(ipsum_XID_scan_in),
    .opsum_XID_scan_in(opsum_XID_scan_in),
    
    .set_YID(set_YID),
    .ifmap_YID_scan_in(ifmap_YID_scan_in),
    .filter_YID_scan_in(filter_YID_scan_in),
    .ipsum_YID_scan_in(ipsum_YID_scan_in),
    .opsum_YID_scan_in(opsum_YID_scan_in),

    .set_LN(set_LN),
    .LN_config_in(LN_config_in),

    // Controller
    .PE_en(PE_en),
    .PE_config(PE_config_out),
    .ifmap_tag_X(ifmap_tag_X),
    .ifmap_tag_Y(ifmap_tag_Y),
    .filter_tag_X(filter_tag_X),
    .filter_tag_Y(filter_tag_Y),
    .ipsum_tag_X(ipsum_tag_X),
    .ipsum_tag_Y(ipsum_tag_Y),
    .opsum_tag_X(opsum_tag_X),
    .opsum_tag_Y(opsum_tag_Y),

    // GLB
    .GLB_ifmap_valid(GLB_ifmap_valid),
    .GLB_ifmap_ready(GLB_ifmap_ready),
    .GLB_filter_valid(GLB_filter_valid),
    .GLB_filter_ready(GLB_filter_ready),
    .GLB_ipsum_valid(GLB_ipsum_valid),
    .GLB_ipsum_ready(GLB_ipsum_ready),
    .GLB_data_in(PE_data_in),
    .GLB_opsum_valid(GLB_opsum_valid),
    .GLB_opsum_ready(GLB_opsum_ready),
    .GLB_data_out(PE_data_out)
);

endmodule
