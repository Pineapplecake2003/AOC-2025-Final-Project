#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

#define q               4
#define r               1
#define p               4
#define t               1
#define IN_CHANNEL      q*r
#define IN_HEIGHT       18
#define IN_WIDTH        18
#define KERNEL_SIZE_W   3
#define KERNEL_SIZE_H   3
#define OUT_HEIGHT      (IN_HEIGHT - KERNEL_SIZE_H + 1)
#define OUT_WIDTH       (IN_WIDTH - KERNEL_SIZE_W + 1)
#define OUT_CHANNEL     p*t

int main(){
    // 輸入 feature map、卷積核和偏置（ipsum）定義
    int8_t ifmap[IN_CHANNEL][IN_HEIGHT][IN_WIDTH];
    int8_t depthwise_filter[IN_CHANNEL][KERNEL_SIZE_H][KERNEL_SIZE_W];
    int32_t depthwise_result[IN_CHANNEL][OUT_HEIGHT][OUT_WIDTH];
    int32_t depthwise_ipsum[IN_CHANNEL][OUT_HEIGHT][OUT_WIDTH];

    int8_t pointwise_filter[OUT_CHANNEL][IN_CHANNEL][1][1];
    int32_t pointwise_ipsum[OUT_CHANNEL][OUT_HEIGHT][OUT_WIDTH];
    int32_t opsum[OUT_CHANNEL][OUT_HEIGHT][OUT_WIDTH];
    
    FILE* ifmap_file = fopen("ifmap.txt", "w+");
    FILE* filter_file = fopen("filter.txt", "w+");
    FILE* point_ipsum_file = fopen("pointwise_ipsum.txt", "w+");
    FILE* depth_ipsum_file = fopen("depthwise_ipsum.txt", "w+");
    FILE* opsum_file = fopen("opsum.txt", "w+");


    // 用連續的數值初始化 ifmap, 從 -128 開始
    int8_t value = -128;
    for (int c = 0; c < IN_CHANNEL; c++){
        for (int row = 0; row < IN_HEIGHT; row++){
            for (int col = 0; col < IN_WIDTH; col++){
                ifmap[c][row][col] = value++;
            }
        }
    }
    
    // 初始化 depthwise_filter
    for (int c = 0; c < IN_CHANNEL; c++){
        for (int row = 0; row < KERNEL_SIZE_H; row++){
            for (int col = 0; col < KERNEL_SIZE_W; col++){
                depthwise_filter[c][row][col] = value++;
            }
        }
    }
    
    // 初始化 pointwise_filter (1x1 卷積核)
    for (int oc = 0; oc < OUT_CHANNEL; oc++){
        for (int ic = 0; ic < IN_CHANNEL; ic++){
            pointwise_filter[oc][ic][0][0] = value++;
        }
    }
    
    // 初始化 depthwise_ipsum (深度卷積偏置)
    for (int c = 0; c < IN_CHANNEL; c++){
        for (int row = 0; row < OUT_HEIGHT; row++){
            for (int col = 0; col < OUT_WIDTH; col++){
                depthwise_ipsum[c][row][col] = 0;//value++;
            }
        }
    }
    
    // 初始化 pointwise_ipsum (逐點卷積偏置)
    for (int oc = 0; oc < OUT_CHANNEL; oc++){
        for (int row = 0; row < OUT_HEIGHT; row++){
            for (int col = 0; col < OUT_WIDTH; col++){
                pointwise_ipsum[oc][row][col] = value++;
            }
        }
    }
    
    // -------------------------------------------------------------------------
    // Depthwise convolution: 每個輸入通道用對應的 3x3 核做卷積
    for (int c = 0; c < IN_CHANNEL; c++){
        for (int i = 0; i < OUT_HEIGHT; i++){
            for (int j = 0; j < OUT_WIDTH; j++){
                int32_t sum = 0;
                for (int ki = 0; ki < KERNEL_SIZE_H; ki++){
                    for (int kj = 0; kj < KERNEL_SIZE_W; kj++){
                        sum += (int32_t)ifmap[c][i + ki][j + kj] * depthwise_filter[c][ki][kj];
                    }
                }
                depthwise_result[c][i][j] = sum + depthwise_ipsum[c][i][j];
            }
        }
    }
    
    // -------------------------------------------------------------------------
    // Pointwise convolution: 使用 1x1 卷積核來跨通道整合特徵
    for (int oc = 0; oc < OUT_CHANNEL; oc++){
        for (int i = 0; i < OUT_HEIGHT; i++){
            for (int j = 0; j < OUT_WIDTH; j++){
                int32_t sum = 0;
                for (int ic = 0; ic < IN_CHANNEL; ic++){
                    sum += depthwise_result[ic][i][j] * pointwise_filter[oc][ic][0][0];
                }
                opsum[oc][i][j] = sum + pointwise_ipsum[oc][i][j];
            }
        }
    }
    
    // -------------------------------------------------------------------------
    // 印出各個陣列內容
    
    // 印出 ifmap
    printf("ifmap:\n");
    for (int c = 0; c < IN_CHANNEL; c++){
        printf("Channel %d:\n", c);
        for (int row = 0; row < IN_HEIGHT; row++){
            for (int col = 0; col < IN_WIDTH; col++){
                printf("%4d ", ifmap[c][row][col]);
            }
            printf("\n");
        }
        printf("\n");
    }
    
    // 印出 depthwise_filter
    printf("depthwise_filter:\n");
    for (int c = 0; c < IN_CHANNEL; c++){
        printf("Channel %d:\n", c);
        for (int row = 0; row < KERNEL_SIZE_H; row++){
            for (int col = 0; col < KERNEL_SIZE_W; col++){
                printf("%4d ", depthwise_filter[c][row][col]);
            }
            printf("\n");
        }
        printf("\n");
    }
    
    // 印出 pointwise_filter (1x1 核)
    printf("pointwise_filter:\n");
    for (int oc = 0; oc < OUT_CHANNEL; oc++){
        printf("Output Channel %d:\n", oc);
        for (int ic = 0; ic < IN_CHANNEL; ic++){
            printf("%4d\n", pointwise_filter[oc][ic][0][0]);
        }
        printf("\n");
    }
    
    // 印出 depthwise_ipsum
    printf("depthwise_ipsum:\n");
    for (int c = 0; c < IN_CHANNEL; c++){
        printf("Channel %d:\n", c);
        for (int row = 0; row < OUT_HEIGHT; row++){
            for (int col = 0; col < OUT_WIDTH; col++){
                printf("%4d ", depthwise_ipsum[c][row][col]);
            }
            printf("\n");
        }
        printf("\n");
    }
    
    // 印出 pointwise_ipsum
    printf("pointwise_ipsum:\n");
    for (int oc = 0; oc < OUT_CHANNEL; oc++){
        printf("Output Channel %d:\n", oc);
        for (int row = 0; row < OUT_HEIGHT; row++){
            for (int col = 0; col < OUT_WIDTH; col++){
                printf("%4d ", pointwise_ipsum[oc][row][col]);
            }
            printf("\n");
        }
        printf("\n");
    }
    
    // 印出 depthwise_result (深度卷積後的結果)
    printf("depthwise_result (after depthwise convolution):\n");
    for (int c = 0; c < IN_CHANNEL; c++){
        printf("Channel %d:\n", c);
        for (int row = 0; row < OUT_HEIGHT; row++){
            for (int col = 0; col < OUT_WIDTH; col++){
                printf("%8d ", depthwise_result[c][row][col]);
            }
            printf("\n");
        }
        printf("\n");
    }
    
    // 印出 opsum (逐點卷積後的最終結果)
    printf("opsum (final result after pointwise convolution):\n");
    for (int oc = 0; oc < OUT_CHANNEL; oc++){
        printf("Output Channel %d:\n", oc);
        for (int row = 0; row < OUT_HEIGHT; row++){
            for (int col = 0; col < OUT_WIDTH; col++){
                printf("%8d ", opsum[oc][row][col]);
            }
            printf("\n");
        }
        printf("\n");
    }
    #ifndef WHOLE_IFMAP
    // output ifmap
    for (int col = 0; col < IN_WIDTH; col++){
        for (int c = 0; c < IN_CHANNEL; c++){
            fprintf(ifmap_file, "%d", int8_t(ifmap[c][0][col] + (uint8_t)128));
            if(!(col == IN_WIDTH-1 && c == IN_CHANNEL-1)){
                fprintf(ifmap_file, ",");
            }
        }
    }

    // output filter
    for (int col = 0; col < KERNEL_SIZE_W; col++){
        for (int c = 0; c < IN_CHANNEL; c++){
            fprintf(filter_file, "%d,", depthwise_filter[c][0][col]);
        }
    }
    for (int oc = 0; oc < OUT_CHANNEL; oc++){
        for (int c = 0; c < IN_CHANNEL; c++){
            fprintf(filter_file, "%d", pointwise_filter[oc][c][0][0]);
            if(!(oc == OUT_CHANNEL-1 && c == IN_CHANNEL-1)){
                fprintf(filter_file, ",");
            }
        }
    }

    //output opsum
    for (int col = 0; col < OUT_WIDTH; col++){
        for (int c = 0; c < OUT_CHANNEL; c++){
            fprintf(opsum_file, "%d", opsum[c][0][col]);
            fprintf(point_ipsum_file, "%d", pointwise_ipsum[c][0][col]);
            fprintf(depth_ipsum_file, "%d", 0);
            if(!(col == OUT_WIDTH-1 && c == OUT_CHANNEL-1)){
                fprintf(opsum_file, ",");
                fprintf(point_ipsum_file, ",");
                fprintf(depth_ipsum_file,",");
            }
        }
    }
    #else
    // ifmap
    for (int row = 0; row < IN_HEIGHT; row++){
        for (int col = 0; col < IN_WIDTH; col++){
            for (int c = 0; c < IN_CHANNEL; c++){
                fprintf(ifmap_file, "%d", int8_t(ifmap[c][row][col] + (uint8_t)128));
                if(!(col == IN_WIDTH-1 && c == IN_CHANNEL-1 && row == IN_HEIGHT-1)){
                    fprintf(ifmap_file, ",");
                }
            }
        }
    }
    // depthwise filter
    // int pointwise_limit = p;
    // int num_filter = 1;
    // for (int tt = 0; tt < t; tt++){
    //     for (int row = 0; row < KERNEL_SIZE_H; row++){
    //         for (int col = 0; col < KERNEL_SIZE_W; col++){
    //             for (int c = 0; c < IN_CHANNEL; c++){
    //                 fprintf(filter_file, "%d,", depthwise_filter[c][row][col]);
    //             }
    //         }
    //     }
    //     // pointwise filter
    //     for (; num_filter < pointwise_limit; num_filter++){
    //         for (int row = 0; row < KERNEL_SIZE_H; row++){
    //             for (int col = 0; col < KERNEL_SIZE_W; col++){
    //                 for (int c = 0; c < IN_CHANNEL; c++){
    //                     //printf("index: [%d][%d][0][0], to zero: %d\n", (num_filter-1)*KERNEL_SIZE_W + col, c, (num_filter-1)*KERNEL_SIZE_W + col <= pointwise_limit-1);
    //                     if(num_filter > p){
    //                         if((num_filter-4)*KERNEL_SIZE_W + col+1<= pointwise_limit-1){
    //                             fprintf(filter_file, "%d", pointwise_filter[(num_filter-4)*KERNEL_SIZE_W + col+1][c][0][0]);}
    //                         else{
    //                             fprintf(filter_file, "%d", 0);
    //                         }
    //                     }
    //                     else{
    //                         if((num_filter-1)*KERNEL_SIZE_W + col <= pointwise_limit-1){
    //                             fprintf(filter_file, "%d", pointwise_filter[(num_filter-1)*KERNEL_SIZE_W + col][c][0][0]);
    //                         }else{
    //                             fprintf(filter_file, "%d", 0);
    //                         }
    //                     }
    //                     
    //                     if(!(tt == t-1 && num_filter == p*t-1 && col == KERNEL_SIZE_W-1 && row == KERNEL_SIZE_H-1 && c == IN_CHANNEL-1)){
    //                         fprintf(filter_file, ",");
    //                     }
    //                 }
    //             }
    //         }
    //     }
    //     pointwise_limit = pointwise_limit + p;
    //     num_filter = 5;
    // }
    int point_num = 0;
    for (int tt = 0; tt < t; tt++){
        for (int row = 0; row < KERNEL_SIZE_H; row++){
            for (int col = 0; col < KERNEL_SIZE_W; col++){
                for (int c = 0; c < IN_CHANNEL; c++){
                    fprintf(filter_file, "%d,", depthwise_filter[c][row][col]);
                }
            }
        }
        for (int aa = 0; aa < 3; aa++){
            for (int ic = 0; ic < IN_CHANNEL; ic++){
                fprintf(filter_file, "%d,", pointwise_filter[0][ic][0][0]);
            }
            for (int ic = 0; ic < IN_CHANNEL; ic++){
                fprintf(filter_file, "%d,", pointwise_filter[1][ic][0][0]);
            }
            for (int ic = 0; ic < IN_CHANNEL; ic++){
                fprintf(filter_file, "%d,", pointwise_filter[2][ic][0][0]);
            }
        }
        for (int aa = 0; aa < 3; aa++){
            for (int ic = 0; ic < IN_CHANNEL; ic++){
                fprintf(filter_file, "%d,", pointwise_filter[3][ic][0][0]);
            }
            for (int ic = 0; ic < IN_CHANNEL; ic++){
                fprintf(filter_file, "%d,", 0);
            }
            for (int ic = 0; ic < IN_CHANNEL; ic++){
                fprintf(filter_file, "%d,", 0);
            }
        }
        for (int aa = 0; aa < 3; aa++){
            for (int ic = 0; ic < IN_CHANNEL; ic++){
                fprintf(filter_file, "%d,", 0);
            }
            for (int ic = 0; ic < IN_CHANNEL; ic++){
                fprintf(filter_file, "%d,", 0);
            }
            for (int ic = 0; ic < IN_CHANNEL; ic++){
                fprintf(filter_file, "%d,", 0);
            }
        }
    }
    //output opsum
    for (int row = 0; row < OUT_HEIGHT; row++){
        for (int col = 0; col < OUT_WIDTH; col++){
            for (int c = 0; c < OUT_CHANNEL; c++){
                fprintf(opsum_file, "%d", opsum[c][row][col]);
                fprintf(point_ipsum_file, "%d", pointwise_ipsum[c][row][col]);
                fprintf(depth_ipsum_file, "%d", 0);
                if(!(col == OUT_WIDTH-1 && c == OUT_CHANNEL-1 && row == OUT_HEIGHT-1)){
                    fprintf(opsum_file, ",");
                    fprintf(point_ipsum_file, ",");
                    fprintf(depth_ipsum_file,",");
                }
            }
        }
    }
    #endif

    return 0;
}
