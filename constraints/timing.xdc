##
## AXI-Vision: FPGA Image Processing Library
##
## File: timing.xdc
## Description: Timing constraints for Xilinx Artix-7
##
## Target: xc7a35tcsg324-1 (Basys3 / similar boards)
##

## Clock constraint
## Adjust according to your design's clock frequency
## Example: 100 MHz system clock
create_clock -period 10.000 -name sys_clk [get_ports clk]

## Input delay constraints
## Assumes AXI4-Stream input from another clock domain or external source
set_input_delay -clock sys_clk -max 2.000 [get_ports s_axis_*]
set_input_delay -clock sys_clk -min 0.500 [get_ports s_axis_*]

## Output delay constraints
## Assumes AXI4-Stream output to another clock domain or external sink
set_output_delay -clock sys_clk -max 2.000 [get_ports m_axis_*]
set_output_delay -clock sys_clk -min 0.500 [get_ports m_axis_*]

## False paths for asynchronous reset
set_false_path -from [get_ports rst_n]

## Multi-cycle paths for configuration registers (if applicable)
## These are typically read-only during frame processing
# set_multicycle_path -setup 2 -from [get_ports img_width*]
# set_multicycle_path -hold 1 -from [get_ports img_width*]

## Maximum delay for critical paths
## This ensures deterministic latency through the pipeline
set_max_delay -from [get_ports s_axis_tvalid] -to [get_ports m_axis_tvalid] 50.000

## BRAM timing optimization
## Ensures line buffers meet timing
set_property BLOCK_SYNTH.RETIMING 1 [get_cells -hierarchical -filter {PRIMITIVE_TYPE =~ BMEM.*}]
