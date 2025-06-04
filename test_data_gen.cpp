#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

#define q               3
#define r               1
#define p               3
#define t               1
#define IN_CHANNEL      q*r
#define IN_HEIGHT       1
#define IN_WIDTH        33
#define KERNEL_SIZE_W   3
#define KERNEL_SIZE_H   1
#define STRIDE          2
#define OUT_HEIGHT      (IN_HEIGHT - KERNEL_SIZE_H + 1)
#define OUT_WIDTH       (IN_WIDTH - KERNEL_SIZE_W)/STRIDE + 1
#define OUT_CHANNEL     p*t

int main(){
    // 輸入 feature map、卷積核和偏置
    int8_t ifmap[IN_CHANNEL][IN_HEIGHT][IN_WIDTH];
    int8_t depthwise_filter[IN_CHANNEL][KERNEL_SIZE_H][KERNEL_SIZE_W];
    int32_t depthwise_result[IN_CHANNEL][OUT_HEIGHT][OUT_WIDTH];
    int32_t depthwise_ipsum[IN_CHANNEL][OUT_HEIGHT][OUT_WIDTH];

    int8_t filter[OUT_CHANNEL][IN_CHANNEL][KERNEL_SIZE_H][KERNEL_SIZE_W];
    int32_t ipsum[OUT_CHANNEL][OUT_HEIGHT][OUT_WIDTH];

    int8_t pointwise_filter[OUT_CHANNEL][IN_CHANNEL][1][1];
    int32_t pointwise_ipsum[OUT_CHANNEL][OUT_HEIGHT][OUT_WIDTH];
    int32_t opsum[OUT_CHANNEL][OUT_HEIGHT][OUT_WIDTH];
    
    FILE* ifmap_file = fopen("ifmap.txt", "w+");
    FILE* filter_file = fopen("filter.txt", "w+");
    FILE* ipsum_file = fopen("ipsum.txt", "w+");
    #ifdef USE_DEPTHWISE
        FILE* point_ipsum_file = fopen("pointwise_ipsum.txt", "w+");
        FILE* depth_ipsum_file = fopen("depthwise_ipsum.txt", "w+");
    #endif
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
    

    #ifdef USE_DEPTHWISE
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
    #else
        // 初始化 filter (一般卷積核)
        for (int oc = 0; oc < OUT_CHANNEL; oc++){
            for (int ic = 0; ic < IN_CHANNEL; ic++){
                for (int row = 0; row < KERNEL_SIZE_H; row++){
                    for (int col = 0; col < KERNEL_SIZE_W; col++){
                        filter[oc][ic][row][col] = value++;
                    }
                }    
            }
        }
    #endif


    #ifdef USE_DEPTHWISE
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
    #else
        for (int oc = 0; oc < OUT_CHANNEL; oc++){
            for (int row = 0; row < OUT_HEIGHT; row++){
                for (int col = 0; col < OUT_WIDTH; col++){
                    ipsum[oc][row][col] = 0;
                }
            }
        }
    #endif
    

    #ifdef USE_DEPTHWISE
        // Depthwise convolution
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

        // Pointwise convolution
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
    #else
        // General convolution
        for (int oc = 0; oc < OUT_CHANNEL; oc++){
            for (int i = 0; i < OUT_HEIGHT; i++){
                for (int j = 0; j < OUT_WIDTH; j++){
                    int32_t sum = 0;
                    for (int ic = 0; ic < IN_CHANNEL; ic++){
                        for (int ki = 0; ki < KERNEL_SIZE_H; ki++){
                            for (int kj = 0; kj < KERNEL_SIZE_W; kj++){
                                sum += ifmap[ic][STRIDE * i + ki][STRIDE * j + kj] * filter[oc][ic][ki][kj];
                            }
                        }
                    }
                    opsum[oc][i][j] = sum + ipsum[oc][i][j];
                }
            }
        }
    #endif
    
    /********** 印出各個陣列內容 **********/
    
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
    
    #ifdef USE_DEPTHWISE
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
    #else
        // 印出 filter
        printf("filter:\n");
        for (int oc = 0; oc < OUT_CHANNEL; oc++){
            printf("Output Channel %d:\n", oc);
            for (int ic = 0; ic < IN_CHANNEL; ic++){
                printf("Input Channel %d:\n", ic);
                for (int row = 0; row < KERNEL_SIZE_H; row++){
                    for (int col = 0; col < KERNEL_SIZE_W; col++){
                        printf("%4d ", filter[oc][ic][row][col]);
                    }
                    printf("\n");
                }
                printf("\n");
            }
            printf("\n");
        }
    #endif

    #ifdef USE_DEPTHWISE
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
    #else
        // 印出 ipsum
        printf("ipsum:\n");
        for (int oc = 0; oc < OUT_CHANNEL; oc++){
            printf("Output Channel %d:\n", oc);
            for (int row = 0; row < OUT_HEIGHT; row++){
                for (int col = 0; col < OUT_WIDTH; col++){
                    printf("%4d ", ipsum[oc][row][col]);
                }
                printf("\n");
            }
            printf("\n");
        }
    #endif

    #ifdef USE_DEPTHWISE
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
    #endif
    
    // 印出 opsum (逐點卷積後的最終結果)
    printf("opsum:\n");
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


    #ifndef WHOLE_IFMAP // PE testcase
        // output ifmap
        for (int col = 0; col < IN_WIDTH; col++){
            for (int c = 0; c < IN_CHANNEL; c++){
                fprintf(ifmap_file, "%d", int8_t(ifmap[c][0][col] + (uint8_t)128));
                if(!(col == IN_WIDTH-1 && c == IN_CHANNEL-1)){
                    fprintf(ifmap_file, ",");
                }
            }
        }

        #ifdef USE_DEPTHWISE
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
        #else
            for (int oc = 0; oc < OUT_CHANNEL; oc++){
                for (int col = 0; col < KERNEL_SIZE_W; col++){
                    for (int c = 0; c < IN_CHANNEL; c++){
                        fprintf(filter_file, "%d", filter[oc][c][0][col]);
                        if(!(col == KERNEL_SIZE_W-1 && c == IN_CHANNEL-1)){
                            fprintf(filter_file, ",");
                        }
                    }
                }
            }
        #endif

        //output opsum
        for (int col = 0; col < OUT_WIDTH; col++) {
            for (int c = 0; c < OUT_CHANNEL; c++) {
                fprintf(opsum_file, "%d", opsum[c][0][col]);
                if (!(col == OUT_WIDTH - 1 && c == OUT_CHANNEL - 1)) {
                    fprintf(opsum_file, ",");
                }
            }
        }

        #ifdef USE_DEPTHWISE
            // output pointwise_ipsum, output depth_ipsum (全 0)
            for (int col = 0; col < OUT_WIDTH; col++) {
                for (int c = 0; c < OUT_CHANNEL; c++) {
                    fprintf(point_ipsum_file, "%d", pointwise_ipsum[c][0][col]);
                    fprintf(depth_ipsum_file, "%d", 0);
                    if (!(col == OUT_WIDTH - 1 && c == OUT_CHANNEL - 1)) {
                        fprintf(point_ipsum_file, ",");
                        fprintf(depth_ipsum_file, ",");
                    }
                }
            }
        #else
            for (int col = 0; col < OUT_WIDTH; col++) {
                for (int c = 0; c < OUT_CHANNEL; c++) {
                    fprintf(ipsum_file, "%d", 0);
                    if (!(col == OUT_WIDTH - 1 && c == OUT_CHANNEL - 1)) {
                        fprintf(ipsum_file, ",");
                    }
                }
            }
        #endif

    #else // PE array testcase
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
        #ifdef USE_DEPTHWISE
            int point_num = 0;
            int pointwise_filter_num = 0;
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
                        fprintf(filter_file, "%d,", pointwise_filter[pointwise_filter_num][ic][0][0]);
                    }
                    for (int ic = 0; ic < IN_CHANNEL; ic++){
                        fprintf(filter_file, "%d,", pointwise_filter[pointwise_filter_num+1][ic][0][0]);
                    }
                    for (int ic = 0; ic < IN_CHANNEL; ic++){
                        fprintf(filter_file, "%d,", pointwise_filter[pointwise_filter_num+2][ic][0][0]);
                    }
                }
                for (int aa = 0; aa < 3; aa++){
                    for (int ic = 0; ic < IN_CHANNEL; ic++){
                        fprintf(filter_file, "%d,", pointwise_filter[pointwise_filter_num+3][ic][0][0]);
                    }
                    for (int ic = 0; ic < IN_CHANNEL; ic++){
                        fprintf(filter_file, "%d,", 0);
                    }
                    for (int ic = 0; ic < IN_CHANNEL; ic++){
                        fprintf(filter_file, "%d,", 0);
                    }
                }
                for (int aa = 0; aa < 3 && p == 4; aa++){
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
                pointwise_filter_num += 4;
            }
        #else
            for(int oc =0; oc < OUT_CHANNEL; oc++){
                for (int ic = 0; ic < IN_CHANNEL; ic++){
                    if(oc == 10 || oc == 11){
                        fprintf(filter_file, "%d", 0);
                    } else {
                        fprintf(filter_file, "%d", pointwise_filter[oc][ic][0][0]);
                    }
                    if(!(oc == OUT_CHANNEL-1 && ic == IN_CHANNEL-1)){
                        fprintf(filter_file, ",");
                    }
                }
            }
        #endif

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
