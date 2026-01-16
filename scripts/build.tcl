#
# AXI-Vision: FPGA Image Processing Library
#
# Script: build.tcl
# Description: Vivado synthesis and implementation script
#
# Usage: vivado -mode batch -source scripts/build.tcl
#
# This script synthesizes a reference design using the AXI-Vision library
# Target: Xilinx Artix-7 xc7a35tcsg324-1 (Basys3 board)
#

# Project settings
set proj_name "axi_vision_example"
set proj_dir "./build/impl"
set top_module "sobel_filter"

# Create project
create_project -force $proj_name $proj_dir -part xc7a35tcsg324-1

# Set project properties
set_property target_language SystemVerilog [current_project]
set_property simulator_language Mixed [current_project]

# Add source files
puts "Adding source files..."
add_files -fileset sources_1 [glob -nocomplain ./rtl/utils/*.sv]
add_files -fileset sources_1 [glob -nocomplain ./rtl/filters/*.sv]
add_files -fileset sources_1 [glob -nocomplain ./rtl/converters/*.sv]

# Add constraint files
if { [file exists ./constraints/timing.xdc] } {
    add_files -fileset constrs_1 ./constraints/timing.xdc
}

# Set top module
set_property top $top_module [current_fileset]

# Update compile order
update_compile_order -fileset sources_1

# Run synthesis
puts "Running synthesis..."
launch_runs synth_1 -jobs 4
wait_on_run synth_1

# Check for synthesis errors
if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {
    error "Synthesis failed"
}

# Open synthesized design
open_run synth_1

# Report utilization and timing
report_utilization -file $proj_dir/utilization_synth.rpt
report_timing_summary -file $proj_dir/timing_synth.rpt

# Run implementation
puts "Running implementation..."
launch_runs impl_1 -jobs 4
wait_on_run impl_1

# Check for implementation errors
if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {
    error "Implementation failed"
}

# Open implemented design
open_run impl_1

# Report final results
report_utilization -file $proj_dir/utilization_impl.rpt
report_timing_summary -file $proj_dir/timing_impl.rpt
report_power -file $proj_dir/power.rpt

# Generate bitstream (optional - commented out as this is a library)
# launch_runs impl_1 -to_step write_bitstream
# wait_on_run impl_1

puts "Build completed successfully"
close_project
