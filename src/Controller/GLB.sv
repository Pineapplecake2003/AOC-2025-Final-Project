module GLB #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 64,               // KiB
    parameter ADDR_WIDTH = 32           // 2^16 = 65536 Bytes
)(
    input  logic                    clk,
    input  logic                    rst_n,
    /* read port */
    input  logic [3:0]              re,     // read enable
    input  logic [ADDR_WIDTH-1:0]   r_addr, // byte address
    output logic [DATA_WIDTH*4-1:0] dout,    // 32-bit read data
    /* write port */
    // write first
    input  logic [3:0]              we,     // write enable
    input  logic [ADDR_WIDTH-1:0]   w_addr, // byte address
    input  logic [DATA_WIDTH*4-1:0] din    // 32-bit write data
);

    // Byte-addressable memory: 64KiB = 65536 x 8-bit
    logic [DATA_WIDTH-1:0] mem [0 : (DEPTH * 1024) - 1];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout <= 0;
        end
        else begin
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

endmodule
