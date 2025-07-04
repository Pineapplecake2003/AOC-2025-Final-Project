#include <x86intrin.h>  //  _rdtsc()

#include "hardware_cpu.h"
#include "runtime.h"

int qconv2d_relu_maxpool_cpu(
    uint8_t *input_in_DRAM, int8_t *filter_in_DRAM, uint8_t *opsum_in_DRAM,
    int32_t *bias, uint32_t ofmap_len, uint32_t ifmap_len, uint32_t filter_len,
    // shape parameter
    uint32_t PAD, uint32_t U, uint32_t R, uint32_t S, uint32_t C, uint32_t M,
    uint32_t W, uint32_t H,
    uint32_t scale) {  // int32_t scale_factor: merge ifmap and weight and ofmap
                       // scale bit-shift
    int start_cycles = __rdtsc();
    conv_maxpooling(C, H, W, input_in_DRAM, M, C, R, S, filter_in_DRAM, bias,
                    PAD, opsum_in_DRAM, scale);
    int end_cycles = __rdtsc();
    return (end_cycles - start_cycles);
};

int qconv2d_relu_cpu(uint8_t *input_in_DRAM, int8_t *filter_in_DRAM,
                     uint8_t *opsum_in_DRAM, int32_t *bias, uint32_t ofmap_len,
                     uint32_t ifmap_len, uint32_t filter_len,
                     // shape parameter
                     uint32_t PAD, uint32_t U, uint32_t R, uint32_t S,
                     uint32_t C_F, uint32_t M, uint32_t W, uint32_t H,
                     uint32_t C_I,
                     uint32_t scale) {  // int32_t scale_factor: merge ifmap and
                                        // weight and ofmap scale bit-shift
    int start_cycles = __rdtsc();
    //convolution 分成input_C filter_C
    conv(C_I, H, W, input_in_DRAM, M, C_F, R, S, filter_in_DRAM, bias, PAD,
         opsum_in_DRAM, scale);
    int end_cycles = __rdtsc();
    return (end_cycles - start_cycles);
};

int qlinear_relu_cpu(uint8_t *input_in_DRAM, int8_t *filter_in_DRAM,
                     uint8_t *opsum_in_DRAM, int32_t *bias, uint32_t ofmap_len,
                     uint32_t ifmap_len, uint32_t filter_len,
                     uint32_t scale) {  // int32_t scale_factor: merge ifmap and
                                        // weight and ofmap scale bit-shift
    int start_cycles = __rdtsc();
    linear_relu(ifmap_len, ofmap_len, input_in_DRAM, opsum_in_DRAM,
                filter_in_DRAM, bias, scale);
    int end_cycles = __rdtsc();
    return (end_cycles - start_cycles);
};

int qlinear_cpu(uint8_t *input_in_DRAM, int8_t *filter_in_DRAM,
                uint8_t *opsum_in_DRAM, int32_t *bias, uint32_t ofmap_len,
                uint32_t ifmap_len, uint32_t filter_len,
                uint32_t scale) {  // int32_t scale_factor: merge ifmap and
                                   // weight and ofmap scale bit-shift
    int start_cycles = __rdtsc();
    linear(ifmap_len, ofmap_len, input_in_DRAM, opsum_in_DRAM, filter_in_DRAM,
           bias, scale);
    int end_cycles = __rdtsc();
    return (end_cycles - start_cycles);
};

int qglobal_avg_pool2d_cpu(uint8_t *input_in_DRAM, uint8_t *output_in_DRAM,
                            uint32_t C, uint32_t H, uint32_t W,
                            uint32_t scale) {  // int32_t scale_factor: merge
                                               // ifmap and ofmap scale bit-shift
    int start_cycles = __rdtsc();
    global_avg_pool2d(C, H, W, input_in_DRAM, output_in_DRAM, scale);
    int end_cycles = __rdtsc();
    return (end_cycles - start_cycles);
}

void quantize_cpu(float *input_in_DRAM, uint8_t *output_in_DRAM, uint32_t size,
                  uint32_t scale) {
    quantize(input_in_DRAM, output_in_DRAM, size, scale);
};

void dequantize_cpu(uint8_t *input_in_DRAM, float *output_in_DRAM,
                    uint32_t size, uint32_t scale) {
    dequantize(input_in_DRAM, output_in_DRAM, size, scale);
};