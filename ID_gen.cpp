#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <iostream>

using namespace std;

#define PE_ARRAY_H      6
#define PE_ARRAY_W      8

#define p               4
#define q               4
#define r               2
#define t               2
#define e               4

#define KERNEL_H        3

void map_para_analysis(int& t_H, int& t_W) {
    int merge_num = (e + PE_ARRAY_W - 1) / PE_ARRAY_W;

    int merged_PE_ARRAY_W = PE_ARRAY_W * merge_num;
    int merged_PE_ARRAY_H = PE_ARRAY_H / merge_num;

    int array_H_tile = merged_PE_ARRAY_H / KERNEL_H;
    int array_W_tile = merged_PE_ARRAY_W / e;

    t_H = array_H_tile / r;
    t_W = t / t_H;
    cout << "t_H: " << t_H << ", t_W: " << t_W << endl;
    
    return;
}


int main(){
    int t_H, t_W;
    map_para_analysis(t_H, t_W); 

    int row_block = 6 / (r * t_H);
    cout << "row_block: " << row_block << endl;

    int filter_XID = 0;
    cout << "filter_XID: " << endl;
    int first_col_idx = 0;
    for(int row_cnt=0; row_cnt < PE_ARRAY_H; row_cnt++){
        for(int col_cnt=0; col_cnt < PE_ARRAY_W; col_cnt++){
            #ifndef LINEAR
                if(col_cnt % e == 0 && col_cnt >= e){
                    filter_XID += KERNEL_H;
                }
                cout << filter_XID << ", ";
            #else
                // cout << filter_XID << ", ";
                if(col_cnt < t){
                    // filter_XID += KERNEL_H;
                    cout << filter_XID++ << ", ";
                }
                else{
                    filter_XID = 31;
                    cout << filter_XID << ", ";
                }
            #endif
        }
        cout << endl;
        #ifndef LINEAR
            if(row_cnt == row_block - 1) {
                filter_XID = 0;
                first_col_idx = 0;
            }
            else {
                filter_XID = first_col_idx + 1;
                first_col_idx++;
            }
        #else
            filter_XID = 0;
        #endif

    }
    int filter_YID = 0;
    cout << "filter_YID: " << endl;
    for(int row_cnt=0; row_cnt < PE_ARRAY_H; row_cnt++){
        #ifndef LINEAR
            if((r==2 || t_H==2) && row_cnt==KERNEL_H) {
                filter_YID++;
            }
            cout << filter_YID << ", ";
        #else
            cout << filter_YID++ << ", ";
        #endif
        cout << endl;
    }
    
    int ifmap_XID = 0;
    first_col_idx = 0;
    cout << "ifmap_XID: " << endl;
    for(int row_cnt=0; row_cnt < PE_ARRAY_H; row_cnt++){
        for(int col_cnt=0; col_cnt < PE_ARRAY_W; col_cnt++){
            #ifndef LINEAR
                if(col_cnt % e == 0 && col_cnt >= e){
                    ifmap_XID = first_col_idx;
                }
                else if(col_cnt != 0){
                    ifmap_XID += 1;
                }
            #else
                if(col_cnt < t){
                    ifmap_XID = 0;
                }
                else{
                    ifmap_XID = 31;
                }    
            #endif
            cout << ifmap_XID << ", ";
        }
        cout << endl;
        if(row_cnt == row_block - 1) {
            ifmap_XID = 0;
            first_col_idx = 0;
        }
        else {
            ifmap_XID = first_col_idx + 1;
            first_col_idx++;
        }
    }
    int ifmap_YID = 0;
    cout << "ifmap_YID: " << endl;
    for(int row_cnt=0; row_cnt < PE_ARRAY_H; row_cnt++){
        #ifndef LINEAR
            if(r==2 && row_cnt==KERNEL_H) {
                ifmap_YID++;
            }
            cout << ifmap_YID << ", ";
        #else
            cout << ifmap_YID++ << ", ";
            
        #endif
        cout << endl;
    }

    int ipsum_XID = 0;
    cout << "ipsum_XID: " << endl;
    for(int row_cnt=0; row_cnt < PE_ARRAY_H; row_cnt++){
        for(int col_cnt=0; col_cnt < PE_ARRAY_W; col_cnt++){
            #ifndef LINEAR
                if((r==1 && row_cnt==0) || (r==1 && row_cnt==3) || (r==2 && row_cnt==0)){
                    cout << ipsum_XID++ << ", ";
                }
            #else
                if(row_cnt==0 && col_cnt < t){
                    cout << ipsum_XID++ << ", ";
                }
            #endif
            else{
                cout << 31 << ", ";
            }
        }
        ipsum_XID = 0;
        cout << endl;
    }
    int ipsum_YID = 0;
    cout << "ipsum_YID: " << endl;
    for(int row_cnt=0; row_cnt < PE_ARRAY_H; row_cnt++){
        #ifndef LINEAR
            if((r==1 && row_cnt==0) || (r==1 && row_cnt==3) || (r==2 && row_cnt==0)){
                cout << ipsum_YID++ << ", ";
            }
        #else
            if(row_cnt==0){
                cout << 0 << ", ";
            }
        #endif
        else{
            cout << 7 << ", ";
        }
        cout << endl;
    }

    int opsum_XID = 0;
    cout << "opsum_XID: " << endl;
    for(int row_cnt=0; row_cnt < PE_ARRAY_H; row_cnt++){
        for(int col_cnt=0; col_cnt < PE_ARRAY_W; col_cnt++){
            #ifndef LINEAR
                if((r==1 && row_cnt==2) || (r==1 && row_cnt==5) || (r==2 && row_cnt==5)){
                    cout << opsum_XID++ << ", ";
                }
            #else
                if(row_cnt==PE_ARRAY_H-1 && col_cnt < t){
                    cout << opsum_XID++ << ", ";
                }
            #endif
            else{
                cout << 31 << ", ";
            }
        }
        opsum_XID = 0;
        cout << endl;
    }
    int opsum_YID = 0;
    cout << "opsum_YID: " << endl;
    for(int row_cnt=0; row_cnt < PE_ARRAY_H; row_cnt++){
        #ifndef LINEAR
            if((r==1 && row_cnt==2) || (r==1 && row_cnt==5) || (r==2 && row_cnt==5)){
                cout << opsum_YID++ << ", ";
            }
        #else
            if(row_cnt==PE_ARRAY_H-1){
                cout << 0 << ", ";
            }
        #endif
        else{
            cout << 7 << ", ";
        }
        cout << endl;
    }
}
