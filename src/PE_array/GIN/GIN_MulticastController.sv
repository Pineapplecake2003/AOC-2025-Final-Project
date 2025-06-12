/* verilator lint_off MULTITOP */
`include "define.svh"

module GIN_MulticastController #(
  parameter ID_SIZE = `XID_BITS
  )(
  input clk,
  input rst_n,

  input set_id,
  input [ID_SIZE - 1:0] id_in,
  output reg [ID_SIZE - 1:0] id,

  input [ID_SIZE - 1:0] tag,

  // form bus 
  input ready_in,
  output logic valid_out,
  
  // to PE 
  input valid_in,
  output logic ready_out
);

// id_config
always @(posedge clk or negedge rst_n) begin
	if(!rst_n)begin
		id <= {ID_SIZE{1'b0}};
	end
	else if (set_id)begin
		id <= id_in;
	end
	else begin
		id <= id;
	end
end

// AXI output
always_comb begin
  if(tag == id)begin
    valid_out = valid_in;
    ready_out = ready_in;
  end
  else begin
    valid_out = 1'b0;
    ready_out = 1'b0;
  end
end
endmodule
