# RTL-Vision
FPGA based image processing library targeting real-time and low-latency vision workloads.

## Vivado compatibility
This repository is kept **version-agnostic** by treating Vivado project files as generated artifacts.
Do **not** rely on the checked-in `.xpr` or run/cache directories for long-term compatibility across Vivado releases.

### Open in any compatible Vivado version
Create a new RTL project for part `xc7a100tcsg324-1`, then add the repository sources manually:

#### Design sources
- `RTLVision/RTLVision.srcs/sources_1/new/grayscale.sv`
- `RTLVision/RTLVision.srcs/sources_1/new/fifo_pipeline.sv`
- `RTLVision/RTLVision.srcs/sources_1/new/sync_fifo.sv`
- `RTLVision/RTLVision.srcs/sources_1/new/sobel.sv`

#### Constraints
- `RTLVision/RTLVision.srcs/constrs_1/new/constraints.xdc`

#### Optional simulation sources
- `RTLVision/RTLVision.srcs/sim_1/new/tb_grayscale.sv`
- `RTLVision/RTLVision.srcs/sim_1/new/ex_grayscale.sv`
- `RTLVision/RTLVision.srcs/examples/new/ex_sobel.sv`
- `RTLVision/RTLVision.srcs/examples/new/tb_fifo_pipeline.sv`
- `RTLVision/RTLVision.srcs/examples/new/tb_sync_fifo.sv`

### Recommended top modules
- Synthesis top: `sobel`
- Example simulation top: `ex_sobel`
- Other available testbenches: `tb_grayscale`, `tb_fifo_pipeline`, `tb_sync_fifo`

### Version-specific files
The following are Vivado-generated and may differ between Vivado versions, so they should not be used as the portability baseline:
- `RTLVision/RTLVision.xpr`
- `RTLVision/RTLVision.runs/`
- `RTLVision/RTLVision.cache/`
- `RTLVision/RTLVision.hw/`
- `RTLVision/RTLVision.ip_user_files/`
- `RTLVision/RTLVision.sim/`

If you regenerate project artifacts locally, keep the HDL and XDC sources under `RTLVision/RTLVision.srcs/` as the source of truth.
