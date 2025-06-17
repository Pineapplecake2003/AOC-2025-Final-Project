`timescale 1ns/10ps
`define CYCLE 10.0    
`define MAX_CYCLE 500000
`define MAX_TILE 20
`include "../../src/Tiling/tiling.sv"
// `include "../../src/Controller/GLB.sv"

module tiling_tb;

    parameter ADDR_WIDTH = 32;
    parameter DATA_WIDTH = 8;
    parameter DEPTH = 64;

    // DUT IO
    logic clk, rst, start, finish, done;
    logic [31:0] mapping_param, shape_param1, shape_param2;
    logic [ADDR_WIDTH-1:0] dram_ifmap_base_addr, dram_filter_base_addr, dram_bias_base_addr, dram_opsum_base_addr;
    logic [ADDR_WIDTH-1:0] glb_ifmap_base_addr, glb_filter_base_addr, glb_bias_base_addr, glb_opsum_base_addr;
    logic dram_we;
    logic [ADDR_WIDTH-1:0] dram_addr;
    logic [DATA_WIDTH*4-1:0] dram_w_data;
    logic [DATA_WIDTH*4-1:0] dram_r_data;
    logic [3:0] glb_re;
    logic [ADDR_WIDTH-1:0] glb_r_addr;
    logic [DATA_WIDTH*4-1:0] glb_r_data;
    logic [3:0] glb_we;
    logic [ADDR_WIDTH-1:0] glb_w_addr;
    logic [DATA_WIDTH*4-1:0] glb_w_data;

    logic [ADDR_WIDTH-1:0] controller_glb_addr;

    // 模擬 DRAM 記憶體
    logic [7:0] dram_mem [0 : 16000];
    logic [DATA_WIDTH-1:0] mem [0 : 3860];

    // DRAM 行為
    always @ (posedge clk) begin
        // DRAM讀
        dram_r_data <= {dram_mem[dram_addr+3], dram_mem[dram_addr+2], dram_mem[dram_addr+1], dram_mem[dram_addr]};
        // DRAM寫
        if (dram_we) begin
            dram_mem[dram_addr+0] = dram_w_data[7:0];
            dram_mem[dram_addr+1] = dram_w_data[15:8];
            dram_mem[dram_addr+2] = dram_w_data[23:16];
            dram_mem[dram_addr+3] = dram_w_data[31:24];
        end
    end

    logic [DATA_WIDTH*4-1:0] dout, din;
    logic [ADDR_WIDTH-1:0] r_addr, w_addr;
    logic [3:0] re, we;
    assign r_addr = glb_r_addr;
    assign w_addr = glb_w_addr;
    assign re = glb_re;
    assign we = glb_we;
    assign din = glb_w_data;
    assign glb_r_data = dout;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout <= 0;
        end else begin
            case(we)
                4'b0001: begin
                    mem[w_addr    ] <= din[7:0];
                end
                4'b0011: begin
                    mem[w_addr    ] <= din[7:0];
                    mem[w_addr + 1] <= din[15:8];
                end
                4'b0111: begin
                    mem[w_addr    ] <= din[7:0];
                    mem[w_addr + 1] <= din[15:8];
                    mem[w_addr + 2] <= din[23:16];
                end
                4'b1111: begin
                    mem[w_addr    ] <= din[7:0];
                    mem[w_addr + 1] <= din[15:8];
                    mem[w_addr + 2] <= din[23:16];
                    mem[w_addr + 3] <= din[31:24];
                end
                default: begin
                    mem[w_addr    ] <= mem[w_addr    ];
                    mem[w_addr + 1] <= mem[w_addr + 1];
                    mem[w_addr + 2] <= mem[w_addr + 2];
                    mem[w_addr + 3] <= mem[w_addr + 3];
                end
            endcase
            case(re)
                4'b0001: begin
                    dout <= {24'd0, mem[r_addr]};
                end
                4'b0011: begin
                    dout <= {16'd0, mem[r_addr+1], mem[r_addr]};
                end
                4'b0111: begin
                    dout <= {8'd0, mem[r_addr+2], mem[r_addr+1], mem[r_addr]};
                end
                4'b1111: begin
                    dout <= {mem[r_addr+3], mem[r_addr+2], mem[r_addr+1], mem[r_addr]};
                end
                default: begin
                    dout <= 0;
                end
            endcase
        end
    end

    tiling #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH)) dut (
        .clk(clk), .rst(rst), .start(start), .finish(finish), .done(done), .controller_glb_addr(controller_glb_addr),
        .mapping_param(mapping_param), .shape_param1(shape_param1), .shape_param2(shape_param2),
        .dram_ifmap_base_addr(dram_ifmap_base_addr),
        .dram_filter_base_addr(dram_filter_base_addr),
        .dram_bias_base_addr(dram_bias_base_addr),
        .dram_opsum_base_addr(dram_opsum_base_addr),
        .dram_we(dram_we), .dram_addr(dram_addr), .dram_w_data(dram_w_data), .dram_r_data(dram_r_data),
        .glb_ifmap_base_addr(glb_ifmap_base_addr),
        .glb_filter_base_addr(glb_filter_base_addr),
        .glb_bias_base_addr(glb_bias_base_addr),
        .glb_opsum_base_addr(glb_opsum_base_addr),
        .glb_re(glb_re), .glb_r_addr(glb_r_addr), .glb_r_data(glb_r_data),
        .glb_we(glb_we), .glb_w_addr(glb_w_addr), .glb_w_data(glb_w_data)
    );

    // 讀檔案到 DRAM
    task load_txt_to_mem(input string fname, input int base, input int bytes);
        int fd, val, i;
        fd = $fopen(fname, "r");
        if (fd == 0) begin
            $display("Cannot open %s", fname);
            $finish;
        end
        for (i = 0; i < bytes; i++) begin
            void'($fscanf(fd, "%d,", val));
            dram_mem[base + i] = val[7:0];
        end
        $display("Finsh loading %s", fname);
        $fclose(fd);
    endtask

    task automatic dla_compute(
        input int glb_ifmap_addr,
        input int glb_filter_addr,
        input int glb_opsum_addr,
        inout logic [7:0] glb_mem []
    );
        // 參數請依 mapping_param/shape_param 設定
        localparam int U = 2, e = 8, R = 3, W = 34, q = 3, r = 1, p = 2, t = 1, F = 16;
        int ifmap_tile [0:U*(e-1)+R-1][0:W-1][0:q*r-1];
        int signed filter_tile [0:R-1][0:R-1][0:q*r-1][0:p*t-1];
        int signed psum_tile [0:e-1][0:F-1][0:p*t-1];
        int h, w, c, val, row, col, oc, ic, rr, s, h_in, w_in, p_addr, if_addr, fil_addr, w_addr;

        // $display("----------------------------");
        // $display("DLA compute. opsum addr: %0d", glb_opsum_addr);
        // 讀 psum_tile
        
        for (h = 0; h < e; h++)
            for (w = 0; w < F; w++)
                for (c = 0; c < p*t; c++) begin
                    p_addr = glb_opsum_addr + ((h * F + w) * (p*t) + c) * 4;
                    val = 0;
                    val |= glb_mem[p_addr + 0];
                    val |= glb_mem[p_addr + 1] << 8;
                    val |= glb_mem[p_addr + 2] << 16;
                    val |= glb_mem[p_addr + 3] << 24;
                    psum_tile[h][w][c] = val;
                    // $display("val =  %0d, addr = %0d", val, p_addr);
                    // p_addr += 4;
                end

        // 讀 ifmap_tile
        if_addr = glb_ifmap_addr;
        for (h = 0; h < U*(e-1)+R; h++)
            for (w = 0; w < W; w++)
                for (c = 0; c < q*r; c++)
                    ifmap_tile[h][w][c] = glb_mem[if_addr++];

        // 讀 filter_tile
        fil_addr = glb_filter_addr;
        for (rr = 0; rr < R; rr++)
            for (s = 0; s < R; s++)
                for (ic = 0; ic < q*r; ic++)
                    for (oc = 0; oc < p*t; oc++)
                        filter_tile[rr][s][ic][oc] = $signed(glb_mem[fil_addr++]);

        // DLA 運算
        for (oc = 0; oc < p*t; oc++)
            for (ic = 0; ic < q*r; ic++)
                for (w = 0; w < F; w++)
                    for (h = 0; h < e; h++)
                        for (rr = 0; rr < R; rr++)
                            for (s = 0; s < R; s++) begin
                                h_in = h * U + rr;
                                w_in = w * U + s;
                                // if(h==0 && w==0 && oc==0)
                                //     $display("psum_tile[%0d][%0d][%0d] = %0d", h, w, oc, psum_tile[h][w][oc]);
                                psum_tile[h][w][oc] += ifmap_tile[h_in][w_in][ic] * filter_tile[rr][s][ic][oc];
                                // if(h==0 && w==0 && oc==0) begin
                                //     $display("psum_tile[%0d][%0d][%0d] += ifmap_tile[%0d][%0d][%0d] * filter_tile[%0d][%0d][%0d][%0d]", h, w, oc, h_in,w_in,ic,rr,s,ic,oc);
                                //     $display("%0d, %0d, %0d", psum_tile[h][w][oc], ifmap_tile[h_in][w_in][ic], filter_tile[rr][s][ic][oc]);
                                // end
                            end

        // 寫回 psum_tile 到 glb_mem
        w_addr = glb_opsum_addr;
        for (row = 0; row < e; row++)
            for (col = 0; col < F; col++)
                for (c = 0; c < p*t; c++) begin
                    val = psum_tile[row][col][c];
                    glb_mem[w_addr++] = val[7:0];
                    glb_mem[w_addr++] = val[15:8];
                    glb_mem[w_addr++] = val[23:16];
                    glb_mem[w_addr++] = val[31:24];
                end
    endtask

    // 取出 GLB 結果與 golden 比對
    function int check_glb_vs_golden(input int base, input string golden_file, input int count, input int word_bytes);
        int fd, val, i, errors;
        int glb_val;
        errors = 0;
        fd = $fopen(golden_file, "r");
        if (fd == 0) begin
            $display("Cannot open %s", golden_file);
            $finish;
        end
        for (i = 0; i < count; i++) begin
            void'($fscanf(fd, "%d,", val));
            glb_val = 0;
            for (int b = 0; b < word_bytes; b++)
                glb_val |= (int'(dram_mem[base + i*word_bytes + b])) << (8*b);
            if (glb_val !== val) begin
                $display("Mismatch at %0d: got %0d, expect %0d", i, glb_val, val);
                errors++;
            end
        end
        $fclose(fd);
        return errors;
    endfunction

    // clock
    always #(`CYCLE/2) clk = ~clk;

    initial begin
        localparam int U = 2, e = 8, R = 3, W = 34, q = 3, r = 1, p = 2, t = 1, F = 16;
        int errors = 0, tile = 0;
        clk = 0; rst = 1; start = 0;
        // 設定參數與 base address
        mapping_param  = 32'h000484c9;
        shape_param1   = 32'h02f01808;
        shape_param2   = 32'h00002222;
        dram_ifmap_base_addr   = 0;    // uint8_t 34*34*6 = 6936
        dram_filter_base_addr  = 6936; // int8_t  3*3*6*8 = 432
        dram_bias_base_addr    = 7368; // int32_t 8*4 = 32
        dram_opsum_base_addr   = 7400; // int32_t 16*16*8*4 = 8192
        glb_ifmap_base_addr    = 0;
        glb_filter_base_addr   = W * (U*(e-1)+R)* q*r;
        glb_bias_base_addr     = W * (U*(e-1)+R)* q*r + p*t *q*r*R*R;
        glb_opsum_base_addr    = W * (U*(e-1)+R) * q*r + p*t *q*r*R*R + p*t*4;

        // 載入txt到DRAM
        load_txt_to_mem("./tb0/ifmap.txt",  dram_ifmap_base_addr,  34*34*6);
        load_txt_to_mem("./tb0/filter.txt", dram_filter_base_addr, 3*3*6*8);
        load_txt_to_mem("./tb0/bias.txt",   dram_bias_base_addr,   8*4);
        // golden_output 只用來比對，不需載入DRAM

        #(`CYCLE) rst = 0;

        // tile by tile測試
        while (!done && tile < `MAX_TILE) begin
            @(negedge clk); start = 1;
            @(negedge clk); start = 0;
            wait(finish);
            // $display("done = %0d", done);

            if (done) begin
                $display("Tile %0d done.", tile);
                break;
            end else begin
                // 每次 finish 後呼叫 dla_compute 處理 glb
                dla_compute(
                    glb_ifmap_base_addr,
                    glb_filter_base_addr,
                    controller_glb_addr,
                    mem
                );
                tile++;
            end

            @(negedge clk);
        end

        errors = check_glb_vs_golden(dram_opsum_base_addr, "./tb0/golden_output.txt", 16*16*8, 4);
        if (errors == 0)
            $display("All Tiles PASS!");
        else
            $display("FAIL: %0d errors", errors);

        $display("All test done.");
        $finish;
    end

    initial begin
    `ifdef FSDB
        $fsdbDumpfile("testbench.fsdb");
        $fsdbDumpvars("+all");
    `endif
    end
endmodule