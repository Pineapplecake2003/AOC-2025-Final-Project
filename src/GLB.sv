`include "define.svh"
module GLB (
    input clk,
    input rst,
    input [3:0] w_en,
    input [15:0] address,
    input [31:0] write_data,
    output [31:0] read_data
);
    integer i;
    reg [7:0] mem [0:65535];
    always @(posedge clk or posedge rst) begin
        if(rst)begin
            for (i = 0; i < `GLB_SIZE; i=i+1) begin
                mem[address] <= 8'b0;
            end
        end
        if(w_en!=4'b0)begin
            mem[address]    <= (w_en[0]==1'b1)? (write_data[7:0] & {8{w_en[0]}})   : mem[address];
            mem[address+1]  <= (w_en[1]==1'b1)? (write_data[15:8]  & {8{w_en[1]}}) : mem[address+1];
            mem[address+2]  <= (w_en[2]==1'b1)? (write_data[23:16] & {8{w_en[2]}}) : mem[address+2];
            mem[address+3]  <= (w_en[3]==1'b1)? (write_data[31:24] & {8{w_en[3]}}) : mem[address+3];
        end
    end 

    // delay 1 cycle
    reg [32:0] read_data_buf;
    always @(posedge clk or posedge rst) begin
        if(rst)
            read_data_buf <= 32'b0;
        else
            read_data_buf <= {mem[address+3],mem[address+2],mem[address+1],mem[address]};
    end
    assign read_data = read_data_buf;

endmodule