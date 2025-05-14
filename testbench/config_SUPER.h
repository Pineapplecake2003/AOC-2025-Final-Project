#ifndef CONFIG_H
#define CONFIG_H

#ifndef TB_SUPER
#define TB_SUPER 0
#endif
using std::string;

const int CYCLE = 10;

#if (TB_SUPER == 0)
const string IFMAP_FILE = "./testbench/PE_test_data/tb0/ifmap_tb0.txt";
const string FILT_FILE = "./testbench/PE_test_data/tb0/filter_tb0.txt";
const string IPSUM_FILE = "./testbench/PE_test_data/tb0/ipsum_tb0.txt";
const string OPSUM_FILE = "./testbench/PE_test_data/tb0/ofmap_tb0.txt";
const int IFMAP_COL = 34;
const int OFMAP_COL = 32;
const int FILT_COL = 3;
const int I_CH = 3;
const int OFMAP_CH = 4;
const int FILTER_RS = 3;
const int DEPTHWISE = 0;
#elif (TB_SUPER == 1)
const string IFMAP_FILE = "./testbench/PE_test_data/tb1/ifmap_tb1.txt";
const string FILT_FILE = "./testbench/PE_test_data/tb1/filter_tb1.txt";
const string IPSUM_FILE = "./testbench/PE_test_data/tb1/ipsum_tb1.txt";
const string OPSUM_FILE = "./testbench/PE_test_data/tb1/ofmap_tb1.txt";
const int IFMAP_COL = 34;
const int OFMAP_COL = 32;
const int FILT_COL = 3;
const int I_CH = 3;
const int OFMAP_CH = 4;
const int FILTER_RS = 3;
const int DEPTHWISE = 0;
#elif (TB_SUPER == 2)
const string IFMAP_FILE = "./testbench/PE_test_data/tb2/ifmap_tb2.txt";
const string FILT_FILE = "./testbench/PE_test_data/tb2/filter_tb2.txt";
const string IPSUM_FILE = "./testbench/PE_test_data/tb2/ipsum_tb2.txt";
const string OPSUM_FILE = "./testbench/PE_test_data/tb2/ofmap_tb2.txt";
const int IFMAP_COL = 18;
const int OFMAP_COL = 16;
const int FILT_COL = 3;
const int I_CH = 4;
const int OFMAP_CH = 4;
const int FILTER_RS = 3;
const int DEPTHWISE = 0;
#elif (TB_SUPER == 3)
// pointwise
const string IFMAP_FILE = "./testbench/PE_test_data/tb3/ifmap_tb3.txt";
const string FILT_FILE = "./testbench/PE_test_data/tb3/filter_tb3.txt";
const string IPSUM_FILE = "./testbench/PE_test_data/tb3/ipsum_tb3.txt";
const string OPSUM_FILE = "./testbench/PE_test_data/tb3/ofmap_tb3.txt";
const int IFMAP_COL = 32;
const int OFMAP_COL = 32;
const int FILT_COL = 1;
const int I_CH = 4;
const int OFMAP_CH = 4;
const int FILTER_RS = 1;
const int DEPTHWISE = 0;
#elif (TB_SUPER == 4)
// depthwise
const string IFMAP_FILE = "./testbench/PE_test_data/tb4/ifmap_tb4.txt";
const string FILT_FILE = "./testbench/PE_test_data/tb4/filter_tb4.txt";
const string IPSUM_FILE = "./testbench/PE_test_data/tb4/ipsum_tb4.txt";
const string OPSUM_FILE = "./testbench/PE_test_data/tb4/ofmap_tb4.txt";
const int IFMAP_COL = 18;
const int OFMAP_COL = 16;
const int FILT_COL = 3;
const int I_CH = 4;
const int OFMAP_CH = 4;
const int FILTER_RS = 3;
const int DEPTHWISE = 1;
#elif (TB_SUPER == 5)
// depthwise
const string IFMAP_FILE = "./testbench/PE_test_data/tb5/ifmap_tb5.txt";
const string FILT_FILE = "./testbench/PE_test_data/tb5/filter_tb5.txt";
const string IPSUM_FILE = "./testbench/PE_test_data/tb5/ipsum_tb5.txt";
const string OPSUM_FILE = "./testbench/PE_test_data/tb5/ofmap_tb5.txt";
const int IFMAP_COL = 18;
const int OFMAP_COL = 16;
const int FILT_COL = 3;
const int I_CH = 3;
const int OFMAP_CH = 3;
const int FILTER_RS = 3;
const int DEPTHWISE = 1;
#elif (TB_SUPER == 6)
// depthwise
const string IFMAP_FILE = "./testbench/PE_test_data/tb6/ifmap_tb6.txt";
const string FILT_FILE = "./testbench/PE_test_data/tb6/filter_tb6.txt";
const string IPSUM_FILE = "./testbench/PE_test_data/tb6/ipsum_tb6.txt";
const string OPSUM_FILE = "./testbench/PE_test_data/tb6/ofmap_tb6.txt";
const int IFMAP_COL = 34;
const int OFMAP_COL = 32;
const int FILT_COL = 3;
const int I_CH = 3;
const int OFMAP_CH = 3;
const int FILTER_RS = 3;
const int DEPTHWISE = 1;

#elif (TB_SUPER == 7)
// depthwise separable
const string IFMAP_FILE = "./testbench/PE_test_data/depthwise_separable0/ifmap.txt";
const string FILT_FILE =  "./testbench/PE_test_data/depthwise_separable0/filter.txt";
const string IPSUM_FILE = "./testbench/PE_test_data/depthwise_separable0/pointwise_ipsum.txt";
const string OPSUM_FILE = "./testbench/PE_test_data/depthwise_separable0/opsum.txt";
const int IFMAP_COL = 6;
const int OFMAP_COL = 4;
const int FILT_COL = 3;
const int I_CH = 4;
const int OFMAP_CH = 4;
const int FILTER_RS = 3;
const int DEPTHWISE = 1;
#elif (TB_SUPER == 8)
// depthwise separable
const string IFMAP_FILE = "./testbench/PE_test_data/depthwise_separable1/ifmap.txt";
const string FILT_FILE =  "./testbench/PE_test_data/depthwise_separable1/filter.txt";
const string IPSUM_FILE = "./testbench/PE_test_data/depthwise_separable1/pointwise_ipsum.txt";
const string OPSUM_FILE = "./testbench/PE_test_data/depthwise_separable1/opsum.txt";
const int IFMAP_COL = 34;
const int OFMAP_COL = 32;
const int FILT_COL = 3;
const int I_CH = 4;
const int OFMAP_CH = 4;
const int FILTER_RS = 3;
const int DEPTHWISE = 1;
#elif (TB_SUPER == 9)
// depthwise separable
const string IFMAP_FILE = "./testbench/PE_test_data/depthwise_separable2/ifmap.txt";
const string FILT_FILE =  "./testbench/PE_test_data/depthwise_separable2/filter.txt";
const string IPSUM_FILE = "./testbench/PE_test_data/depthwise_separable2/pointwise_ipsum.txt";
const string OPSUM_FILE = "./testbench/PE_test_data/depthwise_separable2/opsum.txt";
const int IFMAP_COL = 34;
const int OFMAP_COL = 32;
const int FILT_COL = 3;
const int I_CH = 3;
const int OFMAP_CH = 3;
const int FILTER_RS = 3;
const int DEPTHWISE = 1;
#elif (TB_SUPER == 10)
// depthwise separable
const string IFMAP_FILE = "./testbench/PE_test_data/depthwise_separable3/ifmap.txt";
const string FILT_FILE =  "./testbench/PE_test_data/depthwise_separable3/filter.txt";
const string IPSUM_FILE = "./testbench/PE_test_data/depthwise_separable3/pointwise_ipsum.txt";
const string OPSUM_FILE = "./testbench/PE_test_data/depthwise_separable3/opsum.txt";
const int IFMAP_COL = 34;
const int OFMAP_COL = 32;
const int FILT_COL = 3;
const int I_CH = 2;
const int OFMAP_CH = 2;
const int FILTER_RS = 3;
const int DEPTHWISE = 1;
#endif

#endif  // CONFIG_H