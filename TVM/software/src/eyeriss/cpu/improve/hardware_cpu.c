#include "hardware_cpu.h"
#include <immintrin.h>
#include <stdio.h>

void conv_maxpooling(uint32_t input_C, uint32_t input_H, uint32_t input_W,
                     uint8_t* activation, uint32_t filter_N, uint32_t filter_C,
                     uint32_t filter_H, uint32_t filter_W, int8_t* filter,
                     int32_t* bias, uint32_t padding, uint8_t* output,
                     uint32_t scale) {

    //! hint>>
    uint32_t output_H = input_H >> 1;
    uint32_t output_W = input_W >> 1;

    for (uint32_t n = 0; n < filter_N; n++) {
        for (uint32_t h = 0; h < output_H; h++) {
            for (uint32_t w = 0; w < output_W; w++) {
                int32_t temp_out = INT32_MIN;
                for (uint32_t m_h = 0; m_h < 2; m_h++) {
                    for (uint32_t m_w = 0; m_w < 2; m_w++) {
                        int32_t temp = bias[n];
                        uint32_t origin_h = h * 2 + m_h;
                        uint32_t origin_w = w * 2 + m_w;
                        for (uint32_t c = 0; c < filter_C; c++) {
                            for (uint32_t fh = 0; fh < filter_H; fh++) {
                                for (uint32_t fw = 0; fw < filter_W; fw++) {
                                    int32_t in_h =
                                        (int32_t)origin_h + (int32_t)fh;
                                    int32_t in_w =
                                        (int32_t)origin_w + (int32_t)fw;
                                    if (in_h != 0 && in_h < (input_H + 1) &&
                                        in_w != 0 && in_w < (input_W + 1)) {
                                        uint32_t activation_index =
                                            c * input_H * input_W +
                                            (in_h - 1) * input_W + (in_w - 1);
                                        uint32_t filter_index =
                                            n * filter_C * filter_H * filter_W +
                                            c * filter_H * filter_W +
                                            fh * filter_W + fw;
                                        int32_t activation_val =
                                            activation[activation_index] - 128;
                                        int32_t weight_val =
                                            filter[filter_index];
                                        temp += activation_val * weight_val;
                                    }
                                }
                            }
                        }
                        if (temp_out < temp) temp_out = temp;
                    }
                }
                uint32_t temp_out_relu = relu(temp_out);
                uint8_t temp_out_final = requant(temp_out_relu, scale);
                output[n * output_H * output_W + h * output_W + w] =
                    temp_out_final;
            }
        }
    }
    //! hint<<
};

void conv(uint32_t input_C, uint32_t input_H, uint32_t input_W,
          uint8_t* activation, uint32_t filter_N, uint32_t filter_C,
          uint32_t filter_H, uint32_t filter_W, int8_t* filter, int32_t* bias,
          uint32_t padding, uint8_t* output, uint32_t scale) {
    if (filter_C == 1 && filter_N == input_C) { //depthwise convolution
        for (uint32_t n = 0; n < filter_N; n++) {
            uint32_t c = n; // oc = ic
            for (uint32_t h = 0; h < input_H; h++) {
                for (uint32_t w = 0; w < input_W; w++) {
                    int32_t temp = bias[n];
                    for (uint32_t fh = 0; fh < filter_H; fh++) {
                        for (uint32_t fw = 0; fw < filter_W; fw++) {
                            int32_t in_h = (int32_t)h + (int32_t)fh - (int32_t)padding;
                            int32_t in_w = (int32_t)w + (int32_t)fw - (int32_t)padding;
                            if (in_h >= 0 && in_h < (int32_t)input_H && in_w >= 0 && in_w < (int32_t)input_W) {
                                uint32_t activation_index = c * input_H * input_W + in_h * input_W + in_w;
                                uint32_t filter_index = n * filter_H * filter_W + fh * filter_W + fw;
                                int32_t activation_val = (int32_t)activation[activation_index] - 128;
                                int32_t weight_val = filter[filter_index];
                                temp += activation_val * weight_val;
                            }
                        }
                    }
                    uint32_t temp_relu = relu(temp);
                    uint8_t temp_out = requant(temp_relu, scale);
                    output[n * input_H * input_W + h * input_W + w] = temp_out;
                }
            }
        }
    } else { //pointwise convolution & convolution
        for (uint32_t n = 0; n < filter_N; n++) {
            for (uint32_t h = 0; h < input_H; h++) {
                for (uint32_t w = 0; w < input_W; w++) {
                    int32_t temp = bias[n];
                    for (uint32_t c = 0; c < filter_C; c++) {
                        for (uint32_t fh = 0; fh < filter_H; fh++) {
                            for (uint32_t fw = 0; fw < filter_W; fw++) {
                                int32_t in_h = (int32_t)h + (int32_t)fh - (int32_t)padding;
                                int32_t in_w = (int32_t)w + (int32_t)fw - (int32_t)padding;
                                if (in_h >= 0 && in_h < (int32_t)input_H && in_w >= 0 && in_w < (int32_t)input_W) {
                                    uint32_t activation_index = c * input_H * input_W + in_h * input_W + in_w;
                                    uint32_t filter_index = n * filter_C * filter_H * filter_W + c * filter_H * filter_W + fh * filter_W + fw;
                                    int32_t activation_val = (int32_t)activation[activation_index] - 128;
                                    int32_t weight_val = filter[filter_index];
                                    temp += activation_val * weight_val;
                                }
                            }
                        }
                    }
                    uint32_t temp_relu = relu(temp);
                    uint8_t temp_out = requant(temp_relu, scale);
                    output[n * input_H * input_W + h * input_W + w] = temp_out;
                }
            }
        }
    }
}

void linear_relu(uint32_t input_size, uint32_t output_size, uint8_t* activation,
                 uint8_t* output, int8_t* filter, int32_t* bias,
                 uint32_t scale) {
    //! hint>>
    int32_t* activation_buffer = (int32_t*)malloc(input_size * sizeof(int32_t));
    if (!activation_buffer) exit(1);

    for (uint32_t j = 0; j < input_size; j++) {
        activation_buffer[j] = (int32_t)activation[j] - 128;
    }

    for (uint32_t i = 0; i < output_size; i++) {
        int32_t sum = bias[i];

        const int8_t* f = filter + i * input_size;

        uint32_t j = 0;

        // loop unrolling with 4
        for (; j + 3 < input_size; j += 4) {
            sum += activation_buffer[j] * f[j];
            sum += activation_buffer[j + 1] * f[j + 1];
            sum += activation_buffer[j + 2] * f[j + 2];
            sum += activation_buffer[j + 3] * f[j + 3];
        }
        // handle element which %4 !=0
        for (; j < input_size; j++) {
            sum += activation_buffer[j] * f[j];
        }
        output[i] = requant(relu(sum), scale);
    }
    free(activation_buffer);
    //! hint<<
};

void linear(uint32_t input_size, uint32_t output_size, uint8_t* activation,
            uint8_t* output, int8_t* filter, int32_t* bias, uint32_t scale) {
    //! hint>>
    int32_t* activation_buffer = (int32_t*)malloc(input_size * sizeof(int32_t));

    if (!activation_buffer) exit(1);

    for (uint32_t j = 0; j < input_size; j++) {
        activation_buffer[j] = (int32_t)activation[j] - 128;
    }

    for (uint32_t i = 0; i < output_size; i++) {
        int32_t sum = bias[i];

        const int8_t* f = filter + i * input_size;

        uint32_t j = 0;

        // loop unrolling with 4
        for (; j + 3 < input_size; j += 4) {
            sum += activation_buffer[j] * f[j];
            sum += activation_buffer[j + 1] * f[j + 1];
            sum += activation_buffer[j + 2] * f[j + 2];
            sum += activation_buffer[j + 3] * f[j + 3];
        }
        // handle element which %4 !=0
        for (; j < input_size; j++) {
            sum += activation_buffer[j] * f[j];
        }
        output[i] = requant(sum, scale);
    }
    free(activation_buffer);
    //! hint<<
};

//alteration
void global_avg_pool2d(uint32_t batch, uint32_t height, uint32_t width,
                       uint32_t channels, uint8_t* activation, uint8_t* output,
                       uint32_t scale) {
    printf("Global Average Pooling: batch=%d, height=%d, width=%d, channels=%d\n",
           batch, height, width, channels);
    uint32_t* sums = (uint32_t*)malloc(channels * sizeof(uint32_t));

    uint32_t spatial_size = height * width;

    for (uint32_t n = 0; n < batch; n++) {
        memset(sums, 0, channels * sizeof(uint32_t));

        uint32_t input_base = n * height * width * channels;
        for (uint32_t h = 0; h < height; h++) {
            for (uint32_t w = 0; w < width; w++) {
                uint32_t base_idx = input_base + (h * width + w) * channels;
                uint32_t c = 0;
                for (; c + 3 < channels; c += 4) {
                    sums[c] += (uint32_t)activation[base_idx + c] - 128;
                    sums[c + 1] += (uint32_t)activation[base_idx + c + 1] - 128;
                    sums[c + 2] += (uint32_t)activation[base_idx + c + 2] - 128;
                    sums[c + 3] += (uint32_t)activation[base_idx + c + 3] - 128;
                }
                for (; c < channels; c++) {
                    sums[c] += (uint32_t)activation[base_idx + c] - 128;
                }
            }
        }

        uint32_t output_base = n * channels;
        for (uint32_t c = 0; c < channels; c++) {
            uint32_t avg = sums[c] / spatial_size;
            output[output_base + c] = requant(avg, scale);
        }
    }

    free(sums);
    printf("Global Average Pooling completed.\n");
}

void quantize(float* input_in_DRAM, uint8_t* output_in_DRAM, uint32_t size,
              uint32_t scale) {
    float fp_scale = 1;
    for (uint32_t i = 0; i < scale; i++) {
        fp_scale *= 2;
    }
    for (uint32_t i = 0; i < size; i++) {
        float t = input_in_DRAM[i] * fp_scale;
        int32_t temp = (int32_t)t + 128;
        // clamp to 0 ~ 255
        if (temp < 0) {
            output_in_DRAM[i] = 0;
        } else if (temp > 255)
            output_in_DRAM[i] = 255;
        else
            output_in_DRAM[i] = (uint8_t)temp;
    }
};

void dequantize(uint8_t* input_in_DRAM, float* output_in_DRAM, uint32_t size,
                uint32_t scale) {
    float fp_scale = 1;
    for (uint32_t i = 0; i < scale; i++) {
        fp_scale *= 2;
    }
    for (uint32_t i = 0; i < size; i++) {
        float temp = *(input_in_DRAM + i) - 128;
        *(output_in_DRAM + i) = temp / fp_scale;
    }
};