`timescale 1ns/1ps
module pe_array_id_generator (
    input [2:0] p,
    input [2:0] q,           // r parameter
    input [2:0] r,           // e parameter
    input [2:0] t,           // t parameter
    input [2:0] e,         // t_H parameter  
    input [2:0] t_H,         // t_H parameter  
    input [2:0] t_W,         // t_H parameter  
    input [2:0] PE_ARRAY_H,
    input [3:0] PE_ARRAY_W,
    input [1:0] KERNEL_H,
    input LINEAR,            // LINEAR mode flag
    
    // Filter IDs
    output reg [4:0] filter_XID [0:47],
    output reg [2:0] filter_YID [0:5],
    
    // Input feature map IDs
    output reg [4:0] ifmap_XID [0:47],
    output reg [2:0] ifmap_YID [0:5],
    
    // Input partial sum IDs
    output reg [4:0] ipsum_XID [0:47],
    output reg [2:0] ipsum_YID [0:5],
    
    // Output partial sum IDs
    output reg [4:0] opsum_XID [0:47],
    output reg [2:0] opsum_YID [0:5],
    output reg [4:0] LN_congfig
);

    // Internal variables
    wire [2:0] row_block;
    reg [4:0] temp_filter_XID;
    reg [2:0] temp_filter_YID;
    reg [4:0] temp_ifmap_XID;
    reg [2:0] temp_ifmap_YID;
    reg [4:0] temp_ipsum_XID;
    reg [2:0] temp_ipsum_YID;
    reg [4:0] temp_opsum_XID;
    reg [2:0] temp_opsum_YID;
    reg [2:0] first_col_idx;
    
    integer row_cnt, col_cnt, idx;
    
    // Calculate row_block
    assign row_block = 6 / (r * t_H);
    
    always @(*) begin
        // LN_congfig
        if(LINEAR) begin
            LN_congfig = 5'd31;
        end else begin
            if(r==2)
                LN_congfig = 5'd31;
            else
                LN_congfig = 5'd27;
        end

        // Initialize all arrays
        for (idx = 0; idx < 48; idx = idx + 1) begin
            filter_XID[idx] = 5'd0;
            ifmap_XID[idx] = 5'd0;
            ipsum_XID[idx] = 5'd31;
            opsum_XID[idx] = 5'd31;
        end
        
        for (idx = 0; idx < 6; idx = idx + 1) begin
            filter_YID[idx] = 3'd0;
            ifmap_YID[idx] = 3'd0;
            ipsum_YID[idx] = 3'd7;
            opsum_YID[idx] = 3'd7;
        end
        
        // Generate filter_XID
        temp_filter_XID = 0;
        first_col_idx = 0;
        for (row_cnt = 0; row_cnt < PE_ARRAY_H; row_cnt = row_cnt + 1) begin
            for (col_cnt = 0; col_cnt < PE_ARRAY_W; col_cnt = col_cnt + 1) begin
                idx = row_cnt * PE_ARRAY_W + col_cnt;
                
                if (!LINEAR) begin
                    if ((col_cnt % e == 0) && (col_cnt >= e)) begin
                        temp_filter_XID = temp_filter_XID + KERNEL_H;
                    end
                    filter_XID[idx] = temp_filter_XID;
                end else begin
                    if (col_cnt < t) begin
                        filter_XID[idx] = temp_filter_XID;
                        temp_filter_XID = temp_filter_XID + 1;
                    end else begin
                        filter_XID[idx] = 5'd31;
                    end
                end
            end
            
            if (!LINEAR) begin
                if (row_cnt == row_block - 1) begin
                    temp_filter_XID = 0;
                    first_col_idx = 0;
                end else begin
                    temp_filter_XID = first_col_idx + 1;
                    first_col_idx = first_col_idx + 1;
                end
            end else begin
                temp_filter_XID = 0;
            end
        end

        // Generate filter_YID
        temp_filter_YID = 0;
        for (row_cnt = 0; row_cnt < PE_ARRAY_H; row_cnt = row_cnt + 1) begin
            if (!LINEAR) begin
                if (((r == 2) || (t_H == 2)) && (row_cnt == KERNEL_H)) begin
                    temp_filter_YID = temp_filter_YID + 1;
                end
                filter_YID[row_cnt] = temp_filter_YID;
            end else begin
                filter_YID[row_cnt] = temp_filter_YID;
                temp_filter_YID = temp_filter_YID + 1;
            end
        end
        
        // Generate ifmap_XID
        temp_ifmap_XID = 0;
        first_col_idx = 0;
        for (row_cnt = 0; row_cnt < PE_ARRAY_H; row_cnt = row_cnt + 1) begin
            for (col_cnt = 0; col_cnt < PE_ARRAY_W; col_cnt = col_cnt + 1) begin
                idx = row_cnt * PE_ARRAY_W + col_cnt;
                
                if (!LINEAR) begin
                    if ((col_cnt % e == 0) && (col_cnt >= e)) begin
                        temp_ifmap_XID = first_col_idx;
                    end else if (col_cnt != 0) begin
                        temp_ifmap_XID = temp_ifmap_XID + 1;
                    end
                    ifmap_XID[idx] = temp_ifmap_XID;
                end else begin
                    if (col_cnt < t) begin
                        ifmap_XID[idx] = 5'd0;
                    end else begin
                        ifmap_XID[idx] = 5'd31;
                    end
                end
            end
            
            if (!LINEAR) begin
                if (row_cnt == row_block - 1) begin
                    temp_ifmap_XID = 0;
                    first_col_idx = 0;
                end else begin
                    temp_ifmap_XID = first_col_idx + 1;
                    first_col_idx = first_col_idx + 1;
                end
            end
        end
        
        // Generate ifmap_YID
        temp_ifmap_YID = 0;
        for (row_cnt = 0; row_cnt < PE_ARRAY_H; row_cnt = row_cnt + 1) begin
            if (!LINEAR) begin
                if ((r == 2) && (row_cnt == KERNEL_H)) begin
                    temp_ifmap_YID = temp_ifmap_YID + 1;
                end
                ifmap_YID[row_cnt] = temp_ifmap_YID;
            end else begin
                ifmap_YID[row_cnt] = temp_ifmap_YID;
                temp_ifmap_YID = temp_ifmap_YID + 1;
            end
        end
        
        // Generate ipsum_XID
        temp_ipsum_XID = 0;
        for (row_cnt = 0; row_cnt < PE_ARRAY_H; row_cnt = row_cnt + 1) begin
            for (col_cnt = 0; col_cnt < PE_ARRAY_W; col_cnt = col_cnt + 1) begin
                idx = row_cnt * PE_ARRAY_W + col_cnt;
                
                if (!LINEAR) begin
                    if (((r == 1) && (row_cnt == 0)) || 
                        ((r == 1) && (row_cnt == 3)) || 
                        ((r == 2) && (row_cnt == 0))) begin
                        ipsum_XID[idx] = temp_ipsum_XID;
                        temp_ipsum_XID = temp_ipsum_XID + 1;
                    end else begin
                        ipsum_XID[idx] = 5'd31;
                    end
                end else begin
                    if ((row_cnt == 0) && (col_cnt < t)) begin
                        ipsum_XID[idx] = temp_ipsum_XID;
                        temp_ipsum_XID = temp_ipsum_XID + 1;
                    end else begin
                        ipsum_XID[idx] = 5'd31;
                    end
                end
            end
            temp_ipsum_XID = 0;
        end
        
        // Generate ipsum_YID
        temp_ipsum_YID = 0;
        for (row_cnt = 0; row_cnt < PE_ARRAY_H; row_cnt = row_cnt + 1) begin
            if (!LINEAR) begin
                if (((r == 1) && (row_cnt == 0)) || 
                    ((r == 1) && (row_cnt == 3)) || 
                    ((r == 2) && (row_cnt == 0))) begin
                    ipsum_YID[row_cnt] = temp_ipsum_YID;
                    temp_ipsum_YID = temp_ipsum_YID + 1;
                end else begin
                    ipsum_YID[row_cnt] = 3'd7;
                end
            end else begin
                if (row_cnt == 0) begin
                    ipsum_YID[row_cnt] = 3'd0;
                end else begin
                    ipsum_YID[row_cnt] = 3'd7;
                end
            end
        end
        
        // Generate opsum_XID
        temp_opsum_XID = 0;
        for (row_cnt = 0; row_cnt < PE_ARRAY_H; row_cnt = row_cnt + 1) begin
            for (col_cnt = 0; col_cnt < PE_ARRAY_W; col_cnt = col_cnt + 1) begin
                idx = row_cnt * PE_ARRAY_W + col_cnt;
                
                if (!LINEAR) begin
                    if (((r == 1) && (row_cnt == 2)) || 
                        ((r == 1) && (row_cnt == 5)) || 
                        ((r == 2) && (row_cnt == 5))) begin
                        opsum_XID[idx] = temp_opsum_XID;
                        temp_opsum_XID = temp_opsum_XID + 1;
                    end else begin
                        opsum_XID[idx] = 5'd31;
                    end
                end else begin
                    if ((row_cnt == PE_ARRAY_H - 1) && (col_cnt < t)) begin
                        opsum_XID[idx] = temp_opsum_XID;
                        temp_opsum_XID = temp_opsum_XID + 1;
                    end else begin
                        opsum_XID[idx] = 5'd31;
                    end
                end
            end
            temp_opsum_XID = 0;
        end
        
        // Generate opsum_YID
        temp_opsum_YID = 0;
        for (row_cnt = 0; row_cnt < PE_ARRAY_H; row_cnt = row_cnt + 1) begin
            if (!LINEAR) begin
                if (((r == 1) && (row_cnt == 2)) || 
                    ((r == 1) && (row_cnt == 5)) || 
                    ((r == 2) && (row_cnt == 5))) begin
                    opsum_YID[row_cnt] = temp_opsum_YID;
                    temp_opsum_YID = temp_opsum_YID + 1;
                end else begin
                    opsum_YID[row_cnt] = 3'd7;
                end
            end else begin
                if (row_cnt == PE_ARRAY_H - 1) begin
                    opsum_YID[row_cnt] = 3'd0;
                end else begin
                    opsum_YID[row_cnt] = 3'd7;
                end
            end
        end
    end

endmodule