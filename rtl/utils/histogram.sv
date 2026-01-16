/**
 * AXI-Vision: FPGA Image Processing Library
 * 
 * Module: histogram
 * Description: Real-time histogram computation using AXI4-Stream
 * 
 * Features:
 * - 256-bin histogram for 8-bit grayscale images
 * - Dual-port RAM for concurrent read/write
 * - Frame-based operation with auto-clear
 * - Streaming architecture
 * 
 * Operation:
 * - Accumulates pixel intensity counts during frame
 * - Histogram can be read via AXI-Lite or memory interface
 * - Automatically resets on new frame (TUSER signal)
 * 
 * Memory: 256 x 32-bit counters (1KB BRAM)
 * Latency: Transparent (doesn't modify pixel stream)
 * Target: Xilinx Artix-7
 */

module histogram #(
    parameter int DATA_WIDTH = 8,   // Input pixel width
    parameter int BIN_WIDTH  = 32   // Counter width
) (
    input  logic                    clk,
    input  logic                    rst_n,
    
    // AXI4-Stream Slave Interface (Input - pass-through)
    input  logic                    s_axis_tvalid,
    output logic                    s_axis_tready,
    input  logic [DATA_WIDTH-1:0]   s_axis_tdata,
    input  logic                    s_axis_tlast,
    input  logic                    s_axis_tuser,  // Start of frame
    
    // AXI4-Stream Master Interface (Output - pass-through)
    output logic                    m_axis_tvalid,
    input  logic                    m_axis_tready,
    output logic [DATA_WIDTH-1:0]   m_axis_tdata,
    output logic                    m_axis_tlast,
    output logic                    m_axis_tuser,
    
    // Histogram read interface
    input  logic [7:0]              hist_read_addr,
    output logic [BIN_WIDTH-1:0]    hist_read_data,
    output logic                    hist_frame_done
);

    localparam int NUM_BINS = 2**DATA_WIDTH;
    
    // Histogram memory (dual-port)
    logic [BIN_WIDTH-1:0] histogram [0:NUM_BINS-1];
    
    // Frame control
    logic frame_active;
    logic last_tuser;
    
    // Detect frame start (rising edge of TUSER)
    logic frame_start;
    assign frame_start = s_axis_tuser && s_axis_tvalid && !last_tuser;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            last_tuser <= 1'b0;
        end else begin
            if (s_axis_tvalid) begin
                last_tuser <= s_axis_tuser;
            end
        end
    end
    
    // Histogram accumulation
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            histogram <= '{default: '0};
            frame_active <= 1'b0;
            hist_frame_done <= 1'b0;
        end else begin
            // Clear histogram on frame start
            if (frame_start) begin
                histogram <= '{default: '0};
                frame_active <= 1'b1;
                hist_frame_done <= 1'b0;
            end
            
            // Accumulate pixels
            if (s_axis_tvalid && s_axis_tready && frame_active) begin
                histogram[s_axis_tdata] <= histogram[s_axis_tdata] + 1'b1;
                
                // Mark frame done on last pixel
                if (s_axis_tlast) begin
                    hist_frame_done <= 1'b1;
                    frame_active <= 1'b0;
                end
            end
        end
    end
    
    // Read port
    always_ff @(posedge clk) begin
        hist_read_data <= histogram[hist_read_addr];
    end
    
    // Pass-through AXI Stream
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m_axis_tvalid <= 1'b0;
            m_axis_tdata <= '0;
            m_axis_tlast <= 1'b0;
            m_axis_tuser <= 1'b0;
        end else begin
            m_axis_tvalid <= s_axis_tvalid;
            m_axis_tdata <= s_axis_tdata;
            m_axis_tlast <= s_axis_tlast;
            m_axis_tuser <= s_axis_tuser;
        end
    end
    
    assign s_axis_tready = m_axis_tready;

endmodule : histogram
