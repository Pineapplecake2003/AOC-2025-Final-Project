`include "src/PE_array/PE.sv"
`include "src/PE_array/SUPER.sv"
`include "src/PE_array/GIN/GIN.sv"
`include "src/PE_array/GON/GON.sv"
`include "src/Controller/GLB.sv"
`include "define.svh"

module Top(
    input clk,
    input rst,
    input start,
    output logic done
);
// Controller ...

wire [31:0] data_temp;
assign data_temp = 32'b0;
GLB glb(
    .clk(clk),
    .rst(rst),
    /* read port */
    .re(1'b0),     // read enable
    .r_addr(32'b0), // byte address
    .dout(data_temp),    // 32-bit read data
    /* write port */
    // write first
    .we(1'b0),     // write enable
    .w_addr(32'b0), // byte address
    .din(32'b0)    // 32-bit write data
);

// PE_array ...
initial begin
    done=0;
    #100 done = 1;
end
endmodule
