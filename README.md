# AXI-Vision

![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)
![FPGA](https://img.shields.io/badge/FPGA-Xilinx%20Artix--7-orange.svg)
![Language](https://img.shields.io/badge/language-SystemVerilog-green.svg)

**AXI-Vision** is a reusable FPGA image processing library designed for real-time and low-latency vision workloads. The library provides parameterizable hardware modules implementing core image processing primitives, validated on Xilinx Artix-7 hardware.

## Features

- **AXI4-Stream Interface**: Industry-standard streaming interface for seamless integration
- **Parameterizable Modules**: Configurable data widths, image dimensions, and kernel sizes
- **Low Latency**: Deterministic, pipeline-based architectures optimized for minimal latency
- **Memory Efficient**: Optimized BRAM utilization for line buffers and temporary storage
- **Streaming Architecture**: Processes images on-the-fly without full frame buffering
- **Xilinx Artix-7 Optimized**: Validated on Artix-7 FPGA with efficient resource utilization

## Architecture Overview

AXI-Vision modules follow a consistent streaming architecture:

```
Input Stream → Line Buffer → Processing Pipeline → Output Stream
(AXI4-Stream)     (BRAM)      (Combinational +         (AXI4-Stream)
                               Registered stages)
```

### Key Design Principles

1. **Streaming Processing**: Single-pass algorithms that operate on pixel streams
2. **Deterministic Latency**: Fixed, predictable latency for each module
3. **Memory Bandwidth Efficiency**: Minimal DRAM access through efficient line buffering
4. **Pipeline-Friendly**: Register stages enable high clock frequencies (100+ MHz)

## Available Modules

### Image Filters

| Module | Description | Kernel Size | Latency (cycles) | BRAM Usage |
|--------|-------------|-------------|------------------|------------|
| **sobel_filter** | Edge detection using Sobel operator | 3x3 | ~3 + 2×W + 2 | 2 line buffers |
| **gaussian_filter** | Gaussian blur for noise reduction | 3x3 or 5x5 | ~4 + (K-1)×W | (K-1) line buffers |
| **median_filter** | Median filter using sorting network | 3x3 | ~5 + 2×W + 1 | 2 line buffers |
| **threshold** | Binary/inverse binary thresholding | N/A | 1 | None |

### Color Space Converters

| Module | Description | Latency (cycles) | Algorithm |
|--------|-------------|------------------|-----------|
| **rgb_to_gray** | RGB to Grayscale conversion | 3 | ITU-R BT.601 (Y = 0.299R + 0.587G + 0.114B) |

### Utility Modules

| Module | Description | Configuration | Resource Usage |
|--------|-------------|---------------|----------------|
| **line_buffer** | Configurable line buffer for 2D operations | Kernel size, image width | K-1 line buffers (BRAM) |
| **histogram** | Real-time histogram computation | 256 bins × 32-bit counters | 1KB BRAM |
| **image_scaler** | Bilinear/nearest-neighbor scaling | Scale factors 0.25x to 4.0x | 2 line buffers |

### Common Parameters

- **DATA_WIDTH**: Pixel bit width (typically 8, 10, 12, or 16 bits)
- **IMG_WIDTH**: Maximum image width (default: 1920 for 1080p)
- **KERNEL_SIZE**: Processing kernel size (3x3, 5x5, etc.)

## Quick Start

### Prerequisites

- Xilinx Vivado Design Suite (2020.1 or later)
- Xilinx Artix-7 FPGA board (Basys3, Nexys A7, or similar)
- Basic understanding of AXI4-Stream protocol

### Using a Module in Your Design

1. **Add source files to your Vivado project:**

```tcl
add_files [glob ./rtl/utils/*.sv]
add_files [glob ./rtl/filters/*.sv]
add_files [glob ./rtl/converters/*.sv]
```

2. **Instantiate a filter in your design:**

```systemverilog
sobel_filter #(
    .DATA_WIDTH(8),
    .IMG_WIDTH(1920)
) u_sobel (
    .clk(clk),
    .rst_n(rst_n),
    .s_axis_tvalid(s_axis_tvalid),
    .s_axis_tready(s_axis_tready),
    .s_axis_tdata(s_axis_tdata),
    .s_axis_tlast(s_axis_tlast),
    .s_axis_tuser(s_axis_tuser),
    .m_axis_tvalid(m_axis_tvalid),
    .m_axis_tready(m_axis_tready),
    .m_axis_tdata(m_axis_tdata),
    .m_axis_tlast(m_axis_tlast),
    .m_axis_tuser(m_axis_tuser),
    .img_width(16'd1920)
);
```

3. **Add timing constraints:**

```tcl
source ./constraints/timing.xdc
```

### Running Simulations

```bash
# Simulate line buffer
vivado -mode batch -source scripts/simulate.tcl -tclargs line_buffer_tb

# Simulate Sobel filter
vivado -mode batch -source scripts/simulate.tcl -tclargs sobel_filter_tb
```

### Building Example Design

```bash
# Synthesize and implement reference design
vivado -mode batch -source scripts/build.tcl
```

## AXI4-Stream Protocol

All modules use standard AXI4-Stream signaling:

- **TVALID**: Valid data present on TDATA
- **TREADY**: Downstream ready to accept data
- **TDATA**: Pixel data
- **TLAST**: End of line (row) marker
- **TUSER**: Start of frame marker

### Timing Diagram

```
CLK     __|‾‾|__|‾‾|__|‾‾|__|‾‾|__|‾‾|__
TVALID  ____|‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾|____
TREADY  ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
TDATA   ----<P0 ><P1 ><P2 ><P3 >-------
TLAST   __________________|‾‾|_________
TUSER   ____|‾‾|_______________________
```

## Performance Characteristics

### Latency Analysis

| Module | Latency | Notes |
|--------|---------|-------|
| sobel_filter | ~3 + 2×W + 2 cycles | W = image width |
| gaussian_filter (3×3) | ~4 + 2×W + 1 cycles | W = image width |
| median_filter | ~5 + 2×W + 1 cycles | W = image width |
| rgb_to_gray | 3 cycles | Constant latency |
| threshold | 1 cycle | Constant latency |

### Resource Utilization (Artix-7)

Example for 1920×1080 @ 8-bit:

| Module | LUTs | FFs | BRAM | DSPs |
|--------|------|-----|------|------|
| sobel_filter | ~500 | ~300 | 2 | 0 |
| gaussian_filter (3×3) | ~600 | ~350 | 2 | 0 |
| median_filter | ~800 | ~400 | 2 | 0 |
| rgb_to_gray | ~150 | ~100 | 0 | 3 |

### Throughput

At 100 MHz clock frequency:
- **Maximum throughput**: 100 Mpixels/second
- **1080p (1920×1080)**: ~48 fps
- **720p (1280×720)**: ~108 fps
- **VGA (640×480)**: ~325 fps

## Directory Structure

```
AXI-Vision/
├── rtl/                      # RTL source files
│   ├── filters/              # Image processing filters
│   │   ├── sobel_filter.sv
│   │   ├── gaussian_filter.sv
│   │   ├── median_filter.sv
│   │   └── threshold.sv
│   ├── converters/           # Color space converters
│   │   └── rgb_to_gray.sv
│   └── utils/                # Utility modules
│       ├── axi_stream_pkg.sv
│       ├── line_buffer.sv
│       ├── histogram.sv
│       └── image_scaler.sv
├── sim/                      # Simulation files
│   ├── testbenches/          # Module testbenches
│   │   ├── line_buffer_tb.sv
│   │   └── sobel_filter_tb.sv
│   └── models/               # Behavioral models
├── constraints/              # FPGA constraints
│   └── timing.xdc            # Timing constraints for Artix-7
├── scripts/                  # Build and simulation scripts
│   ├── simulate.tcl          # Vivado simulation script
│   └── build.tcl             # Vivado build script
└── docs/                     # Documentation
```

## Design Methodology

### Memory Bandwidth Optimization

- **Line Buffering**: Only K-1 lines buffered for K×K kernel operations
- **Streaming Processing**: No full frame storage required
- **Single-Pass**: Each pixel processed exactly once
- **BRAM Efficiency**: Optimized for 36Kb BRAM primitives in Artix-7

### Latency Determinism

- **Fixed Pipeline Depth**: All modules have deterministic latency
- **No Data-Dependent Stalls**: Processing time independent of pixel values
- **Backpressure Support**: AXI4-Stream TREADY for flow control
- **Predictable Throughput**: Suitable for real-time systems

### Parameterization Strategy

- **Compile-Time Parameters**: Module parameters set during synthesis
- **Runtime Configuration**: Image dimensions via input ports
- **Resource Scaling**: Larger kernels/widths automatically increase BRAM usage
- **Generic Interfaces**: Same AXI4-Stream interface across all modules

## Testing and Validation

### Simulation

Basic testbenches included for functional verification:
- Line buffer window generation
- Sobel edge detection on synthetic patterns
- Additional testbenches can be added in `sim/testbenches/`

### Hardware Validation

Library modules have been validated on:
- **Board**: Xilinx Basys3 (xc7a35tcsg324-1)
- **Clock**: 100 MHz
- **Test Patterns**: Synthetic gradients, edges, noise patterns
- **Metrics**: Resource usage, timing closure, output correctness

## Integration Guide

### Chaining Modules

Modules can be cascaded using AXI4-Stream connections:

```systemverilog
// Example: RGB → Grayscale → Gaussian → Sobel → Threshold
rgb_to_gray → gaussian_filter → sobel_filter → threshold
```

### Clock Domain Crossing

For multi-clock designs, insert AXI4-Stream FIFOs:

```systemverilog
// Xilinx AXI4-Stream Data FIFO
axis_data_fifo u_cdc_fifo (
    .s_axis_aclk(clk_domain1),
    .m_axis_aclk(clk_domain2),
    // ... other connections
);
```

### DMA Integration

Connect to Xilinx AXI DMA for system memory access:

```
DDR Memory ← AXI DMA → AXI4-Stream → AXI-Vision Filters → AXI4-Stream → AXI DMA → DDR Memory
```

## Performance Tuning

### Increasing Throughput

1. **Increase Clock Frequency**: Target 150+ MHz on -2 speed grade Artix-7
2. **Pipeline Addition**: Add register stages for timing closure
3. **Parallel Processing**: Instantiate multiple filter chains for multi-stream

### Reducing Latency

1. **Minimize Kernel Size**: Use 3×3 instead of 5×5 where acceptable
2. **Optimize Line Buffer**: Reduce IMG_WIDTH parameter if possible
3. **Remove Unnecessary Stages**: Simplify algorithms for lower latency

### Reducing Resource Usage

1. **Smaller Data Width**: Use 8-bit instead of 16-bit if precision allows
2. **Shared Line Buffers**: Multiplex line buffers between modules
3. **Resource Sharing**: Time-multiplex filters for area-constrained designs

## Roadmap

Future enhancements planned:
- [ ] Additional filters (bilateral, Canny edge detection)
- [ ] Multi-channel support (RGB processing without conversion)
- [ ] AXI4-Lite control interface for runtime configuration
- [ ] High-level synthesis (HLS) examples
- [ ] Zynq PS integration examples
- [ ] Performance benchmarks on additional FPGA families

## Contributing

Contributions are welcome! Areas of interest:
- Additional image processing algorithms
- Performance optimizations
- Additional target FPGA families
- Enhanced testbenches and verification
- Example applications and designs

## License

This project is licensed under the Apache License 2.0 - see the LICENSE file for details.

## References

- [AXI4-Stream Protocol Specification](https://www.xilinx.com/support/documentation/ip_documentation/axi_ref_guide/latest/ug1037-vivado-axi-reference-guide.pdf)
- [Xilinx Artix-7 FPGAs Data Sheet](https://www.xilinx.com/support/documentation/data_sheets/ds180_7Series_Overview.pdf)
- Digital Image Processing Algorithms (Gonzalez & Woods)

## Contact

For questions, issues, or suggestions, please open an issue on the GitHub repository.

---

**Built for real-time vision processing on FPGA hardware.**
