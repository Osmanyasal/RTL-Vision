import argparse
from PIL import Image

def main():
    # Set up the parameter parser
    parser = argparse.ArgumentParser(description="Convert and resize any image to a BMP file for Verilog.")
    
    # Define the inputs, outputs, and size parameters
    parser.add_argument("-i", "--input", required=True, help="Path to the input image")
    parser.add_argument("-o", "--output", default="output.bmp", help="Path to the output BMP file")
    parser.add_argument("-w", "--width", type=int, default=512, help="Target width (default: 512)")
    parser.add_argument("-H", "--height", type=int, default=512, help="Target height (default: 512)")
    
    args = parser.parse_args()

    try:
        # Open the original image
        img = Image.open(args.input)
        
        # Convert to standard 24-bit RGB
        img_rgb = img.convert('RGB')
        
        # Force resize to exactly 512x512 (or the provided parameters)
        # Note: This stretches the image if the original is not square
        img_resized = img_rgb.resize((args.width, args.height))
        
        # Save it explicitly as an uncompressed BMP file
        img_resized.save(args.output, format='BMP')
        
        print(f"Success: Converted '{args.input}' to '{args.output}'")
        print(f"Resolution forced to: {img_resized.width} x {img_resized.height} pixels")
        
    except FileNotFoundError:
        print(f"Error: Could not find the file '{args.input}'.")
    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == "__main__":
    main()
