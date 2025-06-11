`timescale 1ns/1ps

module multi_id_generator (
    input clk,
    input rst_n,
    input start,
    input [2:0] PE_ARRAY_H,
    input [3:0] PE_ARRAY_W,
    input [1:0] KERNEL_H,
    input [2:0] p,
    input [2:0] q,
    input [2:0] r,
    input [2:0] t,
    input [2:0] e,
    input [2:0] t_H,
    input [2:0] t_W,
    input LINEAR,
    // Filter IDs
    output reg [4:0] filter_XID [0:47],
    output reg [2:0] filter_YID [0:47],
    // ifmap IDs
    output reg [4:0] ifmap_XID [0:47],
    output reg [2:0] ifmap_YID [0:47],
    // ipsum IDs
    output reg [4:0] ipsum_XID [0:47],
    output reg [2:0] ipsum_YID [0:47],
    // opsum IDs
    output reg [4:0] opsum_XID [0:47],
    output reg [2:0] opsum_YID [0:47],
    output reg x_done,
    output reg y_done
);

reg start_d;

reg [2:0] row_cnt_XID; 
reg [3:0] col_cnt_XID;
reg [2:0] row_cnt_YID;
reg [3:0] first_col_idx;
// 狀態機定義
localparam IDLE    = 1'b0;
localparam GEN_IDS = 1'b1;
reg state, next_state;

always@(*) begin
    case(state)
        IDLE: begin
            if(start)
                next_state = GEN_IDS;
            else
                next_state = IDLE;
        end
        GEN_IDS: begin
            if(row_cnt_XID == PE_ARRAY_H)
                next_state = IDLE;
            else
                next_state = GEN_IDS;
        end
        default: next_state = IDLE;
    endcase
end

always@(posedge clk or negedge rst_n) begin
    if (!rst_n)
        state <= IDLE;
    else
        state <= next_state;
end

// row_block
assign row_block = PE_ARRAY_H / (r * t_H);

//------------------------------
// 主狀態機控制
//------------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        {row_cnt_XID, col_cnt_XID} <= 16'h0;
        {filter_XID, filter_YID, ifmap_XID, ifmap_YID} <= 16'h0;
        {ipsum_XID, ipsum_YID, opsum_XID, opsum_YID} <= 16'h0;
        {x_done, y_done} <= 2'b0;
        first_col_idx <= 4'b0;
        row_cnt_YID <= 3'b0;
        start_d <= 1'b0;
    end else begin
        start_d <= start;
        
        case (state)
            IDLE : begin
                if (start) begin
                    {x_done, y_done} <= 2'b0;
                    row_cnt_XID <= 8'h0;
                    col_cnt_XID <= 8'h0;
                    // 初始化狀態變數
                    filter_XID <= 5'h0;
                    filter_YID <= 3'h0;
                    first_col_idx <= 5'h0;
                    ifmap_XID <= 5'h0;
                    ifmap_YID <= 3'h0;
                    ipsum_XID <= 5'h0;
                    ipsum_YID <= 3'h0;
                    opsum_XID <= 5'h0;
                    opsum_YID <= 3'h0;
                end
            end

            GEN_IDS : begin
                // if(~start_d) begin
                    if (row_cnt_XID < PE_ARRAY_H) begin
                        if (col_cnt_XID < PE_ARRAY_W) begin
                            // Filter XID 生成
                            if (!LINEAR) begin
                                if (col_cnt_XID % e == 0 && col_cnt_XID >= e) begin
                                    filter_XID <= filter_XID + KERNEL_H;
                                end
                                // filter_XID <= c_filter_XID;
                            end else begin
                                if (col_cnt_XID < t) begin
                                    filter_XID <= filter_XID + 1;
                                end else begin
                                    filter_XID <= 5'h1F; // 31
                                end
                            end



                            // ifmap XID 生成
                            if (!LINEAR) begin
                                if (col_cnt_XID % e == 0 && col_cnt_XID >= e) begin
                                    ifmap_XID <= first_col_idx;
                                end else if (col_cnt_XID != 0) begin
                                    ifmap_XID <= ifmap_XID + 1;
                                end
                                // ifmap_XID <= c_ifmap_XID;
                            end else begin
                                if (col_cnt_XID < t) begin
                                    ifmap_XID <= 5'h0;
                                end else begin
                                    ifmap_XID <= 5'h1F; // 31
                                end
                            end



                            // ipsum XID 生成
                            if (!LINEAR) begin
                                if ((r==1 && row_cnt_XID==0) || (r==1 && row_cnt_XID==3) || (r==2 && row_cnt_XID==0)) begin
                                    // ipsum_XID <= c_ipsum_XID;
                                    ipsum_XID <= ipsum_XID + 1;
                                end else begin
                                    ipsum_XID <= 5'h1F; // 31
                                end
                            end else begin
                                if (row_cnt_XID==0 && col_cnt_XID < t) begin
                                    // ipsum_XID <= c_ipsum_XID;
                                    ipsum_XID <= ipsum_XID + 1;
                                end else begin
                                    ipsum_XID <= 5'h1F; // 31
                                end
                            end



                            // opsum XID 生成
                            if (!LINEAR) begin
                                if ((r==1 && row_cnt_XID==2) || (r==1 && row_cnt_XID==5) || (r==2 && row_cnt_XID==5)) begin
                                    // opsum_XID <= c_opsum_XID;
                                    opsum_XID <= opsum_XID + 1;
                                end else begin
                                    opsum_XID <= 5'h1F; // 31
                                end
                            end else begin
                                if (row_cnt_XID==PE_ARRAY_H-1 && col_cnt_XID < t) begin
                                    // opsum_XID <= c_opsum_XID;
                                    opsum_XID <= opsum_XID + 1;
                                end else begin
                                    opsum_XID <= 5'h1F; // 31
                                end
                            end



                            col_cnt_XID <= col_cnt_XID + 1;
                        end else begin
                            col_cnt_XID <= 8'h0;
                            row_cnt_XID <= row_cnt_XID + 1;

                            // 行結束狀態更新 - Filter
                            if (!LINEAR) begin
                                if (row_cnt_XID == row_block - 1) begin
                                    filter_XID <= 5'h0;
                                    first_col_idx <= 5'h0;
                                end else begin
                                    filter_XID <= first_col_idx + 1;
                                    first_col_idx <= first_col_idx + 1;
                                end
                            end else begin
                                filter_XID <= 5'h0;
                            end

                            // 行結束狀態更新 - ifmap
                            if (!LINEAR) begin
                                if (row_cnt_XID == row_block - 1) begin
                                    ifmap_XID <= 5'h0;
                                    first_col_idx <= 5'h0;
                                end else begin
                                    ifmap_XID <= first_col_idx + 1;
                                end
                            end

                            // ipsum/opsum 行結束重置
                            ipsum_XID <= 5'h0;
                            opsum_XID <= 5'h0;

                            // y_done <= (row_cnt_XID == PE_ARRAY_H-1);
                        end
                    end else begin
                        x_done <= 1'b1;
                        // next_state <= IDLE;
                    end

                    if(row_cnt_YID < PE_ARRAY_H) begin
                        // Filter YID 生成
                        if (!LINEAR) begin
                            if ((r==2 || t_H==2) && row_cnt_YID==KERNEL_H) begin
                                filter_YID <= filter_YID + 1;
                            end
                            // filter_YID <= c_filter_YID;
                        end else begin
                            filter_YID <= filter_YID + 1;
                        end

                        // ifmap YID 生成
                        if (!LINEAR) begin
                            if (r==2 && row_cnt_YID==KERNEL_H) begin
                                ifmap_YID <= ifmap_YID + 1;
                            end
                            // ifmap_YID <= c_ifmap_YID;
                        end else begin
                            ifmap_YID <= row_cnt_YID[2:0];
                        end

                        // ipsum YID 生成
                        if (!LINEAR) begin
                            // if ((r==1 && row_cnt_YID==0) || (r==1 && row_cnt_YID==3) || (r==2 && row_cnt_YID==0)) begin
                            if (r==1 && row_cnt_YID==3) begin
                                ipsum_YID <= ipsum_YID + 1;
                            end else if((r==1 && row_cnt_YID==0) || (r==2 && row_cnt_YID==0)) begin
                                ipsum_YID <= 0;
                            end else if(row_cnt_YID > 0) begin
                                ipsum_YID <= 3'h7; // 7
                            end
                        end else begin
                            if (row_cnt_YID==0) begin
                                ipsum_YID <= 3'h0;
                            end else begin
                                ipsum_YID <= 3'h7; // 7
                            end
                        end
    
                        // opsum YID 生成
                        if (!LINEAR) begin
                            // if ((r==1 && row_cnt_YID==2) || (r==1 && row_cnt_YID==5) || (r==2 && row_cnt_YID==5)) begin
                            if (r==1 && row_cnt_YID==5) begin
                                // opsum_YID <= c_opsum_YID;
                                opsum_YID <= opsum_YID + 1;
                            end else if((r==1 && row_cnt_YID==2) || (r==2 && row_cnt_YID==5)) begin
                                opsum_YID <= 0;
                            end else begin
                                opsum_YID <= 3'h7; // 7
                            end
                        end else begin
                            if (row_cnt_YID==PE_ARRAY_H-1) begin
                                opsum_YID <= 3'h0;
                            end else begin
                                opsum_YID <= 3'h7; // 7
                            end
                        end

                        row_cnt_YID <= row_cnt_YID + 1;
                    end
                    else begin
                        y_done <= 1'b1;
                    end
                // end
            end
        endcase
    end
end

endmodule