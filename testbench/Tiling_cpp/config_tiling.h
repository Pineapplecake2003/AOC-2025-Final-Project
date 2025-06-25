#ifndef CONFIG_H
#define CONFIG_H

using std::string;

#ifdef TESTCASE_LAYER0
#define C 3
#define M 32
#define m 32
#define p 4
#define q 3
#define r 1
#define t 2
#define U 1
#define e 8
#define R 3
#define H 34 // H after padding
#define W 34 // W after padding
#define PAD 0
#define F ((W-R+2*PAD)/U+1)
#define E ((H-R+2*PAD)/U+1)
const string DATA_SRC = "./conv0/";
const string IFMAP_FILE = DATA_SRC + "ifmap.txt";
const string FILTER_FILE = DATA_SRC + "filter.txt";
const string BIAS_FILE = DATA_SRC + "bias.txt";
const string GOLDEN_FILE = DATA_SRC + "golden_output.txt";
#endif

#ifdef TESTCASE_LAYER1
#define C 32
#define M 64
#define m 64
#define p 4
#define q 4
#define r 2
#define t 2
#define U 1
#define e 4
#define R 3
#define H 34 // H after padding
#define W 34 // W after padding
#define PAD 0
#define F ((W-R+2*PAD)/U+1)
#define E ((H-R+2*PAD)/U+1)
const string DATA_SRC = "./conv1/";
const string IFMAP_FILE = DATA_SRC + "ifmap.txt";
const string FILTER_FILE = DATA_SRC + "filter.txt";
const string BIAS_FILE = DATA_SRC + "bias.txt";
const string GOLDEN_FILE = DATA_SRC + "golden_output.txt";
#endif

#ifdef TESTCASE_LAYER2
#define C 64
#define M 128
#define m 128
#define p 4
#define q 4
#define r 2
#define t 2
#define U 2
#define e 4
#define R 3
#define H 33 // H after padding
#define W 33 // W after padding
#define PAD 0
#define F ((W-R+2*PAD)/U+1)
#define E ((H-R+2*PAD)/U+1)
const string DATA_SRC = "./conv2/";
const string IFMAP_FILE = DATA_SRC + "ifmap.txt";
const string FILTER_FILE = DATA_SRC + "filter.txt";
const string BIAS_FILE = DATA_SRC + "bias.txt";
const string GOLDEN_FILE = DATA_SRC + "golden_output.txt";
#endif

#ifdef TESTCASE_LAYER3
#define C 128
#define M 128
#define m 128
#define p 4
#define q 4
#define r 2
#define t 2
#define U 1
#define e 4
#define R 3
#define H 18 // H after padding
#define W 18 // W after padding
#define PAD 0
#define F ((W-R+2*PAD)/U+1)
#define E ((H-R+2*PAD)/U+1)
const string DATA_SRC = "./conv3/";
const string IFMAP_FILE = DATA_SRC + "ifmap.txt";
const string FILTER_FILE = DATA_SRC + "filter.txt";
const string BIAS_FILE = DATA_SRC + "bias.txt";
const string GOLDEN_FILE = DATA_SRC + "golden_output.txt";
#endif

#ifdef TESTCASE_LAYER4
#define C 128
#define M 256
#define m 256
#define p 4
#define q 4
#define r 2
#define t 2
#define U 2
#define e 4
#define R 3
#define H 17 // H after padding
#define W 17 // W after padding
#define PAD 0
#define F ((W-R+2*PAD)/U+1)
#define E ((H-R+2*PAD)/U+1)
const string DATA_SRC = "./conv4/";
const string IFMAP_FILE = DATA_SRC + "ifmap.txt";
const string FILTER_FILE = DATA_SRC + "filter.txt";
const string BIAS_FILE = DATA_SRC + "bias.txt";
const string GOLDEN_FILE = DATA_SRC + "golden_output.txt";
#endif

#ifdef TESTCASE_LAYER5
#define C 256
#define M 256
#define m 256
#define p 4
#define q 4
#define r 2
#define t 2
#define U 2
#define e 4
#define R 3
#define H 10 // H after padding
#define W 10 // W after padding
#define PAD 0
#define F ((W-R+2*PAD)/U+1)
#define E ((H-R+2*PAD)/U+1)
const string DATA_SRC = "./conv5/";
const string IFMAP_FILE = DATA_SRC + "ifmap.txt";
const string FILTER_FILE = DATA_SRC + "filter.txt";
const string BIAS_FILE = DATA_SRC + "bias.txt";
const string GOLDEN_FILE = DATA_SRC + "golden_output.txt";
#endif

#ifdef TESTCASE_LAYER6
#define C 256
#define M 512
#define m 512
#define p 4
#define q 4
#define r 2
#define t 2
#define U 2
#define e 4
#define R 3
#define H 9 // H after padding
#define W 9 // W after padding
#define PAD 0
#define F ((W-R+2*PAD)/U+1)
#define E ((H-R+2*PAD)/U+1)
const string DATA_SRC = "./conv6/";
const string IFMAP_FILE = DATA_SRC + "ifmap.txt";
const string FILTER_FILE = DATA_SRC + "filter.txt";
const string BIAS_FILE = DATA_SRC + "bias.txt";
const string GOLDEN_FILE = DATA_SRC + "golden_output.txt";
#endif

#ifdef TESTCASE_LAYER7
#define C 512
#define M 512
#define m 512
#define p 4
#define q 4
#define r 2
#define t 2
#define U 1
#define e 4
#define R 3
#define H 6 // H after padding
#define W 6 // W after padding
#define PAD 0
#define F ((W-R+2*PAD)/U+1)
#define E ((H-R+2*PAD)/U+1)
const string DATA_SRC = "./conv7/";
const string IFMAP_FILE = DATA_SRC + "ifmap.txt";
const string FILTER_FILE = DATA_SRC + "filter.txt";
const string BIAS_FILE = DATA_SRC + "bias.txt";
const string GOLDEN_FILE = DATA_SRC + "golden_output.txt";
#endif

#ifdef TESTCASE_LAYER8
#define C 512
#define M 1024
#define m 1024
#define p 4
#define q 4
#define r 2
#define t 4
#define U 2
#define e 2
#define R 3
#define H 5 // H after padding
#define W 5 // W after padding
#define PAD 0
#define F ((W-R+2*PAD)/U+1)
#define E ((H-R+2*PAD)/U+1)
const string DATA_SRC = "./conv8/";
const string IFMAP_FILE = DATA_SRC + "ifmap.txt";
const string FILTER_FILE = DATA_SRC + "filter.txt";
const string BIAS_FILE = DATA_SRC + "bias.txt";
const string GOLDEN_FILE = DATA_SRC + "golden_output.txt";
#endif

#ifdef TESTCASE_LAYER9
#define C 1032
#define M 12
#define m 12
#define p 4
#define q 4
#define r 6
#define t 3
#define U 1
#define e 1
#define R 1
#define H 1 
#define W 1 
#define PAD 0
#define F ((W-R+2*PAD)/U+1)
#define E ((H-R+2*PAD)/U+1)
const string DATA_SRC = "./linear/";
const string IFMAP_FILE = DATA_SRC + "ifmap.txt";
const string FILTER_FILE = DATA_SRC + "filter.txt";
const string BIAS_FILE = DATA_SRC + "bias.txt";
const string GOLDEN_FILE = DATA_SRC + "golden_output.txt";
#endif

#endif