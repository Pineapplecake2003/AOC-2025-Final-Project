import tvm
import os
import numpy as np

from .fuse import COMPILER_NAME
from .fuse import pattern_table
from .note import *

PATTERN_TABLE = [p[0] for p in pattern_table()]
BUF_PREFIX = "buf_"

##############################################################################################
# Codegen
from tvm._ffi import registry
from abc import ABC, abstractmethod

class Output(dict):
    def __init__(self, name="", dtype="", need_copy=False, size=0):
        self.name = name
        self.dtype = dtype
        self.need_copy = need_copy
        self.size = size

    def __getitem__(self, name):
        if name=="name":
            return self.name
        elif name=="dtype":
            return self.dtype
        elif name=="need_copy":
            return self.need_copy
        elif name=="size":
            return self.size
        else:
            return None

    def __repr__(self):
        d = {
            "name":self.name,
            "dtype":self.dtype,
            "need_copy":self.need_copy,
            "size":self.size
        }
        return str(d)

class Data(dict):
    def __init__(self):
        self.name = None
        self.dtype = None
        self.struct_info = None
        self.data = None

    def __getitem__(self, name):
        if name=="name":
            return self.name
        elif name=="dtype":
            return self.dtype
        elif name=="struct_info":
            return self.struct_info
        elif name=="data":
            return self.data
        else:
            return None

##############################################################################################
### Abstract Class
###

class CodegenCBase(ABC):
    def __init__(self):
        super().__init__()
        self.code_stream = []
        self.indent = 0

    def _append_code(self, line=""):
        self.code_stream.append(" " * self.indent + line)

    def get_code(self):
        return "\n".join(self.code_stream)

    def print_indents(self):
        self._append_code()

    def enter_scope(self):
        self.indent += 2

    def exit_scope(self):
        if self.indent < 2:
            raise ValueError("Wrong indent level detected.")
        self.indent -= 2

    def generate_backend_c_func(self, func_name, args, const_arr_name, outs):
        self._append_code(f'int model_on_{COMPILER_NAME}(')
        for i, arg in enumerate(args):
            dtype_str = self.get_dtype_string(arg)
            self._append_code(f"{dtype_str}* arg{i},")
        for i, out in enumerate(outs[:-1]):
            dtype_str = self.get_dtype_string(arg)
            self._append_code(f"{dtype_str}* out{i},")
        self._append_code(f"{outs[-1]['dtype']}* out{len(outs) - 1})")
        self._append_code(f"{{")
        self.enter_scope()

        self._append_code(f"{func_name}_(")
        for i, arg in enumerate(args):
            dtype_str = self.get_dtype_string(arg)
            self._append_code(f"arg{i},")
        for i, out in enumerate(outs[:-1]):
            self._append_code(f"out{i},")
        self._append_code(f"out{len(outs) - 1});")
        self._append_code("return 0;")
        self.exit_scope()
        self._append_code("}")

    @abstractmethod
    def jit(self, outs):
        pass

    def jit_impl(self, ext_func_id, args, body, const_arr_name, outs):
        if const_arr_name:
            self._append_code(const_arr_name)
        self._append_code(f'\nvoid {ext_func_id}_(')

        for arg in args:
            dtype_str = self.get_dtype_string(arg)
            self._append_code(f"{dtype_str}* {arg.name_hint}, ")
        for i, out in enumerate(outs[:-1]):
            self._append_code(f"{out['dtype']}* out{i}, ")
        self._append_code(f"{outs[-1]['dtype']}* out{len(outs) - 1}) {{")
        self.enter_scope()

        self._append_code("")
        for stmt in body:
            self._append_code(stmt)

        for i, out in enumerate(outs):
            if not out.need_copy:
                continue
            self._append_code(f"memcpy(out{i}, {out['name']}, 4 * {out['size']});")

        self.exit_scope()
        self._append_code("}")

        self.generate_backend_c_func(ext_func_id, args, const_arr_name, outs)
        return self.get_code()

    def get_dtype_string(self, var):
        if isinstance(var, tvm.ir.tensor_type.TensorType):
            ttype = var.dtype
        else:
            ttype = var.checked_type.dtype

        if ttype == "float32":
            return "float"
        elif ttype == "int32":
            return "int32_t"
        elif ttype == "int64":
            return "int64_t"
        elif ttype == "int8":
            return "int8_t"
        elif ttype == "uint8":
            return "uint8_t"
        else:
            raise ValueError(f"Unsupported dtype {ttype}")

    def get_shape(self, var):
        return var.shape

    def create_const_var(self, symbol, const_id):
        return f"{symbol}_const_{const_id}"

class CSourceModuleCodegenBase(ABC):
    def __init__(self):
        super().__init__()

    @abstractmethod
    def create_c_source_module(self, ref):
        pass

    def get_ext_symbol(self, func):
        name_node = func.attrs["global_symbol"]
        if not name_node:
            raise ValueError("Fail to retrieve external symbol.")
        return str(name_node)

##############################################################################################
### Abstract Class
###

from typing import Tuple, List
from io import StringIO, BytesIO
from tvm.relay.expr import Call, Constant, Var, Tuple, TupleGetItem

class CodegenC(CodegenCBase):
    def __init__(self, ext_func_id: str):
        super().__init__()
        self.ext_func_id = ext_func_id
        self.func_idx = 0
        self.buf_idx = 0
        self.const_idx = 0
        self.ext_func_args = []
        self.ext_func_body = []
        self.const_array_name = ""
        self.func_decl = []
        self.const_vars = []

    def create_data_reference(self, symbol, const_id, cn):
        dtype = self.get_dtype_string(cn.checked_type)
        var_name = f"{symbol}_const_{const_id}"

        var_data = Data()
        var_data.name = var_name
        var_data.dtype = dtype
        var_data.data = cn.data
        var_data.struct_info = cn.data.shape

        self.const_vars.append(var_data)
        return f"({dtype}*){var_name}"

    def get_size(self, parameter):
        if parameter == None:
            return None
        shape = self.get_shape(parameter.checked_type)
        size = 1
        for dim in shape:
            size *= dim
        return size

    def visit_expr_default(self, op):
        raise RuntimeError(f"C codegen doesn't support: {op.type_key}")

    def visit_expr(self, node):
        if isinstance(node, Var):
            return self.visit_var(node)
        elif isinstance(node, Tuple):
            return self.visit_tuple(node)
        elif isinstance(node, TupleGetItem):
            return self.visit_tuple_get_item(node)
        elif isinstance(node, Constant):
            return self.visit_constant(node)
        elif isinstance(node, Call):
            return self.visit_call(node)
        else:
            return self.visit_expr_default(node)

    def visit_var(self, node):
        self.ext_func_args.append(node)
        output = Output(name=node.name_hint, size=self.get_size(node))
        return [output]

    def visit_tuple(self, node):
        outs = []
        for field in node.fields:
            res = self.visit_expr(field)
            if len(res) != 1:
                raise RuntimeError("Tuple nesting is not supported")
            outs.append(res[0])
        return outs

    def visit_tuple_get_item(self, op):
        res = self.visit_expr(op.tuple)
        if len(res) <= op.index:
            raise RuntimeError("Index out of bounds in tuple access")
        return [res[op.index]]

    def visit_constant(self, cn):
        output = Output()
        output.name = self.create_data_reference(self.ext_func_id, self.const_idx, cn)
        dtype = self.get_dtype_string(cn.checked_type)

        if not self.const_array_name:
            self.const_array_name = ""

        if dtype not in {"float", "int32_t", "int64_t", "int8_t", "uint8_t"}:
            raise RuntimeError("Only float and int are supported for constants")

        output.dtype = dtype
        output.size = self.get_size(cn)
        const_var_name = self.create_const_var(self.ext_func_id, self.const_idx)
        self.const_idx += 1

        return [output]

    ### Get conv2D Op node information from a Composite
    def get_conv_info(self, call):
        op_list = [call.op.body,]

        conv2d_info = {
            "m": "DEFAULT_m",
            "e": "DEFAULT_e",
            "p": "DEFAULT_p",
            "q": "DEFAULT_q",
            "r": "DEFAULT_r",
            "t": "DEFAULT_t",
            "U": 1
        }

        # BFS
        while len(op_list) > 0:
            op = op_list.pop(0)
            # ------------------------------------------------------------
            # TODO: Extract conv2d attributes from the op node
            # ------------------------------------------------------------
            # If the op is nn.conv2d:
            #   - Extract and store:
            #       - padding -> conv2d_info["PAD"]
            #       - channels -> conv2d_info["M"]
            #       - kernel size (0 and 1) -> conv2d_info["R"], conv2d_info["S"]
            #   - Also set conv2d_info["m"] = conv2d_info["M"] as default.
            #
            # Hint:
            #   - Use op.op.name to check for "nn.conv2d"
            #   - Use op.attrs["padding"], op.attrs["channels"], etc.
            #   - You can assume padding and kernel_size are lists/tuples.
            #
            # Example:
            #   conv2d_info["PAD"] = op.attrs["padding"][0]
            # When done, remove the following line (NotImplementedError)
            if isinstance(op, Call) and op.op.name == "nn.conv2d":
                conv2d_info["PAD"] = op.attrs["padding"][0]  
                conv2d_info["M"] = op.attrs["channels"]
                conv2d_info["R"] = op.attrs["kernel_size"][0]
                conv2d_info["S"] = op.attrs["kernel_size"][1]
                conv2d_info["m"] = conv2d_info["M"] 
                conv2d_info["G"] = op.attrs["groups"]
            for node in op.args:
                if isinstance(node, Call):
                    op_list.append(node)

        return conv2d_info

    ### Traverse all the calls
    def visit_call(self, call):
        composite_name = call.op.attrs["Composite"]
        func_name = composite_name.replace(".","_")
        in_shape = self.get_shape(call.args[0].checked_type)

        if composite_name in PATTERN_TABLE:
            print("[composite trace]", composite_name, in_shape)
        else:
            raise RuntimeError("Unrecognized composite")

        # ------------------------------------------------------------
        # TODO 1: Trace parameters
        # ------------------------------------------------------------
        # For each argument in call.args, determine:
        #   - its mapped name in tvm_auto_args_NOTES[func_name]
        #   - whether it's a Constant or not
        #   - if not a constant, use `self.visit_expr(arg)` to visit it

        # Then fill the `parameters` dict like:
        #   parameters["input"] = (value, is_const)
        #
        # Hint:
        #   - Use zip(call.args, tvm_auto_args_NOTES[func_name])
        #   - Use isinstance(arg, Constant)
        parameters = dict()

        arg_names = tvm_auto_args_NOTES.get(func_name, [])
        for arg, arg_name in zip(call.args, arg_names):
            if isinstance(arg, Constant):
                value = arg
                is_const = True
            else:
                value = self.visit_expr(arg)[0]
                is_const = False
            parameters[arg_name] = (value, is_const)

        # Fetch function generator
        func_gen = tvm_c_func_call_gen.get(func_name, None)
        if not func_gen:
            return parameters["input"]

        # output buffer
        # ------------------------------------------------------------
        # TODO 2: Create output buffer
        # ------------------------------------------------------------
        # You need to:
        #   - Generate a new buffer name using `BUF_PREFIX` and self.buf_idx
        #   - Get the output buffer size: self.get_size(call)
        #   - Get the output buffer dtype: self.get_dtype_string(call.checked_type)
        #
        # You should generate a line like:
        #   float* out_0 = (float*)malloc(size * 4);
        #
        # Output:
        #   - out      -> output buffer name
        #   - out_size -> total number of elements
        #   - dtype    -> C-style data type
        # When done, remove the following line
        out = f"{BUF_PREFIX}{self.buf_idx}"
        self.buf_idx += 1
        out_size = self.get_size(call)
        dtype = self.get_dtype_string(call.checked_type)

        # EX: config = {
        #    "input": "buf_0",              
        #    "output": "buf_1",             
        #    "input_len": 12288,            
        #    "output_len": 12288,        
        #    "input_scale": 1.0,      
        #    "input_zero_point": 0,     
        #}
        ### Gather the parameters that we need
        # Conv2d op info
        if "conv2d" in func_name:
            config = self.get_conv_info(call)
            config["C_I"] = in_shape[1]
            config["H"] = in_shape[2]
            config["W"] = in_shape[3]
            config["C_F"] = 1 if config["G"] == config["C_I"] else config["C_I"]
            #print("[conv2d info]", config)
        elif "global_avg_pool2d" in func_name:
            config = dict()
            config["N"] = in_shape[0]
            config["C_I"] = in_shape[1]
            config["H"] = in_shape[2]
            config["W"] = in_shape[3]
        else:
            config = dict()

        # Wildcard info
        for k in ["input", "weight", "bias"]:
            config[k] = None
            config[f"{k}_len"] = None
            config[f"{k}_dtype"] = None
            param = parameters.get(k, None)
            if param == None:
                continue
            p, is_const = param
            if p == None:
                continue
            if is_const:
                p = self.visit_constant(p)[0]

            config[k] = p.name
            config[f"{k}_len"] = p.size
            config[f"{k}_dtype"] = p.dtype

        config["output"] = out
        config["output_len"] = out_size

        # Convert quantize scale
        for k, (v, is_const) in parameters.items():
            if "scale" in k and is_const:
                n = v.data.numpy()
                config[k] = n[0] if n.ndim == 1 else n

        # Malloc output buffer
        buf_create = f"{dtype}* {out} = ({dtype}*)malloc({out_size * 4});"
        self.ext_func_body.append(buf_create)

        # Generate C function
        self.ext_func_body.append("".join(func_gen(config)))

        # Free input buffer
        p, _ = parameters["input"]
        if BUF_PREFIX in p.name:
            buf_free = f"free({p.name});"
            self.ext_func_body.append(buf_free)

        output = Output(name=out, dtype=dtype, need_copy=True, size=out_size)
        return [output]

    def jit(self, out):
        code_stream = StringIO()
        for decl in self.func_decl:
            code_stream.write(f"{decl}\n")
        return self.jit_impl(
            self.ext_func_id,
            self.ext_func_args,
            self.ext_func_body,
            self.const_array_name,
            out,
        )

class CSourceCodegen(CSourceModuleCodegenBase):
    def __init__(self):
        super().__init__()
        self.code_stream = StringIO()
        self.weight_c_stream = StringIO()
        self.weight_h_stream = StringIO()
        self.weight_bin_stream = BytesIO()

    def gen_c_func(self, func):
        if func is None:
            raise ValueError("Input error: expect a Relay function.")

        sid = self.get_ext_symbol(func)
        builder = CodegenC(sid)
        out = builder.visit_expr(func.body)
        self.code_stream.write(builder.jit(out))

        return sid, builder.const_vars

    def gen_weight(self, const_vars):
        self.weight_c_stream.write("#include <stdint.h>\n")
        self.weight_c_stream.write("#include <stdlib.h>\n")
        self.weight_c_stream.write("#include <stdio.h>\n")
        self.weight_c_stream.write("#include \"weight.h\"\n")

        self.weight_h_stream.write("#ifndef DATA_H\n")
        self.weight_h_stream.write("#define DATA_H\n\n")
        self.weight_h_stream.write("#include <stdint.h>\n\n")

        load_weight_function = "void load_weight(const char *filename)"
        load_weight_script = "\tFILE *file = fopen(filename, \"rb\");\n"
        load_weight_script += "\tif(!file){\n"
        load_weight_script += "\t\tfprintf(stderr, \"file open failed.\\n\");\n"
        load_weight_script += "\t}\n"

        for i, const_var in enumerate(const_vars):
            data_numpy = const_var.data.numpy()
            padded = False
            N, C, H, W = 0, 0, 0, 0
            pad_size = 0
            if data_numpy.ndim == 4:
                N, C, H, W = data_numpy.shape
                remainder = C % 4
                if remainder != 0:
                    print("[Channel Fix]", const_var.name)
                    padded = True
                    pad_size = 4 - remainder
                    padded_data = np.zeros((N, C + pad_size, H, W), dtype=data_numpy.dtype)
                    padded_data[:, :C, :, :] = data_numpy
                    data_numpy = padded_data

            flattened_size = np.prod(data_numpy.shape)
            self.weight_h_stream.write(f"extern {const_var.dtype} {const_var.name}[];\n")
            self.weight_c_stream.write(f"{const_var.dtype} {const_var.name} [{flattened_size}];//{N},{C},{H},{W}\n")
            # Generate the load weight code

            if padded:
                load_weight_script += f"""
#ifdef CPU_ONLY
    for(int n=0;n<{N};n++){{
    \tfread({const_var.name}+(n*{C*H*W}),sizeof({const_var.dtype}),{C*H*W},file);
    \tfseek(file,{pad_size*H*W},SEEK_CUR);
    }}
#else
    fread({const_var.name},sizeof({const_var.dtype}),{flattened_size},file);
#endif
"""
            else:
                load_weight_script += f"\tfread({const_var.name},sizeof({const_var.dtype}),{flattened_size},file);\n"

            self.weight_bin_stream.write(data_numpy.tobytes())

        load_weight_script += "\tfclose(file);\n"
        self.weight_c_stream.write(load_weight_function)
        self.weight_c_stream.write("{\n")
        self.weight_c_stream.write(load_weight_script)
        self.weight_c_stream.write("}\n")

        self.weight_h_stream.write(f"{load_weight_function};\n")
        self.weight_h_stream.write("\n#endif // DATA_H\n")

    def dump_code(self, code, filename="code", file_type="c"):
        output_dir = "./output"
        if not os.path.exists(output_dir):
            os.makedirs(output_dir)

        if isinstance(code, bytes):
            with open(f"./output/{filename}.{file_type}", "wb") as f:
                f.write(code)
            return

        with open(f"./output/{filename}.{file_type}", "w") as f:
            if isinstance(code, list):
                f.write("\n".join(code))
            else:
                f.write(code)

    def create_c_source_module(self, ref):
        self.code_stream.write("#include <string.h>\n")
        self.code_stream.write("#include <stdio.h>\n")
        self.code_stream.write("#include <stdlib.h>\n")
        self.code_stream.write("#include \"weight.h\"\n")
        self.code_stream.write("#include \"runtime.h\"\n")

        if not isinstance(ref, tvm.relay.function.Function):
            raise TypeError("Expected a FunctionNode.")

        res = self.gen_c_func(ref)
        code = self.code_stream.getvalue()

        sym = [res[0],]
        variables = res[1]

        self.gen_weight(variables)

        pf = registry.get_global_func("runtime.CSourceModuleCreate")
        if pf is None:
            raise RuntimeError("Cannot find csource module to create the external runtime module.")

        target = "c"
        result = pf(code, target, sym, [])
        self.dump_code(self.weight_c_stream.getvalue(), "weight", "c")
        self.dump_code(self.weight_h_stream.getvalue(), "weight", "h")
        self.dump_code(self.weight_bin_stream.getvalue(), "weight", "bin")

        return result

#############################################################################################################
# Only c-codegen
@registry.register_func(f"relay.ext.{COMPILER_NAME}")
def DLA_compiler(ref):
    assert isinstance(ref, tvm.relay.function.Function), "Expected IRModule for compilation."

    DLA_codegen = CSourceCodegen()
    result = DLA_codegen.create_c_source_module(ref)

    print("Code gen Done")

    return result