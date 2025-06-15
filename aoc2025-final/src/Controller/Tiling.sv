module Tiling #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 8
)(
    input  logic clk,
    input  logic rst,

    /* Controller signal */
    input  logic start,
    output logic finish,

    /* Tiling parameters */
    input  logic [31:0] mapping_param,
    input  logic [31:0] shape_param1,
    input  logic [31:0] shape_param2,

    /* DRAM base address */
    input  logic [ADDR_WIDTH-1:0]   dram_ifmap_base_addr,
    input  logic [ADDR_WIDTH-1:0]   dram_filter_base_addr,
    input  logic [ADDR_WIDTH-1:0]   dram_bias_base_addr,
    input  logic [ADDR_WIDTH-1:0]   dram_opsum_base_addr,
    
    /* DRAM*/
    output logic                    dram_we,     // write enable
    output logic [ADDR_WIDTH-1:0]   dram_addr, // byte address
    output logic [DATA_WIDTH*4-1:0] dram_w_data, // 32-bit write data
    input  logic [DATA_WIDTH*4-1:0] dram_r_data, // 32-bit read data
    
    /* GLB base address */  
    input  logic [ADDR_WIDTH-1:0]   glb_ifmap_base_addr,
    input  logic [ADDR_WIDTH-1:0]   glb_filter_base_addr,
    input  logic [ADDR_WIDTH-1:0]   glb_bias_base_addr,
    input  logic [ADDR_WIDTH-1:0]   glb_opsum_base_addr,

    /* GLB read out */
    output logic [ADDR_WIDTH-1:0]   glb_r_addr,  // byte address
    input  logic [DATA_WIDTH*4-1:0] glb_r_data,  // 32-bit read data

    /* GLB write in */
    output logic                    glb_we,      // write enable
    output logic [ADDR_WIDTH-1:0]   glb_w_addr,  // byte address
    output logic [DATA_WIDTH*4-1:0] glb_w_data   // 32-bit write data
);
    // Mapping parameters
    logic [31:0] m; // number of ofmap channels stored in the GLB
    logic [31:0] e; // width fo the PE set
    logic [31:0] p; // number of filters processed by a PE set
    logic [31:0] q; // number of channels processed by a PE set
    logic [31:0] r; // number of PE sets that process different channels in the PE array
    logic [31:0] t; // number of PE sets that process different filters in the PE array
    logic [31:0] PAD; // Padding size (PAD) for the input feature map
    logic [31:0] U; // stride
    logic [31:0] R; // filter plane height
    logic [31:0] S; // filter plane width
    logic [31:0] C; // # of ifmap/filter channels
    logic [31:0] M; // # of 3D filters / # of ofmap channels
    logic [31:0] W_original; // ifmap plane width
    logic [31:0] H_original; // ifmap plane height
    logic [31:0] W; // ifmap plane width with padding (+ 2 * PAD)
    logic [31:0] H; // ifmap plane height with padding (+ 2 * PAD)
    logic [31:0] E; // ofmap plane height
    logic [31:0] F; // ofmap plane width

    always_comb begin
        m = {22'b0, mapping_param[25:16]};
        e = {28'b0, mapping_param[15:12]};
        p = {29'b0, mapping_param[11:9]};
        q = {29'b0, mapping_param[8:6]};
        r = {29'b0, mapping_param[5:3]};
        t = {29'b0, mapping_param[2:0]};
        PAD = {29'b0, shape_param1[28:26]};
        U = {30'b0, shape_param1[25:24]};
        R = {30'b0, shape_param1[23:22]};
        S = {30'b0, shape_param1[21:20]};
        C = {22'b0, shape_param1[19:10]};
        M = {22'b0, shape_param1[9:0]};
        W_original = {24'b0, shape_param2[15:8]};
        H_original = {24'b0, shape_param2[7:0]};
        F = (int'(W_original) - int'(S) + (int'(PAD) << 1)) / int'(U) + 1;
        E = (int'(H_original) - int'(R) + (int'(PAD) << 1)) / int'(U) + 1;
    end

    always_comb begin
        W = W_original + 2 * PAD;
        H = H_original + 2 * PAD;
    end

    // Ifmap address calculation
    function [ADDR_WIDTH-1:0] calc_ifmap_dram_addr(input [31:0] x, y, z);
        calc_ifmap_dram_addr = dram_ifmap_base_addr + ((x * W + y) * C + z) * 1; // uint8_t 1 byte per data
    endfunction

    function [ADDR_WIDTH-1:0] calc_ifmap_glb_addr(input [31:0] x, y, z);
        calc_ifmap_glb_addr = glb_ifmap_base_addr + ((x * W + y) * (q * r) + z) * 1; // uint8_t 1 byte per data
    endfunction
    
    // Filter address calculation
    function [ADDR_WIDTH-1:0] calc_filter_dram_addr(input [31:0] x, y, z, k);
        calc_filter_dram_addr = dram_filter_base_addr + ((x * S + y) * C * M + z * M + k) * 1; // int8_t 1 byte per data
    endfunction

    function [ADDR_WIDTH-1:0] calc_filter_glb_addr(input [31:0] x, y, z, k);
        calc_filter_glb_addr = glb_filter_base_addr + ((x * S + y) * (q * r) * (p * t) + z * (p * t) + k) * 1; // int8_t 1 byte per data
    endfunction

    // Bias address calculation
    function [ADDR_WIDTH-1:0] calc_bias_dram_addr(input [31:0] x);
        calc_bias_dram_addr = dram_bias_base_addr + x * 4; // int32_t 4 byte per data
    endfunction

    function [ADDR_WIDTH-1:0] calc_bias_glb_addr(input [31:0] x);
        calc_bias_glb_addr = glb_bias_base_addr + x * 4; // int32_t 4 byte per data
    endfunction

    // Opsum address calculation
    function [ADDR_WIDTH-1:0] calc_opsum_glb_addr(input [31:0] x, y, z);
        calc_opsum_glb_addr = glb_opsum_base_addr + ((x * F + y) * e + z) * 4; // int32_t 4 byte per data
    endfunction

    function [ADDR_WIDTH-1:0] calc_opsum_dram_addr(input [31:0] x, y, z);
        calc_opsum_dram_addr = dram_opsum_base_addr + ((x * F + y) * M + z) * 4; // int32_t 4 byte per data
    endfunction

    typedef enum logic [3:0] {
        IDLE,
        LOAD_IFMAP_DRAM_R,
        LOAD_IFMAP_GLB_W,
        LOAD_FILTER_DRAM_R,
        LOAD_FILTER_GLB_W,
        LOAD_BIAS_DRAM_R,
        LOAD_BIAS_GLB_W,
        WRITE_OPSUM_GLB,
        WRITE_OPSUM_DRAM,
        FINISH
    } state_t;

    state_t state;

    logic [31:0] M_idx, E_idx, c_idx, m_idx_filter, m_idx_bias, m_idx_opsum;
    logic [31:0] ifmap_row, ifmap_col, ifmap_ic;
    logic [31:0] filter_row, filter_col, filter_ic, filter_oc;
    logic [31:0] bias_x;
    logic [31:0] opsum_row, opsum_col, opsum_oc;
    logic        skip_ifmap, skip_opsum;
    
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            // Output signals initialization
            dram_addr   <= '0;
            dram_we     <= '0;
            dram_w_data <= '0;
            glb_r_addr  <= '0;
            glb_we      <= '0;
            glb_w_addr  <= '0;
            glb_w_data  <= '0;
            finish      <= '0;

            // Counters initialization
            M_idx       <= m - 1;
            E_idx       <= e - 1;
            c_idx       <= q * r - 1;
            m_idx_filter<= p * t - 1;
            m_idx_bias  <= p * t - 1;
            m_idx_opsum <= p * t - 1;

            ifmap_row   <= '0;
            ifmap_col   <= '0;
            ifmap_ic    <= '0;
            filter_row  <= '0;
            filter_col  <= '0;
            filter_ic   <= '0;
            filter_oc   <= '0;
            bias_x      <= '0;
            opsum_row   <= '0;
            opsum_col   <= '0;
            opsum_oc    <= '0;

            skip_ifmap  <= '0;
            skip_opsum  <= 1'b1;

            state       <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        ifmap_row   <= (E_idx - e + 1) * U;
                        ifmap_col   <= '0;
                        ifmap_ic    <= c_idx - q * r + 1;
                        filter_row  <= '0;
                        filter_col  <= '0;
                        filter_ic   <= c_idx - q * r + 1;
                        filter_oc   <= M_idx - m + 1 + m_idx_filter - p * t + 1;
                        bias_x      <= M_idx - m + 1 + m_idx_bias - p * t + 1;
                        opsum_row   <= E_idx - e + 1;
                        opsum_col   <= '0;
                        opsum_oc    <= M_idx - m + 1 + m_idx_opsum - p * t + 1;
                        m_idx_opsum <= p * t - 1;
                        finish      <= '0;
                        state       <= skip_ifmap ? LOAD_FILTER_DRAM_R : LOAD_IFMAP_DRAM_R;
                    end
                end
                LOAD_IFMAP_DRAM_R: begin
                    dram_addr <= calc_ifmap_dram_addr(ifmap_row, ifmap_col, ifmap_ic);
                    glb_we      <= '0;
                    state       <= LOAD_IFMAP_GLB_W;
                end
                LOAD_IFMAP_GLB_W: begin
                    if (ifmap_ic < c_idx) begin
                        ifmap_ic  <= ifmap_ic + 1;
                        state     <= LOAD_IFMAP_DRAM_R;
                    end else if (ifmap_col < W - 1) begin
                        ifmap_ic  <= c_idx - q * r + 1;
                        ifmap_col <= ifmap_col + 1;
                        state     <= LOAD_IFMAP_DRAM_R;
                    end else if (ifmap_row < E_idx * U + 3 - 1) begin
                        ifmap_ic  <= c_idx - q * r + 1;
                        ifmap_col <= '0;
                        ifmap_row <= ifmap_row + 1;
                        state     <= LOAD_IFMAP_DRAM_R;
                    end else begin
                        state     <= LOAD_FILTER_DRAM_R;
                    end

                    // Write to GLB
                    glb_we     <= 1'b1;
                    glb_w_addr <= calc_ifmap_glb_addr(ifmap_row, ifmap_col, ifmap_ic);
                    glb_w_data <= dram_r_data;
                end
                LOAD_FILTER_DRAM_R: begin
                    dram_addr <= calc_filter_dram_addr(filter_row, filter_col, filter_ic, filter_oc);
                    glb_we    <= '0;
                    state     <= LOAD_FILTER_GLB_W;
                end
                LOAD_FILTER_GLB_W: begin
                    if (filter_oc < M_idx - m + 1 + m_idx_filter) begin
                        filter_oc  <= filter_oc + 1;
                        state      <= LOAD_FILTER_GLB_W;
                    end else if (filter_ic < c_idx) begin
                        filter_oc  <= M_idx - m + 1;
                        filter_ic  <= filter_ic + 1;
                        state      <= LOAD_FILTER_GLB_W;
                    end else if (filter_col < R - 1) begin
                        filter_oc  <= M_idx - m + 1;
                        filter_ic  <= c_idx - q * r + 1;
                        filter_col <= filter_col + 1;
                        state      <= LOAD_FILTER_GLB_W;
                    end else if (filter_row < R - 1) begin
                        filter_oc  <= M_idx - m + 1;
                        filter_ic  <= c_idx - q * r + 1;
                        filter_col <= '0;
                        filter_row <= filter_row + 1;
                        state      <= LOAD_FILTER_GLB_W;
                    end else begin
                        filter_oc  <= M_idx - m + 1;
                        filter_ic  <= c_idx - q * r + 1;
                        filter_col <= '0;
                        filter_row <= '0;
                        state      <= LOAD_BIAS_DRAM_R;
                    end
                    
                    // Write to GLB
                    glb_we     <= 1'b1;
                    glb_w_addr <= calc_filter_glb_addr(filter_row, filter_col, filter_ic, filter_oc);
                    glb_w_data <= dram_r_data;
                end
                LOAD_BIAS_DRAM_R: begin
                    dram_addr <= calc_bias_dram_addr(bias_x);
                    glb_we      <= 1'b0;
                    state       <= LOAD_BIAS_GLB_W;
                end
                LOAD_BIAS_GLB_W: begin
                    if (bias_x < M_idx - m + 1 + m_idx_bias) begin
                        bias_x <= bias_x + 1;
                        state  <= LOAD_BIAS_DRAM_R;
                    end else begin
                        state  <= skip_opsum ? FINISH : WRITE_OPSUM_GLB;
                    end

                    // Write to GLB
                    glb_we     <= 1'b1;
                    glb_w_addr <= calc_bias_glb_addr(bias_x);
                    glb_w_data <= dram_r_data;
                end
                WRITE_OPSUM_GLB: begin
                    glb_we     <= 1'b0;
                    glb_r_addr <= calc_opsum_glb_addr(opsum_row, opsum_col, opsum_oc);
                    state      <= WRITE_OPSUM_DRAM;
                end
                WRITE_OPSUM_DRAM: begin
                    if (opsum_oc < M_idx - m + 1 + m_idx_opsum) begin
                        opsum_oc <= opsum_oc + 1;
                        state    <= WRITE_OPSUM_GLB;
                    end else if (opsum_col < F - 1) begin
                        opsum_oc  <= M_idx - m + 1 + m_idx_opsum - p * t + 1;
                        opsum_col <= opsum_col + 1;
                        state     <= WRITE_OPSUM_GLB;
                    end else if (opsum_row < M_idx - m + 1 + m_idx_opsum) begin
                        opsum_oc  <= M_idx - m + 1 + m_idx_opsum - p * t + 1;
                        opsum_col <= '0;
                        opsum_row <= opsum_row + 1;
                        state     <= WRITE_OPSUM_GLB;
                    end else if (m_idx_opsum + (p * t) < m) begin
                        m_idx_opsum <= m_idx_opsum + (p * t);
                        opsum_oc    <= M_idx - m + 1 + m_idx_opsum - p * t + 1;
                        opsum_col   <= '0;
                        opsum_row   <= E_idx - e + 1;
                        state       <= WRITE_OPSUM_GLB;
                    end else begin
                        state       <= FINISH;
                    end

                    // Write to DRAM
                    dram_we     <= 1'b1;
                    dram_addr   <= calc_opsum_dram_addr(opsum_row, opsum_col, opsum_oc);
                    dram_w_data <= glb_r_data;

                    // Reset GLB
                    glb_we     <= 1'b1;
                    glb_w_addr <= calc_opsum_glb_addr(opsum_row, opsum_col, opsum_oc);
                    glb_w_data <= '0;
                end
                FINISH: begin
                    dram_addr   <= '0;
                    dram_we     <= '0;
                    dram_addr   <= '0;
                    dram_w_data <= '0;
                    glb_r_addr  <= '0;
                    glb_we      <= '0;
                    glb_w_addr  <= '0;
                    glb_w_data  <= '0;

                    finish      <= 1'b1;

                    if (m_idx_filter + (p * t) < m) begin
                        m_idx_filter <= m_idx_filter + (p * t);
                        m_idx_bias   <= m_idx_bias + (p * t);
                        skip_ifmap   <= 1'b1;
                        skip_opsum   <= 1'b1;
                    end else if (c_idx + (q * r) < C) begin
                        c_idx        <= c_idx + (q * r);
                        m_idx_filter <= p * t - 1;
                        m_idx_bias   <= p * t - 1;
                        skip_ifmap   <= 1'b0;
                        skip_opsum   <= 1'b1;
                    end else if (E_idx + e < E) begin
                        E_idx        <= E_idx + e;
                        m_idx_filter <= p * t - 1;
                        m_idx_bias   <= p * t - 1;
                        c_idx        <= q * r - 1;
                        skip_ifmap   <= 1'b0;
                        skip_opsum   <= 1'b0;
                    end else if (M_idx + m < M) begin
                        M_idx        <= M_idx + m;
                        m_idx_filter <= p * t - 1;
                        m_idx_bias   <= p * t - 1;
                        c_idx        <= q * r - 1;
                        E_idx        <= e - 1;
                        skip_ifmap   <= 1'b0;
                        skip_opsum   <= 1'b0;
                    end
                    state <= IDLE;
                end
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule