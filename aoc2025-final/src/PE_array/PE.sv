`include "define.svh"
module PE #(
    parameter idle = 0,
    parameter read_filter = 1,
    parameter read_ifmap = 2,
    parameter read_ipsum = 3,
    parameter calculation = 4,
    parameter write_opsum = 5
)(
    input clk,
    input rst,
    input PE_en,
    input [`CONFIG_SIZE-1:0] i_config,
    input [`DATA_BITS-1:0] ifmap,
    input [`DATA_BITS-1:0] filter,
    input [`DATA_BITS-1:0] ipsum,
    input ifmap_valid,
    input filter_valid,
    input ipsum_valid,
    input opsum_ready,
    output logic [`DATA_BITS-1:0] opsum,
    output logic ifmap_ready,
    output logic filter_ready,
    output logic ipsum_ready,
    output logic opsum_valid
);
// spad 
logic [`DATA_BITS-1:0] ifmap_spad [2:0];
logic [`DATA_BITS-1:0] filter_spad [11:0];
logic [31:0] psum_spad [3:0];

// config
logic [1:0] p_config, q_config;
logic [4:0] F_config;

// state
logic [2:0] cs, ns;

// counter
logic [1:0] p_ct, q_ct, col_ct;
logic [4:0] F_ct;

// output signal
assign ifmap_ready = (cs == read_ifmap)? 1 : 0;
assign filter_ready = (cs == read_filter)? 1 : 0;
assign ipsum_ready = (cs == read_ipsum)? 1 : 0;
assign opsum_valid = (cs == write_opsum)? 1 : 0;
assign opsum = psum_spad[p_ct];

// multiply
logic signed [31:0] multi_result;
always_comb begin
    case(q_ct)
    2'd0: multi_result = $signed(ifmap_spad[col_ct][7:0])   * $signed(filter_spad[p_ct * 3 + col_ct][7:0]);
    2'd1: multi_result = $signed(ifmap_spad[col_ct][15:8])  * $signed(filter_spad[p_ct * 3 + col_ct][15:8]);
    2'd2: multi_result = $signed(ifmap_spad[col_ct][23:16]) * $signed(filter_spad[p_ct * 3 + col_ct][23:16]);
    2'd3: multi_result = $signed(ifmap_spad[col_ct][31:24]) * $signed(filter_spad[p_ct * 3 + col_ct][31:24]);
    endcase
end

always_ff @(posedge clk or posedge rst) begin
    if(rst) begin
        p_config    <= 0;
        q_config    <= 0;
        F_config    <= 0;
        cs          <= idle;
        p_ct        <= 0;
        col_ct      <= 0;
        F_ct        <= 0;
        q_ct        <= 0;
        psum_spad[0]<= 0;
        psum_spad[1]<= 0;
        psum_spad[2]<= 0;
        psum_spad[3]<= 0;
    end
    else begin
        cs <= ns;
        case (cs)
        idle: begin
            psum_spad[0]<= 0;
            psum_spad[1]<= 0;
            psum_spad[2]<= 0;
            psum_spad[3]<= 0;
            col_ct      <= 0;
            if(PE_en) begin
                p_config        <= i_config[8:7];
                F_config        <= i_config[6:2];
                q_config        <= i_config[1:0];
            end
            else begin

            end
        end
        read_filter: begin
            if(filter_valid) begin
                filter_spad[p_ct * 3 + col_ct]  <= filter;
                col_ct          <= (col_ct == 2)? 0 : col_ct + 1;
                p_ct            <= (col_ct == 2)? ((p_ct == p_config)? 0 : p_ct + 1) : p_ct;
            end
            else begin
                filter_spad[p_ct * 3 + col_ct]  <= filter_spad[p_ct * 3 + col_ct];
                col_ct          <= col_ct;
                p_ct            <= p_ct;
            end
        end
        read_ifmap: begin
            psum_spad[0]        <= 0;
            psum_spad[1]        <= 0;
            psum_spad[2]        <= 0;
            psum_spad[3]        <= 0;
            if(ifmap_valid) begin
                ifmap_spad[0]   <= ifmap_spad[1];
                ifmap_spad[1]   <= ifmap_spad[2];
                ifmap_spad[2]   <= ifmap ^ 32'h80808080;
                col_ct          <= (col_ct == 2)? 0 : col_ct + 1;
            end
            else begin
                ifmap_spad[0]   <= ifmap_spad[0];
                ifmap_spad[1]   <= ifmap_spad[1];
                ifmap_spad[2]   <= ifmap_spad[2];
                col_ct          <= col_ct;
            end
        end
        calculation: begin
            psum_spad[p_ct] <= multi_result + psum_spad[p_ct];
            q_ct            <= (q_ct == q_config)? 0 : q_ct + 1;
            col_ct          <= (q_ct == q_config)? ((col_ct == 2)? 0 : col_ct + 1) : col_ct;
            p_ct            <= (col_ct == 2 && q_ct == q_config)? p_ct + 1 : p_ct;
        end
        read_ipsum: begin
            if(ipsum_valid) begin
                psum_spad[p_ct] <= ipsum + psum_spad[p_ct];
                p_ct            <= (p_ct == p_config)? 0 : p_ct + 1;
            end
            else begin
                psum_spad[p_ct] <= psum_spad[p_ct];
                p_ct            <= p_ct;
            end
        end
        write_opsum: begin
            p_ct            <= (opsum_ready)? ((p_ct == p_config)? 0 : p_ct + 1) : p_ct;
            F_ct            <= (opsum_ready)? ((p_ct == p_config)? F_ct + 1 : F_ct) : F_ct;
            col_ct          <= 2;
        end
        endcase
    end
end

always_comb begin
    case (cs)
    idle: begin
        ns = (PE_en)? read_filter : idle;
    end
    read_filter: begin
        ns = (filter_valid && p_ct == p_config && col_ct == 2)? read_ifmap : read_filter;
    end
    read_ifmap: begin
        ns = (ifmap_valid && col_ct == 2)? calculation : read_ifmap;
    end
    calculation: begin
        ns = (col_ct == 2 && q_ct == q_config && p_ct == p_config)? read_ipsum : calculation;
    end
    read_ipsum: begin
        ns = (ipsum_valid && p_ct == p_config)? write_opsum : read_ipsum;
    end
    write_opsum: begin
        ns = (opsum_ready)? (
                (p_ct == p_config)? (
                    (F_ct == F_config)? idle : read_ifmap
                ) : write_opsum
            ) : write_opsum;
    end
    endcase    
end

endmodule
