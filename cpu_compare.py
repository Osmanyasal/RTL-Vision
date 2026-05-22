import argparse
import csv
import time
from pathlib import Path
import cv2
import numpy as np

# Streaming sharpen 3x3 on Y channel (line-buffered)
def sharpen3x3_ycbcr_stream(image: np.ndarray) -> np.ndarray:
    h, w, c = image.shape
    ycrcb = np.zeros((h, w, 3), dtype=np.uint8)
    for y in range(h):
        for x in range(w):
            b, g, r = image[y, x]
            y_ = int(0.114*b + 0.587*g + 0.299*r)
            cr = int(128 + 0.5*r - 0.419*g - 0.081*b)
            cb = int(128 - 0.169*r - 0.331*g + 0.5*b)
            ycrcb[y, x] = (y_, cr, cb)
    kernel = np.array([[0, -1, 0], [-1, 5, -1], [0, -1, 0]], dtype=np.int32)
    linebuf = [np.zeros((w, 3), dtype=np.uint8) for _ in range(3)]
    out = np.zeros((h, w, 3), dtype=np.uint8)
    for y in range(h):
        linebuf[y % 3] = ycrcb[y]
        if y < 2:
            continue
        for x in range(1, w-1):
            window = np.array([
                linebuf[(y-2)%3][x-1:x+2, 0],
                linebuf[(y-1)%3][x-1:x+2, 0],
                linebuf[y%3][x-1:x+2, 0]
            ])
            y_sharp = np.clip(np.sum(window * kernel), 0, 255)
            cr = linebuf[(y-1)%3][x, 1]
            cb = linebuf[(y-1)%3][x, 2]
            y_, cr_, cb_ = int(y_sharp), int(cr), int(cb)
            c = y_ - 16
            d = cb_ - 128
            e = cr_ - 128
            bgr = [
                np.clip((298*c + 516*d + 128) >> 8, 0, 255),
                np.clip((298*c - 100*d - 208*e + 128) >> 8, 0, 255),
                np.clip((298*c + 409*e + 128) >> 8, 0, 255)
            ]
            out[y, x] = bgr
    return out

# Streaming Sobel 5x5 (line-buffered)
def sobel5x5_stream(image: np.ndarray) -> np.ndarray:
    h, w, c = image.shape
    gray = np.zeros((h, w), dtype=np.uint8)
    for y in range(h):
        for x in range(w):
            b, g, r = image[y, x]
            gray[y, x] = int(0.114 * b + 0.587 * g + 0.299 * r)
    # 5 line buffers
    linebuf = [np.zeros(w, dtype=np.uint8) for _ in range(5)]
    out = np.zeros((h, w, 3), dtype=np.uint8)
    # 5x5 Sobel kernels
    kx = np.array([
        [2, 1, 0, -1, -2],
        [3, 2, 0, -2, -3],
        [4, 3, 0, -3, -4],
        [3, 2, 0, -2, -3],
        [2, 1, 0, -1, -2]
    ])
    ky = kx.T
    for y in range(h):
        linebuf[y % 5] = gray[y]
        if y < 4:
            continue
        for x in range(2, w-2):
            window = np.array([
                linebuf[(y-4)%5][x-2:x+3],
                linebuf[(y-3)%5][x-2:x+3],
                linebuf[(y-2)%5][x-2:x+3],
                linebuf[(y-1)%5][x-2:x+3],
                linebuf[y%5][x-2:x+3]
            ])
            gx = np.sum(window * kx)
            gy = np.sum(window * ky)
            mag = min(255, int(np.hypot(gx, gy)))
            out[y, x] = (mag, mag, mag)
    return out

# Streaming dilation 3x3 (line-buffered)
def dilation3x3_stream(image: np.ndarray) -> np.ndarray:
    h, w, c = image.shape
    out = np.zeros((h, w, 3), dtype=np.uint8)
    # Use grayscale for dilation
    gray = np.zeros((h, w), dtype=np.uint8)
    for y in range(h):
        for x in range(w):
            b, g, r = image[y, x]
            gray[y, x] = int(0.114 * b + 0.587 * g + 0.299 * r)
    linebuf = [np.zeros(w, dtype=np.uint8) for _ in range(3)]
    for y in range(h):
        linebuf[y % 3] = gray[y]
        if y < 2:
            continue
        for x in range(1, w-1):
            window = np.array([
                linebuf[(y-2)%3][x-1:x+2],
                linebuf[(y-1)%3][x-1:x+2],
                linebuf[y%3][x-1:x+2]
            ])
            val = np.max(window)
            out[y, x] = (val, val, val)
    return out

# Streaming erosion 3x3 (line-buffered)
def erosion3x3_stream(image: np.ndarray) -> np.ndarray:
    h, w, c = image.shape
    out = np.zeros((h, w, 3), dtype=np.uint8)
    gray = np.zeros((h, w), dtype=np.uint8)
    for y in range(h):
        for x in range(w):
            b, g, r = image[y, x]
            gray[y, x] = int(0.114 * b + 0.587 * g + 0.299 * r)
    linebuf = [np.zeros(w, dtype=np.uint8) for _ in range(3)]
    for y in range(h):
        linebuf[y % 3] = gray[y]
        if y < 2:
            continue
        for x in range(1, w-1):
            window = np.array([
                linebuf[(y-2)%3][x-1:x+2],
                linebuf[(y-1)%3][x-1:x+2],
                linebuf[y%3][x-1:x+2]
            ])
            val = np.min(window)
            out[y, x] = (val, val, val)
    return out
# Streaming histogram equalization (simulating the RTL 2-pass architecture)
def histeq_stream(image: np.ndarray) -> np.ndarray:
    h, w, c = image.shape
    frame_pixels = h * w
    
    # We will simulate the 2-pass RTL approach.
    hist = np.zeros(256, dtype=np.uint32)
    ycrcb = np.zeros((h, w, 3), dtype=np.uint8)
    
    # PASS 1: Stream in BGR, convert to YCrCb, and build histogram
    for y in range(h):
        for x in range(w):
            b, g, r = image[y, x]
            
            # OpenCV full-range BGR to YCrCb
            y_val = int(0.114*b + 0.587*g + 0.299*r)
            cr = int((r - y_val) * 0.713 + 128)
            cb = int((b - y_val) * 0.564 + 128)
            
            # Constrain to 8-bit limits
            y_val = min(255, max(0, y_val))
            cr = min(255, max(0, cr))
            cb = min(255, max(0, cb))
            
            ycrcb[y, x] = (y_val, cr, cb)
            hist[y_val] += 1
            
    # VBLANK: Simulate RTL state machine computing the CDF and Equalization LUT
    cdf_min = 0
    cdf_min_found = False
    cdf_accum = 0
    eq_lut = np.zeros(256, dtype=np.uint8)
    
    for i in range(256):
        cdf_accum += hist[i]
        
        if not cdf_min_found and hist[i] > 0:
            cdf_min = cdf_accum
            cdf_min_found = True
            
        if cdf_min_found and frame_pixels > cdf_min:
            # Exact integer math matching the FPGA division logic
            numerator = int((cdf_accum - cdf_min) * 255)
            denominator = int(frame_pixels - cdf_min)
            # Add half the denominator for proper rounding
            mapped = (numerator + (denominator // 2)) // denominator
            eq_lut[i] = min(255, max(0, mapped))
        else:
            eq_lut[i] = 0
            
    # PASS 2: Stream YCrCb, apply LUT, convert back to BGR
    out = np.zeros((h, w, 3), dtype=np.uint8)
    for y in range(h):
        for x in range(w):
            y_val = ycrcb[y, x, 0]
            cr = ycrcb[y, x, 1]
            cb = ycrcb[y, x, 2]
            
            # Apply equalization LUT
            y_eq = eq_lut[y_val]
            
            # OpenCV full-range YCrCb to BGR
            delta_cr = cr - 128
            delta_cb = cb - 128
            
            r_out = y_eq + int(1.403 * delta_cr)
            g_out = y_eq - int(0.344 * delta_cb + 0.714 * delta_cr)
            b_out = y_eq + int(1.773 * delta_cb)
            
            # Clip to valid BGR ranges
            out[y, x, 0] = min(255, max(0, b_out))
            out[y, x, 1] = min(255, max(0, g_out))
            out[y, x, 2] = min(255, max(0, r_out))
            
    return out

# Streaming remove red channel (pixel-by-pixel)
def remove_red_stream(image: np.ndarray) -> np.ndarray:
    h, w, c = image.shape
    out = np.zeros((h, w, 3), dtype=np.uint8)
    for y in range(h):
        for x in range(w):
            b, g, r = image[y, x]
            out[y, x] = (b, g, 0)
    return out

# Streaming HSV in-range (pixel-by-pixel)
def hsv_inrange_stream(image: np.ndarray) -> np.ndarray:
    h, w, c = image.shape
    out = np.zeros((h, w, 3), dtype=np.uint8)
    for y in range(h):
        for x in range(w):
            b, g, r = image[y, x]
            # Convert BGR to HSV (manual, simplified)
            b_, g_, r_ = b/255.0, g/255.0, r/255.0
            mx = max(r_, g_, b_)
            mn = min(r_, g_, b_)
            diff = mx - mn
            # Hue
            if diff == 0:
                h_ = 0
            elif mx == r_:
                h_ = (60 * ((g_ - b_) / diff) + 360) % 360
            elif mx == g_:
                h_ = (60 * ((b_ - r_) / diff) + 120) % 360
            else:
                h_ = (60 * ((r_ - g_) / diff) + 240) % 360
            # Saturation
            s_ = 0 if mx == 0 else diff / mx
            # Value
            v_ = mx
            # In-range: greenish
            if 35 <= h_ <= 85 and s_ >= 0.16 and v_ >= 0.16:
                val = 255
            else:
                val = 0
            out[y, x] = (val, val, val)
    return out
print("[DEBUG] Script entry")

import argparse
import csv
import time
from pathlib import Path
import cv2
import numpy as np


RTL_REFERENCE_MS = {
    "histeq": 117.43,
    "blur3x3_ycbcr": 88.39,
    "blur5x5_ycbcr": 88.30,
    "grayscale": 88.21,
    "sharpen3x3_ycbcr": 88.47,
    "sobel3x3": 88.47,
    "sobel5x5": 88.47,
    "threshold_128": 88.47,
    "dilation3x3": 9.2,
    "erosion3x3": 9.2,
}




# Standard vectorized grayscale (cheating, full-frame)
def grayscale(image: np.ndarray) -> np.ndarray:
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    return cv2.cvtColor(gray, cv2.COLOR_GRAY2BGR)

# Streaming blur 3x3 on Y channel (line-buffered)
def blur3x3_ycbcr_stream(image: np.ndarray) -> np.ndarray:
    h, w, c = image.shape
    # Convert to YCrCb streaming
    ycrcb = np.zeros((h, w, 3), dtype=np.uint8)
    for y in range(h):
        for x in range(w):
            b, g, r = image[y, x]
            y_ = int(0.114*b + 0.587*g + 0.299*r)
            cr = int(128 + 0.5*r - 0.419*g - 0.081*b)
            cb = int(128 - 0.169*r - 0.331*g + 0.5*b)
            ycrcb[y, x] = (y_, cr, cb)
    # Line buffers for 3 rows of Y
    linebuf = [np.zeros((w, 3), dtype=np.uint8) for _ in range(3)]
    out = np.zeros((h, w, 3), dtype=np.uint8)
    for y in range(h):
        linebuf[y % 3] = ycrcb[y]
        if y < 2:
            continue
        for x in range(1, w-1):
            # 3x3 window for Y only
            window = np.array([
                linebuf[(y-2)%3][x-1:x+2, 0],
                linebuf[(y-1)%3][x-1:x+2, 0],
                linebuf[y%3][x-1:x+2, 0]
            ])
            y_blur = int(np.mean(window))
            cr = linebuf[(y-1)%3][x, 1]
            cb = linebuf[(y-1)%3][x, 2]
            # Convert back to BGR
            # YCrCb to BGR
            y_, cr_, cb_ = y_blur, cr, cb
            c = y_ - 16
            d = cb_ - 128
            e = cr_ - 128
            bgr = [
                np.clip((298*c + 516*d + 128) >> 8, 0, 255),
                np.clip((298*c - 100*d - 208*e + 128) >> 8, 0, 255),
                np.clip((298*c + 409*e + 128) >> 8, 0, 255)
            ]
            out[y, x] = bgr
    return out

# Streaming blur 5x5 on Y channel (line-buffered)
def blur5x5_ycbcr_stream(image: np.ndarray) -> np.ndarray:
    h, w, c = image.shape
    ycrcb = np.zeros((h, w, 3), dtype=np.uint8)
    for y in range(h):
        for x in range(w):
            b, g, r = image[y, x]
            y_ = int(0.114*b + 0.587*g + 0.299*r)
            cr = int(128 + 0.5*r - 0.419*g - 0.081*b)
            cb = int(128 - 0.169*r - 0.331*g + 0.5*b)
            ycrcb[y, x] = (y_, cr, cb)
    linebuf = [np.zeros((w, 3), dtype=np.uint8) for _ in range(5)]
    out = np.zeros((h, w, 3), dtype=np.uint8)
    for y in range(h):
        linebuf[y % 5] = ycrcb[y]
        if y < 4:
            continue
        for x in range(2, w-2):
            window = np.array([
                linebuf[(y-4)%5][x-2:x+3, 0],
                linebuf[(y-3)%5][x-2:x+3, 0],
                linebuf[(y-2)%5][x-2:x+3, 0],
                linebuf[(y-1)%5][x-2:x+3, 0],
                linebuf[y%5][x-2:x+3, 0]
            ])
            y_blur = int(np.mean(window))
            cr = linebuf[(y-2)%5][x, 1]
            cb = linebuf[(y-2)%5][x, 2]
            y_, cr_, cb_ = y_blur, cr, cb
            c = y_ - 16
            d = cb_ - 128
            e = cr_ - 128
            bgr = [
                np.clip((298*c + 516*d + 128) >> 8, 0, 255),
                np.clip((298*c - 100*d - 208*e + 128) >> 8, 0, 255),
                np.clip((298*c + 409*e + 128) >> 8, 0, 255)
            ]
            out[y, x] = bgr
    return out

# Streaming grayscale: pixel-by-pixel, line-buffered, simulating FPGA
def grayscale_stream(image: np.ndarray) -> np.ndarray:
    h, w, c = image.shape
    out = np.zeros((h, w, 3), dtype=np.uint8)
    for y in range(h):
        for x in range(w):
            b, g, r = image[y, x]
            gray = int(0.114 * b + 0.587 * g + 0.299 * r)
            out[y, x] = (gray, gray, gray)
    return out

# Streaming Sobel 3x3 (pixel-by-pixel, line-buffered)
def sobel3x3_stream(image: np.ndarray) -> np.ndarray:
    h, w, c = image.shape
    # Convert to grayscale first, streaming style
    gray = np.zeros((h, w), dtype=np.uint8)
    for y in range(h):
        for x in range(w):
            b, g, r = image[y, x]
            gray[y, x] = int(0.114 * b + 0.587 * g + 0.299 * r)
    # Line buffers for 3 rows
    linebuf = [np.zeros(w, dtype=np.uint8) for _ in range(3)]
    out = np.zeros((h, w, 3), dtype=np.uint8)
    for y in range(h):
        linebuf[y % 3] = gray[y]
        if y < 2:
            continue  # Not enough rows yet
        for x in range(1, w-1):
            # 3x3 window
            window = np.array([
                linebuf[(y-2)%3][x-1:x+2],
                linebuf[(y-1)%3][x-1:x+2],
                linebuf[y%3][x-1:x+2]
            ])
            gx = (
                -1*window[0,0] + 0*window[0,1] + 1*window[0,2]
                -2*window[1,0] + 0*window[1,1] + 2*window[1,2]
                -1*window[2,0] + 0*window[2,1] + 1*window[2,2]
            )
            gy = (
                -1*window[0,0] -2*window[0,1] -1*window[0,2]
                +1*window[2,0] +2*window[2,1] +1*window[2,2]
            )
            mag = min(255, int(np.hypot(gx, gy)))
            out[y, x] = (mag, mag, mag)
    return out

# Streaming threshold (pixel-by-pixel, line-buffered)
def threshold_128_stream(image: np.ndarray) -> np.ndarray:
    h, w, c = image.shape
    out = np.zeros((h, w, 3), dtype=np.uint8)
    for y in range(h):
        for x in range(w):
            b, g, r = image[y, x]
            gray = int(0.114 * b + 0.587 * g + 0.299 * r)
            val = 255 if gray >= 128 else 0
            out[y, x] = (val, val, val)
    return out


def blur3x3_ycbcr(image: np.ndarray) -> np.ndarray:
    ycrcb = cv2.cvtColor(image, cv2.COLOR_BGR2YCrCb)
    ycrcb[:, :, 0] = cv2.blur(ycrcb[:, :, 0], (3, 3))
    return cv2.cvtColor(ycrcb, cv2.COLOR_YCrCb2BGR)


def blur5x5_ycbcr(image: np.ndarray) -> np.ndarray:
    ycrcb = cv2.cvtColor(image, cv2.COLOR_BGR2YCrCb)
    ycrcb[:, :, 0] = cv2.blur(ycrcb[:, :, 0], (5, 5))
    return cv2.cvtColor(ycrcb, cv2.COLOR_YCrCb2BGR)


def sharpen3x3_ycbcr(image: np.ndarray) -> np.ndarray:
    ycrcb = cv2.cvtColor(image, cv2.COLOR_BGR2YCrCb)
    kernel = np.array([[0, -1, 0], [-1, 5, -1], [0, -1, 0]], dtype=np.float32)
    ycrcb[:, :, 0] = cv2.filter2D(ycrcb[:, :, 0], -1, kernel)
    return cv2.cvtColor(ycrcb, cv2.COLOR_YCrCb2BGR)


def sobel3x3(image: np.ndarray) -> np.ndarray:
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    grad_x = cv2.Sobel(gray, cv2.CV_32F, 1, 0, ksize=3)
    grad_y = cv2.Sobel(gray, cv2.CV_32F, 0, 1, ksize=3)
    magnitude = cv2.magnitude(grad_x, grad_y)
    edges = cv2.convertScaleAbs(magnitude)
    return cv2.cvtColor(edges, cv2.COLOR_GRAY2BGR)


def sobel5x5(image: np.ndarray) -> np.ndarray:
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    grad_x = cv2.Sobel(gray, cv2.CV_32F, 1, 0, ksize=5)
    grad_y = cv2.Sobel(gray, cv2.CV_32F, 0, 1, ksize=5)
    magnitude = cv2.magnitude(grad_x, grad_y)
    edges = cv2.convertScaleAbs(magnitude)
    return cv2.cvtColor(edges, cv2.COLOR_GRAY2BGR)


def threshold_128(image: np.ndarray) -> np.ndarray:
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    _, binary = cv2.threshold(gray, 128, 255, cv2.THRESH_BINARY)
    return cv2.cvtColor(binary, cv2.COLOR_GRAY2BGR)


def dilation3x3(image: np.ndarray) -> np.ndarray:
    kernel = np.ones((3, 3), dtype=np.uint8)
    return cv2.dilate(image, kernel, iterations=1)


def erosion3x3(image: np.ndarray) -> np.ndarray:
    kernel = np.ones((3, 3), dtype=np.uint8)
    return cv2.erode(image, kernel, iterations=1)


def histeq(image: np.ndarray) -> np.ndarray:
    ycrcb = cv2.cvtColor(image, cv2.COLOR_BGR2YCrCb)
    ycrcb[:, :, 0] = cv2.equalizeHist(ycrcb[:, :, 0])
    return cv2.cvtColor(ycrcb, cv2.COLOR_YCrCb2BGR)


def remove_red(image: np.ndarray) -> np.ndarray:
    output = image.copy()
    output[:, :, 2] = 0
    return output


def hsv_inrange(image: np.ndarray) -> np.ndarray:
    hsv = cv2.cvtColor(image, cv2.COLOR_BGR2HSV)
    lower = np.array([35, 40, 40], dtype=np.uint8)
    upper = np.array([85, 255, 255], dtype=np.uint8)
    mask = cv2.inRange(hsv, lower, upper)
    return cv2.cvtColor(mask, cv2.COLOR_GRAY2BGR)


KERNELS = {
    "grayscale_stream": grayscale_stream,
    "blur3x3_ycbcr_stream": blur3x3_ycbcr_stream,
    "blur5x5_ycbcr_stream": blur5x5_ycbcr_stream,
    "sharpen3x3_ycbcr_stream": sharpen3x3_ycbcr_stream,
    "sobel3x3_stream": sobel3x3_stream,
    "sobel5x5_stream": sobel5x5_stream,
    "threshold_128_stream": threshold_128_stream,
    "dilation3x3_stream": dilation3x3_stream,
    "erosion3x3_stream": erosion3x3_stream,
    "histeq_stream": histeq_stream,
    "remove_red_stream": remove_red_stream,
    "hsv_inrange_stream": hsv_inrange_stream,
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Benchmark CPU-side image-processing kernels against a reference image."
    )
    parser.add_argument(
        "--input",
        default="butterfly.bmp",
        help="Path to the input image (default: butterfly.bmp).",
    )
    parser.add_argument(
        "--kernels",
        nargs="+",
        choices=sorted(KERNELS.keys()),
        help="Subset of kernels to benchmark. Defaults to all kernels.",
    )
    parser.add_argument(
        "--warmup-runs",
        type=int,
        default=1,
        help="Number of warmup executions per kernel before timing.",
    )
    parser.add_argument(
        "--benchmark-runs",
        type=int,
        default=10,
        help="Number of timed executions per kernel.",
    )
    parser.add_argument(
        "--sample-iterations",
        type=int,
        default=1,
        help="Number of kernel invocations inside each timed run.",
    )
    parser.add_argument(
        "--save-dir",
        default=".",
        help="Directory where cpu_* output images are written.",
    )
    parser.add_argument(
        "--no-save",
        action="store_true",
        help="Skip writing output images.",
    )
    parser.add_argument(
        "--csv",
        help="Optional CSV report path.",
    )
    parser.add_argument(
        "--list-kernels",
        action="store_true",
        help="List available kernels and exit.",
    )
    return parser.parse_args()


def load_image(path: Path) -> np.ndarray:
    image = cv2.imread(str(path), cv2.IMREAD_COLOR)
    if image is None:
        raise FileNotFoundError(f"Could not open image: {path}")
    return image


def benchmark_kernel(
    kernel_name: str,
    image: np.ndarray,
    warmup_runs: int,
    benchmark_runs: int,
    sample_iterations: int,
) -> tuple[dict[str, float], np.ndarray]:
    kernel = KERNELS[kernel_name]
    output = image

    for _ in range(warmup_runs):
        output = kernel(image)

    samples_ms = []
    for _ in range(benchmark_runs):
        start = time.perf_counter()
        for _ in range(sample_iterations):
            output = kernel(image)
        elapsed_ms = (time.perf_counter() - start) * 1000.0 / sample_iterations
        samples_ms.append(elapsed_ms)

    rtl_ms = RTL_REFERENCE_MS.get(kernel_name)
    summary = {
        "cpu_mean_ms": float(np.mean(samples_ms)),
        "cpu_min_ms": float(np.min(samples_ms)),
        "cpu_max_ms": float(np.max(samples_ms)),
        "rtl_reference_ms": rtl_ms,
        "speedup_vs_rtl": (rtl_ms / float(np.mean(samples_ms))) if rtl_ms else None,
    }
    return summary, output


def print_results(results: list[dict[str, float]]) -> None:
    headers = [
        "kernel",
        "cpu_mean_ms",
        "cpu_min_ms",
        "cpu_max_ms",
        "rtl_reference_ms",
        "speedup_vs_rtl",
    ]
    widths = {header: len(header) for header in headers}

    formatted_rows = []
    for row in results:
        formatted = {
            "kernel": row["kernel"],
            "cpu_mean_ms": f"{row['cpu_mean_ms']:.3f}",
            "cpu_min_ms": f"{row['cpu_min_ms']:.3f}",
            "cpu_max_ms": f"{row['cpu_max_ms']:.3f}",
            "rtl_reference_ms": (
                f"{row['rtl_reference_ms']:.2f}" if row["rtl_reference_ms"] is not None else "-"
            ),
            "speedup_vs_rtl": (
                f"{row['speedup_vs_rtl']:.2f}x" if row["speedup_vs_rtl"] is not None else "-"
            ),
        }
        formatted_rows.append(formatted)
        for header, value in formatted.items():
            widths[header] = max(widths[header], len(value))

    def render_row(row: dict[str, str]) -> str:
        return " | ".join(row[header].ljust(widths[header]) for header in headers)

    print(render_row({header: header for header in headers}))
    print("-+-".join("-" * widths[header] for header in headers))
    for row in formatted_rows:
        print(render_row(row))


def write_csv(path: Path, results: list[dict[str, float]]) -> None:
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=[
                "kernel",
                "cpu_mean_ms",
                "cpu_min_ms",
                "cpu_max_ms",
                "rtl_reference_ms",
                "speedup_vs_rtl",
            ],
        )
        writer.writeheader()
        writer.writerows(results)


def main() -> None:
    args = parse_args()

    if args.list_kernels:
        for kernel_name in sorted(KERNELS):
            print(kernel_name)
        return

    print("[DEBUG] Starting benchmark run with kernels:", args.kernels or list(KERNELS.keys()))

    if args.warmup_runs < 0 or args.benchmark_runs <= 0 or args.sample_iterations <= 0:
        raise ValueError("warmup-runs must be >= 0, benchmark-runs and sample-iterations must be > 0")

    input_path = Path(args.input)
    save_dir = Path(args.save_dir)
    save_dir.mkdir(parents=True, exist_ok=True)

    image = load_image(input_path)
    kernel_names = args.kernels or list(KERNELS.keys())
    stem = input_path.stem

    results = []
    for kernel_name in kernel_names:
        summary, output = benchmark_kernel(
            kernel_name,
            image,
            args.warmup_runs,
            args.benchmark_runs,
            args.sample_iterations,
        )
        result = {"kernel": kernel_name, **summary}
        results.append(result)

        if not args.no_save:
            output_path = save_dir / f"cpu_{stem}_{kernel_name}.png"
            cv2.imwrite(str(output_path), output)

    print_results(results)
    print("[DEBUG] Benchmark results:")
    for r in results:
        print(r)

    if args.csv:
        write_csv(Path(args.csv), results)


if __name__ == "__main__":
    print("[DEBUG] __main__ entry, about to call main()")
    main()