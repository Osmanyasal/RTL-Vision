/**
 * AXI-Vision: FPGA Image Processing Library
 * 
 * Module: median_filter
 * Description: Real-time 3x3 median filter for noise reduction
 * 
 * Features:
 * - 3x3 median filter using sorting network
 * - Optimized for FPGA implementation (parallel comparators)
 * - Streaming architecture with deterministic latency
 * - Effective for salt-and-pepper noise removal
 * 
 * Algorithm:
 * - Uses bitonic sorting network for 9 elements
 * - Extracts median (5th element) from sorted array
 * 
 * Latency: ~5 + IMG_WIDTH*2 + 1 clock cycles
 * Target: Xilinx Artix-7
 */

module median_filter #(
    parameter int DATA_WIDTH = 8,
    parameter int IMG_WIDTH  = 1920
) (
    input  logic                    clk,
    input  logic                    rst_n,
    
    // AXI4-Stream Slave Interface (Input)
    input  logic                    s_axis_tvalid,
    output logic                    s_axis_tready,
    input  logic [DATA_WIDTH-1:0]   s_axis_tdata,
    input  logic                    s_axis_tlast,
    input  logic                    s_axis_tuser,  // Start of frame
    
    // AXI4-Stream Master Interface (Output)
    output logic                    m_axis_tvalid,
    input  logic                    m_axis_tready,
    output logic [DATA_WIDTH-1:0]   m_axis_tdata,
    output logic                    m_axis_tlast,
    output logic                    m_axis_tuser,  // Start of frame
    
    // Configuration
    input  logic [15:0]             img_width
);

    // Line buffer signals
    logic                                    window_valid;
    logic [2:0][2:0][DATA_WIDTH-1:0]        window_data;
    
    // Instantiate line buffer
    line_buffer #(
        .DATA_WIDTH(DATA_WIDTH),
        .IMG_WIDTH(IMG_WIDTH),
        .KERNEL_SIZE(3)
    ) u_line_buffer (
        .clk(clk),
        .rst_n(rst_n),
        .pixel_valid(s_axis_tvalid && s_axis_tready),
        .pixel_data(s_axis_tdata),
        .window_valid(window_valid),
        .window_data(window_data),
        .img_width(img_width),
        .frame_start(s_axis_tuser && s_axis_tvalid)
    );
    
    // Comparator function
    function automatic logic [DATA_WIDTH-1:0] min2(
        input logic [DATA_WIDTH-1:0] a,
        input logic [DATA_WIDTH-1:0] b
    );
        return (a < b) ? a : b;
    endfunction
    
    function automatic logic [DATA_WIDTH-1:0] max2(
        input logic [DATA_WIDTH-1:0] a,
        input logic [DATA_WIDTH-1:0] b
    );
        return (a > b) ? a : b;
    endfunction
    
    // Pipeline stage 1: Flatten window and start sorting
    logic [8:0][DATA_WIDTH-1:0] pixels;
    logic [8:0][DATA_WIDTH-1:0] stage1_sorted;
    logic                        stage1_valid;
    logic                        stage1_tlast;
    logic                        stage1_tuser;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_sorted <= '0;
            stage1_valid <= 1'b0;
            stage1_tlast <= 1'b0;
            stage1_tuser <= 1'b0;
        end else begin
            stage1_valid <= window_valid;
            stage1_tlast <= s_axis_tlast;
            stage1_tuser <= s_axis_tuser;
            
            if (window_valid) begin
                // Flatten 3x3 window to 9-element array
                pixels[0] = window_data[0][0];
                pixels[1] = window_data[0][1];
                pixels[2] = window_data[0][2];
                pixels[3] = window_data[1][0];
                pixels[4] = window_data[1][1];
                pixels[5] = window_data[1][2];
                pixels[6] = window_data[2][0];
                pixels[7] = window_data[2][1];
                pixels[8] = window_data[2][2];
                
                // First stage of sorting network - compare-swap pairs
                stage1_sorted[0] = min2(pixels[0], pixels[1]);
                stage1_sorted[1] = max2(pixels[0], pixels[1]);
                stage1_sorted[2] = min2(pixels[2], pixels[3]);
                stage1_sorted[3] = max2(pixels[2], pixels[3]);
                stage1_sorted[4] = min2(pixels[4], pixels[5]);
                stage1_sorted[5] = max2(pixels[4], pixels[5]);
                stage1_sorted[6] = min2(pixels[6], pixels[7]);
                stage1_sorted[7] = max2(pixels[6], pixels[7]);
                stage1_sorted[8] = pixels[8];
            end
        end
    end
    
    // Pipeline stage 2: Continue sorting
    logic [8:0][DATA_WIDTH-1:0] stage2_sorted;
    logic                        stage2_valid;
    logic                        stage2_tlast;
    logic                        stage2_tuser;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_sorted <= '0;
            stage2_valid <= 1'b0;
            stage2_tlast <= 1'b0;
            stage2_tuser <= 1'b0;
        end else begin
            stage2_valid <= stage1_valid;
            stage2_tlast <= stage1_tlast;
            stage2_tuser <= stage1_tuser;
            
            if (stage1_valid) begin
                stage2_sorted[0] = min2(stage1_sorted[0], stage1_sorted[2]);
                stage2_sorted[1] = min2(stage1_sorted[1], stage1_sorted[3]);
                stage2_sorted[2] = max2(stage1_sorted[0], stage1_sorted[2]);
                stage2_sorted[3] = max2(stage1_sorted[1], stage1_sorted[3]);
                stage2_sorted[4] = min2(stage1_sorted[4], stage1_sorted[6]);
                stage2_sorted[5] = min2(stage1_sorted[5], stage1_sorted[7]);
                stage2_sorted[6] = max2(stage1_sorted[4], stage1_sorted[6]);
                stage2_sorted[7] = max2(stage1_sorted[5], stage1_sorted[7]);
                stage2_sorted[8] = stage1_sorted[8];
            end
        end
    end
    
    // Pipeline stage 3: Final sorting and median extraction
    logic [DATA_WIDTH-1:0] median;
    logic [8:0][DATA_WIDTH-1:0] stage3_sorted;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            median <= '0;
            m_axis_tvalid <= 1'b0;
            m_axis_tlast <= 1'b0;
            m_axis_tuser <= 1'b0;
        end else begin
            m_axis_tvalid <= stage2_valid;
            m_axis_tlast <= stage2_tlast;
            m_axis_tuser <= stage2_tuser;
            
            if (stage2_valid) begin
                // Final sorting comparisons
                stage3_sorted[0] = min2(stage2_sorted[0], stage2_sorted[4]);
                stage3_sorted[1] = min2(stage2_sorted[1], stage2_sorted[5]);
                stage3_sorted[2] = min2(stage2_sorted[2], stage2_sorted[6]);
                stage3_sorted[3] = min2(stage2_sorted[3], stage2_sorted[7]);
                stage3_sorted[4] = max2(stage2_sorted[0], stage2_sorted[4]);
                stage3_sorted[5] = max2(stage2_sorted[1], stage2_sorted[5]);
                stage3_sorted[6] = max2(stage2_sorted[2], stage2_sorted[6]);
                stage3_sorted[7] = max2(stage2_sorted[3], stage2_sorted[7]);
                stage3_sorted[8] = stage2_sorted[8];
                
                // Find median (middle element after partial sort)
                // For 9 elements, median is the 5th smallest
                // Use optimized median extraction
                median = max2(min2(max2(stage3_sorted[1], stage3_sorted[4]), 
                                   min2(stage3_sorted[5], stage3_sorted[8])),
                             min2(max2(stage3_sorted[0], stage3_sorted[3]),
                                   stage3_sorted[4]));
            end
        end
    end
    
    assign m_axis_tdata = median;
    assign s_axis_tready = m_axis_tready;  // Simple flow control

endmodule : median_filter
