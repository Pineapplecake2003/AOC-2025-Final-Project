`include "/src/Controller/ID_gen_combinational.v"

module Controller_pass #(
    parameter NUMS_PE_ROW = `NUMS_PE_ROW,
    parameter NUMS_PE_COL = `NUMS_PE_COL,
    parameter XID_BITS = `XID_BITS,
    parameter YID_BITS = `YID_BITS,
    parameter DATA_SIZE = `DATA_BITS,
    parameter CONFIG_SIZE = `CONFIG_SIZE
)(
    input clk,
    input rst,

    /* higher-level controller interface */
    input start,
    input bias_ipsum_sel,
    input [31:0] op_config,
    input [31:0] mapping_param,
    input [31:0] shape_param1,
    input [31:0] shape_param2,
    input [31:0] filter_baseaddr,
    input [31:0] ifmap_baseaddr,
    input [31:0] bias_baseaddr,
    input [31:0] opsum_baseaddr,
    output done,

    /* PE array interface */
    // Scan X Chain
    output set_XID,
    output [XID_BITS-1:0] ifmap_XID_scan_in,
    output [XID_BITS-1:0] filter_XID_scan_in,
    output [XID_BITS-1:0] ipsum_XID_scan_in,
    output [XID_BITS-1:0] opsum_XID_scan_in,

    // Scan Y Chain
    output set_YID,
    output [YID_BITS-1:0] ifmap_YID_scan_in,
    output [YID_BITS-1:0] filter_YID_scan_in,
    output [YID_BITS-1:0] ipsum_YID_scan_in,
    output [YID_BITS-1:0] opsum_YID_scan_in,

    // Scan LN Chain
    output set_LN,
    output [NUMS_PE_ROW-2:0] LN_config_in,

    // tag controller
    output [NUMS_PE_ROW*NUMS_PE_COL-1:0] PE_en,
    output [CONFIG_SIZE-1:0] PE_config_out,
    output [XID_BITS-1:0] ifmap_tag_X,
    output [YID_BITS-1:0] ifmap_tag_Y,
    output [XID_BITS-1:0] filter_tag_X,
    output [YID_BITS-1:0] filter_tag_Y,
    output [XID_BITS-1:0] ipsum_tag_X,
    output [YID_BITS-1:0] ipsum_tag_Y,
    output [XID_BITS-1:0] opsum_tag_X,
    output [YID_BITS-1:0] opsum_tag_Y,

    // GIN handshake signal
    output reg  GLB_ifmap_valid,
    input       GLB_ifmap_ready,
    output reg  GLB_filter_valid,
    input       GLB_filter_ready,
    output reg  GLB_ipsum_valid,
    input       GLB_ipsum_ready,

    // GIN input data
    output [DATA_SIZE-1:0] PE_data_in,

    // GON handshake signal
    input       GLB_opsum_valid,
    output reg  GLB_opsum_ready,

    // GON output data
    input   [DATA_SIZE-1:0] PE_data_out,

    /* glb interface */
    // write port
    output reg [3:0]        glb_we,
    output  [31:0]          glb_w_addr,
    output  [DATA_SIZE-1:0] glb_w_data, 
    // read port
    output reg [3:0]        glb_re,
    output reg [31:0]       glb_r_addr,
    input   [DATA_SIZE-1:0] glb_r_data
);

    /* parameter decode */
    wire conv_linear, PE_config_U, PE_config_dp;
    wire [1:0] R, S, PE_config_p, PE_config_q, PE_config_R;
    wire [2:0] p, q, r, t;
    wire [4:0] e, PE_config_F;
    wire [7:0] W;
    assign e = mapping_param[16:12];
    assign p = mapping_param[11:9];
    assign q = mapping_param[8:6];
    assign r = mapping_param[5:3];
    assign t = mapping_param[2:0];
    assign U = shape_param1[25:24];
    assign R = shape_param1[23:22];
    assign S = shape_param1[21:20];
    assign W = shape_param2[15:8];
    assign conv_linear = op_config[3];
    assign PE_config_dp = op_config[10];
    assign PE_config_p = p - 1;
    assign PE_config_F = (W - R) / U;
    assign PE_config_q = q - 1;
    assign PE_config_U = U - 1;
    assign PE_config_R = R - 1;

    wire [31:0] merge_num, merged_PE_ARRAY_W, merged_PE_ARRAY_H, array_H_tile, array_W_tile, t_H, t_W;
    assign merge_num = (e + NUMS_PE_COL - 1) / NUMS_PE_COL;
    assign merged_PE_ARRAY_W = NUMS_PE_COL * merge_num;
    assign merged_PE_ARRAY_H = NUMS_PE_ROW / merge_num;
    assign array_H_tile = merged_PE_ARRAY_H / R;
    assign array_W_tile = merged_PE_ARRAY_W / e;
    assign t_H = array_H_tile / r;
    assign t_W = t / t_H;
    /********************/

    /* loading XID, YID data */
    wire [XID_BITS-1:0] ifmap_XID  [0:NUMS_PE_ROW*NUMS_PE_COL-1];
    wire [XID_BITS-1:0] filter_XID [0:NUMS_PE_ROW*NUMS_PE_COL-1];
    wire [XID_BITS-1:0] ipsum_XID  [0:NUMS_PE_ROW*NUMS_PE_COL-1];
    wire [XID_BITS-1:0] opsum_XID  [0:NUMS_PE_ROW*NUMS_PE_COL-1];

    wire [YID_BITS-1:0] ifmap_YID  [0:NUMS_PE_ROW-1];
    wire [YID_BITS-1:0] filter_YID [0:NUMS_PE_ROW-1];
    wire [YID_BITS-1:0] ipsum_YID  [0:NUMS_PE_ROW-1];
    wire [YID_BITS-1:0] opsum_YID  [0:NUMS_PE_ROW-1];
    /*************************/
    
    pe_array_id_generator pe_array_id_generator_inst (
        .p(p),
        .q(q),
        .r(r),
        .t(t),
        .e(e),
        .t_H(t_H[2:0]),
        .t_W(t_W[2:0]),
        .PE_ARRAY_H(NUMS_PE_ROW[2:0]),
        .PE_ARRAY_W(NUMS_PE_COL[3:0]),
        .KERNEL_H(R),
        .LINEAR(conv_linear),
        .filter_XID(filter_XID),
        .filter_YID(filter_YID),
        .ifmap_XID(ifmap_XID),
        .ifmap_YID(ifmap_YID),
        .ipsum_XID(ipsum_XID),
        .ipsum_YID(ipsum_YID),
        .opsum_XID(opsum_XID),
        .opsum_YID(opsum_YID),
        .LN_config(LN_config_in)
    );


    parameter IDLE = 0,
        SET_CONFIG = 1,
        READ_FILTER = 2,
        READ_IFMAP = 3,
        READ_IPSUM = 4,
        WRITE_OPSUM = 5,
        DONE = 6;
        
    reg [31:0] counter;
    reg [31:0] row_ct, col_ct, chn_ct, num_ct, r_ct, tH_ct, tW_ct, ipsum_r_ct, ipsum_c_ct, opsum_r_ct, opsum_c_ct;
    reg [2:0] cs, ns;

    /* SET_CONFIG output logic */
    assign set_XID = (cs == SET_CONFIG)? 1 : 0;
    assign ifmap_XID_scan_in = ifmap_XID[counter];
    assign filter_XID_scan_in = filter_XID[counter];
    assign ipsum_XID_scan_in = ipsum_XID[counter];
    assign opsum_XID_scan_in = opsum_XID[counter];

    assign set_YID = (cs == SET_CONFIG)? ((counter < NUMS_PE_ROW)? 1 : 0) : 0;
    assign ifmap_YID_scan_in = ifmap_YID[counter];
    assign filter_YID_scan_in = filter_YID[counter];
    assign ipsum_YID_scan_in = ipsum_YID[counter];
    assign opsum_YID_scan_in = opsum_YID[counter];

    assign set_LN = (cs == SET_CONFIG)? ((counter == 0)? 1 : 0) : 0;

    assign PE_en = (cs != IDLE && cs != SET_CONFIG && cs != DONE)? 48'hffff_ffff_ffff : 0;
    assign PE_config_out =  {PE_config_dp, PE_config_R ,PE_config_U, PE_config_p, PE_config_F, PE_config_q};

    /***************************/

    /* PE_data_in output logic */
    assign PE_data_in = glb_r_data;

    /* glb reading signal output logic */
    // glb_re
    always @(*) begin
        if(cs != READ_IPSUM) begin
            case (q)
            3'd1: begin
                glb_re = 4'b0001;
            end
            3'd2: begin
                glb_re = 4'b0011;
            end
            3'd3: begin
                glb_re = 4'b0111;
            end
            3'd4: begin
                glb_re = 4'b1111;
            end
            endcase
        end
        else begin
            glb_re = 4'b1111;
        end
    end

    // glb_r_addr
    wire [31:0] filter_addr, ifmap_addr, bias_addr, ipsum_addr, opsum_addr;
    assign filter_addr = filter_baseaddr + counter;
    assign ifmap_addr = ifmap_baseaddr + chn_ct * q + col_ct * q * r + row_ct * q * r * W;
    assign bias_addr = bias_baseaddr + (num_ct + ipsum_c_ct * p * t + ipsum_r_ct * p * t * (PE_config_F+1)) * 4;
    assign ipsum_addr = opsum_baseaddr + (num_ct + ipsum_c_ct * p * t + ipsum_r_ct * p * t * (PE_config_F+1)) * 4;
    assign opsum_addr = opsum_baseaddr + (counter + opsum_c_ct * p * t + opsum_r_ct * p * t * (PE_config_F+1)) * 4;

    always @(*) begin
        case (cs)
        READ_FILTER: begin
            glb_r_addr = filter_addr;
        end
        READ_IFMAP: begin
            glb_r_addr = ifmap_addr;
        end
        READ_IPSUM: begin
            glb_r_addr = (bias_ipsum_sel)? bias_addr : ipsum_addr;
        end
        default: begin
            glb_r_addr = 0;
        end
        endcase
    end
    /********************************/

    /* glb reading signal output logic */
    always @(*) begin
        if(GLB_opsum_valid && GLB_opsum_ready) begin
            glb_we = 4'b1111;
        end
        else begin
            glb_we = 4'b0;
        end
    end

    assign glb_w_addr = opsum_addr;
    assign glb_w_data = PE_data_out;
    /********************************/

    /* tag control output logic */
    wire [31:0] filter_tag_X_tmp, filter_tag_Y_tmp, ipsum_tag_X_tmp, opsum_tag_X_tmp;
    assign filter_tag_X_tmp = row_ct + R * tW_ct;
    assign filter_tag_Y_tmp = r_ct + tH_ct;
    assign filter_tag_X = filter_tag_X_tmp[XID_BITS-1:0];
    assign filter_tag_Y = filter_tag_Y_tmp[YID_BITS-1:0];

    assign ifmap_tag_X = row_ct[XID_BITS-1:0];
    assign ifmap_tag_Y = r_ct[YID_BITS-1:0];

    assign ipsum_tag_X_tmp = ipsum_r_ct + e * tW_ct;
    assign ipsum_tag_X = ipsum_tag_X_tmp[XID_BITS-1:0];
    assign ipsum_tag_Y = tH_ct[YID_BITS-1:0];

    assign opsum_tag_X_tmp = opsum_r_ct + e * tW_ct;
    assign opsum_tag_X = opsum_tag_X_tmp[XID_BITS-1:0];
    assign opsum_tag_Y = tH_ct[YID_BITS-1:0];
    /****************************/

    // fsm logic
    always_ff @(posedge clk or posedge rst) begin
        if(rst) begin
            cs                  <= IDLE;
            counter             <= 0;
            row_ct              <= 0;
            col_ct              <= 0;
            chn_ct              <= 0;
            num_ct              <= 0;
            r_ct                <= 0;
            tH_ct               <= 0;
            tW_ct               <= 0;
            ipsum_r_ct          <= 0;
            ipsum_c_ct          <= 0;
            opsum_r_ct          <= 0;
            opsum_c_ct          <= 0;
            GLB_ifmap_valid     <= 0;
            GLB_filter_valid    <= 0;
            GLB_ipsum_valid     <= 0;
            GLB_opsum_ready     <= 0;
        end
        else begin
            cs <= ns;
            case(cs)
            IDLE: begin
                counter             <= 0;
                row_ct              <= 0;
                col_ct              <= 0;
                chn_ct              <= 0;
                num_ct              <= 0;
                r_ct                <= 0;
                tH_ct               <= 0;
                tW_ct               <= 0;
                ipsum_r_ct          <= 0;
                ipsum_c_ct          <= 0;
                opsum_r_ct          <= 0;
                opsum_c_ct          <= 0;
                GLB_filter_valid    <= 0;
                GLB_ifmap_valid     <= 0;
                GLB_ipsum_valid     <= 0;
                GLB_opsum_ready     <= 0;
            end
            SET_CONFIG: begin
                counter             <= (counter == NUMS_PE_ROW*NUMS_PE_COL-1)? 0 : counter + 1;
            end
            READ_FILTER: begin
                if(GLB_filter_valid & GLB_filter_ready) begin
                    GLB_filter_valid    <= 0;
                    counter             <= (filter_addr == bias_baseaddr - q)? 0 : counter + q;
                    chn_ct              <= (chn_ct == r-1)? 0 : chn_ct + 1;
                    col_ct              <= (chn_ct == r-1)? ((col_ct == S-1)? 0 :  col_ct + 1) : col_ct;
                    row_ct              <= (chn_ct == r-1 && col_ct == S-1)? ((row_ct == R-1)? 0 :  row_ct + 1) : row_ct;
                    num_ct              <= (chn_ct == r-1 && col_ct == S-1 && row_ct == R-1)? ((num_ct == p-1)? 0 : num_ct + 1) : num_ct;
                    r_ct                <= (r_ct   == r-1)? 0 : r_ct + 1;
                    tH_ct               <= (chn_ct == r-1 && col_ct == S-1 && row_ct == R-1 && num_ct % p == p-1)? ((tH_ct == t_H - 1)? 0 : tH_ct + 1) : tH_ct;
                    tW_ct               <= (chn_ct == r-1 && col_ct == S-1 && row_ct == R-1 && num_ct % p == p-1 && tH_ct == t_H - 1)? ((tW_ct == t_W - 1)? 0 : tW_ct + 1) : tW_ct;  
                end
                else begin
                    GLB_filter_valid    <= 1;
                end
            end
            READ_IFMAP: begin
                if(GLB_ifmap_valid & GLB_ifmap_ready) begin
                    GLB_ifmap_valid     <= 0;
                    chn_ct              <= (chn_ct == r-1)? 0 : chn_ct + 1;
                    row_ct              <= (chn_ct == r-1)? ((row_ct == e + R - 2)? 0 :  row_ct + 1) : row_ct;
                    col_ct              <= (chn_ct == r-1 && row_ct == e + R - 2)? ((col_ct >= S-1 && col_ct == W - 1)? 0 :  col_ct + 1) : col_ct;
                    r_ct                <= (r_ct   == r-1)? 0 : r_ct + 1;
               end
                else begin
                    GLB_ifmap_valid     <= 1;
                end
            end
            READ_IPSUM: begin
                if(GLB_ipsum_valid & GLB_ipsum_ready) begin
                    GLB_ipsum_valid     <= 0;
                    tH_ct               <= (num_ct % p == p-1)? (tH_ct == t_H-1)? 0 : tH_ct + 1 : tH_ct;
                    tW_ct               <= (num_ct % p == p-1 && tH_ct == t_H-1)? ((tW_ct == t_W-1)? 0 : tW_ct + 1) : tW_ct;
                    num_ct              <= (num_ct == p*t-1)? 0 : num_ct + 1;   // reuse as ipsum chn_ct
                    ipsum_r_ct          <= (num_ct == p*t-1)? ((ipsum_r_ct == e-1)? 0 : ipsum_r_ct + 1) : ipsum_r_ct;
                    ipsum_c_ct          <= (num_ct == p*t-1 && ipsum_r_ct == e-1)? ((ipsum_c_ct == W-1)? 0 : ipsum_c_ct + 1) : ipsum_c_ct;
                    col_ct              <= (num_ct == p*t-1 && ipsum_r_ct == e-1 && ipsum_c_ct == W-1)? 0 : col_ct;
               end
                else begin
                    GLB_ipsum_valid     <= 1;
                end
            end
            WRITE_OPSUM: begin
                if(GLB_opsum_valid & GLB_opsum_ready) begin
                    GLB_opsum_ready     <= 0;
                    tH_ct               <= (counter % p == p-1)? ((tH_ct == t_H-1)? 0 : tH_ct + 1) : tH_ct;
                    tW_ct               <= (counter % p == p-1 && tH_ct == t_H-1)? ((tW_ct == t_W-1)? 0 : tW_ct + 1) : tW_ct;
                    counter             <= (counter == p*t-1)? 0 : counter + 1; // reuse as opsum chn_ct
                    opsum_r_ct          <= (counter == p*t-1)? ((opsum_r_ct == e-1)? 0 : opsum_r_ct + 1) : opsum_r_ct;
                    opsum_c_ct          <= (counter == p*t-1 && opsum_r_ct == e-1)? ((opsum_c_ct == W-1)? 0 : opsum_c_ct + 1) : opsum_c_ct;
                end
                else begin
                    GLB_opsum_ready     <= 1;
                end
            end
            endcase
        end
    end

    // next state logic
    always_comb begin
        case(cs)
        IDLE: begin
            ns = (start)? SET_CONFIG : IDLE;
        end
        SET_CONFIG: begin
            ns = (counter == NUMS_PE_ROW*NUMS_PE_COL-1)? READ_FILTER : SET_CONFIG;
        end
        READ_FILTER: begin
            ns = (GLB_filter_valid & GLB_filter_ready & filter_addr == bias_baseaddr - q)? READ_IFMAP : READ_FILTER;
        end
        READ_IFMAP: begin
            ns = (GLB_ifmap_valid & GLB_ifmap_ready && chn_ct == r-1 && row_ct == e + R - 2 && col_ct >= S-1)? READ_IPSUM : READ_IFMAP;
        end
        READ_IPSUM: begin
            ns = (GLB_ipsum_valid & GLB_ipsum_ready && num_ct == p*t-1 && ipsum_r_ct == e-1)? WRITE_OPSUM : READ_IPSUM;
        end
        WRITE_OPSUM: begin
            ns = (GLB_opsum_valid & GLB_opsum_ready && counter == p*t-1 && opsum_r_ct == e-1)? ((opsum_c_ct == PE_config_F[4:0])? DONE : READ_IFMAP) : WRITE_OPSUM;
        end
        DONE: begin
            ns = IDLE;
        end
        endcase
    end

    assign done = (cs == DONE)? 1 : 0;
endmodule
