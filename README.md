# RTL-Vision
FPGA based image processing library targeting real-time and low-latency vision workloads.

## Vivado compatibility
This project was generated in Vivado 2025.2, so opening the checked-in `.xpr` directly may require that version or newer.

To use older Vivado versions, recreate the project and add the HDL/constraint sources from `RTLVision/RTLVision.srcs` manually instead of opening the generated project files. In particular, use:
- `RTLVision/RTLVision.srcs/sources_1/new/*.sv`
- `RTLVision/RTLVision.srcs/constrs_1/new/constraints.xdc`
- optional simulation sources under `RTLVision/RTLVision.srcs/sim_1` and `RTLVision/RTLVision.srcs/examples`

The repository also includes Vivado-generated cache/run metadata under directories such as `RTLVision/RTLVision.runs`, `RTLVision/RTLVision.cache`, and `RTLVision/RTLVision.ip_user_files`; those files are version-specific and may not open correctly in older Vivado releases.
