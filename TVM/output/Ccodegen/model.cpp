#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include "weight.h"
#include "runtime.h"

void tvmgen_default_DLA_main_0_(
float* DLA_0_i0, 
float* out0) {
  
  uint8_t* buf_0 = (uint8_t*)malloc(12288);
  
  quantize_cpu(
    DLA_0_i0, buf_0,
    3072,
    5
  );

  uint8_t* buf_1 = (uint8_t*)malloc(131072);
  
#ifndef CPU_ONLY
  qconv2d_relu(
#else
  qconv2d_relu_cpu(
#endif
    buf_0, (int8_t*)tvmgen_default_DLA_main_0_const_0, buf_1,
    (int32_t*)tvmgen_default_DLA_main_0_const_1, 32768, 3072, 864,
#ifndef CPU_ONLY
    32, DEFAULT_e, DEFAULT_p, DEFAULT_q, DEFAULT_r, DEFAULT_t,
#endif
    1, 1, 3, 3,
    3, 32, 32, 32,3,
    7
  );

  free(buf_0);
  uint8_t* buf_2 = (uint8_t*)malloc(131072);
  
#ifndef CPU_ONLY
  qconv2d_relu(
#else
  qconv2d_relu_cpu(
#endif
    buf_1, (int8_t*)tvmgen_default_DLA_main_0_const_2, buf_2,
    (int32_t*)tvmgen_default_DLA_main_0_const_3, 32768, 32768, 288,
#ifndef CPU_ONLY
    32, DEFAULT_e, DEFAULT_p, DEFAULT_q, DEFAULT_r, DEFAULT_t,
#endif
    1, 1, 3, 3,
    1, 32, 32, 32,32,
    7
  );

  free(buf_1);
  uint8_t* buf_3 = (uint8_t*)malloc(262144);
  
#ifndef CPU_ONLY
  qconv2d_relu(
#else
  qconv2d_relu_cpu(
#endif
    buf_2, (int8_t*)tvmgen_default_DLA_main_0_const_4, buf_3,
    (int32_t*)tvmgen_default_DLA_main_0_const_5, 65536, 32768, 2048,
#ifndef CPU_ONLY
    64, DEFAULT_e, DEFAULT_p, DEFAULT_q, DEFAULT_r, DEFAULT_t,
#endif
    0, 1, 1, 1,
    32, 64, 32, 32,32,
    7
  );

  free(buf_2);
  uint8_t* buf_4 = (uint8_t*)malloc(65536);
  
#ifndef CPU_ONLY
  qconv2d_relu(
#else
  qconv2d_relu_cpu(
#endif
    buf_3, (int8_t*)tvmgen_default_DLA_main_0_const_6, buf_4,
    (int32_t*)tvmgen_default_DLA_main_0_const_7, 16384, 65536, 576,
#ifndef CPU_ONLY
    64, DEFAULT_e, DEFAULT_p, DEFAULT_q, DEFAULT_r, DEFAULT_t,
#endif
    1, 1, 3, 3,
    1, 64, 32, 32,64,
    8
  );

  free(buf_3);
  uint8_t* buf_5 = (uint8_t*)malloc(131072);
  
#ifndef CPU_ONLY
  qconv2d_relu(
#else
  qconv2d_relu_cpu(
#endif
    buf_4, (int8_t*)tvmgen_default_DLA_main_0_const_8, buf_5,
    (int32_t*)tvmgen_default_DLA_main_0_const_9, 32768, 16384, 8192,
#ifndef CPU_ONLY
    128, DEFAULT_e, DEFAULT_p, DEFAULT_q, DEFAULT_r, DEFAULT_t,
#endif
    0, 1, 1, 1,
    64, 128, 16, 16,64,
    8
  );

  free(buf_4);
  uint8_t* buf_6 = (uint8_t*)malloc(131072);
  
#ifndef CPU_ONLY
  qconv2d_relu(
#else
  qconv2d_relu_cpu(
#endif
    buf_5, (int8_t*)tvmgen_default_DLA_main_0_const_10, buf_6,
    (int32_t*)tvmgen_default_DLA_main_0_const_11, 32768, 32768, 1152,
#ifndef CPU_ONLY
    128, DEFAULT_e, DEFAULT_p, DEFAULT_q, DEFAULT_r, DEFAULT_t,
#endif
    1, 1, 3, 3,
    1, 128, 16, 16,128,
    8
  );

  free(buf_5);
  uint8_t* buf_7 = (uint8_t*)malloc(131072);
  
#ifndef CPU_ONLY
  qconv2d_relu(
#else
  qconv2d_relu_cpu(
#endif
    buf_6, (int8_t*)tvmgen_default_DLA_main_0_const_12, buf_7,
    (int32_t*)tvmgen_default_DLA_main_0_const_13, 32768, 32768, 16384,
#ifndef CPU_ONLY
    128, DEFAULT_e, DEFAULT_p, DEFAULT_q, DEFAULT_r, DEFAULT_t,
#endif
    0, 1, 1, 1,
    128, 128, 16, 16,128,
    8
  );

  free(buf_6);
  uint8_t* buf_8 = (uint8_t*)malloc(32768);
  
#ifndef CPU_ONLY
  qconv2d_relu(
#else
  qconv2d_relu_cpu(
#endif
    buf_7, (int8_t*)tvmgen_default_DLA_main_0_const_14, buf_8,
    (int32_t*)tvmgen_default_DLA_main_0_const_15, 8192, 32768, 1152,
#ifndef CPU_ONLY
    128, DEFAULT_e, DEFAULT_p, DEFAULT_q, DEFAULT_r, DEFAULT_t,
#endif
    1, 1, 3, 3,
    1, 128, 16, 16,128,
    8
  );

  free(buf_7);
  uint8_t* buf_9 = (uint8_t*)malloc(65536);
  
#ifndef CPU_ONLY
  qconv2d_relu(
#else
  qconv2d_relu_cpu(
#endif
    buf_8, (int8_t*)tvmgen_default_DLA_main_0_const_16, buf_9,
    (int32_t*)tvmgen_default_DLA_main_0_const_17, 16384, 8192, 32768,
#ifndef CPU_ONLY
    256, DEFAULT_e, DEFAULT_p, DEFAULT_q, DEFAULT_r, DEFAULT_t,
#endif
    0, 1, 1, 1,
    128, 256, 8, 8,128,
    8
  );

  free(buf_8);
  uint8_t* buf_10 = (uint8_t*)malloc(65536);
  
#ifndef CPU_ONLY
  qconv2d_relu(
#else
  qconv2d_relu_cpu(
#endif
    buf_9, (int8_t*)tvmgen_default_DLA_main_0_const_18, buf_10,
    (int32_t*)tvmgen_default_DLA_main_0_const_19, 16384, 16384, 2304,
#ifndef CPU_ONLY
    256, DEFAULT_e, DEFAULT_p, DEFAULT_q, DEFAULT_r, DEFAULT_t,
#endif
    1, 1, 3, 3,
    1, 256, 8, 8,256,
    8
  );

  free(buf_9);
  uint8_t* buf_11 = (uint8_t*)malloc(65536);
  
#ifndef CPU_ONLY
  qconv2d_relu(
#else
  qconv2d_relu_cpu(
#endif
    buf_10, (int8_t*)tvmgen_default_DLA_main_0_const_20, buf_11,
    (int32_t*)tvmgen_default_DLA_main_0_const_21, 16384, 16384, 65536,
#ifndef CPU_ONLY
    256, DEFAULT_e, DEFAULT_p, DEFAULT_q, DEFAULT_r, DEFAULT_t,
#endif
    0, 1, 1, 1,
    256, 256, 8, 8,256,
    8
  );

  free(buf_10);
  uint8_t* buf_12 = (uint8_t*)malloc(16384);
  
#ifndef CPU_ONLY
  qconv2d_relu(
#else
  qconv2d_relu_cpu(
#endif
    buf_11, (int8_t*)tvmgen_default_DLA_main_0_const_22, buf_12,
    (int32_t*)tvmgen_default_DLA_main_0_const_23, 4096, 16384, 2304,
#ifndef CPU_ONLY
    256, DEFAULT_e, DEFAULT_p, DEFAULT_q, DEFAULT_r, DEFAULT_t,
#endif
    1, 1, 3, 3,
    1, 256, 8, 8,256,
    8
  );

  free(buf_11);
  uint8_t* buf_13 = (uint8_t*)malloc(32768);
  
#ifndef CPU_ONLY
  qconv2d_relu(
#else
  qconv2d_relu_cpu(
#endif
    buf_12, (int8_t*)tvmgen_default_DLA_main_0_const_24, buf_13,
    (int32_t*)tvmgen_default_DLA_main_0_const_25, 8192, 4096, 131072,
#ifndef CPU_ONLY
    512, DEFAULT_e, DEFAULT_p, DEFAULT_q, DEFAULT_r, DEFAULT_t,
#endif
    0, 1, 1, 1,
    256, 512, 4, 4,256,
    8
  );

  free(buf_12);
  uint8_t* buf_14 = (uint8_t*)malloc(32768);
  
#ifndef CPU_ONLY
  qconv2d_relu(
#else
  qconv2d_relu_cpu(
#endif
    buf_13, (int8_t*)tvmgen_default_DLA_main_0_const_26, buf_14,
    (int32_t*)tvmgen_default_DLA_main_0_const_27, 8192, 8192, 4608,
#ifndef CPU_ONLY
    512, DEFAULT_e, DEFAULT_p, DEFAULT_q, DEFAULT_r, DEFAULT_t,
#endif
    1, 1, 3, 3,
    1, 512, 4, 4,512,
    8
  );

  free(buf_13);
  uint8_t* buf_15 = (uint8_t*)malloc(32768);
  
#ifndef CPU_ONLY
  qconv2d_relu(
#else
  qconv2d_relu_cpu(
#endif
    buf_14, (int8_t*)tvmgen_default_DLA_main_0_const_28, buf_15,
    (int32_t*)tvmgen_default_DLA_main_0_const_29, 8192, 8192, 262144,
#ifndef CPU_ONLY
    512, DEFAULT_e, DEFAULT_p, DEFAULT_q, DEFAULT_r, DEFAULT_t,
#endif
    0, 1, 1, 1,
    512, 512, 4, 4,512,
    8
  );

  free(buf_14);
  uint8_t* buf_16 = (uint8_t*)malloc(8192);
  
#ifndef CPU_ONLY
  qconv2d_relu(
#else
  qconv2d_relu_cpu(
#endif
    buf_15, (int8_t*)tvmgen_default_DLA_main_0_const_30, buf_16,
    (int32_t*)tvmgen_default_DLA_main_0_const_31, 2048, 8192, 4608,
#ifndef CPU_ONLY
    512, DEFAULT_e, DEFAULT_p, DEFAULT_q, DEFAULT_r, DEFAULT_t,
#endif
    1, 1, 3, 3,
    1, 512, 4, 4,512,
    8
  );

  free(buf_15);
  uint8_t* buf_17 = (uint8_t*)malloc(16384);
  
#ifndef CPU_ONLY
  qconv2d_relu(
#else
  qconv2d_relu_cpu(
#endif
    buf_16, (int8_t*)tvmgen_default_DLA_main_0_const_32, buf_17,
    (int32_t*)tvmgen_default_DLA_main_0_const_33, 4096, 2048, 524288,
#ifndef CPU_ONLY
    1024, DEFAULT_e, DEFAULT_p, DEFAULT_q, DEFAULT_r, DEFAULT_t,
#endif
    0, 1, 1, 1,
    512, 1024, 2, 2,512,
    8
  );

  free(buf_16);
  uint8_t* buf_18 = (uint8_t*)malloc(4096);
  
  qglobal_avg_pool2d_cpu(
    buf_17, buf_18,
    1024, 2, 2,
    8
  );

  free(buf_17);
  uint8_t* buf_19 = (uint8_t*)malloc(40);
  
  qlinear_cpu(
    buf_18, (int8_t*)tvmgen_default_DLA_main_0_const_34, buf_19,
    (int32_t*)tvmgen_default_DLA_main_0_const_35, 10, 1024, 10240,
    8
  );

  free(buf_18);
  float* buf_20 = (float*)malloc(40);
  
  dequantize_cpu(
    buf_19, buf_20,
    10,
    8
  );

  free(buf_19);
  memcpy(out0, buf_20, 4 * 10);
}
int model_on_DLA(
float* arg0,
float* out0)
{
  tvmgen_default_DLA_main_0_(
  arg0,
  out0);
  return 0;
}