from .fuse import COMPILER_NAME
import math

tvm_auto_args_NOTES = {
    f"{COMPILER_NAME}_qconv2d_relu_maxpool":[
        "input",
        "input_scale",
        "input_zero_point",
        "weight",
        "weight_scale",
        "weight_zero_point",
        "bias",
        "bias_scale",
        "bias_zero_point",
        "dequantize_scale",
        "dequantize_zero_point",
        "quantize_zero_point",
    ],
    f"{COMPILER_NAME}_qconv2d_relu":[
        "input",
        "input_scale",
        "input_zero_point",
        "weight",
        "weight_scale",
        "weight_zero_point",
        "bias",
        "bias_scale",
        "bias_zero_point",
        "dequantize_scale",
        "dequantize_zero_point",
    ],
    f"{COMPILER_NAME}_qlinear_relu":[
        "input",
        "input_scale",
        "input_zero_point",
        "weight",
        "weight_scale",
        "weight_zero_point",
        "bias",
        "bias_scale",
        "bias_zero_point",
        "dequantize_scale",
        "dequantize_zero_point",
    ],
    f"{COMPILER_NAME}_qlinear":[
        "input",
        "input_scale",
        "input_zero_point",
        "weight",
        "weight_scale",
        "weight_zero_point",
        "bias",
        "bias_scale",
        "bias_zero_point",
        "dequantize_scale",
        "dequantize_zero_point",
    ],
    f"{COMPILER_NAME}_flatten":[
        "input",
        "input_scale",
        "input_zero_point",
    ],
    f"{COMPILER_NAME}_qglobal_avg_pool2d": [
        "input",
        "input_scale",
        "input_zero_point",
    ],
    f"{COMPILER_NAME}_quantize":[
        "input",
        "input_scale",
        "input_zero_point",
    ],
    f"{COMPILER_NAME}_dequantize":[
        "input",
        "input_scale",
        "input_zero_point",
    ],
}

def convert_log(x):
    return -int(math.log2(x))

tvm_c_func_call_gen = {
    f"{COMPILER_NAME}_qconv2d_relu_maxpool": lambda config: f"""
#ifndef CPU_ONLY
  qconv2d_relu_maxpool(
#else
  qconv2d_relu_maxpool_cpu(
#endif
    {config["input"]}, {config["weight"]}, {config["output"]},
    {config["bias"]}, {config["output_len"]}, {config["input_len"]}, {config["weight_len"]},
#ifndef CPU_ONLY
    {config["m"]}, {config["e"]}, {config["p"]}, {config["q"]}, {config["r"]}, {config["t"]},
#endif
    {config["PAD"]}, {config["U"]}, {config["R"]}, {config["S"]},
    {config["C_F"]}, {config["M"]}, {config["W"]}, {config["H"]},{config["C_I"]},
    {convert_log(config["input_scale"] * config["weight_scale"] / config["dequantize_scale"])}
  );
""",
    f"{COMPILER_NAME}_qconv2d_relu":lambda config:f"""
#ifndef CPU_ONLY
  qconv2d_relu(
#else
  qconv2d_relu_cpu(
#endif
    {config["input"]}, {config["weight"]}, {config["output"]},
    {config["bias"]}, {config["output_len"]}, {config["input_len"]}, {config["weight_len"]},
#ifndef CPU_ONLY
    {config["m"]}, {config["e"]}, {config["p"]}, {config["q"]}, {config["r"]}, {config["t"]},
#endif
    {config["PAD"]}, {config["U"]}, {config["R"]}, {config["S"]},
    {config["C_F"]}, {config["M"]}, {config["W"]}, {config["H"]},{config["C_I"]},
    {convert_log(config["input_scale"] * config["weight_scale"] / config["dequantize_scale"])}
  );
""",
    f"{COMPILER_NAME}_qlinear_relu": lambda config: f"""
  qlinear_relu_cpu(
    {config["input"]}, {config["weight"]}, {config["output"]},
    {config["bias"]}, {config["output_len"]}, {config["input_len"]}, {config["weight_len"]},
    {convert_log(config["input_scale"] * config["weight_scale"] / config["dequantize_scale"])}
  );
""",
    f"{COMPILER_NAME}_qlinear": lambda config: f"""
  qlinear_cpu(
    {config["input"]}, {config["weight"]}, {config["output"]},
    {config["bias"]}, {config["output_len"]}, {config["input_len"]}, {config["weight_len"]},
    {convert_log(config["input_scale"] * config["weight_scale"] / config["dequantize_scale"])}
  );
""",
    f"{COMPILER_NAME}_qglobal_avg_pool2d": lambda config: f"""
  qglobal_avg_pool2d_cpu(
    {config["input"]}, {config["output"]},
    {config["C_I"]}, {config["H"]}, {config["W"]},
    {convert_log(config["input_scale"])}
  );
""",
    f"{COMPILER_NAME}_quantize": lambda config: f"""
  quantize_cpu(
    {config["input"]}, {config["output"]},
    {config["output_len"]},
    {convert_log(config["input_scale"])}
  );
""",
    f"{COMPILER_NAME}_dequantize": lambda config: f"""
  dequantize_cpu(
    {config["input"]}, {config["output"]},
    {config["output_len"]},
    {convert_log(config["input_scale"])}
  );
""",  
}