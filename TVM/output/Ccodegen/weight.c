#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include "weight.h"
int8_t tvmgen_default_DLA_main_0_const_0 [1152];//32,3,3,3
int32_t tvmgen_default_DLA_main_0_const_1 [32];//0,0,0,0
int8_t tvmgen_default_DLA_main_0_const_2 [1152];//32,1,3,3
int32_t tvmgen_default_DLA_main_0_const_3 [32];//0,0,0,0
int8_t tvmgen_default_DLA_main_0_const_4 [2048];//64,32,1,1
int32_t tvmgen_default_DLA_main_0_const_5 [64];//0,0,0,0
int8_t tvmgen_default_DLA_main_0_const_6 [2304];//64,1,3,3
int32_t tvmgen_default_DLA_main_0_const_7 [64];//0,0,0,0
int8_t tvmgen_default_DLA_main_0_const_8 [8192];//128,64,1,1
int32_t tvmgen_default_DLA_main_0_const_9 [128];//0,0,0,0
int8_t tvmgen_default_DLA_main_0_const_10 [4608];//128,1,3,3
int32_t tvmgen_default_DLA_main_0_const_11 [128];//0,0,0,0
int8_t tvmgen_default_DLA_main_0_const_12 [16384];//128,128,1,1
int32_t tvmgen_default_DLA_main_0_const_13 [128];//0,0,0,0
int8_t tvmgen_default_DLA_main_0_const_14 [4608];//128,1,3,3
int32_t tvmgen_default_DLA_main_0_const_15 [128];//0,0,0,0
int8_t tvmgen_default_DLA_main_0_const_16 [32768];//256,128,1,1
int32_t tvmgen_default_DLA_main_0_const_17 [256];//0,0,0,0
int8_t tvmgen_default_DLA_main_0_const_18 [9216];//256,1,3,3
int32_t tvmgen_default_DLA_main_0_const_19 [256];//0,0,0,0
int8_t tvmgen_default_DLA_main_0_const_20 [65536];//256,256,1,1
int32_t tvmgen_default_DLA_main_0_const_21 [256];//0,0,0,0
int8_t tvmgen_default_DLA_main_0_const_22 [9216];//256,1,3,3
int32_t tvmgen_default_DLA_main_0_const_23 [256];//0,0,0,0
int8_t tvmgen_default_DLA_main_0_const_24 [131072];//512,256,1,1
int32_t tvmgen_default_DLA_main_0_const_25 [512];//0,0,0,0
int8_t tvmgen_default_DLA_main_0_const_26 [18432];//512,1,3,3
int32_t tvmgen_default_DLA_main_0_const_27 [512];//0,0,0,0
int8_t tvmgen_default_DLA_main_0_const_28 [262144];//512,512,1,1
int32_t tvmgen_default_DLA_main_0_const_29 [512];//0,0,0,0
int8_t tvmgen_default_DLA_main_0_const_30 [18432];//512,1,3,3
int32_t tvmgen_default_DLA_main_0_const_31 [512];//0,0,0,0
int8_t tvmgen_default_DLA_main_0_const_32 [524288];//1024,512,1,1
int32_t tvmgen_default_DLA_main_0_const_33 [1024];//0,0,0,0
int8_t tvmgen_default_DLA_main_0_const_34 [10240];//0,0,0,0
int32_t tvmgen_default_DLA_main_0_const_35 [10];//0,0,0,0
void load_weight(const char *filename){
	FILE *file = fopen(filename, "rb");
	if(!file){
		fprintf(stderr, "file open failed.\n");
	}

#ifdef CPU_ONLY
    for(int n=0;n<32;n++){
    	fread(tvmgen_default_DLA_main_0_const_0+(n*27),sizeof(int8_t),27,file);
    	fseek(file,9,SEEK_CUR);
    }
#else
    fread(tvmgen_default_DLA_main_0_const_0,sizeof(int8_t),1152,file);
#endif
	fread(tvmgen_default_DLA_main_0_const_1,sizeof(int32_t),32,file);

#ifdef CPU_ONLY
    for(int n=0;n<32;n++){
    	fread(tvmgen_default_DLA_main_0_const_2+(n*9),sizeof(int8_t),9,file);
    	fseek(file,27,SEEK_CUR);
    }
#else
    fread(tvmgen_default_DLA_main_0_const_2,sizeof(int8_t),1152,file);
#endif
	fread(tvmgen_default_DLA_main_0_const_3,sizeof(int32_t),32,file);
	fread(tvmgen_default_DLA_main_0_const_4,sizeof(int8_t),2048,file);
	fread(tvmgen_default_DLA_main_0_const_5,sizeof(int32_t),64,file);

#ifdef CPU_ONLY
    for(int n=0;n<64;n++){
    	fread(tvmgen_default_DLA_main_0_const_6+(n*9),sizeof(int8_t),9,file);
    	fseek(file,27,SEEK_CUR);
    }
#else
    fread(tvmgen_default_DLA_main_0_const_6,sizeof(int8_t),2304,file);
#endif
	fread(tvmgen_default_DLA_main_0_const_7,sizeof(int32_t),64,file);
	fread(tvmgen_default_DLA_main_0_const_8,sizeof(int8_t),8192,file);
	fread(tvmgen_default_DLA_main_0_const_9,sizeof(int32_t),128,file);

#ifdef CPU_ONLY
    for(int n=0;n<128;n++){
    	fread(tvmgen_default_DLA_main_0_const_10+(n*9),sizeof(int8_t),9,file);
    	fseek(file,27,SEEK_CUR);
    }
#else
    fread(tvmgen_default_DLA_main_0_const_10,sizeof(int8_t),4608,file);
#endif
	fread(tvmgen_default_DLA_main_0_const_11,sizeof(int32_t),128,file);
	fread(tvmgen_default_DLA_main_0_const_12,sizeof(int8_t),16384,file);
	fread(tvmgen_default_DLA_main_0_const_13,sizeof(int32_t),128,file);

#ifdef CPU_ONLY
    for(int n=0;n<128;n++){
    	fread(tvmgen_default_DLA_main_0_const_14+(n*9),sizeof(int8_t),9,file);
    	fseek(file,27,SEEK_CUR);
    }
#else
    fread(tvmgen_default_DLA_main_0_const_14,sizeof(int8_t),4608,file);
#endif
	fread(tvmgen_default_DLA_main_0_const_15,sizeof(int32_t),128,file);
	fread(tvmgen_default_DLA_main_0_const_16,sizeof(int8_t),32768,file);
	fread(tvmgen_default_DLA_main_0_const_17,sizeof(int32_t),256,file);

#ifdef CPU_ONLY
    for(int n=0;n<256;n++){
    	fread(tvmgen_default_DLA_main_0_const_18+(n*9),sizeof(int8_t),9,file);
    	fseek(file,27,SEEK_CUR);
    }
#else
    fread(tvmgen_default_DLA_main_0_const_18,sizeof(int8_t),9216,file);
#endif
	fread(tvmgen_default_DLA_main_0_const_19,sizeof(int32_t),256,file);
	fread(tvmgen_default_DLA_main_0_const_20,sizeof(int8_t),65536,file);
	fread(tvmgen_default_DLA_main_0_const_21,sizeof(int32_t),256,file);

#ifdef CPU_ONLY
    for(int n=0;n<256;n++){
    	fread(tvmgen_default_DLA_main_0_const_22+(n*9),sizeof(int8_t),9,file);
    	fseek(file,27,SEEK_CUR);
    }
#else
    fread(tvmgen_default_DLA_main_0_const_22,sizeof(int8_t),9216,file);
#endif
	fread(tvmgen_default_DLA_main_0_const_23,sizeof(int32_t),256,file);
	fread(tvmgen_default_DLA_main_0_const_24,sizeof(int8_t),131072,file);
	fread(tvmgen_default_DLA_main_0_const_25,sizeof(int32_t),512,file);

#ifdef CPU_ONLY
    for(int n=0;n<512;n++){
    	fread(tvmgen_default_DLA_main_0_const_26+(n*9),sizeof(int8_t),9,file);
    	fseek(file,27,SEEK_CUR);
    }
#else
    fread(tvmgen_default_DLA_main_0_const_26,sizeof(int8_t),18432,file);
#endif
	fread(tvmgen_default_DLA_main_0_const_27,sizeof(int32_t),512,file);
	fread(tvmgen_default_DLA_main_0_const_28,sizeof(int8_t),262144,file);
	fread(tvmgen_default_DLA_main_0_const_29,sizeof(int32_t),512,file);

#ifdef CPU_ONLY
    for(int n=0;n<512;n++){
    	fread(tvmgen_default_DLA_main_0_const_30+(n*9),sizeof(int8_t),9,file);
    	fseek(file,27,SEEK_CUR);
    }
#else
    fread(tvmgen_default_DLA_main_0_const_30,sizeof(int8_t),18432,file);
#endif
	fread(tvmgen_default_DLA_main_0_const_31,sizeof(int32_t),512,file);
	fread(tvmgen_default_DLA_main_0_const_32,sizeof(int8_t),524288,file);
	fread(tvmgen_default_DLA_main_0_const_33,sizeof(int32_t),1024,file);
	fread(tvmgen_default_DLA_main_0_const_34,sizeof(int8_t),10240,file);
	fread(tvmgen_default_DLA_main_0_const_35,sizeof(int32_t),10,file);
	fclose(file);
}
