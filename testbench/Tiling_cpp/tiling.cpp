#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <iostream>
#include <iomanip> // for std::setw
using namespace std;
// ifmap [row][col][c]
// psum [row][col][oc]
// filter [row][col][ic][oc]
#define C 512
#define M 512
#define m 512
#define p 4
#define q 4
#define r 2
#define t 2
#define U 1
#define e 4
#define R 3
#define H 6 // H after padding
#define W 6 // W after padding
#define PAD 0
#define F ((W-3+2*PAD)/U+1)
#define E ((H-3+2*PAD)/U+1)

void print_ifmap_custom(uint8_t data[H][W][C], int h, int w, int c) {
    printf("ifmap:\n");
    for (int d3 = 0; d3 < c; d3++) {
        printf("Layer %d:\n", d3);
        for (int d2 = 0; d2 < h; d2++) {
            for (int d1 = 0; d1 < w; d1++) {
                printf("%4d ", data[d2][d1][d3]);
            }
            printf("\n");
        }
        printf("\n");
    }
}
void print_filter_custom(int8_t* data, int h, int w, int ic, int oc) {
    printf("filter:\n");
    for (int d4 = 0; d4 < oc; d4++) {
        printf("Filter %d:\n", d4);
        for (int d3 = 0; d3 < ic; d3++) {
            printf(" SubLayer %d:\n", d3);
            for (int d1 = 0; d1 < h; d1++) {
                for (int d2 = 0; d2 < w; d2++) {
                    int idx = d1 * w * ic * oc + d2 * ic * oc + d3 * oc + d4;
                    printf("%4d ", data[idx]);
                }
                printf("\n");
            }
            printf("\n");
        }
        printf("--------\n");
    }
}
void print_opsum_custom(int32_t* data, int h, int w, int c) {
    printf("opsum:\n");
    for (int d3 = 0; d3 < c; d3++) {
        printf("Layer %d:\n", d3);
        for (int d2 = 0; d2 < h; d2++) {
            for (int d1 = 0; d1 < w; d1++) {
                int idx = d2 * w * c + d1 * c + d3;
                printf("%8d ", data[idx]);
            }
            printf("\n");
        }
        printf("\n");
    }
}
void print_glb_int32_by_ch(uint8_t* glb, int base_addr, int h, int w, int c) {
    int total = h * w * c;
    int idx = 0;

    for (int ch = 0; ch < c; ++ch) {
        printf("Layer %d:\n", ch);
        for (int row = 0; row < h; ++row) {
            for (int col = 0; col < w; ++col) {
                int offset = ((row * w + col) * c + ch) * 4;  // row-major [row][col][ch]
                int addr = base_addr + offset;
                int32_t val = 0;
                val |= (int32_t)glb[addr + 0];
                val |= ((int32_t)glb[addr + 1]) << 8;
                val |= ((int32_t)glb[addr + 2]) << 16;
                val |= ((int32_t)glb[addr + 3]) << 24;
                printf("%8d ", val);
            }
            printf("\n");
        }
        printf("\n");
    }
}

void load_ifmap_from_file(const char* filename, uint8_t ifmap_buf[H][W][C]) {
    FILE* file = fopen(filename, "r");
    if (!file) {
        printf("Failed to open %s\n", filename);
        exit(1);
    }
    for (int h_idx = 0; h_idx < H; h_idx++) {
        for (int w_idx = 0; w_idx < W; w_idx++) {
            for (int c_idx = 0; c_idx < C; c_idx++) {
                int temp;
                fscanf(file, "%d,", &temp);
                ifmap_buf[h_idx][w_idx][c_idx] = (uint8_t)temp;
            }
        }
    }
    fclose(file);
}
void load_filter_from_file(const char* filename, int8_t filter_buf[R][R][C][M]) {
    FILE* file = fopen(filename, "r");
    if (!file) {
        printf("Failed to open %s\n", filename);
        exit(1);
    }
    // for (int r_idx = 0; r_idx < R; r_idx++) {
    //     for (int s_idx = 0; s_idx < R; s_idx++) {
    //         for (int c_idx = 0; c_idx < C; c_idx++) {
    //             for (int m_idx = 0; m_idx < M; m_idx++) {
    //                 int temp;
    //                 fscanf(file, "%d,", &temp);
    //                 filter_buf[r_idx][s_idx][c_idx][m_idx] = (int8_t)temp;
    //             }
    //         }
    //     }
    // }
    for (int m_idx = 0; m_idx < M; m_idx++){
        for (int r_idx = 0; r_idx < R; r_idx++) {
            for (int s_idx = 0; s_idx < R; s_idx++) {
                for (int c_idx = 0; c_idx < C; c_idx++) {
                    int temp;
                    fscanf(file, "%d,", &temp);
                    filter_buf[r_idx][s_idx][c_idx][m_idx] = (int8_t)temp;
                }
            }
        }
    }
    fclose(file);
}
void load_bias_from_file(const char* filename, int32_t bias_arr[M]) {
    FILE* file = fopen(filename, "r");
    if (!file) {
        printf("Failed to open %s\n", filename);
        exit(1);
    }
    for (int m_idx = 0; m_idx < M; m_idx++) {
        fscanf(file, "%d,", &bias_arr[m_idx]);
    }
    fclose(file);
}
void load_golden_output_from_file(const char* filename, int32_t golden_buf[E][F][M]) {
    FILE* file = fopen(filename, "r");
    if (!file) {
        printf("Failed to open %s\n", filename);
        exit(1);
    }
    for (int e_idx = 0; e_idx < E; e_idx++) {
        for (int f_idx = 0; f_idx < F; f_idx++) {
            for (int m_idx = 0; m_idx < M; m_idx++) {
                fscanf(file, "%d,", &golden_buf[e_idx][f_idx][m_idx]);
            }
        }
    }
    fclose(file);
}

void compare_with_golden(int32_t opsum[E][F][M], int32_t golden[E][F][M]) {
    int errors = 0;
    for (int E_idx = 0; E_idx < E; E_idx++) {
        for (int f = 0; f < F; f++) {
            for (int M_idx = 0; M_idx < M; M_idx++) {
                if (opsum[E_idx][f][M_idx] != golden[E_idx][f][M_idx]) {
                    printf("Mismatch at (%d,%d,%d): got %d, expected %d\n",
                        E_idx, f, M_idx, opsum[E_idx][f][M_idx], golden[E_idx][f][M_idx]);
                    errors++;
                }
                else{
                    printf("Match at (%d,%d,%d): got %d\n",
                        E_idx, f, M_idx, opsum[E_idx][f][M_idx]);
                }
            }
        }
    }
    if (errors == 0)
        printf("PASS: Output matches golden result.\n");
    else
        printf("FAIL: %d mismatches found.\n", errors);
}
void dla_compute(int glb_ifmap_addr, int glb_filter_addr,int glb_opsum_addr, uint8_t* glb){
    printf("DLA compute. opsum addr: %d\n", glb_opsum_addr);
    uint8_t ifmap_tile[U*(e-1)+R][W][q*r];
    int8_t filter_tile[3][3][q*r][p*t];
    int8_t depthwise_filter_tile[R][R][q*r];
    int8_t pointwise_filter_tile[1][1][q*r][p*t];
    int32_t psum_tile[e][F][p*t]={{{0}}};
    int psum_addr = glb_opsum_addr;
    for (int h = 0; h < e; h++) {
        for (int w = 0; w < F; w++) {
            for (int c = 0; c < p*t; c++) {
                int addr = psum_addr + ((h * F + w) * p*t + c) * 4;
                int32_t val = 0;
                val |= (int32_t)glb[addr + 0];
                val |= ((int32_t)glb[addr + 1]) << 8;
                val |= ((int32_t)glb[addr + 2]) << 16;
                val |= ((int32_t)glb[addr + 3]) << 24;
                psum_tile[h][w][c] = val;
            }
        }
    }

    int ifmap_addr = glb_ifmap_addr;
    for (int h = 0; h < U*(e-1)+R; h++) {
        for (int w = 0; w < W; w++) {
            for (int c = 0; c < q*r; c++) {
                int idx = ((h * W + w) * (q*r)) + c;
                ifmap_tile[h][w][c] = glb[ifmap_addr + idx];
            }
        }
    }
    //print_ifmap_custom(&ifmap_tile[0][0][0], U*(e-1)+R, W, q*r);
    //int ttt;
    ////cin >>ttt;

    int filter_addr = glb_filter_addr;
    // for (int r1 = 0; r1 < R; r1++) {
    //     for (int r2 = 0; r2 < R; r2++) {
    //         for (int ic = 0; ic < q*r; ic++) {
    //             for (int oc = 0; oc < p*t; oc++) {
    //                 int idx = (((r1 * R + r2) * (q*r) + ic) * (p*t)) + oc;
    //                 filter_tile[r1][r2][ic][oc] = (int8_t)glb[filter_addr + idx];
    //             }
    //         }
    //     }
    // }
    
    for (int oc = 0; oc < p * t; oc++) {
        for (int row = 0; row < R; row++) {
            for (int col = 0; col < R; col++) {
                for (int ic = 0; ic < q * r; ic++) {
                    filter_tile[row][col][ic][oc] = (int8_t)glb[filter_addr++];
                }
            }
        }
    }

    #ifdef USE_DEPTHWISE
        for (int row = 0; row < R; row++) {
            for (int col = 0; col < R; col++) {
                for (int ic = 0; ic < q * r; ic++) {
                    depthwise_filter_tile[row][col][ic] = filter_tile[row][col][ic][0];
                }
            }
        }
        // std::cout << "===== depthwise_filter_tile =====\n";
        // for (int c = 0; c < q * r; c++) {
        //     std::cout << "Channel " << c << ":\n";
        //     for (int row = 0; row < R; row++) {
        //         for (int col = 0; col < R; col++) {
        //             std::cout << std::setw(4) << (int)depthwise_filter_tile[row][col][c] << " ";
        //         }
        //         std::cout << "\n";
        //     }
        //     std::cout << "---------------------\n";
        // }
        /* assume p=4 */ 
        for (int tt = 0; tt < t; tt++) {
            int oc_t = p * tt;
            for (int ic = 0; ic < q * r; ic++) {
                pointwise_filter_tile[0][0][ic][oc_t] = filter_tile[0][0][ic][oc_t+1];
                pointwise_filter_tile[0][0][ic][oc_t+1] = filter_tile[0][1][ic][oc_t+1];
                pointwise_filter_tile[0][0][ic][oc_t+2] = filter_tile[0][2][ic][oc_t+1];
                pointwise_filter_tile[0][0][ic][oc_t+3] = filter_tile[0][0][ic][oc_t+2];
            }
        }
        // std::cout << "===== pointwise_filter_tile =====\n";
        // for (int oc = 0; oc < p * t; oc++) {
        //     std::cout << "Output Channel " << oc << ":\n";
        //     for (int ic = 0; ic < q * r; ic++) {
        //         std::cout << "  IC " << std::setw(2) << ic << ": " 
        //                   << std::setw(4) << (int)pointwise_filter_tile[0][0][ic][oc] << "\n";
        //     }
        //     std::cout << "---------------------\n";
        // }
    #endif

    //print_filter_custom(&filter_tile[0][0][0][0], R,R,q*r, p*t);
    ////cin >>ttt;
    #ifndef USE_DEPTHWISE
        for (int oc = 0; oc < p * t; oc++) {
            for (int ic = 0; ic < q * r; ic++) {                      // input channel
                for (int w = 0; w < F; w++) {                         // output width
                    for (int h = 0; h < e; h++) {                     // output height
                        for (int rr = 0; rr < R; rr++) {              // filter height
                            for (int s = 0; s < R; s++) {             // filter width
                                int h_in = h * U + rr;
                                int w_in = w * U + s;
                                psum_tile[h][w][oc] +=
                                    ifmap_tile[h_in][w_in][ic] *
                                    filter_tile[rr][s][ic][oc];
                            }
                        }
                    }
                }
            }
        }
    #else
        int depthwise_result_tile[e][F][q*r] = {{{0}}}; 
        for (int ic = 0; ic < q * r; ic++) {                      // input channel
            for (int w = 0; w < F; w++) {                         // output width
                for (int h = 0; h < e; h++) {                     // output height
                    for (int rr = 0; rr < R; rr++) {              // filter height
                        for (int s = 0; s < R; s++) {             // filter width
                            int h_in = h * U + rr;
                            int w_in = w * U + s;
                            depthwise_result_tile[h][w][ic] +=
                                ifmap_tile[h_in][w_in][ic] *
                                depthwise_filter_tile[rr][s][ic];
                        }
                    }
                }
            }
        }
        // std::cout << "===== depthwise_result_tile =====\n";
        // for (int ic = 0; ic < q * r; ic++) {
        //     std::cout << "Input Channel " << ic << ":\n";
        //     for (int h = 0; h < e; h++) {
        //         for (int w = 0; w < F; w++) {
        //             std::cout << std::setw(6) << depthwise_result_tile[h][w][ic] << " ";
        //         }
        //         std::cout << "\n";
        //     }
        //     std::cout << "-----------------------------\n";
        // }
        for (int oc = 0; oc < p * t; oc++) {
            for (int ic = 0; ic < q * r; ic++) {                      // input channel
                for (int w = 0; w < F; w++) {                         // output width
                    for (int h = 0; h < e; h++) {                     // output height
                        psum_tile[h][w][oc] +=
                            depthwise_result_tile[h][w][ic] *
                            pointwise_filter_tile[0][0][ic][oc];
                    }
                }
            }
        }
        // std::cout << "===== psum_tile =====\n";
        // for (int oc = 0; oc < p * t; oc++) {
        //     std::cout << "Output Channel " << oc << ":\n";
        //     for (int h = 0; h < e; h++) {
        //         for (int w = 0; w < F; w++) {
        //             std::cout << std::setw(8) << psum_tile[h][w][oc] << " ";
        //         }
        //         std::cout << "\n";
        //     }
        //     std::cout << "-----------------------------\n";
        // }
    #endif
    //print_opsum_custom(&psum_tile[0][0][0],e, F, p*t);
    ////cin >> ttt;

    int answer_addr = glb_opsum_addr;
    for (int row = 0; row < e; row++){
        for (int col = 0; col < F; col++){
            for (int c = 0; c < p*t; c++){
                int32_t val = psum_tile[row][col][c];
                glb[answer_addr++] = (uint8_t)((val >> 0)  & 0xFF);
                glb[answer_addr++] = (uint8_t)((val >> 8)  & 0xFF);
                glb[answer_addr++] = (uint8_t)((val >> 16) & 0xFF);
                glb[answer_addr++] = (uint8_t)((val >> 24) & 0xFF);
            }
        }
    }

    //printf("sdfsdfsdfsdf\n");
    //print_glb_int32_by_ch(glb, W * (U*(e-1)+R)* q*r + p*t *q*r*R*R + p*t*4, e, F, p*t);
    //print_glb_int32_by_ch(glb, W * (U*(e-1)+R)* q*r + p*t *q*r*R*R + p*t*4 + e*F*p*t*4, e, F, p*t);
}

void ifmap_to_glb(int c_start, int c_end, int w_start, int w_end, int h_start, int h_end, uint8_t ifmap[H][W][C], int glb_addr, uint8_t* glb) {
    uint8_t tile_ifmap[h_end - h_start+1][w_end-w_start+1][c_end - c_start+1];
    for (int row = h_start; row <= h_end; row++){
        for (int col = w_start; col <= w_end; col++){
            for (int c = c_start; c <= c_end; c++){
                tile_ifmap[row - h_start][col - w_start][c - c_start] = *&ifmap[row][col][c];
                glb[glb_addr++] = *&ifmap[row][col][c];
                // address : &ifmap[row][col][c]
                // printf("Address of ifmap[%d][%d][%d]: %p\n", row, col,c, &ifmap[c][row][col]);
            }
        }
    }
    //print_ifmap_custom(&tile_ifmap[0][0][0], h_end - h_start+1, w_end-w_start+1, c_end-c_start+1);
    //int ttt;
    //cin >> ttt;
}
void psum_to_dram(int c_start, int c_end,int w_start, int w_end,int h_start, int h_end,int32_t opsum[E][F][M],int glb_addr,uint8_t* glb) {
    int HH = h_end - h_start + 1;
    int WW = w_end - w_start + 1;
    int CC = c_end - c_start + 1;

    int32_t tile_psum[HH][WW][CC];
    for (int row = h_start; row <= h_end; row++){
        for (int col = w_start; col <= w_end; col++){
            for (int c = c_start; c <= c_end; c++){
                int32_t val = 
                    (int32_t) glb[glb_addr++] |
                    ((int32_t)glb[glb_addr++] << 8) |
                    ((int32_t)glb[glb_addr++] << 16) |
                    ((int32_t)glb[glb_addr++] << 24);
                opsum[row][col][c] = val;
                /*******************************IMPORTANT RESET GLB_IPSUM */
                glb_addr -= 4;
                glb[glb_addr++] = 0;
                glb[glb_addr++] = 0;
                glb[glb_addr++] = 0;
                glb[glb_addr++] = 0;
                /*******************************IMPORTANT RESET GLB_IPSUM */
            }
        }
    }
    //for (int c = c_start; c <= c_end; c++){
    //    for (int row = h_start; row <= h_end; row++){
    //        for (int col = w_start; col <= w_end; col++){
    //            printf("%5d", opsum[row][col][c]);
    //        }
    //        printf("\n");
    //    }
    //    printf("\n");
    //}
}
void filter_to_glb(int ic_start, int ic_end, int oc_start, int oc_end,int w_start, int w_end, int h_start, int h_end, int8_t filter[R][R][C][M], int glb_addr, uint8_t* glb) {
    int8_t tile_filter[h_end - h_start+1][w_end-w_start+1][ic_end - ic_start+1][oc_end - oc_start+1];
    
    for (int oc = oc_start; oc <= oc_end; oc++){
        for (int row = h_start; row <= h_end; row++){
            for (int col = w_start; col <= w_end; col++){
                for (int ic = ic_start; ic <= ic_end; ic++){
                    tile_filter [row - h_start][col - w_start][ic - ic_start][oc - oc_start]= *&filter[row][col][ic][oc];
                    glb[glb_addr++] = *&filter[row][col][ic][oc];
                    // address : &filter[row][col][ic][oc]
                    //printf("Address of opsum[%d][%d][%d][%d]: %p\n",  row, col,ic,oc, &filter[row][col][ic][oc]);
                }
            }
        }
    }
    //print_filter_custom(&tile_filter[0][0][0][0], h_end - h_start+1, w_end-w_start+1,ic_end - ic_start+1, oc_end - oc_start+1);
    //int ttt;
    //cin >> ttt;
    //exit(0);
}
void bias_to_glb(int start, int end,int32_t bias[M], int glb_addr, uint8_t* glb) {
    for (int i = start; i <= end; i++){
        glb[glb_addr++] = (*&bias[i] << 24) >> 24;
        glb[glb_addr++] = (*&bias[i] << 16) >> 24;
        glb[glb_addr++] = (*&bias[i] <<  8) >> 24;
        glb[glb_addr++] = (*&bias[i] <<  0) >> 24;
    }
    //exit(0);
}
int main(int argc, char const *argv[])
{
    uint8_t ifmap[H][W][C];
    int8_t filter[R][R][C][M];
    int32_t bias[M];
    int32_t opsum[E][F][M] = {{{0}}};
    int32_t golden_opsum[E][F][M];
    uint8_t glb[65535] = {0};

    load_ifmap_from_file("./conv7/ifmap.txt", ifmap);
    load_filter_from_file("./conv7/filter.txt", filter);
    load_bias_from_file("./conv7/bias.txt", bias);
    load_golden_output_from_file("./conv7/golden_output.txt", golden_opsum);

    int E_idx;
    int num = 0;
    for (int M_idx = m - 1; M_idx < M; M_idx += m){
        for (E_idx = e - 1; E_idx < E; E_idx += e){
            printf("E_idx: %d\n", E_idx);
            for (int c_idx = q * r - 1; c_idx < C; c_idx += q * r){
                    printf("ifmap [%2d:%2d][%2d:%2d][%2d:%2d]\n",
                        (E_idx - e + 1) * U, E_idx * U + 3 - 1,
                        0, W-1,
                        c_idx - q * r + 1, c_idx
                    );
                    ifmap_to_glb(
                        c_idx - q * r + 1, c_idx,
                        0, W-1,
                        (E_idx - e + 1) * U, E_idx * U + 3 - 1,
                        ifmap,
                        0,
                        glb
                    );
                    int current_pass_glb_opsum_addr = W * (U*(e-1)+R)* q*r + p*t *q*r*R*R + p*t*4;
                for (int m_idx = p * t - 1; m_idx < m; m_idx += p * t){
                    num++;
                    
                    // write filter to glb
                    printf("filter[%2d:%2d][%2d:%2d][%2d:%2d][%2d:%2d]\n",
                        0, 2, 0, 2,
                        c_idx - q * r + 1, c_idx,
                        M_idx - m + 1 + m_idx - p * t + 1, M_idx - m + 1 + m_idx
                    );
                    filter_to_glb(
                        c_idx - q * r + 1, c_idx,
                        M_idx - m + 1 + m_idx - p * t + 1, M_idx - m + 1 + m_idx,
                        0, 2, 0, 2,
                        filter,
                        W * (U*(e-1)+R)* q*r,
                        glb
                    );
                    
                    //  write bias to glb
                    printf("bias  [%2d:%2d]\n",
                        M_idx - m + 1 + m_idx - p * t + 1, M_idx - m + 1 + m_idx
                    );
                    bias_to_glb(
                        M_idx - m + 1 + m_idx - p * t + 1, M_idx - m + 1 + m_idx,
                        bias, W * (U*(e-1)+R)* q*r + p*t *q*r*R*R,
                        glb
                    );
                    
                    // wait dla
                    // while(!done){}
                    dla_compute(
                        0,                                                     // glb_ifmap_addr
                        W * (U * (e - 1) + R) * q * r,                         // glb_filter_addr
                        current_pass_glb_opsum_addr,                           // glb_opsum_addr
                        glb                                                    // glb pointer
                    );

                    printf("opsum [%2d:%2d][%2d:%2d][%2d:%2d] store in glb\n",
                        E_idx -  e + 1, E_idx, 
                        0, F - 1,
                        M_idx - m + 1 + m_idx - p * t + 1, M_idx - m + 1 + m_idx
                    );
                    printf("opsumaddr from %d to %d\n", current_pass_glb_opsum_addr, current_pass_glb_opsum_addr+e*F*p*t*4);
                    // cat next ipsum to current ipsum
                    current_pass_glb_opsum_addr += e*F*p*t*4;
                    printf("-------------------------\n");
                }
            }
            // write to dram
            printf("write e * F * m * 4 to dram\n");
            int current_pass_glb_opsum_addr = W * (U*(e-1)+R) * q*r + p*t *q*r*R*R + p*t*4;

            for (int m_idx = p * t-1; m_idx < m; m_idx += p * t) {

                psum_to_dram(
                    M_idx - m+1+ m_idx-p*t+1,  M_idx - m+1 + m_idx,
                    0, F - 1,
                    E_idx - e + 1, E_idx,
                    opsum,
                    current_pass_glb_opsum_addr,
                    glb
                );

                current_pass_glb_opsum_addr += e * F * p * t * 4;
            }

        }
        // TODO remain e
    }
    printf("%d\n", num);
    print_ifmap_custom(ifmap, W, H, C);
    print_filter_custom(&filter[0][0][0][0], R, R, C, M);

    printf("GOLDEN\n");
    print_opsum_custom(&golden_opsum[0][0][0], E, F, M);
    printf("opsum\n");
    print_opsum_custom(&opsum[0][0][0], E, F, M);
    compare_with_golden(opsum, golden_opsum);
    return 0;
}
