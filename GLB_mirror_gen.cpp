#include<stdio.h>
#include<stdint.h>
#include <stdlib.h>
#include <string>
#include <fstream>
#include <vector>
#include <sstream>
#include <iomanip>
#include <iostream>
#include <stdexcept>
#define p 4
#define q 4
#define r 1
#define t 2
#define e 8
#define U 1

#define TB_LOCATION "./testbench/PE_array_test_data/depthwise_separable_tb0_format/"
#define IFMAP_FILE  TB_LOCATION "ifmap.txt"
#define FILTER_FILE TB_LOCATION "filter.txt"
#define IPSUM_FILE  TB_LOCATION "pointwise_ipsum.txt"
#define OPSUM_FILE  TB_LOCATION "opsum.txt"
#define BIAS_FILE  TB_LOCATION "bias.txt"

#define FILT_ROW 3
#define FILT_COL 3
#define IFMAP_COL 18
#define OFMAP_COL IFMAP_COL - FILT_ROW + U

// ifmap[row][col][in_channel]
// filter[out_channel][row][col][in_channel]
// psum[row][col][out_channel]
using namespace std;
void load_data(vector<vector<vector<int8_t>>>& ifmap, vector<vector<vector<vector<int8_t>>>>& filter,
               vector<vector<vector<int32_t>>>& ipsum, vector<vector<vector<int32_t>>>& opsum_golden,
            vector<int32_t>& bias) {
    // Implementation to load data into the vectors
    string line;
    string value;
    stringstream ss;

    ifstream ifmap_file(IFMAP_FILE);
    getline(ifmap_file, line);
    ifmap_file.close();
    ss.str(line);
    ss.clear();
    for (int i = 0; i < (e + FILT_ROW - 1); i++) {
        for (int j = 0; j < IFMAP_COL; j++) {
            for (int k = 0; k < q * r; k++) {
                if (getline(ss, value, ',')) {
                    ifmap[i][j][k] = stoi(value);
                }
            }
        }
    }
    ifstream filter_file(FILTER_FILE);
    getline(filter_file, line);
    filter_file.close();
    ss.str(line);
    ss.clear();
    for (int l = 0; l < p * t; l++) {
        for (int i = 0; i < FILT_ROW; i++) {
            for (int j = 0; j < FILT_COL; j++) {
                for (int k = 0; k < q * r; k++) {
                    if (getline(ss, value, ',')) {
                        filter[l][i][j][k] = stoi(value);
                    }
                }
            }
        }
    }
    ifstream ipsum_file(IPSUM_FILE);
    getline(ipsum_file, line);
    ipsum_file.close();
    ss.str(line);
    ss.clear();
    for (int i = 0; i < e; i++) {
        for (int j = 0; j < OFMAP_COL; j++) {
            for (int k = 0; k < p * t; k++) {
                if (getline(ss, value, ',')) {
                    ipsum[i][j][k] = stoi(value);
                }
            }
        }
    }
    ifstream opsum_golden_file(OPSUM_FILE);
    getline(opsum_golden_file, line);
    opsum_golden_file.close();
    ss.str(line);
    ss.clear();
    for (int i = 0; i < e; i++) {
        for (int j = 0; j < OFMAP_COL; j++) {
            for (int k = 0; k < p * t; k++) {
                if (getline(ss, value, ',')) {
                    opsum_golden[i][j][k] = stoi(value);
                }
            }
        }
    }

    ifstream bias_file(BIAS_FILE);
    getline(bias_file, line);
    bias_file.close();
    ss.str(line);
    ss.clear();
    for (int k = 0; k < p * t; k++) {
        if (getline(ss, value, ',')) {
            bias[k] = stoi(value);
        }
    }
}
int main(int argc, char const *argv[])
{
    vector<vector<vector<int8_t>>> ifmap((e + FILT_ROW - 1), vector<vector<int8_t>>(IFMAP_COL, vector<int8_t>(q * r)));
    vector<vector<vector<vector<int8_t>>>> filter(
        p * t, vector<vector<vector<int8_t>>>(FILT_ROW, vector<vector<int8_t>>(FILT_COL, vector<int8_t>(q * r))));
    vector<vector<vector<int32_t>>> ipsum(e, vector<vector<int>>(OFMAP_COL, vector<int32_t>(p * t)));
    vector<vector<vector<int32_t>>> opsum(e, vector<vector<int>>(OFMAP_COL, vector<int32_t>(p * t)));
    vector<vector<vector<int32_t>>> opsum_golden(e, vector<vector<int>>(OFMAP_COL, vector<int32_t>(p * t)));
    vector<int32_t> bias(p * t);
    FILE* GLB_file = fopen("./GLB_mirror.hex", "w+");
    load_data(ifmap, filter, ipsum, opsum_golden, bias);
    int num_bytes = 0;
    // ifmap
    for (int row = 0; row < (e + FILT_ROW - 1); row++){
        for (int col = 0; col < IFMAP_COL; col++){
            for (int ic = 0; ic < q * r; ic++){
                fprintf(GLB_file, "%02x\n", static_cast<uint8_t>(ifmap[row][col][ic]));
                num_bytes++;
            }
        }
    }
    //filter
    for (int oc = 0; oc < p * t; oc ++){
        for (int row = 0; row < FILT_ROW; row++){
            for (int col = 0; col < FILT_COL; col++){
                for (int ic = 0; ic < q * r; ic++){
                    fprintf(GLB_file, "%02x\n", static_cast<uint8_t>(filter[oc][row][col][ic]));
                    num_bytes++;
                }
            }
        }
    }
    // bias
    for (int oc = 0; oc < p * t; oc ++){
        fprintf(GLB_file,"%02x\n", static_cast<uint8_t>((bias[oc]<<24)>>24));
        fprintf(GLB_file,"%02x\n", static_cast<uint8_t>((bias[oc]<<16)>>24));
        fprintf(GLB_file,"%02x\n", static_cast<uint8_t>((bias[oc]<<8)>>24 ));
        fprintf(GLB_file,"%02x\n", static_cast<uint8_t>((bias[oc]<<0)>>24 ));
        num_bytes+=4;
    }
    // ipsum
    for (int row = 0; row < e; row++) {
        for (int col = 0; col < OFMAP_COL; col++) {
            for (int oc = 0; oc < p * t; oc++) {
                fprintf(GLB_file,"%02x\n", static_cast<uint8_t>((ipsum[row][col][oc]<<24)>>24));
                fprintf(GLB_file,"%02x\n", static_cast<uint8_t>((ipsum[row][col][oc]<<16)>>24));
                fprintf(GLB_file,"%02x\n", static_cast<uint8_t>((ipsum[row][col][oc]<<8)>>24 ));
                fprintf(GLB_file,"%02x", static_cast<uint8_t>((ipsum[row][col][oc]<<0)>>24 ));
                #ifdef DEBUG
                printf("%d: %x\n", ipsum[row][col][oc], static_cast<uint32_t>(ipsum[row][col][oc]));
                printf("%02x\n", static_cast<uint8_t>((ipsum[row][col][oc]<<24)>>24));
                printf("%02x\n", static_cast<uint8_t>((ipsum[row][col][oc]<<16)>>24));
                printf("%02x\n", static_cast<uint8_t>((ipsum[row][col][oc]<<8)>>24 ));
                printf("%02x\n", static_cast<uint8_t>((ipsum[row][col][oc]<<0)>>24 ));
                #endif
                if(!(oc == p * t - 1 && col == OFMAP_COL - 1 && row == e - 1)){
                    fprintf(GLB_file,"\n");
                }
                num_bytes+=4;
            }
        }
    }
    printf("Cost : %d bytes\n", num_bytes);
    if(num_bytes > 64 * 1024){
        throw std::runtime_error("Error! file size exceed 64 KiB!\n");
    }
    return 0;
}
