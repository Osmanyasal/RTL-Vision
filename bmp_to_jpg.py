
import argparse
from pathlib import Path
from PIL import Image
import glob


def main():
    parser = argparse.ArgumentParser(description="Convert BMP images to JPG files.")
    parser.add_argument("-i", "--input", required=True, nargs='+', help="Input BMP image(s), supports globbing (e.g. *.bmp)")
    parser.add_argument("-o", "--output", help="Output JPG file (only valid if one input, else auto-named)")
    parser.add_argument("-q", "--quality", type=int, default=95, help="JPEG quality (default: 95)")
    args = parser.parse_args()

    # Expand globs for all input patterns
    input_files = []
    for pattern in args.input:
        expanded = glob.glob(pattern)
        if not expanded:
            print(f"Warning: No files matched pattern '{pattern}'")
        input_files.extend(expanded)

    if not input_files:
        print("Error: No input files found.")
        return

    for idx, input_path in enumerate(input_files):
        try:
            img = Image.open(input_path)
            img_rgb = img.convert('RGB')
            # Output path logic: if only one input and user specified output, use it; else auto-name
            if args.output and len(input_files) == 1:
                output_path = args.output
            else:
                output_path = str(Path(input_path).with_suffix(".jpg"))
            img_rgb.save(output_path, format='JPEG', quality=args.quality)
            print(f"Success: Converted '{input_path}' to '{output_path}' (quality={args.quality})")
        except FileNotFoundError:
            print(f"Error: Could not find the file '{input_path}'.")
        except Exception as e:
            print(f"An error occurred with '{input_path}': {e}")

if __name__ == "__main__":
    main()
