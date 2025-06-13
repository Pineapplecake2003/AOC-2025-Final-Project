`timescale 1ns/1ps
`include "/src/Controller/ID_gen_combinational.v"
module tb_id_generator();

reg [2:0] PE_ARRAY_H;
reg [3:0] PE_ARRAY_W;
reg [1:0] KERNEL_H;
reg [2:0] p;
reg [2:0] q;
reg [2:0] r;
reg [2:0] t;
reg [5:0] e;
reg [2:0] t_H;
reg [2:0] t_W;
reg LINEAR;
wire [4:0] filter_XID [0:47];
wire [2:0] filter_YID [0:5];  // 修改為每行一個
wire [4:0] ifmap_XID [0:47];
wire [2:0] ifmap_YID [0:5];   // 修改為每行一個
wire [4:0] ipsum_XID [0:47];
wire [2:0] ipsum_YID [0:5];   // 修改為每行一個
wire [4:0] opsum_XID [0:47];
wire [2:0] opsum_YID [0:5];   // 修改為每行一個
wire [4:0] LN_config;

// 被測模組實例化
pe_array_id_generator dut (
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
    .LN_config(LN_config)
);

initial begin
    // 設置參數（與C代碼一致）
    PE_ARRAY_H = 3'd6;   // 6行
    PE_ARRAY_W = 4'd8;   // 8列
    KERNEL_H = 2'd3;     // 卷積核高度
    p = 3'd4;
    q = 3'd4;
    r = 3'd1;            // 重要參數（恢復為C代碼的r=1）
    t = 3'd1;
    e = 6'd16;
    t_H = 3'd1;          // 預先計算值
    t_W = 3'd1;
    LINEAR = 0;          // 非線性模式
    
    #5000;
    
    // 專用格式化打印函數
    $display("=== filter_XID ===");
    print_array_2d(filter_XID, 6, 8);
    
    $display("\n=== filter_YID ===");
    print_array_1d(filter_YID, 6);
    
    $display("\n=== ifmap_XID ===");
    print_array_2d(ifmap_XID, 6, 8);
    
    $display("\n=== ifmap_YID ===");
    print_array_1d(ifmap_YID, 6);
    
    $display("\n=== ipsum_XID ===");
    print_array_2d(ipsum_XID, 6, 8);
    
    $display("\n=== ipsum_YID ===");
    print_array_1d(ipsum_YID, 6);
    
    $display("\n=== opsum_XID ===");
    print_array_2d(opsum_XID, 6, 8);
    
    $display("\n=== opsum_YID ===");
    print_array_1d(opsum_YID, 6);
    
    $display("");  // 換行
    $display("LN_config: ");  // 換行
    $display("%0d", LN_config);
    $display("");  // 換行
    
    $finish;
end

// Print tasks for debugging
task print_array_2d;
    input [4:0] array [0:47];
    input integer rows;
    input integer cols;
    integer i, j, index;
    begin
        for (i = 0; i < rows; i = i + 1) begin
            for (j = 0; j < cols; j = j + 1) begin
                index = i * cols + j;
                if (array[index] == 31) 
                    $write("31");
                else
                    $write("%0d", array[index]);
                $write(", ");
            end
            $display("");  // 換行
        end
    end
endtask

task print_array_1d;
    input [2:0] array [0:5];
    input integer rows;
    integer i;
    begin
        for (i = 0; i < rows; i = i + 1) begin
            if (array[i] == 7)
                $display("7, ");
            else
                $display("%0d, ", array[i]);
        end
    end
endtask



endmodule
