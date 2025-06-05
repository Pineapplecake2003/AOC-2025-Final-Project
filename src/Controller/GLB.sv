module GLB #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 64,               // KiB
    parameter ADDR_WIDTH = 32           // 2^16 = 65536 Bytes
)(
    input  logic                    clk,
    input  logic                    rst,
    /* read port */
    input  logic                    re,     // read enable
    input  logic [ADDR_WIDTH-1:0]   r_addr, // byte address
    output logic [DATA_WIDTH*4-1:0] dout,    // 32-bit read data
    /* write port */
    // write first
    input  logic                    we,     // write enable
    input  logic [ADDR_WIDTH-1:0]   w_addr, // byte address
    input  logic [DATA_WIDTH*4-1:0] din    // 32-bit write data
);

    // Byte-addressable memory: 64KiB = 65536 x 8-bit
    logic [DATA_WIDTH-1:0] mem [0 : (DEPTH * 1024) - 1];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout <= 0;
        end
        else begin
            if (we) begin
                mem[w_addr    ] <= din[7:0];
                mem[w_addr + 1] <= din[15:8];
                mem[w_addr + 2] <= din[23:16];
                mem[w_addr + 3] <= din[31:24];
            end
            if (re) begin
                if(we && r_addr == w_addr) begin
                    dout <= din;
                end
                else begin
                    dout <= {
                        mem[r_addr + 3],
                        mem[r_addr + 2],
                        mem[r_addr + 1],
                        mem[r_addr    ]
                    };
                end
            end
            else begin
                dout <= 0;
            end
        end
    end

endmodule
