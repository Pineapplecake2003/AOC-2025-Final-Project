#include <iostream>
#include <fstream>

#include <Vtop.h>
#include "verilated_vcd_c.h"
#include "data.h"

using namespace std;

uint64_t sim_time = 0;
VerilatedVcdC* fp = new VerilatedVcdC();
ofstream log_file("./logs/output.log");

#define clock_step(dut, signal)         \
    dut->signal = 1;                    \
    dut->eval(); /* falling edge */     \
    fp->dump(sim_time++);               \
    dut->signal = 0;                    \
    dut->eval(); /* rising edge */      \
    fp->dump(sim_time++);

#define set_signal(dut, signal, value) \
    (signal) = (value);                \
    (dut)->eval();

#define mem_ifmap_addr  0x00000000
#define mem_filter_addr 0x00001000
#define mem_psum_addr   0x00002000

#define glb_ifmap_addr  0x00000000
#define glb_filter_addr 0x00006000
#define glb_psum_addr   0x00007000

#define max_cycle 100000

uint32_t ifmap_answer[192];

void handle_dma_read(Vtop *dut){
    // jump to READ state
    clock_step(dut, clk);

    // get read info
    uint32_t len = dut->mem_length;
    uint32_t read_addr = dut->mem_read_addr;

    switch(read_addr){
        case mem_ifmap_addr:
            for(int i = 0; i < len; i++){
                dut->mem_read_data = activation_flat_array[i];
                dut->eval();
                clock_step(dut, clk);
                clock_step(dut, clk);
            }
            break;
    }
}

void read_glb(Vtop *dut){
    for(int i = 0; i < 192; i++){
        dut->glb_r_addr = mem_ifmap_addr + i * 4;
        clock_step(dut, clk);
        log_file << hex << i << ": "<< dec << dut->glb_dout << endl;
        clock_step(dut, clk);
    }
}

int main(){
    /* Configure Verilator to trace the signals */
    Verilated::traceEverOn(true);

    /* Initilize the DUT and waveform file to dump */
    auto dut = new Vtop;
    dut->trace(fp, 99);
    fp->open("wave.vcd");

    int cycle = 0;
    /* Simulation start */

    // rst
    dut->rst = 1;
    clock_step(dut, clk);
    dut->rst = 0;

    // sim controller
    dut->start = 1;
    dut->src_addr = mem_ifmap_addr;
    dut->dst_addr = glb_ifmap_addr;
    dut->length = 192;
    clock_step(dut, clk);

    dut->start = 0;
    // sim hal
    while(!dut->notify_host){
        clock_step(dut, clk);
        if(cycle > max_cycle){
            log_file << "time out !!!" << endl;
            break;
        }
        cycle++;
    }

    handle_dma_read(dut);
    read_glb(dut);

    fp->close();
    log_file.close();
    delete fp;
    return 0;
    /* Simulation end */
}