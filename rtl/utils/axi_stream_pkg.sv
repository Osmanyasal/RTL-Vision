/**
 * AXI-Vision: FPGA Image Processing Library
 * 
 * Module: axi_stream_pkg
 * Description: Package containing AXI4-Stream interface definitions and parameters
 * 
 * Features:
 * - Parameterizable data width
 * - Support for TUSER, TKEEP, TSTRB signals
 * - Common image processing parameters
 * 
 * Target: Xilinx Artix-7
 * Author: AXI-Vision Project
 * License: Apache-2.0
 */

package axi_stream_pkg;

  // AXI4-Stream standard signals structure
  typedef struct packed {
    logic        tvalid;
    logic        tready;
    logic        tlast;
    logic        tuser;
  } axi_stream_ctrl_t;

  // Common image dimensions
  parameter int IMG_WIDTH_MAX  = 1920;  // Maximum width (1080p)
  parameter int IMG_HEIGHT_MAX = 1080;  // Maximum height (1080p)
  
  // Common data widths
  parameter int PIXEL_WIDTH_8  = 8;
  parameter int PIXEL_WIDTH_10 = 10;
  parameter int PIXEL_WIDTH_12 = 12;
  parameter int PIXEL_WIDTH_16 = 16;
  
  // AXI Stream data widths
  parameter int AXIS_TDATA_WIDTH_8  = 8;
  parameter int AXIS_TDATA_WIDTH_16 = 16;
  parameter int AXIS_TDATA_WIDTH_24 = 24;
  parameter int AXIS_TDATA_WIDTH_32 = 32;
  parameter int AXIS_TDATA_WIDTH_64 = 64;

endpackage : axi_stream_pkg
