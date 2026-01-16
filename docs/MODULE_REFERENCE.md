# Module Documentation

This document provides detailed information about each module in the AXI-Vision library.

## Table of Contents

- [Line Buffer](#line-buffer)
- [Sobel Filter](#sobel-filter)
- [Gaussian Filter](#gaussian-filter)
- [Median Filter](#median-filter)
- [RGB to Grayscale](#rgb-to-grayscale)
- [Threshold](#threshold)
- [Histogram](#histogram)
- [Image Scaler](#image-scaler)

---

## Line Buffer

**File**: `rtl/utils/line_buffer.sv`

### Description

Parameterizable line buffer for 2D image processing operations. Efficiently stores K-1 image lines in BRAM and provides a sliding K×K window output.

### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| DATA_WIDTH | int | 8 | Bit width of pixel data |
| IMG_WIDTH | int | 1920 | Maximum image width |
| KERNEL_SIZE | int | 3 | Kernel dimensions (3 = 3×3, 5 = 5×5) |
| NUM_LINES | int | KERNEL_SIZE | Number of line buffers (typically KERNEL_SIZE) |

### Ports

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| clk | input | 1 | System clock |
| rst_n | input | 1 | Active-low async reset |
| pixel_valid | input | 1 | Input pixel valid |
| pixel_data | input | DATA_WIDTH | Input pixel data |
| window_valid | output | 1 | Output window valid |
| window_data | output | [K][K][DATA_WIDTH] | Kernel window output |
| img_width | input | 16 | Actual image width |
| frame_start | input | 1 | Start of frame signal |

### Timing

- **Latency**: (KERNEL_SIZE/2) × IMG_WIDTH + (KERNEL_SIZE/2) cycles
- **Throughput**: 1 pixel per cycle (when valid)
- Window becomes valid after filling initial border pixels

### Resource Usage (Artix-7)

For 1920×1080, 8-bit, 3×3 kernel:
- **BRAM**: 2 × 36Kb (2 line buffers)
- **LUTs**: ~100
- **FFs**: ~50

### Usage Example

```systemverilog
line_buffer #(
    .DATA_WIDTH(8),
    .IMG_WIDTH(1920),
    .KERNEL_SIZE(3)
) u_line_buf (
    .clk(clk),
    .rst_n(rst_n),
    .pixel_valid(pixel_valid),
    .pixel_data(pixel_data),
    .window_valid(window_valid),
    .window_data(window_data),
    .img_width(16'd1920),
    .frame_start(frame_start)
);
```

---

## Sobel Filter

**File**: `rtl/filters/sobel_filter.sv`

### Description

Real-time Sobel edge detection filter using 3×3 convolution kernels. Computes horizontal (Gx) and vertical (Gy) gradients and outputs edge magnitude.

### Algorithm

**Gx Kernel (Horizontal)**:
```
[-1  0  1]
[-2  0  2]
[-1  0  1]
```

**Gy Kernel (Vertical)**:
```
[-1 -2 -1]
[ 0  0  0]
[ 1  2  1]
```

**Edge Magnitude**: |Gx| + |Gy| (Manhattan distance approximation)

### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| DATA_WIDTH | int | 8 | Pixel bit width |
| IMG_WIDTH | int | 1920 | Maximum image width |

### AXI4-Stream Interface

**Slave (Input)**:
- s_axis_tvalid, s_axis_tready, s_axis_tdata
- s_axis_tlast (end of line), s_axis_tuser (start of frame)

**Master (Output)**:
- m_axis_tvalid, m_axis_tready, m_axis_tdata
- m_axis_tlast (end of line), m_axis_tuser (start of frame)

### Timing

- **Pipeline Stages**: 3
- **Latency**: ~3 + 2×IMG_WIDTH + 2 cycles
- **Throughput**: 1 pixel per cycle

### Resource Usage (Artix-7)

For 1920×1080, 8-bit:
- **BRAM**: 2 × 36Kb
- **LUTs**: ~500
- **FFs**: ~300
- **DSPs**: 0

### Usage Example

```systemverilog
sobel_filter #(
    .DATA_WIDTH(8),
    .IMG_WIDTH(1920)
) u_sobel (
    .clk(clk),
    .rst_n(rst_n),
    // AXI4-Stream Slave
    .s_axis_tvalid(s_tvalid),
    .s_axis_tready(s_tready),
    .s_axis_tdata(s_tdata),
    .s_axis_tlast(s_tlast),
    .s_axis_tuser(s_tuser),
    // AXI4-Stream Master
    .m_axis_tvalid(m_tvalid),
    .m_axis_tready(m_tready),
    .m_axis_tdata(m_tdata),
    .m_axis_tlast(m_tlast),
    .m_axis_tuser(m_tuser),
    // Configuration
    .img_width(16'd1920)
);
```

---

## Gaussian Filter

**File**: `rtl/filters/gaussian_filter.sv`

### Description

Gaussian blur filter for noise reduction and smoothing. Implements 3×3 or 5×5 Gaussian convolution using fixed-point arithmetic.

### Algorithm

**3×3 Gaussian Kernel (σ ≈ 1.0)**:
```
[1  2  1]
[2  4  2] / 16
[1  2  1]
```

**5×5 Gaussian Kernel (σ ≈ 1.4)**:
```
[1  4  6  4  1]
[4 16 24 16  4]
[6 24 36 24  6] / 256
[4 16 24 16  4]
[1  4  6  4  1]
```

### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| DATA_WIDTH | int | 8 | Pixel bit width |
| IMG_WIDTH | int | 1920 | Maximum image width |
| KERNEL_SIZE | int | 3 | 3 or 5 supported |

### Timing

- **Pipeline Stages**: 2
- **Latency (3×3)**: ~4 + 2×IMG_WIDTH + 1 cycles
- **Latency (5×5)**: ~4 + 4×IMG_WIDTH + 2 cycles
- **Throughput**: 1 pixel per cycle

### Resource Usage (Artix-7)

For 1920×1080, 8-bit, 3×3:
- **BRAM**: 2 × 36Kb
- **LUTs**: ~600
- **FFs**: ~350
- **DSPs**: 0

---

## Median Filter

**File**: `rtl/filters/median_filter.sv`

### Description

3×3 median filter for salt-and-pepper noise removal. Uses a bitonic sorting network optimized for FPGA implementation.

### Algorithm

- Flattens 3×3 window to 9-element array
- Sorts using parallel comparator network
- Extracts median (5th element)

### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| DATA_WIDTH | int | 8 | Pixel bit width |
| IMG_WIDTH | int | 1920 | Maximum image width |

### Timing

- **Pipeline Stages**: 3
- **Latency**: ~5 + 2×IMG_WIDTH + 1 cycles
- **Throughput**: 1 pixel per cycle

### Resource Usage (Artix-7)

For 1920×1080, 8-bit:
- **BRAM**: 2 × 36Kb
- **LUTs**: ~800
- **FFs**: ~400
- **DSPs**: 0

---

## RGB to Grayscale

**File**: `rtl/converters/rgb_to_gray.sv`

### Description

Converts RGB color images to grayscale using ITU-R BT.601 standard formula with fixed-point arithmetic.

### Algorithm

**Y = 0.299×R + 0.587×G + 0.114×B**

Implemented as:
**Y = (77×R + 150×G + 29×B) / 256**

### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| RGB_WIDTH | int | 24 | Total RGB width (8 bits/channel) |
| GRAY_WIDTH | int | 8 | Output grayscale width |

### Timing

- **Pipeline Stages**: 3
- **Latency**: 3 cycles
- **Throughput**: 1 pixel per cycle

### Resource Usage (Artix-7)

- **BRAM**: 0
- **LUTs**: ~150
- **FFs**: ~100
- **DSPs**: 3 (for multiplications)

---

## Threshold

**File**: `rtl/filters/threshold.sv`

### Description

Simple binary thresholding for image segmentation. Supports binary and inverse binary modes.

### Modes

- **Binary**: output = (input > threshold) ? max_val : 0
- **Binary Inverse**: output = (input > threshold) ? 0 : max_val

### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| DATA_WIDTH | int | 8 | Pixel bit width |
| INVERSE | bit | 0 | 0=binary, 1=inverse binary |

### Timing

- **Pipeline Stages**: 1
- **Latency**: 1 cycle
- **Throughput**: 1 pixel per cycle

### Resource Usage (Artix-7)

- **BRAM**: 0
- **LUTs**: ~50
- **FFs**: ~30
- **DSPs**: 0

---

## Histogram

**File**: `rtl/utils/histogram.sv`

### Description

Real-time histogram computation for 8-bit grayscale images. Accumulates pixel intensity distribution during frame processing.

### Features

- 256 bins (one per intensity level)
- 32-bit counters (supports up to 4G pixels)
- Auto-clear on frame start
- Pass-through AXI4-Stream (transparent)

### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| DATA_WIDTH | int | 8 | Pixel bit width |
| BIN_WIDTH | int | 32 | Counter bit width |

### Timing

- **Latency**: 0 (pass-through)
- **Throughput**: 1 pixel per cycle

### Resource Usage (Artix-7)

- **BRAM**: 1 × 36Kb (256 × 32-bit counters)
- **LUTs**: ~200
- **FFs**: ~100

---

## Image Scaler

**File**: `rtl/utils/image_scaler.sv`

### Description

Image scaling with nearest-neighbor or bilinear interpolation. Supports arbitrary scale factors.

### Features

- Scale factors: 0.25× to 4.0×
- Nearest-neighbor: low latency, blocky output
- Bilinear: higher quality, increased latency (partial implementation)
- Fixed-point coordinate calculation

### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| DATA_WIDTH | int | 8 | Pixel bit width |
| IMG_WIDTH_MAX | int | 1920 | Maximum image width |
| BILINEAR | bit | 1 | 1=bilinear, 0=nearest |

### Timing

- **Latency**: Variable, depends on scale factor
- **Throughput**: Variable, depends on scale factor

### Resource Usage (Artix-7)

For 1920×1080, 8-bit:
- **BRAM**: 2 × 36Kb (2 line buffers)
- **LUTs**: ~1000
- **FFs**: ~500
- **DSPs**: 2 (for multiplications)

---

## Common Design Patterns

### Module Chaining

```systemverilog
// Chain: RGB → Gray → Gaussian → Sobel
rgb_to_gray u_rgb2gray (...);
gaussian_filter u_gaussian (...);
sobel_filter u_sobel (...);

// Connect AXI streams
assign gaussian_s_axis = rgb2gray_m_axis;
assign sobel_s_axis = gaussian_m_axis;
```

### Frame Synchronization

All modules respect TUSER (start of frame) and TLAST (end of line):

```
Frame Start: TUSER=1, TVALID=1
Line End: TLAST=1, TVALID=1
```

### Backpressure Handling

All modules support AXI4-Stream backpressure via TREADY signal:

```
Data Transfer occurs when: TVALID=1 AND TREADY=1
```

---

For additional information, see the source code comments and the main README.md.
