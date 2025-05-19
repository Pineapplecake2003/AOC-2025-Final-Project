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
    _layers = []
    match model_format:
        case "torch":
            _layers = parse_pytorch(model)
        case "onnx":
            _layers = parse_onnx(model)
        case _:
            raise ValueError(f"Unsupported model format: {model_format}")

    # Pair Conv2d with MaxPool2d or None
    layers = []
    maxpool = None
    for layer in _layers:
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