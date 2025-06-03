`include "src/Controller/GLB.sv"
`include "src/Controller/DMA.sv"

module top #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,

    parameter GLB_DATA_WIDTH = 8,
    parameter GLB_DEPTH = 64,               // KiB
    parameter GLB_ADDR_WIDTH = 32           // 2^16 = 65536 Bytes
)(
    // controller <-> dma interface
    input  logic                      clk,
    input  logic                      rst,
    input  logic                      start,
    input  logic [ADDR_WIDTH-1:0]     src_addr,
    input  logic [ADDR_WIDTH-1:0]     dst_addr,
    input  logic [15:0]               length,
    output logic                      done,

    // dma <-> hal (dram) interface
    output logic                      notify_host,
    output logic [ADDR_WIDTH-1:0]     mem_read_addr,
    input  logic [DATA_WIDTH-1:0]     mem_read_data,
    output logic [15:0]               mem_length,

    // glb interface (optional)
    input  logic                      glb_re,
    input  logic [ADDR_WIDTH-1:0]     glb_r_addr,
    output logic [DATA_WIDTH-1:0]     glb_dout
);

    // internal signals
    logic [ADDR_WIDTH-1:0] dma_write_addr;
    logic                  dma_write_en;
    logic [DATA_WIDTH-1:0] dma_write_data;

    // Instantiate DMA
    DMA #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) dma_inst (
        .clk(clk),
        .rst(rst),
        .start(start),
        .src_addr(src_addr),
        .dst_addr(dst_addr),
        .length(length),
        .done(done),
        .notify_host(notify_host),
        .mem_read_addr(mem_read_addr),
        .mem_read_data(mem_read_data),
        .mem_length(mem_length),
        .mem_write_addr(dma_write_addr),
        .mem_write_en(dma_write_en),
        .mem_write_data(dma_write_data)
    );

    // Instantiate GLB
    GLB #(
        .DATA_WIDTH(GLB_DATA_WIDTH),
        .DEPTH(GLB_DEPTH),
        .ADDR_WIDTH(GLB_ADDR_WIDTH)
    ) glb_inst (
        .clk(clk),
        .rst(rst),
        .re(glb_re),
        .r_addr(glb_r_addr),
        .dout(glb_dout),
        .we(dma_write_en),
        .w_addr(dma_write_addr)
        .din(dma_write_data)
    );

endmodule
