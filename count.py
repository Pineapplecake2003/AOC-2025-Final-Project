import argparse

def main():
    parser = argparse.ArgumentParser(description="Count int8 numbers from a file.")
    parser.add_argument("filename", help="Input file containing comma-separated int8 values")
    args = parser.parse_args()

    try:
        with open(args.filename, "r") as f:
            content = f.read().strip()
            # 轉成整數並過濾掉空值
            numbers = [int(num) for num in content.split(",") if num.strip()]
            print(f"Total int8 numbers: {len(numbers)}")
    except FileNotFoundError:
        print(f"File not found: {args.filename}")
    except ValueError:
        print("File contains non-integer values or formatting issues.")

if __name__ == "__main__":
    main()
