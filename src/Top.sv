`include "src/PE_array/PE.sv"
`include "src/PE_array/SUPER.sv"
`include "src/PE_array/GIN/GIN.sv"
`include "src/PE_array/GON/GON.sv"
`include "src/PE_array/PE_array.sv"
`include "src/Controller/GLB.sv"
`include "src/Controller/Controller_pass.sv"
`include "src/Tiling/tiling.sv"
`include "define.svh"

module Top(
    input           clk,
    input           rst,
    input           ctrl_reg_w_en,
    input  [1:0]    ctrl_reg_wsel,
    input  [31:0]   ctrl_reg_wdata,
    output reg      dla_done
);


// higher-level controller interface
wire bias_ipsum_sel, pass_start, tiling_start, pass_done, tiling_done, all_done;
reg [31:0] op_config, mapping_param, shape_param1, shape_param2;
reg [1:0] cs, ns;

/*  testing only  */
assign bias_ipsum_sel = 0;
assign op_config = (DEPTHWISE << 10) | (LINEAR << 3) | 1;
assign mapping_param = (e << 12) | (p << 9) | (q << 6) | (r << 3) | t;
assign shape_param1 = (1 << 26) | (STRIDE << 24) | (FILT_ROW << 22) | (FILT_COL << 20);
assign shape_param2 = (IFMAP_COL << 8) | (IFMAP_COL);
/******************/

assign pass_start = (tiling_done & !all_done);
assign tiling_start = (cs == idle)? op_config[0] : pass_done;
assign dla_done = (cs == done)? 1 : 0;

parameter idle = 0;
parameter tiling = 1;
parameter pass = 2;
parameter done = 3;

always @(posedge clk or posedge rst) begin
    if(rst) begin
        cs                  <= idle;
        op_config           <= 0;
        mapping_param       <= 0;
        shape_param1        <= 0;
        shape_param2        <= 0;
    end
    else begin
        cs  <= ns;
        case(cs)
        idle: begin
            if(ctrl_reg_w_en) begin
                case(ctrl_reg_wsel)
                2'd0: begin
                    mapping_param   <= ctrl_reg_wdata;
                end
                2'd1: begin
                    shape_param1    <= ctrl_reg_wdata;
                end
                2'd2: begin
                    shape_param2    <= ctrl_reg_wdata;
                end
                2'd3: begin
                    op_config       <= ctrl_reg_wdata;
                end
                endcase
            end
        end
        done: begin
            if(ctrl_reg_w_en && ctrl_reg_wsel == 2'd3) begin
                op_config           <= ctrl_reg_wdata;
            end
        end
        endcase
    end
end

// ns logic
always @(*) begin
    case (cs)
    idle:   ns = (op_config[0]) ? tiling : idle;
    tiling: ns = (tiling_done)? ((all_done)? done : pass) : tiling;
    pass:   ns = (pass_done)? tiling : pass;
    done:   ns = (!op_config[0])? idle : done;
    endcase
end

/* wire for connect only */
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

/* glb base address */
wire [31:0] filter_baseaddr, ifmap_baseaddr, bias_baseaddr, opsum_baseaddr;
assign ifmap_baseaddr = 32'd0;
assign filter_baseaddr = q * r * (STRIDE * (e - 1) + FILT_ROW) * IFMAP_COL;
assign bias_baseaddr = filter_baseaddr + p * t * q * r * FILT_ROW * FILT_COL;

//TODO
assign opsum_baseaddr = bias_baseaddr + p * t * 4;

/* controller <-> glb */
wire [3:0] ctrl2glb_we, ctrl2glb_re;
wire [31:0] ctrl2glb_w_addr, ctrl2glb_r_addr;
wire [`DATA_SIZE-1:0] ctrl2glb_w_data;

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
    .start(pass_start),
    .bias_ipsum_sel(bias_ipsum_sel),
    .op_config(op_config),
    .mapping_param(mapping_param),
    .shape_param1(shape_param1),
    .shape_param2(shape_param2),
    .filter_baseaddr(filter_baseaddr),
    .ifmap_baseaddr(ifmap_baseaddr),
    .bias_baseaddr(bias_baseaddr),
    .opsum_baseaddr(opsum_baseaddr),
    .done(pass_done),

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

    .glb_we(ctrl2glb_we),
    .glb_w_addr(ctrl2glb_w_addr),
    .glb_w_data(ctrl2glb_r_data),
    .glb_re(ctrl2glb_re),
    .glb_r_addr(ctrl2glb_r_addr),
    .glb_r_data(glb_r_data)
);

wire [3:0] dram2glb_we, dram2glb_re;
wire [31:0] dram2glb_w_addr, dram2glb_r_addr;
wire [`DATA_SIZE-1:0] dram2glb_w_data;

/* wire for connect only */
wire [31:0] dram_ifmap_base_addr, dram_filter_base_addr, dram_bias_base_addr, dram_opsum_base_addr;
wire        dram_we,    
wire [31:0] dram_addr, dram_w_data, dram_r_data;
/*************************/

tiling u_tiling (
    .clk(clk),
    .rst(rst),

    /* Controller signal */
    .start(tiling_start),
    .finish(tiling_done),

    /* Tiling parameters */
    .mapping_param(mapping_param),
    .shape_param1(shape_param1),
    .shape_param2(shape_param2),

    /* DRAM base address */
    .dram_ifmap_base_addr(dram_ifmap_base_addr),
    .dram_filter_base_addr(dram_filter_base_addr),
    .dram_bias_base_addr(dram_bias_base_addr),
    .dram_opsum_base_addr(dram_opsum_base_addr),

    /* DRAM */
    .dram_we(dram_we),
    .dram_addr(dram_addr),
    .dram_w_data(dram_w_data),
    .dram_r_data(dram_r_data),

    /* GLB base address */
    .glb_ifmap_base_addr(ifmap_baseaddr),
    .glb_filter_base_addr(filter_baseaddr),
    .glb_bias_base_addr(bias_baseaddr),
    .glb_opsum_base_addr(opsum_baseaddr),

    /* GLB read out */
    .glb_r_addr(dram2glb_r_addr),
    .glb_r_data(glb_r_data),

    /* GLB write in */
    .glb_we(dram2glb_we),
    .glb_w_addr(dram2glb_w_addr),
    .glb_w_data(dram2glb_w_data)
);

wire [3:0]              glb_we;
wire [31:0]             glb_w_addr;
wire [`DATA_SIZE-1:0]   glb_w_data;
wire [3:0]              glb_re;
wire [31:0]             glb_r_addr;
wire [`DATA_SIZE-1:0]   glb_r_data;

assign glb_we = (cs == pass)? ctrl2glb_we : dram2glb_we;
assign glb_w_addr = (cs == pass)? ctrl2glb_w_addr : dram2glb_w_addr;
assign glb_w_data = (cs == pass)? ctrl2glb_w_data : dram2glb_w_data;
assign glb_re = (cs == pass)? ctrl2glb_re : 4'b1111; //TODO
assign glb_r_addr = (cs == pass)? ctrl2glb_r_addr : dram2glb_r_addr;

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
