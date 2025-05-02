`include "src/PE_array/PE.sv"
`include "src/PE_array/GIN/GIN.sv"
`include "src/PE_array/GON/GON.sv"
`include "define.svh"

module PE_array #(
  parameter NUMS_PE_ROW = `NUMS_PE_ROW,
  parameter NUMS_PE_COL = `NUMS_PE_COL,
  parameter XID_BITS = `XID_BITS,
  parameter YID_BITS = `YID_BITS,
  parameter DATA_SIZE = `DATA_BITS,
  parameter CONFIG_SIZE = `CONFIG_SIZE
)(
  input clk,
  input rst,

  /* Scan Chain */
  input set_XID,
  input [`XID_BITS-1:0] ifmap_XID_scan_in,
  input [`XID_BITS-1:0] filter_XID_scan_in,
  input [`XID_BITS-1:0] ipsum_XID_scan_in,
  input [`XID_BITS-1:0] opsum_XID_scan_in,
  // output [XID_BITS-1:0] XID_scan_out,

  input set_YID,
  input [`YID_BITS-1:0] ifmap_YID_scan_in,
  input [`YID_BITS-1:0] filter_YID_scan_in,
  input [`YID_BITS-1:0] ipsum_YID_scan_in,
  input [`YID_BITS-1:0] opsum_YID_scan_in,
  // output logic [YID_BITS-1:0] YID_scan_out,

  input set_LN,
  input [`NUMS_PE_ROW-2:0] LN_config_in,

  /* Controller */
  input [`NUMS_PE_ROW*`NUMS_PE_COL-1:0] PE_en,
  input [`CONFIG_SIZE-1:0] PE_config,
  input [`XID_BITS-1:0] ifmap_tag_X,
  input [`YID_BITS-1:0] ifmap_tag_Y,
  input [`XID_BITS-1:0] filter_tag_X,
  input [`YID_BITS-1:0] filter_tag_Y,
  input [`XID_BITS-1:0] ipsum_tag_X,
  input [`YID_BITS-1:0] ipsum_tag_Y,
  input [`XID_BITS-1:0] opsum_tag_X,
  input [`YID_BITS-1:0] opsum_tag_Y,

  /* GLB */
  input GLB_ifmap_valid,
  output logic GLB_ifmap_ready,
  input GLB_filter_valid,
  output logic GLB_filter_ready,
  input GLB_ipsum_valid,
  output logic GLB_ipsum_ready,
  input [DATA_SIZE-1:0] GLB_data_in,

  output logic GLB_opsum_valid,
  input GLB_opsum_ready,
  output logic [DATA_SIZE-1:0] GLB_data_out
);

// LN_config
logic [`NUMS_PE_ROW-2:0] LN_config;
always @(posedge clk or posedge rst) begin
  if(rst)begin
		LN_config <= {(`NUMS_PE_ROW-1){1'b0}};
	end
	else if (set_LN)begin
		LN_config <= LN_config_in;
	end
	else begin
		LN_config <= LN_config;
	end
end

// PEs
logic [DATA_SIZE - 1:0] to_PE_filter;
logic [DATA_SIZE - 1:0] to_PE_ifmap;
logic [DATA_SIZE - 1:0] to_PE_ispum[NUMS_PE_COL * NUMS_PE_ROW - 1 :0];
logic [DATA_SIZE * NUMS_PE_COL * NUMS_PE_ROW - 1:0] out_PE_ospum;

logic [NUMS_PE_COL * NUMS_PE_ROW - 1 :0] filter_ready;
logic [NUMS_PE_COL * NUMS_PE_ROW - 1 :0] ifmap_ready;
logic [NUMS_PE_COL * NUMS_PE_ROW - 1 :0] ipsum_ready;
logic [NUMS_PE_COL * NUMS_PE_ROW - 1 :0] opsum_ready;

logic [NUMS_PE_COL * NUMS_PE_ROW - 1 :0] filter_valid;
logic [NUMS_PE_COL * NUMS_PE_ROW - 1 :0] ifmap_valid;
logic [NUMS_PE_COL * NUMS_PE_ROW - 1 :0] ipsum_valid;
logic [NUMS_PE_COL * NUMS_PE_ROW - 1 :0] opsum_valid;
genvar i_pe;
generate
  for (i_pe = 0;i_pe < NUMS_PE_COL * NUMS_PE_ROW ;i_pe=i_pe+1 ) begin: PE_dachi
    PE pe(
      .clk(clk),
      .rst(rst),
      .PE_en(PE_en[i_pe]),
      .i_config(PE_config),

      .ifmap(to_PE_ifmap),
      .filter(to_PE_filter),
      .ipsum(to_PE_ispum[i_pe]),
			.opsum(out_PE_ospum[DATA_SIZE * i_pe +: DATA_SIZE]),

      .ifmap_valid(ifmap_valid[i_pe]),
      .filter_valid(filter_valid[i_pe]),
      .ipsum_valid(ipsum_valid[i_pe]),
      .opsum_valid(opsum_valid[i_pe]),
      
      .ifmap_ready(ifmap_ready[i_pe]),
      .filter_ready(filter_ready[i_pe]),
      .ipsum_ready(ipsum_ready[i_pe]),
			.opsum_ready(opsum_ready[i_pe])
    );
  end
endgenerate


// GINs

// filter
GIN gin_filter(
  .clk(clk),
  .rst(rst),

  .GIN_valid(GLB_filter_valid),
  .GIN_ready(GLB_filter_ready),
  .GIN_data(GLB_data_in),

  .tag_X(filter_tag_X),
  .tag_Y(filter_tag_Y),

  .set_XID(set_XID),
  .XID_scan_in(filter_XID_scan_in),
  .set_YID(set_YID),
  .YID_scan_in(filter_YID_scan_in),

  .PE_ready(filter_ready),
  .PE_valid(filter_valid),
  .PE_data(to_PE_filter)
);

// ifmap
GIN gin_ifmap(
  .clk(clk),
  .rst(rst),

  .GIN_valid(GLB_ifmap_valid),
  .GIN_ready(GLB_ifmap_ready),
  .GIN_data(GLB_data_in),

  .tag_X(ifmap_tag_X),
  .tag_Y(ifmap_tag_Y),

  .set_XID(set_XID),
  .XID_scan_in(ifmap_XID_scan_in),
  .set_YID(set_YID),
  .YID_scan_in(ifmap_YID_scan_in),

  .PE_ready(ifmap_ready),
  .PE_valid(ifmap_valid),
  .PE_data(to_PE_ifmap)
);

// ipsum
logic [DATA_SIZE - 1: 0] out_GIN_ipsum;
logic [NUMS_PE_COL * NUMS_PE_ROW - 1: 0] out_GIN_ipsum_valid;
GIN gin_ipsum(
  .clk(clk),
  .rst(rst),

  .GIN_valid(GLB_ipsum_valid),
  .GIN_ready(GLB_ipsum_ready),
  .GIN_data(GLB_data_in),

  .tag_X(ipsum_tag_X),
  .tag_Y(ipsum_tag_Y),

  .set_XID(set_XID),
  .XID_scan_in(ipsum_XID_scan_in),
  .set_YID(set_YID),
  .YID_scan_in(ipsum_YID_scan_in),

  .PE_ready(ipsum_ready),
  .PE_valid(out_GIN_ipsum_valid),
  .PE_data(out_GIN_ipsum)
);
integer i;
always @(*) begin
	for (i = 0;i < NUMS_PE_COL * NUMS_PE_ROW ;i=i+1 ) begin
		if(i >= NUMS_PE_COL * NUMS_PE_ROW - NUMS_PE_COL) begin
			ipsum_valid[i] = out_GIN_ipsum_valid[i];
			to_PE_ispum[i] = out_GIN_ipsum;
		end
		else begin
			ipsum_valid[i]  = (LN_config[(i >> 3)])? 
        opsum_valid[i + 8] : 
        out_GIN_ipsum_valid[i];
			to_PE_ispum[i] = (LN_config[(i >> 3)])? 
        out_PE_ospum[DATA_SIZE * (i + 8) +: DATA_SIZE] : 
        out_GIN_ipsum;
		end
	end
end

// GON
logic [NUMS_PE_COL * NUMS_PE_ROW - 1: 0] out_GON_ready;
GON gon_opsum(
  .clk(clk),
  .rst(rst),
	
  .GON_valid(GLB_opsum_valid),
  .GON_ready(GLB_opsum_ready),
  .GON_data(GLB_data_out),

  .tag_X(opsum_tag_X),
  .tag_Y(opsum_tag_Y),

  .set_XID(set_XID),
  .XID_scan_in(opsum_XID_scan_in),
  .set_YID(set_YID),
  .YID_scan_in(opsum_YID_scan_in),

  .PE_ready(out_GON_ready),
  .PE_valid(opsum_valid),
  .PE_data(out_PE_ospum)
);

always @(*) begin
  for (i = 0; i < NUMS_PE_COL * NUMS_PE_ROW; i = i + 1) begin
      if(i < NUMS_PE_COL) begin
          opsum_ready[i] = out_GON_ready[i];
      end
      else begin
          opsum_ready[i] = (LN_config[(i >> 3) - 1])? 
            ipsum_ready[i - 8] : 
            out_GON_ready[i];
      end
  end
end
endmodule