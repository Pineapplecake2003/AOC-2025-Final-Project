`include "define.svh"
module Controller #(
    parameter NUMS_PE_ROW = `NUMS_PE_ROW,
    parameter NUMS_PE_COL = `NUMS_PE_COL,
    parameter XID_BITS    = `XID_BITS,
    parameter YID_BITS    = `YID_BITS,
    parameter DATA_SIZE   = `DATA_BITS,
    parameter CONFIG_SIZE = `CONFIG_SIZE,
    parameter MMIO_ADDR   = `MMIO_ADDR
)(
    input clk,
    input rst,

    /* MMIO interface */
    input we,
    input w_addr,
    input w_data,
    input r_addr,
    output r_data,

    /* DMA interface */
    output logic                  dma_start,
    output logic [ADDR_WIDTH-1:0] src_addr,
    output logic [ADDR_WIDTH-1:0] dst_addr,
    output logic [15:0]           length,  
    input dma_done,

    /* PE array interface */
    // Scan Chain
    output set_XID,
    output [XID_BITS-1:0] ifmap_XID_scan_in,
    output [XID_BITS-1:0] filter_XID_scan_in,
    output [XID_BITS-1:0] ipsum_XID_scan_in,
    output [XID_BITS-1:0] opsum_XID_scan_in,
    // input [XID_BITS-1:0] XID_scan_out,

    output set_YID,
    output [YID_BITS-1:0] ifmap_YID_scan_in,
    output [YID_BITS-1:0] filter_YID_scan_in,
    output [YID_BITS-1:0] ipsum_YID_scan_in,
    output [YID_BITS-1:0] opsum_YID_scan_in,
    // input [YID_BITS-1:0] YID_scan_out,

    output set_LN,
    output [NUMS_PE_ROW-2:0] LN_config_in,

    // tag controller
    output [NUMS_PE_ROW*NUMS_PE_COL-1:0] PE_en,
    output [CONFIG_SIZE-1:0] PE_config,
    output [XID_BITS-1:0] ifmap_tag_X,
    output [YID_BITS-1:0] ifmap_tag_Y,
    output [XID_BITS-1:0] filter_tag_X,
    output [YID_BITS-1:0] filter_tag_Y,
    output [XID_BITS-1:0] ipsum_tag_X,
    output [YID_BITS-1:0] ipsum_tag_Y,
    output [XID_BITS-1:0] opsum_tag_X,
    output [YID_BITS-1:0] opsum_tag_Y,

    // glb handshake signal
    output GLB_ifmap_valid,
    input GLB_ifmap_ready,
    output GLB_filter_valid,
    input GLB_filter_ready,
    output GLB_ipsum_valid,
    input GLB_ipsum_ready,
    output [DATA_SIZE-1:0] GLB_data_in,

    input GLB_opsum_valid,
    output GLB_opsum_ready,
    input [DATA_SIZE-1:0] GLB_data_out
);
    logic [XID_BITS-1:0] ifmap_XID  [NUMS_PE_ROW*NUMS_PE_COL-1:0];
    logic [XID_BITS-1:0] filter_XID [NUMS_PE_ROW*NUMS_PE_COL-1:0];
    logic [XID_BITS-1:0] ipsum_XID  [NUMS_PE_ROW*NUMS_PE_COL-1:0];
    logic [XID_BITS-1:0] opsum_XID  [NUMS_PE_ROW*NUMS_PE_COL-1:0];

    logic [YID_BITS-1:0] ifmap_YID  [NUMS_PE_ROW-1:0];
    logic [YID_BITS-1:0] filter_YID [NUMS_PE_ROW-1:0];
    logic [YID_BITS-1:0] ipsum_YID  [NUMS_PE_ROW-1:0];
    logic [YID_BITS-1:0] opsum_YID  [NUMS_PE_ROW-1:0];

    initial begin
        $readmemh("ifmap_XID.txt", ifmap_XID );
        $readmemh("filter_XID.txt", filter_XID);
        $readmemh("ipsum_XID.txt", ipsum_XID );
        $readmemh("opsum_XID.txt", opsum_XID );
        $readmemh("ifmap_YID.txt", ifmap_YID );
        $readmemh("filter_YID.txt", filter_YID);
        $readmemh("ipsum_YID.txt", ipsum_YID );
        $readmemh("opsum_YID.txt", opsum_YID );
    end

    logic [5:0] counter;
    logic [31:0] op_config, mapping_param, shape_param1, shape_param2;
    logic [31:0] ifmap_addr, filter_addr, ipsum_addr, opsum_addr;

    typedef enum logic [2:0] {
        IDLE,
        SET_CONFIG,
        CALL_DMA,
        LOAD_DATA,
        READ_FILTER,
        READ_IFMAP,
        READ_IPSUM,
        WRITE_OPSUM,
        DONE
    } state_t;

    state_t cs, ns;

    // output logic
    assign set_XID = (cs == SET_CONFIG)? 1 : 0;
    assign ifmap_XID_scan_in = ifmap_XID[counter];
    assign filter_XID_scan_in = filter_XID[counter];
    assign ipsum_XID_scan_in = ipsum_XID[counter];
    assign opsum_XID_scan_in = opsum_XID[counter];

    assign set_YID = (cs == SET_CONFIG)? ((counter < NUMS_PE_ROW)? 1 : 0) : 0;
    assign ifmap_YID_scan_in = ifmap_YID[counter];
    assign filter_YID_scan_in = filter_YID[counter];
    assign ipsum_YID_scan_in = ipsum_YID[counter];
    assign opsum_YID_scan_in = opsum_YID[counter];

    assign set_LN = (cs == SET_CONFIG)? ((counter == 0)? 1 : 0) : 0;

    // dma logic
    assign dma_start = (cs == CALL_DMA)? 1 : 0;


    //TODO
    //assign LN_config
    //MMIO_addr

    // fsm logic
    always_ff @(posedge clk or posedge rst) begin
        if(rst) begin
            cs              <= IDLE;
            counter         <= 0;
            op_config       <= 0;
            mapping_param   <= 0;
            shape_param1    <= 0;
            shape_param2    <= 0;
        end
        else begin
            cs <= ns;
            case(cs)
            IDLE: begin
                if(we) begin
                    case(w_addr)
                    MMIO_ADDR: begin
                        op_config       <= w_data;
                    end
                    MMIO_ADDR + 4: begin
                        mapping_param   <= w_data;
                    end
                    MMIO_ADDR + 8: begin
                        shape_param1    <= w_data;
                    end
                    MMIO_ADDR + 12: begin
                        shape_param2    <= w_data;
                    end
                    default: begin

                    end
                    endcase
                end
                counter <= 0;
            end
            SET_CONFIG: begin
                counter <= counter + 1;
            end
            CALL_DMA: begin
                dma_start   <= 1;
                src_addr    <= 
                counter     <= 0;
            end
            LOAD_DATA: begin
                if(!dma_done) begin
                    
                end
            end
            endcase
        end
    end

    // next state logic
    always_comb begin
        case(cs)
        IDLE: begin
            ns = (op_config[0])? SET_CONFIG : IDLE;
        end
        SET_CONFIG: begin
            ns = (counter == NUMS_PE_ROW*NUMS_PE_COL-1)? LOAD_DATA : SET_CONFIG;
        end
        CALL_DMA: begin
            ns = LOAD_DATA;
        end
        LOAD_DATA: begin
            ns = 
        end
        endcase
    end

    // read MMIO register
    always_comb begin
        if(!we) begin
            case(r_addr)
            MMIO_ADDR: begin
                r_data = op_config;
            end
            MMIO_ADDR + 4: begin
                r_data = mapping_param;
            end
            MMIO_ADDR + 8: begin
                r_data = shape_param1;
            end
            MMIO_ADDR + 12: begin
                r_data = shape_param2;
            end
            default: begin
                r_data = 0
            end
            endcase
        end
    end

endmodule
