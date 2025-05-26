`ifndef LAB3_DEFINE
`define LAB3_DEFINE

`define DATA_BITS 32
`define FILT_R 3
`define FILT_S 3

/* PE Define */
`define IFMAP_SIZE 8
`define FILTER_SIZE 8
`define PSUM_SIZE 32
`define IFMAP_SPAD_LEN 12
`define FILTER_SPAD_LEN 48
`define OFMAP_SPAD_LEN 4
`define IFMAP_INDEX_BIT 4
`define FILTER_INDEX_BIT 6
`define OFMAP_INDEX_BIT 2
`define OFMAP_COL_BIT 5

/* PE Array Define*/
`define XID_BITS 5
`define YID_BITS 3
`define DEFAULT_XID  (2**`XID_BITS - 1)
`define DEFAULT_YID  (2**`YID_BITS - 1)
`define NUMS_PE_ROW 6
`define NUMS_PE_COL 8
`define DATA_SIZE 32
`define CONFIG_SIZE 13
/*
+------+------+------+------+------+------+------+------+------+------+------+------+------+
|    12|    11|    10|     9|     8|     7|     6|     5|     4|     3|     2|     1|     0|  
+------+------+------+------+------+------+------+------+------+------+------+------+------+
|depthw| FILTER_RS-1 |  U-1 |    p - 1    |              F - 1               |    q - 1    |
+------+------+------+------+------+------+------+------+------+------+------+------+------+
*/
`endif
