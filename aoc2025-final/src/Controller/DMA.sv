module DMA #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input  logic                  clk,
    input  logic                  rst,

    /* controller <-> dma interface */
    input  logic                  start,            // start signal
    input  logic [ADDR_WIDTH-1:0] src_addr,         // source addr
    input  logic [ADDR_WIDTH-1:0] dst_addr,         // target addr
    input  logic [15:0]           length,           // data length
    output logic                  done,

    /* dma <-> hal (dram) interface */
    output logic                  notify_host,      // call dma support
    output logic [ADDR_WIDTH-1:0] mem_read_addr,
    input  logic [DATA_WIDTH-1:0] mem_read_data,
    output logic [15:0]           mem_length,

    /* dma <-> glb interface */
    output logic [ADDR_WIDTH-1:0] mem_write_addr,
    output logic                  mem_write_en,
    output logic [DATA_WIDTH-1:0] mem_write_data
);

    typedef enum logic [2:0] {
        IDLE,
        NOTIFY,
        READ,
        WRITE,
        DONE
    } state_t;

    state_t cs, ns;

    logic [15:0] counter, len;
    logic [ADDR_WIDTH-1:0] read_ptr, write_ptr;

    assign notify_host = (cs == NOTIFY)? 1 : 0;
    assign done = (cs == DONE)? 1 : 0;
    assign mem_length = len;

    assign mem_write_en = (cs == WRITE)? 1 : 0;
    assign mem_write_addr = write_ptr;
    assign mem_read_addr = read_ptr;
    assign mem_write_data = mem_read_data;

    // state change
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            cs              <= IDLE;
            counter         <= 0;
            read_ptr        <= 0;
            write_ptr       <= 0;
            len             <= 0;
        end 
        else begin
            cs <= ns;
            case (cs)
                IDLE: begin
                    counter         <= 0;
                    read_ptr        <= src_addr;
                    write_ptr       <= dst_addr;
                    len             <= length;
                end
                WRITE: begin
                    counter         <= counter + 1;
                    read_ptr        <= read_ptr + 4;
                    write_ptr       <= write_ptr + 4;
                end
                default: begin
                    counter         <= counter;
                    read_ptr        <= read_ptr;
                    write_ptr       <= write_ptr;
                    len             <= len;
                end
            endcase
        end
    end

    // next state logic
    always_comb begin
        case (cs)
            IDLE:       ns = (start)? NOTIFY : IDLE;
            NOTIFY:     ns = READ;
            READ:       ns = WRITE;
            WRITE:      ns = (counter == len - 1)? DONE : READ;
            DONE:       ns = IDLE;
            default:    ns = IDLE;
        endcase
    end

endmodule
