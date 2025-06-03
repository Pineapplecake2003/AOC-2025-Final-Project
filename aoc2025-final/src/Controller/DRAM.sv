module DRAM #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 1024,               // KiB
    parameter ADDR_WIDTH = 20             // 2^20 = 1048576 Bytes
    parameter string INIT_FILE = ""       // initialized memory file
)(
    input  logic                    clk,
    input  logic                    rst,
    input  logic                    we,   // write enable
    input  logic [ADDR_WIDTH-1:0]   addr, // byte address
    input  logic [DATA_WIDTH*4-1:0] din,  // 32-bit write data
    output logic [DATA_WIDTH*4-1:0] dout  // 32-bit read data
);

    // Byte-addressable memory: 64KiB = 65536 x 8-bit
    logic [DATA_WIDTH-1:0] mem [0 : (DEPTH * 1024) - 1];

    initial begin
        if (INIT_FILE != "") begin
            $display("DRAM: loading memory from %s ...", INIT_FILE);
            $readmemh(INIT_FILE, mem);
        end
    end
    
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            dout <= 0;
        end 
        else begin
            if (we) begin
                mem[addr    ] <= din[7:0];
                mem[addr + 1] <= din[15:8];
                mem[addr + 2] <= din[23:16];
                mem[addr + 3] <= din[31:24];
            end
            dout <= {
                mem[addr + 3],
                mem[addr + 2],
                mem[addr + 1],
                mem[addr    ]
            };
        end
    end

endmodule
