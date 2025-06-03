import argparse
from pathlib import Path
import time
import pandas as pd
from lib.models.mobilenet_v1 import MobileNetV1
from lib.models.qconfig import CustomQConfig
from lib.utils import load_model
from analytical_model import EyerissMapper
from network_parser import parse_pytorch, parse_onnx
from layer_info import Conv2DShapeParam, MaxPool2DShapeParam, ShapeParam
from roofline import plot_roofline_from_df

def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument("model_path", type=str, help="path to the ONNX or PyTorch model")
    parser.add_argument("-f", "--format", type=str, default="torch", choices=["torch", "onnx"], help="input model format")
    parser.add_argument("-o", "--output", type=str, default=f"../log/{time.strftime('%Y%m%d-%H%M%S')}", help="directory to save the output results")
    parser.add_argument("--plot", action="store_true", help="plot the roofline model and save it to the output directory")
    parser.add_argument("-v", "--verbose", action="store_true", help="print the results to stdout")
    return parser.parse_args()

def parse_network(model_path: str, model_format: str) -> list[ShapeParam | None]:
    model = load_model(
        MobileNetV1(),
        model_path,
        qconfig=CustomQConfig.POWER2.value,
        fuse_modules=True,
    )
    layers_for_evaluate = [
        Conv2DShapeParam(N=1, H=32, W=32, R=3, S=3, E=32, F=32, C=3, M=32, U=1, P=1),  # conv1
        # DepthwiseSeparableConv 1
        Conv2DShapeParam(N=1, H=32, W=32, R=3, S=3, E=32, F=32, C=32, M=64, U=1, P=1),  # dw1 depthwise
        # Conv2DShapeParam(N=1, H=32, W=32, R=1, S=1, E=32, F=32, C=32, M=64, U=1, P=0),  # dw1 pointwise
        # DepthwiseSeparableConv 2
        Conv2DShapeParam(N=1, H=32, W=32, R=3, S=3, E=16, F=16, C=64, M=128, U=2, P=1),  # dw2 depthwise
        # Conv2DShapeParam(N=1, H=16, W=16, R=1, S=1, E=16, F=16, C=64, M=128, U=1, P=0),  # dw2 pointwise
        # DepthwiseSeparableConv 3
        Conv2DShapeParam(N=1, H=16, W=16, R=3, S=3, E=16, F=16, C=128, M=128, U=1, P=1),  # dw3 depthwise
        # Conv2DShapeParam(N=1, H=16, W=16, R=1, S=1, E=16, F=16, C=128, M=128, U=1, P=0),  # dw3 pointwise
        # DepthwiseSeparableConv 4
        Conv2DShapeParam(N=1, H=16, W=16, R=3, S=3, E=8, F=8, C=128, M=256, U=2, P=1),   # dw4 depthwise
        # Conv2DShapeParam(N=1, H=8, W=8, R=1, S=1, E=8, F=8, C=128, M=256, U=1, P=0),    # dw4 pointwise
        # DepthwiseSeparableConv 5
        Conv2DShapeParam(N=1, H=8, W=8, R=3, S=3, E=8, F=8, C=256, M=256, U=1, P=1),    # dw5 depthwise
        # Conv2DShapeParam(N=1, H=8, W=8, R=1, S=1, E=8, F=8, C=256, M=256, U=1, P=0),    # dw5 pointwise
        # DepthwiseSeparableConv 6
        Conv2DShapeParam(N=1, H=8, W=8, R=3, S=3, E=4, F=4, C=256, M=512, U=2, P=1),    # dw6 depthwise
        # Conv2DShapeParam(N=1, H=4, W=4, R=1, S=1, E=4, F=4, C=256, M=512, U=1, P=0),    # dw6 pointwise
        # DepthwiseSeparableConv 7
        Conv2DShapeParam(N=1, H=4, W=4, R=3, S=3, E=4, F=4, C=512, M=512, U=1, P=1),    # dw7 depthwise
        # Conv2DShapeParam(N=1, H=4, W=4, R=1, S=1, E=4, F=4, C=512, M=512, U=1, P=0),    # dw7 pointwise
        # DepthwiseSeparableConv 8
        Conv2DShapeParam(N=1, H=4, W=4, R=3, S=3, E=2, F=2, C=512, M=1024, U=2, P=1),    # dw8 depthwise
        # Conv2DShapeParam(N=1, H=2, W=2, R=1, S=1, E=2, F=2, C=512, M=1024, U=1, P=0),   # dw8 pointwise
        # AdaptiveAvgPool2d(1) 影響輸出，但不作為獨立層
        Conv2DShapeParam(N=1, H=1, W=1, R=1, S=1, E=1, F=1, C=1024, M=10, U=1, P=0),    # use conv to do linear
        # LinearShapeParam(N=1, in_features=1024, out_features=10),  # fc
    ]
    """
    match model_format:
        case "torch":
            _layers = parse_pytorch(model)
        case "onnx":
            _layers = parse_onnx(model)
        case _:
            raise ValueError(f"Unsupported model format: {model_format}")
    """
    # Pair Conv2d with MaxPool2d or None
    layers = []
    maxpool = None
    for layer in layers_for_evaluate:
        if isinstance(layer, Conv2DShapeParam):
            layers.append((layer, maxpool))
            maxpool = None
        elif isinstance(layer, MaxPool2DShapeParam):
            maxpool = layer
    if maxpool:
        layers.append((None, maxpool))
    return layers

def export_results(results: list[dict[str, str | int | float]], output_dir: str | Path) -> None:
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    df = pd.DataFrame(results)
    df.to_csv(output_dir / "output.csv", index=False)
    markdown_table = df.to_markdown(index=False)
    with open(output_dir / "output.md", "w") as f:
        f.write("# Eyeriss Mapping Report\n\n")
        f.write("## Results\n\n")
        f.write(markdown_table)
    print(f"Report is saved to {output_dir}.")
    return df

def main():
    args = parse_args()
    model_path = Path(args.model_path).absolute()
    output_dir = Path(args.output).absolute()

    layers = parse_network(model_path, args.format)
    results = []
    for i, (conv, maxpool) in enumerate(layers):
        if conv is None:
            continue  # Skip MaxPool2d-only entries
        mapper = EyerissMapper(name=f"mobilenetv1.conv{i}")
        res = mapper.run(conv, maxpool)
        results.extend(res)

    df = export_results(results, output_dir)
    if args.plot:
        plot_roofline_from_df(df, output_dir / "output.png")

if __name__ == "__main__":
    main()