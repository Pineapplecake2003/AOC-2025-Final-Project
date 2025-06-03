import sys
from pathlib import Path
import torch
import torch.nn as nn
import torch.nn.quantized as nnq
import onnx
from onnx import shape_inference

project_root = Path(__file__).parents[1]
sys.path.append(str(project_root))

from layer_info import ShapeParam, Conv2DShapeParam, LinearShapeParam, MaxPool2DShapeParam
from network_parser import torch2onnx
# import torch2onnx
from lib.models.mobilenet_v1 import MobileNetV1, DepthwiseSeparableConv

def parse_pytorch(model: nn.Module, input_shape=(1, 3, 32, 32)) -> list[ShapeParam]:
    layers = []

    def hook_fn(module: nn.Module, inputs: torch.Tensor, output: torch.Tensor) -> None:
        # Debug output
        print(f"Layer: {module.__class__.__name__}")
        print(f"Input Shape: {inputs[0].shape}")
        print(f"Output Shape: {output.shape}\n")

        if isinstance(module, (nn.Conv2d, nnq.Conv2d)):
            inp_shape = inputs[0].shape  # [N, C, H, W]
            out_shape = output.shape     # [N, M, E, F]
            N, C, H, W = inp_shape
            M, E, F = out_shape[1], out_shape[2], out_shape[3]
            ks = module.kernel_size if isinstance(module.kernel_size, tuple) else (module.kernel_size, module.kernel_size)
            R, S = ks
            U = module.stride[0] if isinstance(module.stride, tuple) else module.stride
            P = module.padding[0] if isinstance(module.padding, tuple) else module.padding
            layers.append(Conv2DShapeParam(N=N, H=H, W=W, R=R, S=S, E=E, F=F, C=C, M=M, U=U, P=P))

        elif isinstance(module, nn.MaxPool2d):
            inp_shape = inputs[0].shape
            N = inp_shape[0]
            ks = module.kernel_size if isinstance(module.kernel_size, tuple) else (module.kernel_size, module.kernel_size)
            st = module.stride if isinstance(module.stride, tuple) else (module.stride, module.stride)
            layers.append(MaxPool2DShapeParam(N=N, kernel_size=ks[0], stride=st[0]))

        elif isinstance(module, nn.Linear):
            inp_shape = inputs[0].shape
            N = inp_shape[0]
            in_features = module.in_features
            out_features = module.out_features
            layers.append(Conv2DShapeParam(N=N, H=1, W=1, R=1, S=1, E=1, F=1, C=in_features, M=out_features, U=1, P=0))
            # layers.append(LinearShapeParam(N=N, in_features=in_features, out_features=out_features))

    # Register hooks for relevant modules
    hooks = []
    for name, module in model.named_modules():
        if isinstance(module, (nn.Conv2d, nnq.Conv2d, nn.MaxPool2d, nn.Linear)):
            hooks.append(module.register_forward_hook(hook_fn))

    # Forward pass
    model.eval()
    with torch.no_grad():
        dummy_input = torch.randn(*input_shape)
        model(dummy_input)

    # Remove hooks
    for h in hooks:
        h.remove()

    return layers

def parse_onnx(model: onnx.ModelProto) -> list[ShapeParam]:
    layers = []
    inferred = shape_inference.infer_shapes(model)
    tensor_shapes = {}
    for vi in list(inferred.graph.value_info) + list(inferred.graph.input) + list(inferred.graph.output):
        dims = [d.dim_value for d in vi.type.tensor_type.shape.dim]
        tensor_shapes[vi.name] = dims

    def _get_weight_shape(name: str):
        for init in inferred.graph.initializer:
            if init.name == name:
                return list(init.dims)
        return None

    for node in inferred.graph.node:
        if node.op_type == "Conv":
            inp_name = node.input[0]
            weight_name = node.input[1]
            out_name = node.output[0]
            inp_shape = tensor_shapes.get(inp_name)
            out_shape = tensor_shapes.get(out_name)
            weight_shape = _get_weight_shape(weight_name)
            if not all([inp_shape, out_shape, weight_shape]):
                continue

            kernel_attr = next((a for a in node.attribute if a.name == "kernel_shape"), None)
            if not kernel_attr:
                continue
            kernel = list(kernel_attr.ints)
            R = kernel[0]
            S = kernel[1] if len(kernel) > 1 else kernel[0]

            stride_attr = next((a for a in node.attribute if a.name == "strides"), None)
            U = list(stride_attr.ints)[0] if stride_attr else 1
            pad_attr = next((a for a in node.attribute if a.name == "pads"), None)
            P = list(pad_attr.ints)[0] if pad_attr else 1

            N, C, H, W = inp_shape
            M = weight_shape[0]
            E, F = out_shape[2], out_shape[3]
            layers.append(Conv2DShapeParam(N=N, H=H, W=W, R=R, S=S, E=E, F=F, C=C, M=M, U=U, P=P))

        elif node.op_type == "MaxPool":
            inp_name = node.input[0]
            inp_shape = tensor_shapes.get(inp_name)
            if not inp_shape:
                continue
            N = inp_shape[0]
            kernel_attr = next((a for a in node.attribute if a.name == "kernel_shape"), None)
            if not kernel_attr:
                continue
            kernel = list(kernel_attr.ints)
            k = kernel[0] if len(kernel) == 2 and kernel[0] == kernel[1] else kernel[0]

            stride_attr = next((a for a in node.attribute if a.name == "strides"), None)
            s = list(stride_attr.ints)[0] if stride_attr else k
            layers.append(MaxPool2DShapeParam(N=N, kernel_size=k, stride=s))

        elif node.op_type == "Gemm":
            inp_name = node.input[0]
            out_name = node.output[0]
            inp_shape = tensor_shapes.get(inp_name)
            if not inp_shape:
                continue
            N = inp_shape[0]
            weight_name = node.input[1]
            weight_shape = _get_weight_shape(weight_name)
            if not weight_shape:
                continue
            transB = next((a.i for a in node.attribute if a.name == "transB"), 0)
            in_features = weight_shape[0] if transB == 0 else weight_shape[1]
            out_features = weight_shape[1] if transB == 0 else weight_shape[0]
            layers.append(Conv2DShapeParam(N=N, H=1, W=1, R=1, S=1, E=1, F=1, C=in_features, M=out_features, U=1, P=0))
            # layers.append(LinearShapeParam(N=N, in_features=in_features, out_features=out_features))

    return layers

def compare_layers(answer, layers):
    if len(answer) != len(layers):
        print(f"Layer count mismatch: answer has {len(answer)}, but ONNX has {len(layers)}")

    min_len = min(len(answer), len(layers))
    for i in range(min_len):
        ans_layer = vars(answer[i])
        layer = vars(layers[i])
        diffs = {k: (ans_layer[k], layer[k]) for k in ans_layer if k in layer and ans_layer[k] != layer[k]}
        if diffs:
            print(f"Difference in layer {i + 1} ({type(answer[i]).__name__}):")
            for k, (ans_val, val) in diffs.items():
                print(f"  {k}: answer = {ans_val}, onnx = {val}")

    if len(answer) > len(layers):
        print(f"Extra layers in answer: {answer[len(layers) :]}")
    elif len(layers) > len(answer):
        print(f"Extra layers in yours: {layers[len(answer) :]}")

def run_tests() -> None:
    """Run tests on the network parser functions."""
    answer = [
        Conv2DShapeParam(N=1, H=32, W=32, R=3, S=3, E=32, F=32, C=3, M=32, U=1, P=1),  # conv1
        # DepthwiseSeparableConv 1
        Conv2DShapeParam(N=1, H=32, W=32, R=3, S=3, E=32, F=32, C=32, M=32, U=1, P=1),  # dw1 depthwise
        Conv2DShapeParam(N=1, H=32, W=32, R=1, S=1, E=32, F=32, C=32, M=64, U=1, P=0),  # dw1 pointwise
        # DepthwiseSeparableConv 2
        Conv2DShapeParam(N=1, H=32, W=32, R=3, S=3, E=16, F=16, C=64, M=64, U=2, P=1),  # dw2 depthwise
        Conv2DShapeParam(N=1, H=16, W=16, R=1, S=1, E=16, F=16, C=64, M=128, U=1, P=0),  # dw2 pointwise
        # DepthwiseSeparableConv 3
        Conv2DShapeParam(N=1, H=16, W=16, R=3, S=3, E=16, F=16, C=128, M=128, U=1, P=1),  # dw3 depthwise
        Conv2DShapeParam(N=1, H=16, W=16, R=1, S=1, E=16, F=16, C=128, M=128, U=1, P=0),  # dw3 pointwise
        # DepthwiseSeparableConv 4
        Conv2DShapeParam(N=1, H=16, W=16, R=3, S=3, E=8, F=8, C=128, M=128, U=2, P=1),   # dw4 depthwise
        Conv2DShapeParam(N=1, H=8, W=8, R=1, S=1, E=8, F=8, C=128, M=256, U=1, P=0),    # dw4 pointwise
        # DepthwiseSeparableConv 5
        Conv2DShapeParam(N=1, H=8, W=8, R=3, S=3, E=8, F=8, C=256, M=256, U=1, P=1),    # dw5 depthwise
        Conv2DShapeParam(N=1, H=8, W=8, R=1, S=1, E=8, F=8, C=256, M=256, U=1, P=0),    # dw5 pointwise
        # DepthwiseSeparableConv 6
        Conv2DShapeParam(N=1, H=8, W=8, R=3, S=3, E=4, F=4, C=256, M=256, U=2, P=1),    # dw6 depthwise
        Conv2DShapeParam(N=1, H=4, W=4, R=1, S=1, E=4, F=4, C=256, M=512, U=1, P=0),    # dw6 pointwise
        # DepthwiseSeparableConv 7
        Conv2DShapeParam(N=1, H=4, W=4, R=3, S=3, E=4, F=4, C=512, M=512, U=1, P=1),    # dw7 depthwise
        Conv2DShapeParam(N=1, H=4, W=4, R=1, S=1, E=4, F=4, C=512, M=512, U=1, P=0),    # dw7 pointwise
        # DepthwiseSeparableConv 8
        Conv2DShapeParam(N=1, H=4, W=4, R=3, S=3, E=2, F=2, C=512, M=512, U=2, P=1),    # dw8 depthwise
        Conv2DShapeParam(N=1, H=2, W=2, R=1, S=1, E=2, F=2, C=512, M=1024, U=1, P=0),   # dw8 pointwise
        # AdaptiveAvgPool2d(1) 影響輸出，但不作為獨立層
        Conv2DShapeParam(N=1, H=1, W=1, R=1, S=1, E=1, F=1, C=1024, M=10, U=1, P=0),    # use conv to do linear
        # LinearShapeParam(N=1, in_features=1024, out_features=10),  # fc
    ]

    model = MobileNetV1()
    layers_pth = parse_pytorch(model)

    dummy_input = torch.randn(1, 3, 32, 32)
    torch2onnx.torch2onnx(model, "parser_onnx.onnx", dummy_input)
    model_onnx = onnx.load("parser_onnx.onnx")
    layers_onnx = parse_onnx(model_onnx)

    print("PyTorch Network Parser:")
    if layers_pth == answer:
        print("Correct!")
    else:
        print("Wrong!")
        compare_layers(answer, layers_pth)

    print("ONNX Network Parser:")
    if layers_onnx == answer:
        print("Correct!")
    else:
        print("Wrong!")
        compare_layers(answer, layers_onnx)

    print(answer)

if __name__ == "__main__":
    run_tests()