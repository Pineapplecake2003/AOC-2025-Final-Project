`timescale 1ns/1ps
`include "Tiling.sv"

module Tiling_tb;

    parameter ADDR_WIDTH = 32;
    parameter DATA_WIDTH = 8;

    // DUT IO
    logic clk, rst, start, finish;
    logic [31:0] mapping_param, shape_param1, shape_param2;
    logic [ADDR_WIDTH-1:0] dram_ifmap_base_addr, dram_filter_base_addr, dram_bias_base_addr, dram_opsum_base_addr;
    logic [ADDR_WIDTH-1:0] glb_ifmap_base_addr, glb_filter_base_addr, glb_bias_base_addr, glb_opsum_base_addr;
    logic dram_we;
    logic [ADDR_WIDTH-1:0] dram_addr;
    logic [DATA_WIDTH*4-1:0] dram_w_data;
    logic [DATA_WIDTH*4-1:0] dram_r_data;
    logic [ADDR_WIDTH-1:0] glb_r_addr;
    logic [DATA_WIDTH*4-1:0] glb_r_data;
    logic glb_we;
    logic [ADDR_WIDTH-1:0] glb_w_addr;
    logic [DATA_WIDTH*4-1:0] glb_w_data;

    // 模擬 DRAM/GLB 記憶體
    localparam DRAM_SIZE = 65536;
    localparam GLB_SIZE  = 65536;
    logic [7:0] dram_mem [0:DRAM_SIZE-1];
    logic [7:0] glb_mem  [0:GLB_SIZE-1];

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
        $fclose(fd);
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
                glb_val |= (int'(glb_mem[base + i*word_bytes + b])) << (8*b);
            if (glb_val !== val) begin
                $display("Mismatch at %0d: got %0d, expect %0d", i, glb_val, val);
                errors++;
            end
        end
        $fclose(fd);
        return errors;
    endfunction

    // clock
    `ifdef NO_TIMING
        always clk = ~clk;
    `else
        always #5 clk = ~clk;
    `endif

    // DUT
    Tiling #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH)) dut (
        .clk(clk), .rst(rst), .start(start), .finish(finish),
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
        .glb_r_addr(glb_r_addr), .glb_r_data(glb_r_data),
        .glb_we(glb_we), .glb_w_addr(glb_w_addr), .glb_w_data(glb_w_data)
    );

    // DRAM/GLB 行為
    always_ff @(posedge clk) begin
        // DRAM讀
        dram_r_data <= {dram_mem[dram_addr+3], dram_mem[dram_addr+2], dram_mem[dram_addr+1], dram_mem[dram_addr]};
        // DRAM寫
        if (dram_we) begin
            dram_mem[dram_addr+0] <= dram_w_data[7:0];
            dram_mem[dram_addr+1] <= dram_w_data[15:8];
            dram_mem[dram_addr+2] <= dram_w_data[23:16];
            dram_mem[dram_addr+3] <= dram_w_data[31:24];
        end
        // GLB寫
        if (glb_we) begin
            glb_mem[glb_w_addr+0] <= glb_w_data[7:0];
            glb_mem[glb_w_addr+1] <= glb_w_data[15:8];
            glb_mem[glb_w_addr+2] <= glb_w_data[23:16];
            glb_mem[glb_w_addr+3] <= glb_w_data[31:24];
        end
        // GLB讀
        glb_r_data <= {glb_mem[glb_r_addr+3], glb_mem[glb_r_addr+2], glb_mem[glb_r_addr+1], glb_mem[glb_r_addr]};
    end

    initial begin
        int errors = 0;
        clk = 0; rst = 1; start = 0;
        // 設定參數與 base address
        mapping_param  = 32'h000480D9;
        shape_param1   = 32'h024C1808;
        shape_param2   = 32'h00002222;
        dram_ifmap_base_addr   = 0;
        dram_filter_base_addr  = 4096;
        dram_bias_base_addr    = 8192;
        dram_opsum_base_addr   = 12288;
        glb_ifmap_base_addr    = 0;
        glb_filter_base_addr   = 2048;
        glb_bias_base_addr     = 4096;
        glb_opsum_base_addr    = 6144;

        // 載入txt到DRAM
        load_txt_to_mem("../test/U=2,E=F=16/ifmap.txt",    dram_ifmap_base_addr, 34*34*6);
        load_txt_to_mem("../test/U=2,E=F=16/filter.txt",   dram_filter_base_addr, 3*3*6*8);
        load_txt_to_mem("../test/U=2,E=F=16/bias.txt",     dram_bias_base_addr, 8*4);
        // golden_output 只用來比對，不需載入DRAM

        #20 rst = 0;

        // tile by tile測試
        repeat (10) begin // 依實際tile數調整
            @(negedge clk);
            start = 1;
            @(negedge clk);
            start = 0;
            wait(finish);
            // 比對GLB與golden
            errors = check_glb_vs_golden(glb_opsum_base_addr, "../test/U=2,E=F=16/golden_output.txt", 16*16*8, 4);
            if (errors == 0)
                $display("Tile PASS!");
            else
                $display("Tile FAIL: %0d errors", errors);
            @(negedge clk);
        end

        $display("All test done.");
        $finish;
    end

endmodule