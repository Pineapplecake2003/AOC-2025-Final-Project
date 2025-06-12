/* verilator lint_off MULTITOP */
`include "define.svh"

module GON_Bus #(
    parameter NUMS_MASTER = `NUMS_PE_COL,
    parameter ID_SIZE = `XID_BITS
) (
    input clk,
    input rst_n,
    input [ID_SIZE - 1:0] tag,

    input [NUMS_MASTER - 1:0] master_valid,
    input [NUMS_MASTER * `DATA_BITS - 1:0] master_data,
    output logic [NUMS_MASTER - 1:0] master_ready,

    output logic slave_valid,
    input slave_ready,
    output logic [`DATA_BITS - 1:0] slave_data,

    // Config
    input set_id,
    input [ID_SIZE - 1:0] ID_scan_in,
    output logic [ID_SIZE - 1:0] ID_scan_out
);
integer i;
genvar i_mc;
logic [ID_SIZE * (NUMS_MASTER + 1) - 1:0] MC_id_chain;
logic [NUMS_MASTER - 1:0] pe_valid;
logic [2:0] output_data_index;
generate
    for (i_mc = 0; i_mc < NUMS_MASTER; i_mc = i_mc + 1) begin: MC_dachi
        GON_MulticastController #ID_SIZE MC(
            .clk(clk),
            .rst_n(rst_n),
            .set_id(set_id),
            .id_in(MC_id_chain[ID_SIZE * i_mc +: ID_SIZE]),  
            .id(MC_id_chain[ID_SIZE * (i_mc + 1) +: ID_SIZE]),
            .tag(tag),
            // form bus
            .ready_in(slave_ready),
            .valid_out(pe_valid[i_mc]),
            // to PE 
            .valid_in(master_valid[i_mc]),
            .ready_out(master_ready[i_mc])
        );
    end
endgenerate

always_comb begin   
    case ({{(8 - NUMS_MASTER){1'b0}}, pe_valid})
        8'b0000_0001: output_data_index = 3'd0;
        8'b0000_0010: output_data_index = 3'd1;
        8'b0000_0100: output_data_index = 3'd2;
        8'b0000_1000: output_data_index = 3'd3;
        8'b0001_0000: output_data_index = 3'd4;
        8'b0010_0000: output_data_index = 3'd5;
        8'b0100_0000: output_data_index = 3'd6;
        8'b1000_0000: output_data_index = 3'd7;
        default: output_data_index = 3'd0;
    endcase
end
always_comb begin
    slave_valid = |pe_valid;
    MC_id_chain[ID_SIZE-1:0] = ID_scan_in;
    ID_scan_out = MC_id_chain[ID_SIZE * NUMS_MASTER +: ID_SIZE];
    
    slave_data = master_data[
        `DATA_BITS * {
            28'b0, ({1'b0, output_data_index} + 4'd1)
        } - 1 -: `DATA_BITS
    ];
end

endmodule
