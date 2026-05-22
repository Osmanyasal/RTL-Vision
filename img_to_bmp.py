import argparse
from pathlib import Path
from PIL import Image

def main():
    # Set up the parameter parser
    parser = argparse.ArgumentParser(description="Convert and resize any image to a BMP file for Verilog.")
    
    # Define the inputs, outputs, and size parameters
    parser.add_argument("-i", "--input", required=True, help="Path to the input image")
    parser.add_argument("-o", "--output", help="Path to the output BMP file (defaults to the input name with a .bmp extension)")
    parser.add_argument("-w", "--width", type=int, help="Target width (defaults to the original image width)")
    parser.add_argument("-H", "--height", type=int, help="Target height (defaults to the original image height)")
    
    args = parser.parse_args()

    try:
        # Open the original image
        img = Image.open(args.input)

        target_width = args.width if args.width is not None else img.width
        target_height = args.height if args.height is not None else img.height
        output_path = args.output if args.output else str(Path(args.input).with_suffix(".bmp"))
        
        # Convert to standard 24-bit RGB
        img_rgb = img.convert('RGB')
        
        # Resize only when requested dimensions differ from the source image
        # Note: This stretches the image if the original is not square
        img_resized = img_rgb.resize((target_width, target_height))
        
        # Save it explicitly as an uncompressed BMP file
        img_resized.save(output_path, format='BMP')
        
        print(f"Success: Converted '{args.input}' to '{output_path}'")
        print(f"Resolution used: {img_resized.width} x {img_resized.height} pixels")
        
    except FileNotFoundError:
        print(f"Error: Could not find the file '{args.input}'.")
    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == "__main__":
    main()
