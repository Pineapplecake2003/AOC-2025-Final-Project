`include "src/PE_array/PE.sv"
`include "src/PE_array/SUPER.sv"
`include "src/PE_array/GIN/GIN.sv"
`include "src/PE_array/GON/GON.sv"
`include "src/PE_array/PE_array.sv"
`include "src/Controller/GLB.sv"
`include "src/Controller/Controller_pass.sv"
`include "define.svh"

module Top(
    input           clk,
    input           rst_n,
    input           ctrl_ID_wen,
    input  [2:0]    ctrl_ID_wsel,
    input  [5:0]    ctrl_ID_widx,
    input  [4:0]    ctrl_ID_wdata,
    input           ctrl_reg_w_en,
    input  [2:0]    ctrl_reg_wsel,
    input  [31:0]   ctrl_reg_wdata,
    input           dram_w_en,
    input  [31:0]   dram_w_addr,
    input  [31:0]   dram_w_data,
    input           dram_r_en,
    input  [31:0]   dram_r_addr,
    output [31:0]   dram_r_data,
    output          glb_we,    
    output [31:0]   glb_w_addr,
    output [31:0]   glb_w_data,
    output          glb_re,    
    output [31:0]   glb_r_addr,
    input  [31:0]   glb_r_data,
    output done
);

/* control register */
reg [31:0] op_config, mapping_param, shape_param1, shape_param2;
reg bias_ipsum_sel;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        op_config       <= 0;
        mapping_param   <= 0;
        shape_param1    <= 0;
        shape_param2    <= 0;
    end
    else begin
        if(ctrl_reg_w_en) begin
            case(ctrl_reg_wsel)
            3'd0: begin
                mapping_param   <= ctrl_reg_wdata;
            end
            3'd1: begin
                shape_param1    <= ctrl_reg_wdata;
            end
            3'd2: begin
                shape_param2    <= ctrl_reg_wdata;
            end
            3'd3: begin
                bias_ipsum_sel  <= ctrl_reg_wdata[0];
            end
            3'd4: begin
                op_config       <= ctrl_reg_wdata;
            end
            endcase
        end
    end
end

/* decode wire */
wire maxpool, relu, conv_linear;
wire [5:0] scale;
assign maxpool      = op_config[1];
assign relu         = op_config[2];
assign conv_linear  = op_config[3];
assign scale        = op_config[9:4];

wire [2:0] t, r, q, p;
wire [4:0] e;
wire [9:0] m;
assign t = mapping_param[2:0];
assign r = mapping_param[5:3];
assign q = mapping_param[8:6];
assign p = mapping_param[11:9];
assign e = mapping_param[16:12];
assign m = mapping_param[26:17];

wire [9:0] M, C;
wire [1:0] R, S, U;
wire [2:0] PAD;
assign M   = shape_param1[9:0];
assign C   = shape_param1[19:10];
assign S   = shape_param1[21:20];
assign R   = shape_param1[23:22];
assign U   = shape_param1[25:24];
assign PAD = shape_param1[28:26];

wire [7:0] H, W;
assign H = shape_param2[7:0];
assign W = shape_param2[15:8];

/* glb base address */
wire [31:0] filter_baseaddr, ifmap_baseaddr, bias_baseaddr, opsum_baseaddr;
assign ifmap_baseaddr = 32'd0;
assign filter_baseaddr = q * r * (U * (e - 1) + R) * W;
assign bias_baseaddr = filter_baseaddr + p * t * q * r * R * S;
assign opsum_baseaddr = bias_baseaddr + p * t * 4;

/* controller <-> glb */
wire ctrl_re, ctrl_we;
wire [31:0] ctrl_w_addr, ctrl_r_addr;
wire [`DATA_SIZE-1:0] ctrl_w_data;

/* glb signal select */
assign glb_we       = (op_config[0])? ctrl_we     : dram_w_en;
assign glb_w_addr   = (op_config[0])? ctrl_w_addr : dram_w_addr;
assign glb_w_data   = (op_config[0])? ctrl_w_data : dram_w_data;
assign glb_re       = (op_config[0])? ctrl_re     : dram_r_en;
assign glb_r_addr   = (op_config[0])? ctrl_r_addr : dram_r_addr;
assign dram_r_data  = glb_r_data;
/* wire for connecting only */
wire set_XID, set_YID, set_LN;
wire [`XID_BITS-1:0] ifmap_XID_scan_in, filter_XID_scan_in, ipsum_XID_scan_in, opsum_XID_scan_in;
wire [`YID_BITS-1:0] ifmap_YID_scan_in, filter_YID_scan_in, ipsum_YID_scan_in, opsum_YID_scan_in;
wire [`NUMS_PE_ROW-2:0] LN_config_in;
wire [`NUMS_PE_ROW*`NUMS_PE_COL-1:0] PE_en;
wire [9:0] PE_config_out;
wire [`XID_BITS-1:0] ifmap_tag_X, filter_tag_X, ipsum_tag_X, opsum_tag_X;
wire [`YID_BITS-1:0] ifmap_tag_Y, filter_tag_Y, ipsum_tag_Y, opsum_tag_Y;
wire GLB_ifmap_ready, GLB_filter_ready, GLB_ipsum_ready, GLB_opsum_ready;
wire GLB_ifmap_valid, GLB_filter_valid, GLB_ipsum_valid, GLB_opsum_valid;
wire [`DATA_SIZE-1:0] PE_data_in, PE_data_out;

Controller_pass #(
    .NUMS_PE_ROW(`NUMS_PE_ROW),
    .NUMS_PE_COL(`NUMS_PE_COL),
    .XID_BITS(`XID_BITS),
    .YID_BITS(`YID_BITS),
    .DATA_SIZE(`DATA_BITS)
) controller_pass (
    .clk(clk),
    .rst_n(rst_n),
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
    .ctrl_ID_wen(ctrl_ID_wen)
    .ctrl_ID_wsel(ctrl_ID_wsel),
    .ctrl_ID_widx(ctrl_ID_widx),
    .ctrl_ID_wdata(ctrl_ID_wdata),
    
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

    .glb_we(ctrl_we),
    .glb_w_addr(ctrl_w_addr),
    .glb_w_data(ctrl_w_data),
    .glb_re(ctrl_re),
    .glb_r_addr(ctrl_r_addr),
    .glb_r_data(glb_r_data)
);
/*
GLB glb(
    .clk(clk),
    .rst_n(rst_n),
    .re(glb_re),            // read enable
    .r_addr(glb_r_addr),    // byte address
    .dout(glb_r_data),      // 32-bit read data
    .we(glb_we),            // write enable
    .w_addr(glb_w_addr),    // byte address
    .din(glb_w_data)        // 32-bit write data
);
*/
PE_array #(
    .NUMS_PE_ROW(`NUMS_PE_ROW),
    .NUMS_PE_COL(`NUMS_PE_COL),
    .XID_BITS(`XID_BITS),
    .YID_BITS(`YID_BITS),
    .DATA_SIZE(`DATA_BITS),
    .CONFIG_SIZE(`CONFIG_SIZE)
) pe_array_inst (
    .clk(clk),
    .rst_n(rst_n),

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
