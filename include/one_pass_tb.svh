`ifndef CONFIG_PE_ARRAY_H
`define CONFIG_PE_ARRAY_H


parameter int CYCLE = 10;
parameter int PE_ARRAY_H = 6;
parameter int PE_ARRAY_W = 8;
parameter int DEFAULT_TAG_X = 31;
parameter int DEFAULT_TAG_Y = 7;

`ifdef TBA0
`define DATA_SRC   "./testbench/PE_array_test_data/tb0/"
`define CONFIG_SRC  "./testbench/PE_array_test_data/tb0/"
`define IFMAP_CONFIG_XID_FILE   "./testbench/PE_array_test_data/tb0/ifmap_config_chain_XID_tb0.txt"
`define IFMAP_CONFIG_YID_FILE   "./testbench/PE_array_test_data/tb0/ifmap_config_chain_YID_tb0.txt"
`define FILTER_CONFIG_XID_FILE  "./testbench/PE_array_test_data/tb0/filter_config_chain_XID_tb0.txt"
`define FILTER_CONFIG_YID_FILE  "./testbench/PE_array_test_data/tb0/filter_config_chain_YID_tb0.txt"
`define IPSUM_CONFIG_XID_FILE   "./testbench/PE_array_test_data/tb0/ipsum_config_chain_XID_tb0.txt"
`define IPSUM_CONFIG_YID_FILE   "./testbench/PE_array_test_data/tb0/ipsum_config_chain_YID_tb0.txt"
`define OPSUM_CONFIG_XID_FILE   "./testbench/PE_array_test_data/tb0/opsum_config_chain_XID_tb0.txt"
`define OPSUM_CONFIG_YID_FILE   "./testbench/PE_array_test_data/tb0/opsum_config_chain_YID_tb0.txt"
`define IFMAP_FILE  "./testbench/PE_array_test_data/tb0/ifmap_tb0.txt"
`define FILTER_FILE "./testbench/PE_array_test_data/tb0/filter_tb0.txt"
`define IPSUM_FILE  "./testbench/PE_array_test_data/tb0/ipsum_tb0.txt"
`define OPSUM_FILE  "./testbench/PE_array_test_data/tb0/opsum_tb0.txt"
`define GLB_MIRROR_FILE "./testbench/PE_array_test_data/tb0/GLB_mirror.hex"
`define GOLDEN_FILE "./testbench/PE_array_test_data/tb0/golden.hex"
parameter int FILT_ROW = 3;
parameter int FILT_COL = 3;
parameter int p = 4;
parameter int q = 4;
parameter int r = 1;
parameter int t = 2;
parameter int e = 8;
parameter int STRIDE = 1;
parameter int IFMAP_COL = 18;
parameter int OFMAP_COL = IFMAP_COL - FILT_ROW + 1;
parameter int LN_CONFIG = 27;
parameter int FILTER_RS = 3;
parameter [47:0]PE_EN= (1'b1 << (PE_ARRAY_H * PE_ARRAY_W)) - 1;
parameter int DEPTHWISE = 0;
parameter int PE_CONFIG = (DEPTHWISE << 12) + ((FILTER_RS - 1) << 10) + ((p - 1) << 7) + ((OFMAP_COL - 1) << 2) + (q - 1);

`elsif TBA1
`define DATA_SRC "./testbench/PE_array_test_data/tb1/"
`define CONFIG_SRC "./testbench/PE_array_test_data/tb1/"
`define IFMAP_CONFIG_XID_FILE "./testbench/PE_array_test_data/tb1/ifmap_config_chain_XID_tb1.txt"
`define IFMAP_CONFIG_YID_FILE "./testbench/PE_array_test_data/tb1/ifmap_config_chain_YID_tb1.txt"
`define FILTER_CONFIG_XID_FILE "./testbench/PE_array_test_data/tb1/filter_config_chain_XID_tb1.txt"
`define FILTER_CONFIG_YID_FILE "./testbench/PE_array_test_data/tb1/filter_config_chain_YID_tb1.txt"
`define IPSUM_CONFIG_XID_FILE "./testbench/PE_array_test_data/tb1/ipsum_config_chain_XID_tb1.txt"
`define IPSUM_CONFIG_YID_FILE "./testbench/PE_array_test_data/tb1/ipsum_config_chain_YID_tb1.txt"
`define OPSUM_CONFIG_XID_FILE "./testbench/PE_array_test_data/tb1/opsum_config_chain_XID_tb1.txt"
`define OPSUM_CONFIG_YID_FILE "./testbench/PE_array_test_data/tb1/opsum_config_chain_YID_tb1.txt"
`define IFMAP_FILE "./testbench/PE_array_test_data/tb1/ifmap_tb1.txt"
`define FILTER_FILE"./testbench/PE_array_test_data/tb1/filter_tb1.txt"
`define IPSUM_FILE "./testbench/PE_array_test_data/tb1/ipsum_tb1.txt"
`define OPSUM_FILE "./testbench/PE_array_test_data/tb1/opsum_tb1.txt"
`define GLB_MIRROR_FILE "./testbench/PE_array_test_data/tb1/GLB_mirror.hex"
`define GOLDEN_FILE "./testbench/PE_array_test_data/tb1/golden.hex"
parameter int FILT_ROW = 3;
parameter int FILT_COL = 3;
parameter int p = 4;
parameter int q = 3;
parameter int r = 1;
parameter int t = 2;
parameter int e = 8;
parameter int STRIDE = 1;
parameter int IFMAP_COL = 34;
parameter int OFMAP_COL = IFMAP_COL - FILT_ROW + 1;
parameter int LN_CONFIG = 27;
parameter int FILTER_RS = 3;
parameter [47:0]PE_EN= (1'b1 << (PE_ARRAY_H * PE_ARRAY_W)) - 1;
parameter int DEPTHWISE = 0;
parameter int PE_CONFIG = (DEPTHWISE << 12) + ((FILTER_RS - 1) << 10) + ((p - 1) << 7) + ((OFMAP_COL - 1) << 2) + (q - 1);


`elsif TBA2
`define DATA_SRC "./testbench/PE_array_test_data/tb2/"
`define CONFIG_SRC "./testbench/PE_array_test_data/tb2/"
`define IFMAP_CONFIG_XID_FILE  "./testbench/PE_array_test_data/tb2/ifmap_config_chain_XID_tb2.txt"
`define IFMAP_CONFIG_YID_FILE  "./testbench/PE_array_test_data/tb2/ifmap_config_chain_YID_tb2.txt"
`define FILTER_CONFIG_XID_FILE "./testbench/PE_array_test_data/tb2/filter_config_chain_XID_tb2.txt"
`define FILTER_CONFIG_YID_FILE "./testbench/PE_array_test_data/tb2/filter_config_chain_YID_tb2.txt"
`define IPSUM_CONFIG_XID_FILE  "./testbench/PE_array_test_data/tb2/ipsum_config_chain_XID_tb2.txt"
`define IPSUM_CONFIG_YID_FILE  "./testbench/PE_array_test_data/tb2/ipsum_config_chain_YID_tb2.txt"
`define OPSUM_CONFIG_XID_FILE  "./testbench/PE_array_test_data/tb2/opsum_config_chain_XID_tb2.txt"
`define OPSUM_CONFIG_YID_FILE  "./testbench/PE_array_test_data/tb2/opsum_config_chain_YID_tb2.txt"
`define IFMAP_FILE             "./testbench/PE_array_test_data/tb2/ifmap_tb2.txt"
`define FILTER_FILE            "./testbench/PE_array_test_data/tb2/filter_tb2.txt"
`define IPSUM_FILE             "./testbench/PE_array_test_data/tb2/ipsum_tb2.txt"
`define OPSUM_FILE             "./testbench/PE_array_test_data/tb2/opsum_tb2.txt"
`define GLB_MIRROR_FILE        "./testbench/PE_array_test_data/tb2/GLB_mirror.hex"
`define GOLDEN_FILE            "./testbench/PE_array_test_data/tb2/golden.hex"
parameter int FILT_ROW = 3;
parameter int FILT_COL = 3;
parameter int p = 4;
parameter int q = 4;
parameter int r = 2;
parameter int t = 1;
parameter int e = 8;
parameter int STRIDE = 1;
parameter int IFMAP_COL = 18;
parameter int OFMAP_COL = IFMAP_COL - FILT_ROW + 1;
parameter int LN_CONFIG = 31;
parameter int FILTER_RS = 3;
parameter [47:0]PE_EN= (1'b1 << (PE_ARRAY_H * PE_ARRAY_W)) - 1;
parameter int DEPTHWISE = 0;
parameter int PE_CONFIG = (DEPTHWISE << 12) + ((FILTER_RS - 1) << 10) + ((p - 1) << 7) + ((OFMAP_COL - 1) << 2) + (q - 1);


`elsif TBA3
`define DATA_SRC "./testbench/PE_array_test_data/tb3/"
`define CONFIG_SRC "./testbench/PE_array_test_data/tb3/"
`define IFMAP_CONFIG_XID_FILE  "./testbench/PE_array_test_data/tb3/ifmap_config_chain_XID_tb3.txt"
`define IFMAP_CONFIG_YID_FILE  "./testbench/PE_array_test_data/tb3/ifmap_config_chain_YID_tb3.txt"
`define FILTER_CONFIG_XID_FILE "./testbench/PE_array_test_data/tb3/filter_config_chain_XID_tb3.txt"
`define FILTER_CONFIG_YID_FILE "./testbench/PE_array_test_data/tb3/filter_config_chain_YID_tb3.txt"
`define IPSUM_CONFIG_XID_FILE  "./testbench/PE_array_test_data/tb3/ipsum_config_chain_XID_tb3.txt"
`define IPSUM_CONFIG_YID_FILE  "./testbench/PE_array_test_data/tb3/ipsum_config_chain_YID_tb3.txt"
`define OPSUM_CONFIG_XID_FILE  "./testbench/PE_array_test_data/tb3/opsum_config_chain_XID_tb3.txt"
`define OPSUM_CONFIG_YID_FILE  "./testbench/PE_array_test_data/tb3/opsum_config_chain_YID_tb3.txt"
`define IFMAP_FILE             "./testbench/PE_array_test_data/tb3/ifmap_tb3.txt"
`define FILTER_FILE            "./testbench/PE_array_test_data/tb3/filter_tb3.txt"
`define IPSUM_FILE             "./testbench/PE_array_test_data/tb3/ipsum_tb3.txt"
`define OPSUM_FILE             "./testbench/PE_array_test_data/tb3/opsum_tb3.txt"
`define GLB_MIRROR_FILE        "./testbench/PE_array_test_data/tb3/GLB_mirror.hex"
`define GOLDEN_FILE            "./testbench/PE_array_test_data/tb3/golden.hex"
parameter int FILT_ROW = 3;
parameter int FILT_COL = 3;
parameter int p = 4;
parameter int q = 4;
parameter int r = 2;
parameter int t = 2;
parameter int e = 4;
parameter int STRIDE = 1;
parameter int IFMAP_COL = 18;
parameter int OFMAP_COL = IFMAP_COL - FILT_ROW + 1;
parameter int LN_CONFIG = 31;
parameter int FILTER_RS = 3;
parameter [47:0]PE_EN= (1'b1 << (PE_ARRAY_H * PE_ARRAY_W)) - 1;
parameter int DEPTHWISE = 0;
parameter int PE_CONFIG = (DEPTHWISE << 12) + ((FILTER_RS - 1) << 10) + ((p - 1) << 7) + ((OFMAP_COL - 1) << 2) + (q - 1);


`elsif TBA4
`define DATA_SRC "./testbench/PE_array_test_data/tb4/"
`define CONFIG_SRC "./testbench/PE_array_test_data/tb4/"
`define IFMAP_CONFIG_XID_FILE  "./testbench/PE_array_test_data/tb4/ifmap_config_chain_XID_tb4.txt"
`define IFMAP_CONFIG_YID_FILE  "./testbench/PE_array_test_data/tb4/ifmap_config_chain_YID_tb4.txt"
`define FILTER_CONFIG_XID_FILE "./testbench/PE_array_test_data/tb4/filter_config_chain_XID_tb4.txt"
`define FILTER_CONFIG_YID_FILE "./testbench/PE_array_test_data/tb4/filter_config_chain_YID_tb4.txt"
`define IPSUM_CONFIG_XID_FILE  "./testbench/PE_array_test_data/tb4/ipsum_config_chain_XID_tb4.txt"
`define IPSUM_CONFIG_YID_FILE  "./testbench/PE_array_test_data/tb4/ipsum_config_chain_YID_tb4.txt"
`define OPSUM_CONFIG_XID_FILE  "./testbench/PE_array_test_data/tb4/opsum_config_chain_XID_tb4.txt"
`define OPSUM_CONFIG_YID_FILE  "./testbench/PE_array_test_data/tb4/opsum_config_chain_YID_tb4.txt"
`define IFMAP_FILE             "./testbench/PE_array_test_data/tb4/ifmap_tb4.txt"
`define FILTER_FILE            "./testbench/PE_array_test_data/tb4/filter_tb4.txt"
`define IPSUM_FILE             "./testbench/PE_array_test_data/tb4/ipsum_tb4.txt"
`define OPSUM_FILE             "./testbench/PE_array_test_data/tb4/opsum_tb4.txt"
`define GLB_MIRROR_FILE        "./testbench/PE_array_test_data/tb4/GLB_mirror.hex"
`define GOLDEN_FILE            "./testbench/PE_array_test_data/tb4/golden.hex"
parameter int FILT_ROW = 3;
parameter int FILT_COL = 3;
parameter int p = 4;
parameter int q = 4;
parameter int r = 1;
parameter int t = 4;
parameter int e = 4;
parameter int STRIDE = 1;
parameter int IFMAP_COL = 18;
parameter int OFMAP_COL = IFMAP_COL - FILT_ROW + 1;
parameter int LN_CONFIG = 27;
parameter int FILTER_RS = 3;
parameter [47:0]PE_EN= (1'b1 << (PE_ARRAY_H * PE_ARRAY_W)) - 1;
parameter int DEPTHWISE = 0;
parameter int PE_CONFIG = (DEPTHWISE << 12) + ((FILTER_RS - 1) << 10) + ((p - 1) << 7) + ((OFMAP_COL - 1) << 2) + (q - 1);


`elsif TBA5
`define DATA_SRC "./testbench/PE_array_test_data/tb5/"
`define CONFIG_SRC "./testbench/PE_array_test_data/tb5/"
`define IFMAP_CONFIG_XID_FILE  "./testbench/PE_array_test_data/tb5/ifmap_config_chain_XID_tb5.txt"
`define IFMAP_CONFIG_YID_FILE  "./testbench/PE_array_test_data/tb5/ifmap_config_chain_YID_tb5.txt"
`define FILTER_CONFIG_XID_FILE "./testbench/PE_array_test_data/tb5/filter_config_chain_XID_tb5.txt"
`define FILTER_CONFIG_YID_FILE "./testbench/PE_array_test_data/tb5/filter_config_chain_YID_tb5.txt"
`define IPSUM_CONFIG_XID_FILE  "./testbench/PE_array_test_data/tb5/ipsum_config_chain_XID_tb5.txt"
`define IPSUM_CONFIG_YID_FILE  "./testbench/PE_array_test_data/tb5/ipsum_config_chain_YID_tb5.txt"
`define OPSUM_CONFIG_XID_FILE  "./testbench/PE_array_test_data/tb5/opsum_config_chain_XID_tb5.txt"
`define OPSUM_CONFIG_YID_FILE  "./testbench/PE_array_test_data/tb5/opsum_config_chain_YID_tb5.txt"
`define IFMAP_FILE             "./testbench/PE_array_test_data/tb5/ifmap_tb5.txt"
`define FILTER_FILE            "./testbench/PE_array_test_data/tb5/filter_tb5.txt"
`define IPSUM_FILE             "./testbench/PE_array_test_data/tb5/ipsum_tb5.txt"
`define OPSUM_FILE             "./testbench/PE_array_test_data/tb5/opsum_tb5.txt"
`define GLB_MIRROR_FILE        "./testbench/PE_array_test_data/tb5/GLB_mirror.hex"
`define GOLDEN_FILE            "./testbench/PE_array_test_data/tb5/golden.hex"
parameter int FILT_ROW = 3;
parameter int FILT_COL = 3;
parameter int p = 4;
parameter int q = 4;
parameter int r = 1;
parameter int t = 1;
parameter int e = 16;
parameter int STRIDE = 1;
parameter int IFMAP_COL = 18;
parameter int OFMAP_COL = IFMAP_COL - FILT_ROW + 1;
parameter int LN_CONFIG = 27;
parameter int FILTER_RS = 3;
parameter [47:0]PE_EN= (1'b1 << (PE_ARRAY_H * PE_ARRAY_W)) - 1;
parameter int DEPTHWISE = 0;
parameter int PE_CONFIG = (DEPTHWISE << 12) + ((FILTER_RS - 1) << 10) + ((p - 1) << 7) + ((OFMAP_COL - 1) << 2) + (q - 1);

`elsif TBA6
`define DATA_SRC "./testbench/PE_array_test_data/tb6/"
`define CONFIG_SRC "./testbench/PE_array_test_data/tb6/"
`define IFMAP_CONFIG_XID_FILE  "./testbench/PE_array_test_data/tb6/ifmap_config_chain_XID_tb6.txt"
`define IFMAP_CONFIG_YID_FILE  "./testbench/PE_array_test_data/tb6/ifmap_config_chain_YID_tb6.txt"
`define FILTER_CONFIG_XID_FILE "./testbench/PE_array_test_data/tb6/filter_config_chain_XID_tb6.txt"
`define FILTER_CONFIG_YID_FILE "./testbench/PE_array_test_data/tb6/filter_config_chain_YID_tb6.txt"
`define IPSUM_CONFIG_XID_FILE  "./testbench/PE_array_test_data/tb6/ipsum_config_chain_XID_tb6.txt"
`define IPSUM_CONFIG_YID_FILE  "./testbench/PE_array_test_data/tb6/ipsum_config_chain_YID_tb6.txt"
`define OPSUM_CONFIG_XID_FILE  "./testbench/PE_array_test_data/tb6/opsum_config_chain_XID_tb6.txt"
`define OPSUM_CONFIG_YID_FILE  "./testbench/PE_array_test_data/tb6/opsum_config_chain_YID_tb6.txt"
`define IFMAP_FILE             "./testbench/PE_array_test_data/tb6/ifmap_tb6.txt"
`define FILTER_FILE            "./testbench/PE_array_test_data/tb6/filter_tb6.txt"
`define IPSUM_FILE             "./testbench/PE_array_test_data/tb6/ipsum_tb6.txt"
`define OPSUM_FILE             "./testbench/PE_array_test_data/tb6/opsum_tb6.txt"
`define GLB_MIRROR_FILE        "./testbench/PE_array_test_data/tb6/GLB_mirror.hex"
`define GOLDEN_FILE            "./testbench/PE_array_test_data/tb6/golden.hex"
parameter int FILT_ROW = 3;
parameter int FILT_COL = 3;
parameter int p = 4;
parameter int q = 4;
parameter int r = 1;
parameter int t = 1;
parameter int e = 16;
parameter int STRIDE = 1;
parameter int IFMAP_COL = 18;
parameter int OFMAP_COL = IFMAP_COL - FILT_ROW + 1;
parameter int LN_CONFIG = 27;
parameter int FILTER_RS = 3;
parameter [47:0]PE_EN= (1'b1 << (PE_ARRAY_H * PE_ARRAY_W)) - 1;
parameter int DEPTHWISE = 1;
parameter int PE_CONFIG = (DEPTHWISE << 12) + ((FILTER_RS - 1) << 10) + ((p - 1) << 7) + ((OFMAP_COL - 1) << 2) + (q - 1);
`elsif TBA7

`define DATA_SRC "./testbench/PE_array_test_data/depthwise_separable_tb0_format/"
`define CONFIG_SRC "./testbench/PE_array_test_data/depthwise_separable_tb0_format/"
`define IFMAP_CONFIG_XID_FILE  "./testbench/PE_array_test_data/depthwise_separable_tb0_format/ifmap_config_chain_XID_tb0.txt"
`define IFMAP_CONFIG_YID_FILE  "./testbench/PE_array_test_data/depthwise_separable_tb0_format/ifmap_config_chain_YID_tb0.txt"
`define FILTER_CONFIG_XID_FILE "./testbench/PE_array_test_data/depthwise_separable_tb0_format/filter_config_chain_XID_tb0.txt"
`define FILTER_CONFIG_YID_FILE "./testbench/PE_array_test_data/depthwise_separable_tb0_format/filter_config_chain_YID_tb0.txt"
`define IPSUM_CONFIG_XID_FILE  "./testbench/PE_array_test_data/depthwise_separable_tb0_format/ipsum_config_chain_XID_tb0.txt"
`define IPSUM_CONFIG_YID_FILE  "./testbench/PE_array_test_data/depthwise_separable_tb0_format/ipsum_config_chain_YID_tb0.txt"
`define OPSUM_CONFIG_XID_FILE  "./testbench/PE_array_test_data/depthwise_separable_tb0_format/opsum_config_chain_XID_tb0.txt"
`define OPSUM_CONFIG_YID_FILE  "./testbench/PE_array_test_data/depthwise_separable_tb0_format/opsum_config_chain_YID_tb0.txt"
`define IFMAP_FILE             "./testbench/PE_array_test_data/depthwise_separable_tb0_format/ifmap.txt"
`define FILTER_FILE            "./testbench/PE_array_test_data/depthwise_separable_tb0_format/filter.txt"
`define IPSUM_FILE             "./testbench/PE_array_test_data/depthwise_separable_tb0_format/pointwise_ipsum.txt"
`define OPSUM_FILE             "./testbench/PE_array_test_data/depthwise_separable_tb0_format/opsum.txt"
`define GLB_MIRROR_FILE        "./testbench/PE_array_test_data/depthwise_separable_tb0_format/GLB_mirror.hex"
`define GOLDEN_FILE            "./testbench/PE_array_test_data/depthwise_separable_tb0_format/golden.hex"
parameter int FILT_ROW = 3;
parameter int FILT_COL = 3;
parameter int p = 4;
parameter int q = 4;
parameter int r = 1;
parameter int t = 2;
parameter int e = 8;
parameter int STRIDE = 1;
parameter int IFMAP_COL = 18;
parameter int OFMAP_COL = IFMAP_COL - FILT_ROW + 1;
parameter int LN_CONFIG = 27;
parameter int FILTER_RS = 3;
parameter [47:0]PE_EN= (1'b1 << (PE_ARRAY_H * PE_ARRAY_W)) - 1;
parameter int DEPTHWISE = 1;
parameter int PE_CONFIG = (DEPTHWISE << 12) + ((FILTER_RS - 1) << 10) + ((p - 1) << 7) + ((OFMAP_COL - 1) << 2) + (q - 1);

`elsif TBA8
`define DATA_SRC "./testbench/PE_array_test_data/depthwise_separable_tb1_format/"
`define CONFIG_SRC "./testbench/PE_array_test_data/depthwise_separable_tb1_format/"
`define IFMAP_CONFIG_XID_FILE  "./testbench/PE_array_test_data/depthwise_separable_tb1_format/ifmap_config_chain_XID_tb1.txt"
`define IFMAP_CONFIG_YID_FILE  "./testbench/PE_array_test_data/depthwise_separable_tb1_format/ifmap_config_chain_YID_tb1.txt"
`define FILTER_CONFIG_XID_FILE "./testbench/PE_array_test_data/depthwise_separable_tb1_format/filter_config_chain_XID_tb1.txt"
`define FILTER_CONFIG_YID_FILE "./testbench/PE_array_test_data/depthwise_separable_tb1_format/filter_config_chain_YID_tb1.txt"
`define IPSUM_CONFIG_XID_FILE  "./testbench/PE_array_test_data/depthwise_separable_tb1_format/ipsum_config_chain_XID_tb1.txt"
`define IPSUM_CONFIG_YID_FILE  "./testbench/PE_array_test_data/depthwise_separable_tb1_format/ipsum_config_chain_YID_tb1.txt"
`define OPSUM_CONFIG_XID_FILE  "./testbench/PE_array_test_data/depthwise_separable_tb1_format/opsum_config_chain_XID_tb1.txt"
`define OPSUM_CONFIG_YID_FILE  "./testbench/PE_array_test_data/depthwise_separable_tb1_format/opsum_config_chain_YID_tb1.txt"
`define IFMAP_FILE             "./testbench/PE_array_test_data/depthwise_separable_tb1_format/ifmap.txt"
`define FILTER_FILE            "./testbench/PE_array_test_data/depthwise_separable_tb1_format/filter.txt"
`define IPSUM_FILE             "./testbench/PE_array_test_data/depthwise_separable_tb1_format/pointwise_ipsum.txt"
`define OPSUM_FILE             "./testbench/PE_array_test_data/depthwise_separable_tb1_format/opsum.txt"
`define GLB_MIRROR_FILE        "./testbench/PE_array_test_data/depthwise_separable_tb1_format/GLB_mirror.hex"
`define GOLDEN_FILE            "./testbench/PE_array_test_data/depthwise_separable_tb1_format/golden.hex"
parameter int FILT_ROW = 3;
parameter int FILT_COL = 3;
parameter int p = 4;
parameter int q = 3;
parameter int r = 1;
parameter int t = 2;
parameter int e = 8;
parameter int STRIDE = 1;
parameter int IFMAP_COL = 34;
parameter int OFMAP_COL = IFMAP_COL - FILT_ROW + 1;
parameter int LN_CONFIG = 27;
parameter int FILTER_RS = 3;
parameter [47:0]PE_EN= (1'b1 << (PE_ARRAY_H * PE_ARRAY_W)) - 1;
parameter int DEPTHWISE = 1;
parameter int PE_CONFIG = (DEPTHWISE << 12) + ((FILTER_RS - 1) << 10) + ((p - 1) << 7) + ((OFMAP_COL - 1) << 2) + (q - 1);

`elsif TBA9
`define DATA_SRC "./testbench/PE_array_test_data/depthwise_separable_tb2_format/"
`define CONFIG_SRC "./testbench/PE_array_test_data/depthwise_separable_tb2_format/"
`define IFMAP_CONFIG_XID_FILE  "./testbench/PE_array_test_data/depthwise_separable_tb2_format/ifmap_config_chain_XID_tb2.txt"
`define IFMAP_CONFIG_YID_FILE  "./testbench/PE_array_test_data/depthwise_separable_tb2_format/ifmap_config_chain_YID_tb2.txt"
`define FILTER_CONFIG_XID_FILE "./testbench/PE_array_test_data/depthwise_separable_tb2_format/filter_config_chain_XID_tb2.txt"
`define FILTER_CONFIG_YID_FILE "./testbench/PE_array_test_data/depthwise_separable_tb2_format/filter_config_chain_YID_tb2.txt"
`define IPSUM_CONFIG_XID_FILE  "./testbench/PE_array_test_data/depthwise_separable_tb2_format/ipsum_config_chain_XID_tb2.txt"
`define IPSUM_CONFIG_YID_FILE  "./testbench/PE_array_test_data/depthwise_separable_tb2_format/ipsum_config_chain_YID_tb2.txt"
`define OPSUM_CONFIG_XID_FILE  "./testbench/PE_array_test_data/depthwise_separable_tb2_format/opsum_config_chain_XID_tb2.txt"
`define OPSUM_CONFIG_YID_FILE  "./testbench/PE_array_test_data/depthwise_separable_tb2_format/opsum_config_chain_YID_tb2.txt"
`define IFMAP_FILE             "./testbench/PE_array_test_data/depthwise_separable_tb2_format/ifmap.txt"
`define FILTER_FILE            "./testbench/PE_array_test_data/depthwise_separable_tb2_format/filter.txt"
`define IPSUM_FILE             "./testbench/PE_array_test_data/depthwise_separable_tb2_format/pointwise_ipsum.txt"
`define OPSUM_FILE             "./testbench/PE_array_test_data/depthwise_separable_tb2_format/opsum.txt"
`define GLB_MIRROR_FILE        "./testbench/PE_array_test_data/depthwise_separable_tb2_format/GLB_mirror.hex"
`define GOLDEN_FILE            "./testbench/PE_array_test_data/depthwise_separable_tb2_format/golden.hex"
parameter int FILT_ROW = 3;
parameter int FILT_COL = 3;
parameter int p = 4;
parameter int q = 4;
parameter int r = 2;
parameter int t = 1;
parameter int e = 8;
parameter int STRIDE = 1;
parameter int IFMAP_COL = 18;
parameter int OFMAP_COL = IFMAP_COL - FILT_ROW + 1;
parameter int LN_CONFIG = 31;
parameter int FILTER_RS = 3;
parameter [47:0]PE_EN= (1'b1 << (PE_ARRAY_H * PE_ARRAY_W)) - 1;
parameter int DEPTHWISE = 1;
parameter int PE_CONFIG = (DEPTHWISE << 12) + ((FILTER_RS - 1) << 10) + ((p - 1) << 7) + ((OFMAP_COL - 1) << 2) + (q - 1);

`elsif TBA10
`define DATA_SRC "./testbench/PE_array_test_data/depthwise_separable_tb3_format/"
`define CONFIG_SRC "./testbench/PE_array_test_data/depthwise_separable_tb3_format/"
`define IFMAP_CONFIG_XID_FILE  "./testbench/PE_array_test_data/depthwise_separable_tb3_format/ifmap_config_chain_XID_tb3.txt"
`define IFMAP_CONFIG_YID_FILE  "./testbench/PE_array_test_data/depthwise_separable_tb3_format/ifmap_config_chain_YID_tb3.txt"
`define FILTER_CONFIG_XID_FILE "./testbench/PE_array_test_data/depthwise_separable_tb3_format/filter_config_chain_XID_tb3.txt"
`define FILTER_CONFIG_YID_FILE "./testbench/PE_array_test_data/depthwise_separable_tb3_format/filter_config_chain_YID_tb3.txt"
`define IPSUM_CONFIG_XID_FILE  "./testbench/PE_array_test_data/depthwise_separable_tb3_format/ipsum_config_chain_XID_tb3.txt"
`define IPSUM_CONFIG_YID_FILE  "./testbench/PE_array_test_data/depthwise_separable_tb3_format/ipsum_config_chain_YID_tb3.txt"
`define OPSUM_CONFIG_XID_FILE  "./testbench/PE_array_test_data/depthwise_separable_tb3_format/opsum_config_chain_XID_tb3.txt"
`define OPSUM_CONFIG_YID_FILE  "./testbench/PE_array_test_data/depthwise_separable_tb3_format/opsum_config_chain_YID_tb3.txt"
`define IFMAP_FILE             "./testbench/PE_array_test_data/depthwise_separable_tb3_format/ifmap.txt"
`define FILTER_FILE            "./testbench/PE_array_test_data/depthwise_separable_tb3_format/filter.txt"
`define IPSUM_FILE             "./testbench/PE_array_test_data/depthwise_separable_tb3_format/pointwise_ipsum.txt"
`define OPSUM_FILE             "./testbench/PE_array_test_data/depthwise_separable_tb3_format/opsum.txt"
`define GLB_MIRROR_FILE        "./testbench/PE_array_test_data/depthwise_separable_tb3_format/GLB_mirror.hex"
`define GOLDEN_FILE            "./testbench/PE_array_test_data/depthwise_separable_tb3_format/golden.hex"
parameter int FILT_ROW = 3;
parameter int FILT_COL = 3;
parameter int p = 4;
parameter int q = 4;
parameter int r = 2;
parameter int t = 2;
parameter int e = 4;
parameter int STRIDE = 1;
parameter int IFMAP_COL = 18;
parameter int OFMAP_COL = IFMAP_COL - FILT_ROW + 1;
parameter int LN_CONFIG = 31;
parameter int FILTER_RS = 3;
parameter [47:0]PE_EN= (1'b1 << (PE_ARRAY_H * PE_ARRAY_W)) - 1;
parameter int DEPTHWISE = 1;
parameter int PE_CONFIG = (DEPTHWISE << 12) + ((FILTER_RS - 1) << 10) + ((p - 1) << 7) + ((OFMAP_COL - 1) << 2) + (q - 1);
`elsif TBA11
`define DATA_SRC "./testbench/PE_array_test_data/depthwise_separable_tb4_format/"
`define CONFIG_SRC "./testbench/PE_array_test_data/depthwise_separable_tb4_format/"
`define IFMAP_CONFIG_XID_FILE  "./testbench/PE_array_test_data/depthwise_separable_tb4_format/ifmap_config_chain_XID_tb4.txt"
`define IFMAP_CONFIG_YID_FILE  "./testbench/PE_array_test_data/depthwise_separable_tb4_format/ifmap_config_chain_YID_tb4.txt"
`define FILTER_CONFIG_XID_FILE "./testbench/PE_array_test_data/depthwise_separable_tb4_format/filter_config_chain_XID_tb4.txt"
`define FILTER_CONFIG_YID_FILE "./testbench/PE_array_test_data/depthwise_separable_tb4_format/filter_config_chain_YID_tb4.txt"
`define IPSUM_CONFIG_XID_FILE  "./testbench/PE_array_test_data/depthwise_separable_tb4_format/ipsum_config_chain_XID_tb4.txt"
`define IPSUM_CONFIG_YID_FILE  "./testbench/PE_array_test_data/depthwise_separable_tb4_format/ipsum_config_chain_YID_tb4.txt"
`define OPSUM_CONFIG_XID_FILE  "./testbench/PE_array_test_data/depthwise_separable_tb4_format/opsum_config_chain_XID_tb4.txt"
`define OPSUM_CONFIG_YID_FILE  "./testbench/PE_array_test_data/depthwise_separable_tb4_format/opsum_config_chain_YID_tb4.txt"
`define IFMAP_FILE             "./testbench/PE_array_test_data/depthwise_separable_tb4_format/ifmap.txt"
`define FILTER_FILE            "./testbench/PE_array_test_data/depthwise_separable_tb4_format/filter.txt"
`define IPSUM_FILE             "./testbench/PE_array_test_data/depthwise_separable_tb4_format/pointwise_ipsum.txt"
`define OPSUM_FILE             "./testbench/PE_array_test_data/depthwise_separable_tb4_format/opsum.txt"
`define GLB_MIRROR_FILE        "./testbench/PE_array_test_data/depthwise_separable_tb4_format/GLB_mirror.hex"
`define GOLDEN_FILE            "./testbench/PE_array_test_data/depthwise_separable_tb4_format/golden.hex"
parameter int FILT_ROW = 3;
parameter int FILT_COL = 3;
parameter int p = 4;
parameter int q = 4;
parameter int r = 1;
parameter int t = 4;
parameter int e = 4;
parameter int STRIDE = 1;
parameter int IFMAP_COL = 18;
parameter int OFMAP_COL = IFMAP_COL - FILT_ROW + 1;
parameter int LN_CONFIG = 27;
parameter int FILTER_RS = 3;
parameter [47:0]PE_EN= (1'b1 << (PE_ARRAY_H * PE_ARRAY_W)) - 1;
parameter int DEPTHWISE = 1;
parameter int PE_CONFIG = (DEPTHWISE << 12) + ((FILTER_RS - 1) << 10) + ((p - 1) << 7) + ((OFMAP_COL - 1) << 2) + (q - 1);
`elsif TBA12
`define DATA_SRC "./testbench/PE_array_test_data/depthwise_separable_tb5_format/"
`define CONFIG_SRC "./testbench/PE_array_test_data/depthwise_separable_tb5_format/"
`define IFMAP_CONFIG_XID_FILE  "./testbench/PE_array_test_data/depthwise_separable_tb5_format/ifmap_config_chain_XID_tb5.txt"
`define IFMAP_CONFIG_YID_FILE  "./testbench/PE_array_test_data/depthwise_separable_tb5_format/ifmap_config_chain_YID_tb5.txt"
`define FILTER_CONFIG_XID_FILE "./testbench/PE_array_test_data/depthwise_separable_tb5_format/filter_config_chain_XID_tb5.txt"
`define FILTER_CONFIG_YID_FILE "./testbench/PE_array_test_data/depthwise_separable_tb5_format/filter_config_chain_YID_tb5.txt"
`define IPSUM_CONFIG_XID_FILE  "./testbench/PE_array_test_data/depthwise_separable_tb5_format/ipsum_config_chain_XID_tb5.txt"
`define IPSUM_CONFIG_YID_FILE  "./testbench/PE_array_test_data/depthwise_separable_tb5_format/ipsum_config_chain_YID_tb5.txt"
`define OPSUM_CONFIG_XID_FILE  "./testbench/PE_array_test_data/depthwise_separable_tb5_format/opsum_config_chain_XID_tb5.txt"
`define OPSUM_CONFIG_YID_FILE  "./testbench/PE_array_test_data/depthwise_separable_tb5_format/opsum_config_chain_YID_tb5.txt"
`define IFMAP_FILE             "./testbench/PE_array_test_data/depthwise_separable_tb5_format/ifmap.txt"
`define FILTER_FILE            "./testbench/PE_array_test_data/depthwise_separable_tb5_format/filter.txt"
`define IPSUM_FILE             "./testbench/PE_array_test_data/depthwise_separable_tb5_format/pointwise_ipsum.txt"
`define OPSUM_FILE             "./testbench/PE_array_test_data/depthwise_separable_tb5_format/opsum.txt"
`define GLB_MIRROR_FILE        "./testbench/PE_array_test_data/depthwise_separable_tb5_format/GLB_mirror.hex"
`define GOLDEN_FILE            "./testbench/PE_array_test_data/depthwise_separable_tb5_format/golden.hex"
parameter int FILT_ROW = 3;
parameter int FILT_COL = 3;
parameter int p = 4;
parameter int q = 4;
parameter int r = 1;
parameter int t = 1;
parameter int e = 16;
parameter int STRIDE = 1;
parameter int IFMAP_COL = 18;
parameter int OFMAP_COL = IFMAP_COL - FILT_ROW + 1;
parameter int LN_CONFIG = 27;
parameter int FILTER_RS = 3;
parameter [47:0]PE_EN= (1'b1 << (PE_ARRAY_H * PE_ARRAY_W)) - 1;
parameter int DEPTHWISE = 1;
parameter int PE_CONFIG = (DEPTHWISE << 12) + ((FILTER_RS - 1) << 10) + ((p - 1) << 7) + ((OFMAP_COL - 1) << 2) + (q - 1);
`elsif TBA13
`define DATA_SRC "./testbench/PE_array_test_data/depthwise_separable_tb6_format/"
`define CONFIG_SRC "./testbench/PE_array_test_data/depthwise_separable_tb6_format/"
`define IFMAP_CONFIG_XID_FILE  "./testbench/PE_array_test_data/depthwise_separable_tb6_format/ifmap_config_chain_XID_tb6.txt"
`define IFMAP_CONFIG_YID_FILE  "./testbench/PE_array_test_data/depthwise_separable_tb6_format/ifmap_config_chain_YID_tb6.txt"
`define FILTER_CONFIG_XID_FILE "./testbench/PE_array_test_data/depthwise_separable_tb6_format/filter_config_chain_XID_tb6.txt"
`define FILTER_CONFIG_YID_FILE "./testbench/PE_array_test_data/depthwise_separable_tb6_format/filter_config_chain_YID_tb6.txt"
`define IPSUM_CONFIG_XID_FILE  "./testbench/PE_array_test_data/depthwise_separable_tb6_format/ipsum_config_chain_XID_tb6.txt"
`define IPSUM_CONFIG_YID_FILE  "./testbench/PE_array_test_data/depthwise_separable_tb6_format/ipsum_config_chain_YID_tb6.txt"
`define OPSUM_CONFIG_XID_FILE  "./testbench/PE_array_test_data/depthwise_separable_tb6_format/opsum_config_chain_XID_tb6.txt"
`define OPSUM_CONFIG_YID_FILE  "./testbench/PE_array_test_data/depthwise_separable_tb6_format/opsum_config_chain_YID_tb6.txt"
`define IFMAP_FILE             "./testbench/PE_array_test_data/depthwise_separable_tb6_format/ifmap.txt"
`define FILTER_FILE            "./testbench/PE_array_test_data/depthwise_separable_tb6_format/filter.txt"
`define IPSUM_FILE             "./testbench/PE_array_test_data/depthwise_separable_tb6_format/pointwise_ipsum.txt"
`define OPSUM_FILE             "./testbench/PE_array_test_data/depthwise_separable_tb6_format/opsum.txt"
`define GLB_MIRROR_FILE        "./testbench/PE_array_test_data/depthwise_separable_tb6_format/GLB_mirror.hex"
`define GOLDEN_FILE            "./testbench/PE_array_test_data/depthwise_separable_tb6_format/golden.hex"
parameter int FILT_ROW = 3;
parameter int FILT_COL = 3;
parameter int p = 4;
parameter int q = 4;
parameter int r = 2;
parameter int t = 4;
parameter int e = 2;
parameter int STRIDE = 1;
parameter int IFMAP_COL = 18;
parameter int OFMAP_COL = IFMAP_COL - FILT_ROW + 1;
parameter int LN_CONFIG = 31;
parameter int FILTER_RS = 3;
parameter [47:0]PE_EN= (1'b1 << (PE_ARRAY_H * PE_ARRAY_W)) - 1;
parameter int DEPTHWISE = 1;
parameter int PE_CONFIG = (DEPTHWISE << 12) + ((FILTER_RS - 1) << 10) + ((p - 1) << 7) + ((OFMAP_COL - 1) << 2) + (q - 1);

`elsif TBA14
`define DATA_SRC "./testbench/PE_array_test_data/depthwise_separable_p_leq_4/"
`define CONFIG_SRC "./testbench/PE_array_test_data/depthwise_separable_p_leq_4/"
`define IFMAP_CONFIG_XID_FILE  "./testbench/PE_array_test_data/depthwise_separable_p_leq_4/ifmap_config_chain_XID_tb5.txt"
`define IFMAP_CONFIG_YID_FILE  "./testbench/PE_array_test_data/depthwise_separable_p_leq_4/ifmap_config_chain_YID_tb5.txt"
`define FILTER_CONFIG_XID_FILE "./testbench/PE_array_test_data/depthwise_separable_p_leq_4/filter_config_chain_XID_tb5.txt"
`define FILTER_CONFIG_YID_FILE "./testbench/PE_array_test_data/depthwise_separable_p_leq_4/filter_config_chain_YID_tb5.txt"
`define IPSUM_CONFIG_XID_FILE  "./testbench/PE_array_test_data/depthwise_separable_p_leq_4/ipsum_config_chain_XID_tb5.txt"
`define IPSUM_CONFIG_YID_FILE  "./testbench/PE_array_test_data/depthwise_separable_p_leq_4/ipsum_config_chain_YID_tb5.txt"
`define OPSUM_CONFIG_XID_FILE  "./testbench/PE_array_test_data/depthwise_separable_p_leq_4/opsum_config_chain_XID_tb5.txt"
`define OPSUM_CONFIG_YID_FILE  "./testbench/PE_array_test_data/depthwise_separable_p_leq_4/opsum_config_chain_YID_tb5.txt"
`define IFMAP_FILE             "./testbench/PE_array_test_data/depthwise_separable_p_leq_4/ifmap.txt"
`define FILTER_FILE            "./testbench/PE_array_test_data/depthwise_separable_p_leq_4/filter.txt"
`define IPSUM_FILE             "./testbench/PE_array_test_data/depthwise_separable_p_leq_4/pointwise_ipsum.txt"
`define OPSUM_FILE             "./testbench/PE_array_test_data/depthwise_separable_p_leq_4/opsum.txt"
`define GLB_MIRROR_FILE        "./testbench/PE_array_test_data/depthwise_separable_p_leq_4/GLB_mirror.hex"
`define GOLDEN_FILE            "./testbench/PE_array_test_data/depthwise_separable_p_leq_4/golden.hex"
parameter int FILT_ROW = 3;
parameter int FILT_COL = 3;
parameter int p = 3;
parameter int q = 4;
parameter int r = 1;
parameter int t = 1;
parameter int e = 16;
parameter int STRIDE = 1;
parameter int IFMAP_COL = 18;
parameter int OFMAP_COL = IFMAP_COL - FILT_ROW + 1;
parameter int LN_CONFIG = 27;
parameter int FILTER_RS = 3;
parameter [47:0]PE_EN= (1'b1 << (PE_ARRAY_H * PE_ARRAY_W)) - 1;
parameter int DEPTHWISE = 1;
parameter int PE_CONFIG = (DEPTHWISE << 12) + ((FILTER_RS - 1) << 10) + ((p - 1) << 7) + ((OFMAP_COL - 1) << 2) + (q - 1);

`elsif TBA15
`define DATA_SRC "./testbench/PE_array_test_data/linear_tb1/"
`define CONFIG_SRC "./testbench/PE_array_test_data/linear_tb1/"
`define IFMAP_CONFIG_XID_FILE  "./testbench/PE_array_test_data/linear_tb1/ifmap_config_chain_XID_linear.txt"
`define IFMAP_CONFIG_YID_FILE  "./testbench/PE_array_test_data/linear_tb1/ifmap_config_chain_YID_linear.txt"
`define FILTER_CONFIG_XID_FILE "./testbench/PE_array_test_data/linear_tb1/filter_config_chain_XID_linear.txt"
`define FILTER_CONFIG_YID_FILE "./testbench/PE_array_test_data/linear_tb1/filter_config_chain_YID_linear.txt"
`define IPSUM_CONFIG_XID_FILE  "./testbench/PE_array_test_data/linear_tb1/ipsum_config_chain_XID_linear.txt"
`define IPSUM_CONFIG_YID_FILE  "./testbench/PE_array_test_data/linear_tb1/ipsum_config_chain_YID_linear.txt"
`define OPSUM_CONFIG_XID_FILE  "./testbench/PE_array_test_data/linear_tb1/opsum_config_chain_XID_linear.txt"
`define OPSUM_CONFIG_YID_FILE  "./testbench/PE_array_test_data/linear_tb1/opsum_config_chain_YID_linear.txt"
`define IFMAP_FILE             "./testbench/PE_array_test_data/linear_tb1/ifmap.txt"
`define FILTER_FILE            "./testbench/PE_array_test_data/linear_tb1/filter.txt"
`define IPSUM_FILE             "./testbench/PE_array_test_data/linear_tb1/ipsum.txt"
`define OPSUM_FILE             "./testbench/PE_array_test_data/linear_tb1/opsum.txt"
`define GLB_MIRROR_FILE        "./testbench/PE_array_test_data/linear_tb1/GLB_mirror.hex"
`define GOLDEN_FILE            "./testbench/PE_array_test_data/linear_tb1/golden.hex"
parameter int FILT_ROW = 1;
parameter int FILT_COL = 1;
parameter int p = 4;
parameter int q = 4;
parameter int r = 6;
parameter int t = 3;
parameter int e = 1;
parameter int STRIDE = 1;
parameter int IFMAP_COL = 1;
parameter int OFMAP_COL = IFMAP_COL - FILT_ROW + 1;
parameter int LN_CONFIG = 31;
parameter int FILTER_RS = 1;
parameter [47:0]PE_EN= (1'b1 << (PE_ARRAY_H * PE_ARRAY_W)) - 1;
parameter int DEPTHWISE = 0;
parameter int PE_CONFIG = (DEPTHWISE << 12) + ((FILTER_RS - 1) << 10) + ((p - 1) << 7) + ((OFMAP_COL - 1) << 2) + (q - 1);

`elsif TBA16
`define DATA_SRC "./testbench/PE_array_test_data/linear_tb2/"
`define CONFIG_SRC "./testbench/PE_array_test_data/linear_tb2/"
`define IFMAP_CONFIG_XID_FILE  "./testbench/PE_array_test_data/linear_tb2/ifmap_config_chain_XID_linear.txt"
`define IFMAP_CONFIG_YID_FILE  "./testbench/PE_array_test_data/linear_tb2/ifmap_config_chain_YID_linear.txt"
`define FILTER_CONFIG_XID_FILE "./testbench/PE_array_test_data/linear_tb2/filter_config_chain_XID_linear.txt"
`define FILTER_CONFIG_YID_FILE "./testbench/PE_array_test_data/linear_tb2/filter_config_chain_YID_linear.txt"
`define IPSUM_CONFIG_XID_FILE  "./testbench/PE_array_test_data/linear_tb2/ipsum_config_chain_XID_linear.txt"
`define IPSUM_CONFIG_YID_FILE  "./testbench/PE_array_test_data/linear_tb2/ipsum_config_chain_YID_linear.txt"
`define OPSUM_CONFIG_XID_FILE  "./testbench/PE_array_test_data/linear_tb2/opsum_config_chain_XID_linear.txt"
`define OPSUM_CONFIG_YID_FILE  "./testbench/PE_array_test_data/linear_tb2/opsum_config_chain_YID_linear.txt"
`define IFMAP_FILE             "./testbench/PE_array_test_data/linear_tb2/ifmap.txt"
`define FILTER_FILE            "./testbench/PE_array_test_data/linear_tb2/filter.txt"
`define IPSUM_FILE             "./testbench/PE_array_test_data/linear_tb2/ipsum.txt"
`define OPSUM_FILE             "./testbench/PE_array_test_data/linear_tb2/opsum.txt"
`define GLB_MIRROR_FILE        "./testbench/PE_array_test_data/linear_tb2/GLB_mirror.hex"
`define GOLDEN_FILE            "./testbench/PE_array_test_data/linear_tb2/golden.hex"
parameter int FILT_ROW = 1;
parameter int FILT_COL = 1;
parameter int p = 2;
parameter int q = 4;
parameter int r = 6;
parameter int t = 5;
parameter int e = 1;
parameter int STRIDE = 1;
parameter int IFMAP_COL = 1;
parameter int OFMAP_COL = IFMAP_COL - FILT_ROW + 1;
parameter int LN_CONFIG = 31;
parameter int FILTER_RS = 1;
parameter [47:0]PE_EN= (1'b1 << (PE_ARRAY_H * PE_ARRAY_W)) - 1;
parameter int DEPTHWISE = 0;
parameter int PE_CONFIG = (DEPTHWISE << 12) + ((FILTER_RS - 1) << 10) + ((p - 1) << 7) + ((OFMAP_COL - 1) << 2) + (q - 1);

`endif

`endif