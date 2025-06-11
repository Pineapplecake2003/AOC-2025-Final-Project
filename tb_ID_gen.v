// Testbench for multi_id_generator
`timescale 1ns/1ps

module tb_multi_id_generator;

// 測試參數
wire [2:0] PE_ARRAY_H = 6;
wire [3:0] PE_ARRAY_W = 8;
wire [1:0] KERNEL_H   = 3;
wire [2:0] p          = 4;
wire [2:0] q          = 4;
wire [2:0] r          = 2;
wire [2:0] t          = 2;
wire [2:0] t_H        = 1;
wire [2:0] t_W        = 2;
wire [2:0] e          = 4;
wire       LINEAR     = 0;

// 測試信號
reg clk;
reg rst_n;
reg start;

wire [4:0] filter_XID;
wire [2:0] filter_YID;
wire [4:0] ifmap_XID;
wire [2:0] ifmap_YID;
wire [4:0] ipsum_XID;
wire [2:0] ipsum_YID;
wire [4:0] opsum_XID;
wire [2:0] opsum_YID;
wire x_done;
wire y_done;

// DUT實例化
multi_id_generator dut (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .PE_ARRAY_H(PE_ARRAY_H),
    .PE_ARRAY_W(PE_ARRAY_W),
    .KERNEL_H(KERNEL_H),
    .p(p),
    .q(q),
    .r(r),
    .t(t),
    .e(e),
    .t_H(t_H),
    .t_W(t_W),
    .LINEAR(LINEAR),
    .filter_XID(filter_XID),
    .filter_YID(filter_YID),
    .ifmap_XID(ifmap_XID),
    .ifmap_YID(ifmap_YID),
    .ipsum_XID(ipsum_XID),
    .ipsum_YID(ipsum_YID),
    .opsum_XID(opsum_XID),
    .opsum_YID(opsum_YID),
    .x_done(x_done),
    .y_done(y_done)
);

// 時脈生成
initial begin
    clk = 0;
    forever #5 clk = ~clk; // 100MHz 時脈
end

// 測試序列
initial begin
    // 初始化
    rst_n = 0;
    start = 0;
    
    // 重設階段
    #20;
    rst_n = 1;
    #10;
    
    // 開始測試
    $display("=== 開始 ID 生成測試 ===");
    $display("時間\t行\t列\tFilter_XID\tFilter_YID\tifmap_XID\tifmap_YID\tipsum_XID\tipsum_YID\topsum_XID\topsum_YID");
    
    start = 1;
    #10;
    start = 0;
    
    /*
    // 監控輸出
    while (!x_done) begin
        @(posedge clk);
        $display("%0t\t%0d\t%0d\t%0d\t\t%0d\t\t%0d\t\t%0d\t\t%0d\t\t%0d\t\t%0d\t\t%0d", 
                $time, dut.row_cnt_XID, dut.col_cnt_XID, filter_XID, filter_YID, ifmap_XID, ifmap_YID, 
                ipsum_XID, ipsum_YID, opsum_XID, opsum_YID);
    end
    */
    while (!x_done) begin
        @(posedge clk);
        $display("ID generating...");
    end

    $display("=== 測試完成 ===");
    $display("x_done = %b, y_done = %b", x_done, y_done);
    
    #100;
    $finish;
end

// 波形檔案輸出
initial begin
    $dumpfile("multi_id_generator.vcd");
    $dumpvars(0, tb_multi_id_generator);
end

endmodule