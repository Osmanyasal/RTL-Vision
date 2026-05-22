# RTL-Vision
FPGA-based image processing library targeting real-time and low-latency vision workloads.

### Kernel Comparison Table
<table>
	<thead>
		<tr>
			<th>Kernel</th>
			<th>FPGA Output</th>
			<th>CPU Output (Streaming)</th>
			<th>FPGA Time</th>
			<th>CPU Time (Streaming)</th>
		</tr>
	</thead>
	<tbody>
		<tr>
			<td><code>grayscale</code></td>
			<td><img src="butterfly_gray.jpg" alt="RTLVision grayscale output" width="280"></td>
			<td><img src="cpu_butterfly_grayscale_stream.png" alt="CPU grayscale_stream output" width="280"></td>
			<td>117.43 ms</td>
			<td>26466.603 ms </td>
		</tr>
		<tr>
			<td><code>histeq</code></td>
			<td><img src="butterfly_histeq_ycbcr.jpg" alt="RTLVision histeq output" width="280"></td>
			<td><img src="cpu_butterfly_histeq_stream.png" alt="CPU histeq_stream output" width="280"></td>
			<td>177.37 ms</td>
			<td>149014.166 ms </td>
		</tr>
	</tbody>
</table>

## Kernel Set
The checked-in HDL sources currently cover these image-processing kernels and helpers:
 
### Morphological Operations
- ✅ Erosion (`erosion3x3`, `erosion5x5`)
- ✅ Dilation (`dilation3x3`, `dilation5x5`)

### Noise Reduction
- ✅ Salt Papper (`saltpapper`)
- ✅ Median filter (`median3x3`, `median5x5`)

### Edge and Feature Extraction
- ✅ Sobel: `sobel3x3`, `sobel5x5`
- ✅ Sharpen: `sharpen3x3_ycbcr`
- ✅ Blur: `blur3x3_ycbcr`, `blur5x5_ycbcr`
- ✅ Grayscale: `grayscale`
- ✅ Prewitt filter (`prewitt3x3`)
- ✅ Laplacian filter (`laplacian3x3`)
- ✅ Emboss filter (`emboss3x3`)

### Color Segmentation and Masking
- ✅ RGB_to_HSV
- ✅ RGB_to_YCBCR
- ✅ Inverse
- ✅ Inrage
- ✅ HSV range threshold (`hsv_inrange`)   

### Thresholding Improvements
- ✅ Threshold simple: `threshold`
- ✅ Adaptive / local thresholding (`adaptive_threshold`)

### Histogram and Contrast Operations
- ✅ Histogram generator (`histogram`)
- Contrast stretch (`contrast_stretch`)
- ✅ Histogram equalization (`histeq`)

### Pixel Arithmetic and Compositing
- ✅ Brightness adjustment (`brightness`)
- Contrast adjustment (`contrast`)
- ✅ Invert (`invert`)
- Gamma approximation / LUT-based gamma (`gamma_lut`)
- ✅ Multiply Accumulate (`mac`)
- ✅ Image or mask add/subtract operations

### Geometric Operations
- Crop ROI (`crop_roi`)
- Resize with nearest-neighbor (`resize_nn`)
- Horizontal flip (`flip_horizontal`)

### Advanced Vision Features
- Scharr filter
- Corner response approximation
- Non-maximum suppression
- Hough pre-processing blocks

### Binary Image Analysis
- Blob area counter
- Bounding box extractor
- Centroid estimator
  
## 4K Sample Timing
The default frame budget is approximately `~9.2 ms`.

For the commonly cited `4096 x 2160` reference case at `100 MHz`:

- Total pixels per frame: $4096 \times 2160 = 8,847,360$
- Clock frequency: $100\,\text{MHz}$, so each cycle is $10\,\text{ns}$
- Total active pixel time: $8,847,360 \times 10\,\text{ns} \approx 88.47\,\text{ms}$
 
## CPU Comparison Flow
`cpu_compare.py` reads `butterfly.jpg` or `butterfly.png` as the software input image. It does not generate any Verilog-side assets. It executes the CPU-streaming equivalents of the kernels and writes `cpu_*` output images.

The script benchmarks the available CPU reference kernels with `time.perf_counter()`, reports per-kernel latency in milliseconds, optionally compares those numbers with the checked-in RTL reference timings, and writes `cpu_*` output images for visual inspection.

Available kernels can be listed with:

```bash
python3 cpu_compare.py --list-kernels
```

Running the script:

```bash
python3 -m pip install -r requirements.txt
python3 cpu_compare.py
python3 cpu_compare.py --input butterfly.png
python3 cpu_compare.py --kernels grayscale sobel3x3 --benchmark-runs 25 --sample-iterations 5
```

Generates:

- `cpu_butterfly_*.png` as CPU-streaming reference outputs
- a console timing table with CPU mean/min/max latency per kernel
- an optional CSV report when `--csv benchmark.csv` is supplied

Dependencies are captured in `requirements.txt`.

Image write-out is not included in the reported timing. Use `--no-save` when you only want benchmarking data.

