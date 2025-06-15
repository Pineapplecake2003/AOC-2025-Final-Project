#include <verilated.h>
#include <verilated_vcd_c.h>
#include "VTiling.h"
#include <fstream>
#include <iostream>
#include <vector>
#include <cassert>
using namespace std;

#define DRAM_SIZE 65536
#define GLB_SIZE  65536

#define IFMAP_SIZE (34*34*6)
#define FILTER_SIZE (3*3*6*8)
#define BIAS_SIZE (8*4)
#define OPSUM_SIZE (16*16*8*4)

uint8_t dram[DRAM_SIZE] = {0};
uint8_t glb[GLB_SIZE] = {0};

int max_cycles = 100;
int cycles = 0;

// 讀txt到dram
void load_txt(const char* fname, uint8_t* mem, int base, int bytes) {
    ifstream fin(fname);
    if (!fin) {
        cerr << "Cannot open " << fname << endl;
        exit(1);
    }
    int val;
    char comma;
    for (int i = 0; i < bytes; ++i) {
        fin >> val;
        if (fin.peek() == ',') fin >> comma;
        mem[base + i] = val & 0xFF;
    }
    fin.close();
}

// 讀txt到vector<int32_t>（for golden output）
void load_txt32(const char* fname, vector<int32_t>& vec, int count) {
    ifstream fin(fname);
    if (!fin) {
        cerr << "Cannot open " << fname << endl;
        exit(1);
    }
    int val;
    char comma;
    for (int i = 0; i < count; ++i) {
        fin >> val;
        if (fin.peek() == ',') fin >> comma;
        vec[i] = val;
    }
    fin.close();
}

// 取出GLB的opsum結果
void get_glb_opsum(uint8_t* glb, int base, vector<int32_t>& out, int count) {
    for (int i = 0; i < count; ++i) {
        int32_t v = 0;
        v |= glb[base + i*4 + 0];
        v |= glb[base + i*4 + 1] << 8;
        v |= glb[base + i*4 + 2] << 16;
        v |= glb[base + i*4 + 3] << 24;
        out[i] = v;
    }
}

// 比對
bool check_result(const vector<int32_t>& glb, const vector<int32_t>& golden) {
    int err = 0;
    for (size_t i = 0; i < glb.size(); ++i) {
        if (glb[i] != golden[i]) {
            cout << "Mismatch at " << i << ": got " << glb[i] << ", expect " << golden[i] << endl;
            ++err;
        }
    }
    if (err == 0) cout << "PASS!" << endl;
    else cout << "FAIL: " << err << " errors" << endl;
    return err == 0;
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    VTiling* dut = new VTiling;

    // 波形初始化
    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC;
    dut->trace(tfp, 99);
    tfp->open("wave.vcd");
    vluint64_t main_time = 0;

    // 1. 載入資料到 DRAM
    load_txt("ifmap.txt",   dram, 0, IFMAP_SIZE);
    load_txt("filter.txt",  dram, 4096, FILTER_SIZE);
    load_txt("bias.txt",    dram, 8192, BIAS_SIZE);

    vector<int32_t> golden(16*16*8);
    load_txt32("golden_output.txt", golden, 16*16*8);

    // 2. 設定參數
    dut->clk = 0;
    dut->rst = 1;
    dut->start = 0;
    dut->mapping_param = 0x000480D9;
    dut->shape_param1  = 0x024C1808;
    dut->shape_param2  = 0x00002222;
    dut->dram_ifmap_base_addr   = 0;
    dut->dram_filter_base_addr  = 4096;
    dut->dram_bias_base_addr    = 8192;
    dut->dram_opsum_base_addr   = 12288;
    dut->glb_ifmap_base_addr    = 0;
    dut->glb_filter_base_addr   = 2048;
    dut->glb_bias_base_addr     = 4096;
    dut->glb_opsum_base_addr    = 6144;

    // 3. 初始化GLB
    for (int i = 0; i < GLB_SIZE; ++i) glb[i] = 0;

    // 4. 模擬時脈
    int cycles = 0;
    auto eval = [&]() {
        dut->eval();
        tfp->dump(main_time);
        main_time++;
        ++cycles;
    };

    // 5. 連接DRAM/GLB
    dut->dram_r_data = 0;
    dut->glb_r_data = 0;
    for (int i = 0; i < 10; ++i) { // reset
        dut->clk = !dut->clk; eval();
    }
    dut->rst = 0;

    // 6. 開始搬運流程
    bool done = false;
    int tile_cnt = 0;
    while (!done && tile_cnt < 10 && cycles < max_cycles) { // 最多10個tile
        // 拉高start
        dut->start = 1;
        dut->clk = !dut->clk; eval();
        dut->clk = !dut->clk; eval();
        dut->start = 0;

        // 等待finish
        while (!dut->finish) {
            // DRAM讀
            if (dut->dram_addr < DRAM_SIZE)
                dut->dram_r_data = dram[dut->dram_addr] | (dram[dut->dram_addr+1]<<8) | (dram[dut->dram_addr+2]<<16) | (dram[dut->dram_addr+3]<<24);
            // GLB讀
            if (dut->glb_r_addr < GLB_SIZE)
                dut->glb_r_data = glb[dut->glb_r_addr] | (glb[dut->glb_r_addr+1]<<8) | (glb[dut->glb_r_addr+2]<<16) | (glb[dut->glb_r_addr+3]<<24);
            // GLB寫
            if (dut->glb_we && dut->glb_w_addr < GLB_SIZE) {
                glb[dut->glb_w_addr+0] = dut->glb_w_data & 0xFF;
                glb[dut->glb_w_addr+1] = (dut->glb_w_data >> 8) & 0xFF;
                glb[dut->glb_w_addr+2] = (dut->glb_w_data >> 16) & 0xFF;
                glb[dut->glb_w_addr+3] = (dut->glb_w_data >> 24) & 0xFF;
            }
            // DRAM寫
            if (dut->dram_we && dut->dram_addr < DRAM_SIZE) {
                dram[dut->dram_addr+0] = dut->dram_w_data & 0xFF;
                dram[dut->dram_addr+1] = (dut->dram_w_data >> 8) & 0xFF;
                dram[dut->dram_addr+2] = (dut->dram_w_data >> 16) & 0xFF;
                dram[dut->dram_addr+3] = (dut->dram_w_data >> 24) & 0xFF;
            }
            dut->clk = !dut->clk; eval();
        }
        // finish 拉高時再多跑一拍
        dut->clk = !dut->clk; eval();

        // 7. 比對GLB與golden
        vector<int32_t> glb_out(16*16*8);
        get_glb_opsum(glb, 6144, glb_out, 16*16*8);
        cout << "Tile " << tile_cnt << ": ";
        check_result(glb_out, golden);

        cycles++;
        tile_cnt++;
        // 若只要搬一次就 break
        done = true;
    }

    cout << "All test done." << endl;
    tfp->close();
    delete dut;
    return 0;
}