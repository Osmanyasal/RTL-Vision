from __future__ import annotations

import argparse
import time
from pathlib import Path

import cv2
import numpy as np


DIAMOND_KERNEL_3X3 = np.array(
	[[0, 1, 0], [1, 1, 1], [0, 1, 0]],
	dtype=np.uint8,
)


def parse_args() -> argparse.Namespace:
	parser = argparse.ArgumentParser(
		description="Generate CPU reference images for RTLVision morphology kernels.",
	)
	parser.add_argument(
		"--input",
		type=Path,
		default=None,
		help="Input image path. Defaults to kaan.bmp, then kaan.png.",
	)
	parser.add_argument(
		"--output-dir",
		type=Path,
		default=Path("."),
		help="Directory for generated cpu_*.png images.",
	)
	parser.add_argument(
		"--operations",
		default="dilation3x3,erosion3x3",
		help="Comma-separated operation list. Supported: dilation3x3, erosion3x3.",
	)
	parser.add_argument(
		"--threshold",
		type=int,
		default=128,
		help="Binary threshold applied before morphology.",
	)
	parser.add_argument(
		"--warmup-runs",
		type=int,
		default=0,
		help="Warmup runs per operation before benchmarking.",
	)
	parser.add_argument(
		"--benchmark-runs",
		type=int,
		default=1,
		help="Measured benchmark runs per operation.",
	)
	parser.add_argument(
		"--sample-iterations",
		type=int,
		default=1,
		help="Operation invocations per measured benchmark run.",
	)
	return parser.parse_args()


def resolve_input_path(explicit_path: Path | None) -> Path:
	if explicit_path is not None:
		if not explicit_path.exists():
			raise FileNotFoundError(f"Input image not found: {explicit_path}")
		return explicit_path

	for candidate in (Path("kaan.bmp"), Path("kaan.png")):
		if candidate.exists():
			return candidate

	raise FileNotFoundError("Could not find kaan.bmp or kaan.png in the project root.")


def load_bgr_image(path: Path) -> np.ndarray:
	image = cv2.imread(str(path), cv2.IMREAD_COLOR)
	if image is None:
		raise ValueError(f"Failed to decode image: {path}")
	return image


def rtl_grayscale(image_bgr: np.ndarray) -> np.ndarray:
	blue = image_bgr[:, :, 0].astype(np.uint16)
	green = image_bgr[:, :, 1].astype(np.uint16)
	red = image_bgr[:, :, 2].astype(np.uint16)

	gray = (
		(red >> 2)
		+ (red >> 5)
		+ (green >> 1)
		+ (green >> 4)
		+ (blue >> 4)
		+ (blue >> 5)
	)
	return gray.astype(np.uint8)


def rtl_threshold(gray: np.ndarray, threshold: int) -> np.ndarray:
	return np.where(threshold > gray, 0, 255).astype(np.uint8)


def apply_streaming_delay(image: np.ndarray) -> np.ndarray:
	delayed = np.zeros_like(image)
	delayed[1:, 1:] = image[:-1, :-1]
	return delayed


def morphology_reference(binary_image: np.ndarray, operation: str) -> np.ndarray:
	if operation == "dilation3x3":
		centered = cv2.dilate(
			binary_image,
			DIAMOND_KERNEL_3X3,
			borderType=cv2.BORDER_CONSTANT,
			borderValue=0,
		)
	elif operation == "erosion3x3":
		centered = cv2.erode(
			binary_image,
			DIAMOND_KERNEL_3X3,
			borderType=cv2.BORDER_CONSTANT,
			borderValue=0,
		)
	else:
		raise ValueError(f"Unsupported operation: {operation}")

	return apply_streaming_delay(centered)


def benchmark_operation(
	binary_image: np.ndarray,
	operation: str,
	warmup_runs: int,
	benchmark_runs: int,
	sample_iterations: int,
) -> tuple[np.ndarray, list[float]]:
	for _ in range(warmup_runs):
		for _ in range(sample_iterations):
			morphology_reference(binary_image, operation)

	result: np.ndarray | None = None
	samples_ms: list[float] = []

	for _ in range(benchmark_runs):
		start = time.perf_counter()
		for _ in range(sample_iterations):
			result = morphology_reference(binary_image, operation)
		elapsed_ms = (time.perf_counter() - start) * 1000.0 / sample_iterations
		samples_ms.append(elapsed_ms)

	if result is None:
		result = morphology_reference(binary_image, operation)

	return result, samples_ms


def output_path(output_dir: Path, input_path: Path, operation: str) -> Path:
	return output_dir / f"cpu_{input_path.stem}_{operation}.png"


def parse_operations(raw_operations: str) -> list[str]:
	operations = [item.strip() for item in raw_operations.split(",") if item.strip()]
	supported = {"dilation3x3", "erosion3x3"}
	invalid = [item for item in operations if item not in supported]
	if invalid:
		raise ValueError(
			f"Unsupported operations: {', '.join(invalid)}. Supported: {', '.join(sorted(supported))}",
		)
	if not operations:
		raise ValueError("At least one operation must be requested.")
	return operations


def main() -> None:
	args = parse_args()
	input_path = resolve_input_path(args.input)
	operations = parse_operations(args.operations)

	args.output_dir.mkdir(parents=True, exist_ok=True)

	image_bgr = load_bgr_image(input_path)
	grayscale = rtl_grayscale(image_bgr)
	binary = rtl_threshold(grayscale, args.threshold)

	print(f"Input: {input_path}")
	print(f"Resolution: {image_bgr.shape[1]}x{image_bgr.shape[0]}")
	print(f"Threshold: {args.threshold}")

	for operation in operations:
		result, samples_ms = benchmark_operation(
			binary,
			operation,
			warmup_runs=args.warmup_runs,
			benchmark_runs=args.benchmark_runs,
			sample_iterations=args.sample_iterations,
		)

		destination = output_path(args.output_dir, input_path, operation)
		if not cv2.imwrite(str(destination), result):
			raise OSError(f"Failed to write output image: {destination}")

		if samples_ms:
			avg_ms = sum(samples_ms) / len(samples_ms)
			print(f"{operation}: {avg_ms:.3f} ms -> {destination}")
		else:
			print(f"{operation}: wrote {destination}")


if __name__ == "__main__":
	main()
