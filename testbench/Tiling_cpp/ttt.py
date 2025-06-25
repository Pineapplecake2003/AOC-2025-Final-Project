import numpy as np

# 設定參數
M = 32
m = 32
C = 3
H = 34
W = 34
R = 3
U = 1  # stride

E = (H - R) // U + 1 
F = (W - R) // U + 1 

# 產生 ifmap[h][w][c] = h + w + c
ifmap = np.zeros((H, W, C), dtype=np.uint8)
for h in range(H):
    for w in range(W):
        for c in range(C):
            ifmap[h][w][c] = h + w + c

# filter: 全設為 1
filter_ = np.zeros((R, R, C, M), dtype=np.int8)
# for r in range(R):
#     for s in range(R):
#         for c in range(C):
#             for m_ in range(M):
#                 filter_[r][s][c][m_] = r - s + c - m_
for m_ in range(M):
    for r in range(R):
        for s in range(R):
            for c in range(C):
                filter_[r][s][c][m_] = r - s + c - m_
# bias: 全 0
bias = np.zeros(M, dtype=np.int32)

# 計算卷積 output[e][f][m]
output = np.zeros((E, F, M), dtype=np.int32)
for e in range(E):
    for f in range(F):
        for m_ in range(M):
            acc = 0
            for c in range(C):
                for r in range(R):
                    for s in range(R):
                        acc += int(ifmap[U * e + r][U * f + s][c]) * int(filter_[r][s][c][m_])
            output[e][f][m_] = acc + bias[m_]

# 檢查 sample 值
print("Sample output at (0,0):", output[0][0])

# 儲存檔案：flatten 為 1 維
def save_flat(filename, arr):
    flat = arr.flatten()
    with open(filename, "w") as f:
        f.write(",".join(str(x) for x in flat) + "\n")

save_flat("./conv0/ifmap.txt", ifmap)
save_flat("./conv0/filter.txt", filter_)
save_flat("./conv0/bias.txt", bias)
save_flat("./conv0/golden_output.txt", output)


