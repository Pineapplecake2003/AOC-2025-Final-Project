#include <fstream>
#include <iomanip>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>
#include "./testbench/config_PE_array.h"  // 必須定義 PE_ARRAY_H 與 PE_ARRAY_W
using namespace std;

// 將 vector 中的資料輸出成十六進位格式檔案
void write_vector_to_hex_file(const string& filename, const vector<int>& data, bool isXID) {
    ofstream fout(filename);
    for (int val : data) {
        if (isXID) {
            fout << hex << setw(2) << setfill('0') << val << endl;  // XID: 兩位補0
        } else {
            fout << hex << val << endl;  // YID: 原樣，不補0
        }
    }
    fout.close();
}

// 載入設定資料並輸出為 hex
void load_config_data(vector<int>& GIN_ifmap_XID_config, vector<int>& GIN_ifmap_YID_config,
                      vector<int>& GIN_filter_XID_config, vector<int>& GIN_filter_YID_config,
                      vector<int>& GIN_ipsum_XID_config, vector<int>& GIN_ipsum_YID_config,
                      vector<int>& GON_opsum_XID_config, vector<int>& GON_opsum_YID_config) {
    string line, value;
    stringstream ss;

    // IFMAP XID
    ifstream ifmap_XID_config_file(IFMAP_CONFIG_XID_FILE);
    getline(ifmap_XID_config_file, line);
    ifmap_XID_config_file.close();
    ss.str(line); ss.clear();
    for (int i = 0; i < PE_ARRAY_H * PE_ARRAY_W && getline(ss, value, ','); i++) {
        GIN_ifmap_XID_config[i] = stoi(value);
    }

    // IFMAP YID
    ifstream ifmap_YID_config_file(IFMAP_CONFIG_YID_FILE);
    getline(ifmap_YID_config_file, line);
    ifmap_YID_config_file.close();
    ss.str(line); ss.clear();
    for (int i = 0; i < PE_ARRAY_H && getline(ss, value, ','); i++) {
        GIN_ifmap_YID_config[i] = stoi(value);
    }

    // FILTER XID
    ifstream filter_XID_config_file(FILTER_CONFIG_XID_FILE);
    getline(filter_XID_config_file, line);
    filter_XID_config_file.close();
    ss.str(line); ss.clear();
    for (int i = 0; i < PE_ARRAY_H * PE_ARRAY_W && getline(ss, value, ','); i++) {
        GIN_filter_XID_config[i] = stoi(value);
    }

    // FILTER YID
    ifstream filter_YID_config_file(FILTER_CONFIG_YID_FILE);
    getline(filter_YID_config_file, line);
    filter_YID_config_file.close();
    ss.str(line); ss.clear();
    for (int i = 0; i < PE_ARRAY_H && getline(ss, value, ','); i++) {
        GIN_filter_YID_config[i] = stoi(value);
    }

    // IPSUM XID
    ifstream ipsum_XID_config_file(IPSUM_CONFIG_XID_FILE);
    getline(ipsum_XID_config_file, line);
    ipsum_XID_config_file.close();
    ss.str(line); ss.clear();
    for (int i = 0; i < PE_ARRAY_H * PE_ARRAY_W && getline(ss, value, ','); i++) {
        GIN_ipsum_XID_config[i] = stoi(value);
    }

    // IPSUM YID
    ifstream ipsum_YID_config_file(IPSUM_CONFIG_YID_FILE);
    getline(ipsum_YID_config_file, line);
    ipsum_YID_config_file.close();
    ss.str(line); ss.clear();
    for (int i = 0; i < PE_ARRAY_H && getline(ss, value, ','); i++) {
        GIN_ipsum_YID_config[i] = stoi(value);
    }

    // OPSUM XID
    ifstream opsum_XID_config_file(OPSUM_CONFIG_XID_FILE);
    getline(opsum_XID_config_file, line);
    opsum_XID_config_file.close();
    ss.str(line); ss.clear();
    for (int i = 0; i < PE_ARRAY_H * PE_ARRAY_W && getline(ss, value, ','); i++) {
        GON_opsum_XID_config[i] = stoi(value);
    }

    // OPSUM YID
    ifstream opsum_YID_config_file(OPSUM_CONFIG_YID_FILE);
    getline(opsum_YID_config_file, line);
    opsum_YID_config_file.close();
    ss.str(line); ss.clear();
    for (int i = 0; i < PE_ARRAY_H && getline(ss, value, ','); i++) {
        GON_opsum_YID_config[i] = stoi(value);
    }

    // 輸出成檔案
    write_vector_to_hex_file("ifmap_XID.txt", GIN_ifmap_XID_config, true);
    write_vector_to_hex_file("ifmap_YID.txt", GIN_ifmap_YID_config, false);
    write_vector_to_hex_file("filter_XID.txt", GIN_filter_XID_config, true);
    write_vector_to_hex_file("filter_YID.txt", GIN_filter_YID_config, false);
    write_vector_to_hex_file("ipsum_XID.txt", GIN_ipsum_XID_config, true);
    write_vector_to_hex_file("ipsum_YID.txt", GIN_ipsum_YID_config, false);
    write_vector_to_hex_file("opsum_XID.txt", GON_opsum_XID_config, true);
    write_vector_to_hex_file("opsum_YID.txt", GON_opsum_YID_config, false);
}

int main() {
    // 宣告所有 config 向量
    vector<int> GIN_ifmap_XID_config(PE_ARRAY_H * PE_ARRAY_W);
    vector<int> GIN_ifmap_YID_config(PE_ARRAY_H);
    vector<int> GIN_filter_XID_config(PE_ARRAY_H * PE_ARRAY_W);
    vector<int> GIN_filter_YID_config(PE_ARRAY_H);
    vector<int> GIN_ipsum_XID_config(PE_ARRAY_H * PE_ARRAY_W);
    vector<int> GIN_ipsum_YID_config(PE_ARRAY_H);
    vector<int> GON_opsum_XID_config(PE_ARRAY_H * PE_ARRAY_W);
    vector<int> GON_opsum_YID_config(PE_ARRAY_H);

    // 執行載入與輸出
    load_config_data(GIN_ifmap_XID_config, GIN_ifmap_YID_config,
                     GIN_filter_XID_config, GIN_filter_YID_config,
                     GIN_ipsum_XID_config, GIN_ipsum_YID_config,
                     GON_opsum_XID_config, GON_opsum_YID_config);

    cout << "Configuration data loaded and saved in hex format." << endl;
    return 0;
}
