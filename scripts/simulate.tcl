#
# AXI-Vision: FPGA Image Processing Library
#
# Script: simulate.tcl
# Description: Vivado simulation script for testbenches
#
# Usage: vivado -mode batch -source scripts/simulate.tcl -tclargs <testbench_name>
#

# Get testbench name from command line
if { $argc > 0 } {
    set tb_name [lindex $argv 0]
} else {
    set tb_name "line_buffer_tb"
    puts "No testbench specified, using default: $tb_name"
}

# Create simulation project
set proj_name "sim_${tb_name}"
create_project -force $proj_name ./build/sim -part xc7a35tcsg324-1

# Add source files
add_files -fileset sources_1 [glob ./rtl/utils/*.sv]
add_files -fileset sources_1 [glob ./rtl/filters/*.sv]
add_files -fileset sources_1 [glob ./rtl/converters/*.sv]

# Add testbench files
add_files -fileset sim_1 ./sim/testbenches/${tb_name}.sv

# Set top module
set_property top ${tb_name} [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]

# Update compile order
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

# Launch simulation
launch_simulation

# Run simulation
run 10us

# Close project
close_project
