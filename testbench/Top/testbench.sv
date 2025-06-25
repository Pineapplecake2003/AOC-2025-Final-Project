`timescale 1ns/10ps
`define CYCLE 10.0    
`define MAX_CYCLE 500000
`define MAX_TILE 20
`include "src/Top.sv"

module Top_tb;

    parameter ADDR_WIDTH = 32;
    parameter DATA_WIDTH = 8;
    parameter DEPTH = 64;

    // DUT IO
    logic clk, rst, done;
    logic dram_we;
    logic [ADDR_WIDTH-1:0]   dram_addr;
    logic [DATA_WIDTH*4-1:0] dram_w_data, dram_r_data;
    logic ctrl_reg_w_en;
    logic [1:0] ctrl_reg_wsel;
    logic [31:0] ctrl_reg_wdata;

    // 模擬 DRAM 記憶體
    logic [7:0] dram_mem [0 : 20000];

    Top #(
        .DRAM_IFMAP_BASE_ADDR (0),
        .DRAM_FILTER_BASE_ADDR(6936),
        .DRAM_BIAS_BASE_ADDR  (7368),
        .DRAM_OPSUM_BASE_ADDR (7400)
    ) Top_test (
        .clk           (clk),
        .rst           (rst),
        .ctrl_reg_w_en (ctrl_reg_w_en),
        .ctrl_reg_wsel (ctrl_reg_wsel),
        .ctrl_reg_wdata(ctrl_reg_wdata),
        .dla_done      (done),

        /* DRAM*/
        .dram_we       (dram_we),
        .dram_addr     (dram_addr),
        .dram_w_data   (dram_w_data),
        .dram_r_data   (dram_r_data)
    );

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

    // 取出 DRAM 結果與 golden 比對
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
        int errors = 0;
        int cycle = 0;
        int mapping_param = 32'h000484ca;
        int shape_param1  = 32'h01f01808;
        int shape_param2  = 32'h00002222;
        int op_config     = 32'h00000001;
        int dram_ifmap_base_addr  = 0;    // DRAM_IFMAP_BASE_ADDR
        int dram_filter_base_addr = 6936; // DRAM_FILTER_BASE_ADDR
        int dram_bias_base_addr   = 7368; // DRAM_BIAS_BASE_ADDR
        int dram_opsum_base_addr  = 7400; // DRAM_OPSUM_BASE

        clk = 0; rst = 1;

        // 載入txt到DRAM
        load_txt_to_mem("./tb0/ifmap.txt",  dram_ifmap_base_addr,  34*34*6);
        load_txt_to_mem("./tb0/filter.txt", dram_filter_base_addr, 3*3*6*8);
        load_txt_to_mem("./tb0/bias.txt",   dram_bias_base_addr,   8*4);

        #(`CYCLE) rst = 0;

        // tile by tile測試
        while (cycle < `MAX_CYCLE) begin
            // 寫入 mapping_param
            @(negedge clk);
            ctrl_reg_w_en    = 1;
            ctrl_reg_wsel    = 2'd0;
            ctrl_reg_wdata   = mapping_param;
            @(negedge clk);
            ctrl_reg_w_en    = 0;

            // 寫入 shape_param1
            @(negedge clk);
            ctrl_reg_w_en    = 1;
            ctrl_reg_wsel    = 2'd1;
            ctrl_reg_wdata   = shape_param1;
            @(negedge clk);
            ctrl_reg_w_en    = 0;

            // 寫入 shape_param2
            @(negedge clk);
            ctrl_reg_w_en    = 1;
            ctrl_reg_wsel    = 2'd2;
            ctrl_reg_wdata   = shape_param2;
            @(negedge clk);
            ctrl_reg_w_en    = 0;

            // 寫入 op_config
            @(negedge clk);
            ctrl_reg_w_en    = 1;
            ctrl_reg_wsel    = 2'd3;
            ctrl_reg_wdata   = op_config;
            @(negedge clk);
            ctrl_reg_w_en    = 0;

            if (done) begin
                $display("All done.");
                break;
            end

            @(negedge clk);
            cycle++;
        end

        errors = check_glb_vs_golden(dram_opsum_base_addr, "./tb0/golden_output.txt", 16*16*8, 4);
        if (errors == 0)
            $display("All PASS!");
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