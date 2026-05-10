# Roadmap

This document outlines future development targets for the project.

## Future Development Targets

### Morphological Operations
- Erosion (`erode3x3`)
- Dilation (`dilate3x3`)
- Opening (`open3x3`)
- Closing (`close3x3`)

### Noise Reduction
- Median filter (`median3x3`)
- Larger-window median filter (`median5x5`)

### Edge and Feature Extraction
- Prewitt filter (`prewitt3x3`)
- Laplacian filter (`laplacian3x3`)
- Emboss filter (`emboss3x3`)
- Gradient magnitude / gradient direction split

### Color Segmentation and Masking
- HSV range threshold (`hsv_inrange`)
- YCbCr skin-color detector (`ycbcr_skin_mask`)
- Channel extraction (`channel_extract`)
- False-color mask overlay

### Thresholding Improvements
- Adaptive / local thresholding (`adaptive_threshold`)
- Otsu thresholding or a hardware-friendly approximation
- Mean-based local thresholding
- Dynamic thresholding from running luminance statistics

### Histogram and Contrast Operations
- Histogram generator (`histogram_luma`)
- Contrast stretch (`contrast_stretch`)
- Histogram equalization (`hist_eq`)

### Pixel Arithmetic and Compositing
- Brightness adjustment (`brightness`)
- Contrast adjustment (`contrast`)
- Invert (`invert`)
- Gamma approximation / LUT-based gamma (`gamma_lut`)
- Alpha blending (`alpha_blend`)
- Image or mask add/subtract operations

### Geometric Operations
- Crop ROI (`crop_roi`)
- Resize with nearest-neighbor (`resize_nn`)
- Horizontal flip (`flip_horizontal`)
- Vertical flip
- Rotate 90° (if buffering strategy allows)

### Advanced Vision Features
- Scharr filter
- Corner response approximation
- Non-maximum suppression
- Hough pre-processing blocks

### Binary Image Analysis
- Connected-component pre-label helpers
- Blob area counter
- Bounding box extractor
- Centroid estimator

## Suggested Priority Order
1. `dilate3x3`
2. `erode3x3`
3. `median3x3`
4. `hsv_inrange`
5. `laplacian3x3`
6. `adaptive_threshold`
7. `contrast_stretch`
8. `resize_nn`

## Suggested Feature Packs

### Binary Vision Pack
- `threshold`
- `adaptive_threshold`
- `erode3x3`
- `dilate3x3`
- `open3x3`
- `close3x3`

### Edge and Detail Pack
- `sobel3x3`
- `sobel5x5`
- `prewitt3x3`
- `laplacian3x3`
- `sharpen3x3`
- `emboss3x3`

### Color Analytics Pack
- `rgb_to_hsv`
- `rgb_to_ycbcr`
- `hsv_inrange`
- `ycbcr_skin_mask`
- `channel_extract`

### Utility Pack
- `brightness`
- `contrast`
- `invert`
- `gamma_lut`
- `resize_nn`
- `crop_roi`
