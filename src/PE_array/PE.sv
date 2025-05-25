`include "./src/PE_array/Mutiplier_gating.sv"
`include "./include/define.svh"

module PE (
    input                              clk,
    input                              rst,

    input                              PE_en,
    input        [`CONFIG_SIZE-1:0]    i_config,
    input        [`DATA_BITS-1:0]      ifmap,
    input        [`DATA_BITS-1:0]      filter,
    input        [`DATA_BITS-1:0]      ipsum,

    input                              ifmap_valid,
    input                              filter_valid,
    input                              ipsum_valid,
    output logic                       opsum_valid,

    input                              opsum_ready,
    output logic [`DATA_BITS-1:0]      opsum,
    output logic                       ifmap_ready,
    output logic                       filter_ready,
    output logic                       ipsum_ready
);
    integer i;
    // i_config
    logic [`CONFIG_SIZE-1:0]    i_config_reg;
    logic                       mode;
    logic [2:0]                 p;    		// output channel
    logic [4:0]                 F;    		// output column
    logic [2:0]                 q;    		// input channel
    logic [1:0] 				filter_rs;
    logic 						depthwise;

    // split config
    always_comb begin
        depthwise = i_config_reg[12];
        filter_rs = i_config_reg[11:10] + 2'b1;
        mode      = i_config_reg[9];
        p         = {1'b0, i_config_reg[8:7]} + 3'b1;
        F         = i_config_reg[6:2];
        q         = {1'b0, i_config_reg[1:0]} + 3'b1;
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst)            i_config_reg <= `CONFIG_SIZE'b0;
        else if (PE_en)     i_config_reg <= i_config;
    end

    // SPAD declarations
    logic signed [`IFMAP_SIZE - 1:0]  ifmap_spad  [0:`IFMAP_SPAD_LEN - 1];
    logic signed [`FILTER_SIZE - 1:0] filter_spad [0:`FILTER_SPAD_LEN - 1];
    logic signed [`PSUM_SIZE - 1:0]   psum_spad   [0:`OFMAP_SPAD_LEN - 1];

    //spad counter
    logic [`IFMAP_INDEX_BIT - 1:0]  ifmap_spad_cnt;
    logic [`FILTER_INDEX_BIT - 1:0] filter_spad_cnt;
    logic [`OFMAP_INDEX_BIT - 1:0]  psum_spad_cnt;

    // conv counter
    logic [`IFMAP_INDEX_BIT - 1:0]  conv_ifmap_cnt;
    logic [`FILTER_INDEX_BIT - 1:0] conv_filter_cnt;
    logic [`OFMAP_INDEX_BIT - 1:0]  conv_result_cnt;

    // used for pop out ifmap element
    logic [3:0] shift;
    always_comb begin
        shift = (q >= 1 && q <= 4) ? {1'b0, q} : 4'd12;
    end

    //split filter & ifmap 
    logic [`FILTER_SIZE - 1:0] split_filter[0:3];
    logic [`IFMAP_SIZE - 1:0]  split_ifmap[0:3];

    always_comb begin
        {split_filter[3], split_filter[2], split_filter[1], split_filter[0]} = filter;
        {split_ifmap[3], split_ifmap[2], split_ifmap[1], split_ifmap[0]} = ifmap;
    end

    // Debug wires
    wire [7:0]  debug_wire1 = ifmap_spad  [conv_ifmap_cnt];
    wire [7:0]  debug_wire2 = filter_spad [conv_filter_cnt];
    wire [7:0]  debug_wire3 = split_ifmap [3];
    wire [7:0]  debug_wire4 = split_ifmap [3]^128;
    wire [31:0] debug_wire5 = filter_spad [conv_filter_cnt] * ifmap_spad[conv_ifmap_cnt];
    wire        debug_wire6 = skip_mul_filter[conv_filter_cnt] || skip_mul_ifmap[conv_ifmap_cnt];

    // FSM state definitions
    typedef enum logic [2:0] {
        IDLE        = 3'd0,
        READ_FILTER = 3'd1,
        READ_IFMAP  = 3'd2,
        READ_IPSUM  = 3'd3,
        CONV        = 3'd4,
        WRITE_OPSUM = 3'd5
    } state_t;

    state_t state;
    state_t next_state;

    // skip_mul logic
    logic [`FILTER_SPAD_LEN - 1 : 0] skip_mul_filter;
    logic [`IFMAP_SPAD_LEN - 1 : 0]  skip_mul_ifmap;
    logic [`PSUM_SIZE - 1:0]  skip_mul_result;

    Mutiplier_gating mutiplier0(
        .clk(clk),
        .en(skip_mul_filter[conv_filter_cnt] || skip_mul_ifmap[conv_ifmap_cnt]),
        .a(filter_spad[conv_filter_cnt]),
        .b(ifmap_spad[conv_ifmap_cnt]),
        .result(skip_mul_result)
    );

    // counters logic
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            ifmap_spad_cnt  <= '0;
            filter_spad_cnt <= '0;
            psum_spad_cnt   <= '0;

            conv_ifmap_cnt  <= '0;
            conv_filter_cnt <= '0;
            conv_result_cnt <= '0;

            skip_mul_filter <= '0;
            skip_mul_ifmap  <= '0;
            
            for (i = 0; i < `IFMAP_SPAD_LEN;  i++)  ifmap_spad[i]  <= '0;
            for (i = 0; i < `FILTER_SPAD_LEN; i++)  filter_spad[i] <= '0;
            for (i = 0; i < `OFMAP_SPAD_LEN;  i++)  psum_spad[i]   <= '0;
        end else begin
            case (state)
                READ_FILTER: begin
                    if (filter_valid) begin
                        for (i = 0; i < 4; i++) begin
                            filter_spad[filter_spad_cnt + i[`FILTER_INDEX_BIT-1:0]] <= split_filter[i];
                            // TODO: Gate inactive
                            skip_mul_filter[filter_spad_cnt + i[`FILTER_INDEX_BIT-1:0]] <= split_filter[i] == '0 ? 1'b1 : 1'b0;
                        end
                        filter_spad_cnt <= filter_spad_cnt + {3'b0, q};
                    end
                end
                READ_IFMAP: begin
                    if (ifmap_valid) begin
                        for (i = 0; i < 4; i++) begin
                            ifmap_spad[ifmap_spad_cnt + i[`IFMAP_INDEX_BIT-1:0]] <= (split_ifmap[i] ^ `IFMAP_SIZE'd128);
                            // TODO: Gate inactive
                            skip_mul_ifmap[ifmap_spad_cnt + i[`IFMAP_INDEX_BIT-1:0]] <= split_ifmap[i] == `IFMAP_SIZE'd128 ? 1'b1 : 1'b0;
                        end
                        ifmap_spad_cnt <= ifmap_spad_cnt + {1'b0, q};
                    end
                end
                READ_IPSUM: begin
                    if (ipsum_valid) begin
                        psum_spad[psum_spad_cnt] <= ipsum;
                        psum_spad_cnt <= psum_spad_cnt + `OFMAP_INDEX_BIT'b1;
                    end
                end
                CONV: begin
                    // TODO: Gate inactive
                    psum_spad[conv_result_cnt] <= (skip_mul_filter[conv_filter_cnt] || skip_mul_ifmap[conv_ifmap_cnt]) ? 
                        psum_spad[conv_result_cnt] : psum_spad[conv_result_cnt] + skip_mul_result;
                    conv_filter_cnt <= conv_filter_cnt + `FILTER_INDEX_BIT'b1;
                    if (depthwise) begin
                        /**
                        * assume q=3
                        * time ----------------------->
                        * filter cnt 0 1 2 3 4 5 6 7 8
                        * ifmap cnt  0 1 2 3 4 5 6 7 8
                        * psum cnt   0 1 2 0 1 2 0 1 2
                        */
                        conv_ifmap_cnt <= conv_ifmap_cnt + `IFMAP_INDEX_BIT'b1;
                        if (conv_result_cnt == q[1:0]-2'b1)
                            // to depthwise ipsum limit(`q` channel)
                            conv_result_cnt <= `OFMAP_INDEX_BIT'b0;
                        else
                            conv_result_cnt <= conv_result_cnt + `OFMAP_INDEX_BIT'b1;
                    end else begin
                        /**
                        * assume q=3
                        * 				filer_num = 0				filer_num = 1
                        * filter cnt  0  1  2  3  4  5  6  7  8 | 9 10 11 12 13 14 15 16 17
                        * ifmap cnt   0  1  2  3  4  5  6  7  8 | 0  1  2  3  4  5  6  7  8
                        * psum cnt    0  0  0  0  0  0  0  0  0 | 1  1  1  1  1  1  1  1  1 
                        * time ------------------------------------------------------------>
                        */
                        if (conv_ifmap_cnt == ifmap_spad_cnt - `IFMAP_INDEX_BIT'b1) begin
                            conv_ifmap_cnt <= 'b0;
                            conv_result_cnt <= conv_result_cnt + `OFMAP_INDEX_BIT'b1;
                        end else begin
                            conv_ifmap_cnt <= conv_ifmap_cnt + `IFMAP_INDEX_BIT'b1;
                        end
                    end
                end
                WRITE_OPSUM: begin
                    conv_result_cnt <= (opsum_ready) ? conv_result_cnt + `OFMAP_INDEX_BIT'b1 : conv_result_cnt;
                    if (next_state == READ_IFMAP) begin
                        //reset conv cnt
                        conv_result_cnt <= 'b0;
                        conv_ifmap_cnt  <= 'b0;
                        conv_filter_cnt <= 'b0;
                        //reset psum_cnt
                        psum_spad_cnt   <= 'b0;
                        // ifmap pointer decrease by q
                        ifmap_spad_cnt <= ifmap_spad_cnt - {1'b0, q};
                        // pop out the oldest ifmap
                        // TODO stride == 2
                        for (i = 0; i < 12; i++) begin
                            ifmap_spad[i] <= (i[2:0] + shift < 12) ? ifmap_spad[i[2:0] + shift] : 'b0;
                            // TODO: Gate inactive
                            skip_mul_ifmap[i] <= (i[2:0] + shift < 12) ? skip_mul_ifmap[i[2:0] + shift] : 'b0;
                        end
                    end
                end
                default: begin
                    ifmap_spad_cnt  <= '0;
                    filter_spad_cnt <= '0;
                    psum_spad_cnt   <= '0;

                    conv_ifmap_cnt  <= '0;
                    conv_filter_cnt <= '0;
                    conv_result_cnt <= '0;
                    
                    for (i = 0; i < `IFMAP_SPAD_LEN; i++)   ifmap_spad[i]  <= '0;
                    for (i = 0; i < `FILTER_SPAD_LEN; i++)  filter_spad[i] <= '0;
                    for (i = 0; i < `OFMAP_SPAD_LEN; i++)   psum_spad[i]   <= '0;
                end
            endcase
        end
    end

    always_ff @(posedge clk or posedge rst) begin
        state <= rst ? IDLE : next_state;
    end

    always_comb begin
        case (state)
            IDLE:
                next_state = PE_en ? READ_FILTER : IDLE;
            READ_FILTER:
                next_state = {26'b0, filter_spad_cnt} == (p * q * filter_rs) ? READ_IFMAP : READ_FILTER;
            READ_IFMAP:
                next_state = {28'b0, ifmap_spad_cnt} == ({29'b0, q} * filter_rs) ? READ_IPSUM : READ_IFMAP;
            READ_IPSUM: begin
                if (depthwise)
                    next_state = ({1'b0, psum_spad_cnt} == (q - 3'b1)) && ipsum_valid ? CONV : READ_IPSUM;
                else
                    next_state = ({1'b0, psum_spad_cnt} == (p - 3'b1)) && ipsum_valid ? CONV : READ_IPSUM;
            end
            CONV: begin
                if (depthwise)
                    next_state = {1'b0,conv_result_cnt} == (q-1) && conv_ifmap_cnt == ((filter_rs * q) -1) ? WRITE_OPSUM : CONV;
                else
                    next_state = conv_filter_cnt == filter_spad_cnt - `FILTER_INDEX_BIT'b1 ? WRITE_OPSUM : CONV;
            end
            WRITE_OPSUM: begin
                if (depthwise)
                    next_state = ({1'b0, conv_result_cnt} == (q - 3'b1)) && opsum_ready ? (output_col_cnt == F ? IDLE : READ_IFMAP) : WRITE_OPSUM;
                else
                    next_state = ({1'b0, conv_result_cnt} == (p - 3'b1)) && opsum_ready ? (output_col_cnt == F ? IDLE : READ_IFMAP) : WRITE_OPSUM;
            end
            default: next_state = IDLE;
        endcase
    end

    // check dont yet
    logic [4:0] output_col_cnt;
    always_ff @(posedge clk or posedge rst) begin
        if(rst)
            output_col_cnt <= 5'b0;
        else if(state == WRITE_OPSUM && next_state == READ_IFMAP)
            output_col_cnt <= output_col_cnt + 5'b1;
    end

    always_comb begin
        // output opsum
        opsum = psum_spad[conv_result_cnt];
        // AXI signal
        filter_ready = (state == READ_FILTER) ? 1'b1 : 1'b0;
        ifmap_ready  = (state == READ_IFMAP)  ? 1'b1 : 1'b0;
        ipsum_ready  = (state == READ_IPSUM)  ? 1'b1 : 1'b0;
        opsum_valid  = (state == WRITE_OPSUM) ? 1'b1 : 1'b0;
    end
endmodule