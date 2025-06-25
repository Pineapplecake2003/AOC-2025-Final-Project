#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

#include <random>
#include <cstdint> // for int8_t

/* remember to adjust the config here */
#define p               4
#define q               4
#define r               2
#define t               2
#define e               4
#define STRIDE          2
#define KERNEL_SIZE_W   3
#define KERNEL_SIZE_H   3
// #define IN_WIDTH        33
// #define IN_HEIGHT       (STRIDE*(e-1) + KERNEL_SIZE_H)
// #define IN_CHANNEL      (q*r)
// #define OUT_HEIGHT      e
// #define OUT_WIDTH       ((IN_WIDTH - KERNEL_SIZE_W)/STRIDE + 1)
// #define OUT_CHANNEL     (p*t)
#define IN_INITIAL      5
#define PADDING         0
#define IN_WIDTH        IN_INITIAL + 2 * PADDING 
#define IN_HEIGHT       IN_WIDTH
#define IN_CHANNEL      512
#define OUT_WIDTH       ((IN_WIDTH - KERNEL_SIZE_W)/STRIDE + 1)
#define OUT_HEIGHT      OUT_WIDTH
#define OUT_CHANNEL     1024

uint8_t random_uint8() {
    static std::random_device rd;
    static std::mt19937 gen(rd());
    static std::uniform_int_distribution<int> dist(1, 1);
    return static_cast<uint8_t>(dist(gen));
}

int8_t random_int8() {
    static std::random_device rd;
    static std::mt19937 gen(rd());
    static std::uniform_int_distribution<int> dist(-2, 2);
    return static_cast<int8_t>(dist(gen));
}

int main(){
    // 輸入 feature map、卷積核和偏置
    uint8_t ifmap[IN_CHANNEL][IN_HEIGHT][IN_WIDTH];
    int8_t depthwise_filter[IN_CHANNEL][KERNEL_SIZE_H][KERNEL_SIZE_W];
    int32_t depthwise_result[IN_CHANNEL][OUT_HEIGHT][OUT_WIDTH];
    // int32_t depthwise_ipsum[IN_CHANNEL][OUT_HEIGHT][OUT_WIDTH];

    int32_t bias[OUT_CHANNEL];
    int8_t filter[OUT_CHANNEL][IN_CHANNEL][KERNEL_SIZE_H][KERNEL_SIZE_W];
    // int32_t ipsum[OUT_CHANNEL][OUT_HEIGHT][OUT_WIDTH];

    int8_t pointwise_filter[OUT_CHANNEL][IN_CHANNEL][1][1];
    // int32_t pointwise_ipsum[OUT_CHANNEL][OUT_HEIGHT][OUT_WIDTH];
    int32_t opsum[OUT_CHANNEL][OUT_HEIGHT][OUT_WIDTH];
    
    FILE* ifmap_file = fopen("ifmap.txt", "w+");
    FILE* filter_file = fopen("filter.txt", "w+");
    // #ifdef USE_DEPTHWISE
    //     FILE* point_ipsum_file = fopen("pointwise_ipsum.txt", "w+");
    //     FILE* depth_ipsum_file = fopen("depthwise_ipsum.txt", "w+");
    // #else
    //     FILE* ipsum_file = fopen("ipsum.txt", "w+");
 // // #endif
    FILE* bias_file = fopen("bias.txt", "w+");
    FILE* opsum_file = fopen("golden_output.txt", "w+");


    // // 用連續的數值初始化 ifmap, 從 -128 開始
    // int8_t value = -128;
    // for (int c = 0; c < IN_CHANNEL; c++){
    //     for (int row = 0; row < IN_HEIGHT; row++){
    //         for (int col = 0; col < IN_WIDTH; col++){
    //             ifmap[c][row][col] = value++;
    //         }
    //     }
    // }

    // ifmap 初始化
    for (int c = 0; c < IN_CHANNEL; c++) {
        for (int row = 0; row < IN_HEIGHT; row++) {
            for (int col = 0; col < IN_WIDTH; col++) {
                ifmap[c][row][col] = random_uint8();
            }
        }
    }
    

    #ifdef USE_DEPTHWISE
        // 初始化 depthwise_filter
        for (int c = 0; c < IN_CHANNEL; c++){
            for (int row = 0; row < KERNEL_SIZE_H; row++){
                for (int col = 0; col < KERNEL_SIZE_W; col++){
                    depthwise_filter[c][row][col] = random_int8();
                }
            }
        }

        // 初始化 pointwise_filter (1x1 卷積核)
        for (int oc = 0; oc < OUT_CHANNEL; oc++){
            for (int ic = 0; ic < IN_CHANNEL; ic++){
                pointwise_filter[oc][ic][0][0] = random_int8();
            }
        }
    #elif USE_LINEAR // M is 10
        for (int oc = 0; oc < OUT_CHANNEL; oc++){
            for (int ic = 0; ic < IN_CHANNEL; ic++){
                for (int row = 0; row < KERNEL_SIZE_H; row++){
                    for (int col = 0; col < KERNEL_SIZE_W; col++){
                        if(oc==10 || oc==11){ // for linear layer
                            filter[oc][ic][row][col] = 0; // 0 for linear layer
                        } else if(ic>1023){
                            filter[oc][ic][row][col] = 0; // 0 for linear layer
                        } else{
                            filter[oc][ic][row][col] = random_int8();
                        }
                    }
                }
            }
        }       
    #else
        // 初始化 filter (一般卷積核)
        for (int oc = 0; oc < OUT_CHANNEL; oc++){
            for (int ic = 0; ic < IN_CHANNEL; ic++){
                for (int row = 0; row < KERNEL_SIZE_H; row++){
                    for (int col = 0; col < KERNEL_SIZE_W; col++){
                        filter[oc][ic][row][col] = random_int8();
                    }
                }
            }
        }
    #endif

    
    // calculate psum golden
    #ifdef USE_DEPTHWISE
        // Depthwise convolution
        for (int c = 0; c < IN_CHANNEL; c++){
            for (int i = 0; i < OUT_HEIGHT; i++){
                for (int j = 0; j < OUT_WIDTH; j++){
                    depthwise_result[c][i][j] = 0;
                    for (int ki = 0; ki < KERNEL_SIZE_H; ki++){
                        for (int kj = 0; kj < KERNEL_SIZE_W; kj++){
                            depthwise_result[c][i][j] += (int32_t)ifmap[c][STRIDE * i + ki][STRIDE * j + kj] * depthwise_filter[c][ki][kj];
                        }
                    }
                    // depthwise_result[c][i][j] = sum + depthwise_ipsum[c][i][j];
                }
            }
        }

        // Pointwise convolution
        for (int oc = 0; oc < OUT_CHANNEL; oc++){
            for (int i = 0; i < OUT_HEIGHT; i++){
                for (int j = 0; j < OUT_WIDTH; j++){
                    opsum[oc][i][j] = 0;
                    for (int ic = 0; ic < IN_CHANNEL; ic++){
                        opsum[oc][i][j] += depthwise_result[ic][i][j] * pointwise_filter[oc][ic][0][0];
                    }
                    // opsum[oc][i][j] = sum + pointwise_ipsum[oc][i][j];
                }
            }
        }
    #else
        // General convolution
        for (int oc = 0; oc < OUT_CHANNEL; oc++){
            for (int i = 0; i < OUT_HEIGHT; i++){
                for (int j = 0; j < OUT_WIDTH; j++){
                    opsum[oc][i][j] = 0;
                    for (int ic = 0; ic < IN_CHANNEL; ic++){
                        for (int ki = 0; ki < KERNEL_SIZE_H; ki++){
                            for (int kj = 0; kj < KERNEL_SIZE_W; kj++){
                                opsum[oc][i][j] += ifmap[ic][STRIDE * i + ki][STRIDE * j + kj] * filter[oc][ic][ki][kj];
                            }
                        }
                    }
                    // opsum[oc][i][j] = sum + ipsum[oc][i][j];
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
    #endif

    // // 印出 bias
    // printf("bias:\n");
    // for (int oc = 0; oc < OUT_CHANNEL; oc++){
    //     printf("Output Channel %d:\n", oc);
    //     printf("%8d ", 0);
    //     printf("\n");
    // }

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


    // ifmap
    for (int row = 0; row < IN_HEIGHT; row++){
        for (int col = 0; col < IN_WIDTH; col++){
            for (int c = 0; c < IN_CHANNEL; c++){
                // fprintf(ifmap_file, "%d", uint8_t(ifmap[c][row][col] + (uint8_t)128));
                fprintf(ifmap_file, "%d", uint8_t(ifmap[c][row][col]));
                if(!(col == IN_WIDTH-1 && c == IN_CHANNEL-1 && row == IN_HEIGHT-1)){
                    fprintf(ifmap_file, ",");
                }
            }
        }
    }

    #ifdef USE_DEPTHWISE
        int point_num = 0;
        int pointwise_filter_num = 0;
        for (int m_over_pt = 0; m_over_pt < OUT_CHANNEL/(p*t) ; m_over_pt++){
            for (int tt = 0; tt < t; tt++){
                for (int row = 0; row < KERNEL_SIZE_H; row++){
                    for (int col = 0; col < KERNEL_SIZE_W; col++){
                        for (int c = 0; c < IN_CHANNEL; c++){
                            // printf("%d,", depthwise_filter[c][row][col]);
                            fprintf(filter_file, "%d,", depthwise_filter[c][row][col]);
                        }
                    }
                }
                for (int aa = 0; aa < 3; aa++){
                    for (int ic = 0; ic < IN_CHANNEL; ic++){
                        fprintf(filter_file, "%d,", pointwise_filter[pointwise_filter_num][ic][0][0]);
                        // printf("%d,", pointwise_filter[pointwise_filter_num][ic][0][0]);
                    }
                    for (int ic = 0; ic < IN_CHANNEL; ic++){
                        fprintf(filter_file, "%d,", pointwise_filter[pointwise_filter_num+1][ic][0][0]);
                        // printf( "%d,", pointwise_filter[pointwise_filter_num+1][ic][0][0]);
                    }
                    for (int ic = 0; ic < IN_CHANNEL; ic++){
                        fprintf(filter_file, "%d,", pointwise_filter[pointwise_filter_num+2][ic][0][0]);
                        // printf( "%d,", pointwise_filter[pointwise_filter_num+2][ic][0][0]);
                    }
                }
                for (int aa = 0; aa < 3; aa++){
                    for (int ic = 0; ic < IN_CHANNEL; ic++){
                        fprintf(filter_file, "%d,", pointwise_filter[pointwise_filter_num+3][ic][0][0]);
                        // printf( "%d,", pointwise_filter[pointwise_filter_num+3][ic][0][0]);
                    }
                    for (int ic = 0; ic < IN_CHANNEL; ic++){
                        fprintf(filter_file, "%d,", 0);
                        // printf( "%d,", 0);
                    }
                    for (int ic = 0; ic < IN_CHANNEL; ic++){
                        fprintf(filter_file, "%d,", 0);
                        // printf( "%d,", 0);
                    }
                }
                for (int aa = 0; aa < 3 && p == 4; aa++){
                    for (int ic = 0; ic < IN_CHANNEL; ic++){
                        fprintf(filter_file, "%d,", 0);
                        // printf( "%d,", 0);
                    }
                    for (int ic = 0; ic < IN_CHANNEL; ic++){
                        fprintf(filter_file, "%d,", 0);
                        // printf( "%d,", 0);
                    }
                    for (int ic = 0; ic < IN_CHANNEL; ic++){
                        fprintf(filter_file, "%d,", 0);
                        // printf( "%d,", 0);
                    }
                }
                pointwise_filter_num += 4;
            }
        }
    #elif USE_LINEAR
        // Linear 待補齊
        for(int oc =0; oc < OUT_CHANNEL; oc++){
            for (int ic = 0; ic < IN_CHANNEL; ic++){
                // if(oc == 10 || oc == 11){ // for linear layer
                //     fprintf(filter_file, "%d", 0);
                // } else {
                //     fprintf(filter_file, "%d", filter[oc][ic][0][0]);
                // }
                fprintf(filter_file, "%d", filter[oc][ic][0][0]);

                if(!(oc == OUT_CHANNEL-1 && ic == IN_CHANNEL-1)){
                    fprintf(filter_file, ",");
                }
            }
        }
    #else
        for (int oc = 0; oc < OUT_CHANNEL; oc++){
            for (int row = 0; row < KERNEL_SIZE_H; row++){
                for (int col = 0; col < KERNEL_SIZE_W; col++){
                    for (int ic = 0; ic < IN_CHANNEL; ic++){
                        if(oc == OUT_CHANNEL-1 && ic == IN_CHANNEL-1 && row == KERNEL_SIZE_H-1 && col == KERNEL_SIZE_W-1){
                            fprintf(filter_file, "%d", filter[oc][ic][row][col]);
                        } else {
                            fprintf(filter_file, "%d,", filter[oc][ic][row][col]);
                        }
                    }
                }
            }
        }
    #endif

    for (int oc = 0; oc < OUT_CHANNEL; oc++){
        fprintf(bias_file, "%d", 0);
        if(!(oc == OUT_CHANNEL-1)){
            fprintf(bias_file, ",");
        }
    }

    for (int row = 0; row < OUT_HEIGHT; row++){
        for (int col = 0; col < OUT_WIDTH; col++){
            for (int oc = 0; oc < OUT_CHANNEL; oc++){
                fprintf(opsum_file, "%d", opsum[oc][row][col]);
                if(!(col == OUT_WIDTH-1 && oc == OUT_CHANNEL-1 && row == OUT_HEIGHT-1)){
                    fprintf(opsum_file, ",");
                }
            }
        }
    }

    return 0;
}