/**
 * AXI-Vision: FPGA Image Processing Library
 * 
 * Module: line_buffer
 * Description: Configurable line buffer for 2D image processing operations
 * 
 * Features:
 * - Parameterizable kernel size (3x3, 5x5, 7x7, etc.)
 * - Efficient BRAM utilization
 * - Streaming architecture with single-cycle latency
 * - Supports arbitrary image widths
 * 
 * Use Cases:
 * - Convolution filters (Sobel, Gaussian, etc.)
 * - Morphological operations
 * - Any 2D kernel-based processing
 * 
 * Target: Xilinx Artix-7 (optimized for BRAM)
 */

module line_buffer #(
    parameter int DATA_WIDTH    = 8,      // Bit width of pixel data
    parameter int IMG_WIDTH     = 1920,   // Maximum image width
    parameter int KERNEL_SIZE   = 3,      // Kernel size (3 = 3x3, 5 = 5x5, etc.)
    parameter int NUM_LINES     = KERNEL_SIZE  // Number of line buffers needed
) (
    input  logic                    clk,
    input  logic                    rst_n,
    
    // Input pixel stream
    input  logic                    pixel_valid,
    input  logic [DATA_WIDTH-1:0]   pixel_data,
    
    // Output kernel window
    output logic                    window_valid,
    output logic [KERNEL_SIZE-1:0][KERNEL_SIZE-1:0][DATA_WIDTH-1:0] window_data,
    
    // Control signals
    input  logic [15:0]             img_width,  // Actual image width
    input  logic                    frame_start
);

    // Line buffer memories (implemented as shift registers or BRAM)
    logic [NUM_LINES-1:0][IMG_WIDTH-1:0][DATA_WIDTH-1:0] line_buffers;
    
    // Column buffer for current processing window
    logic [KERNEL_SIZE-1:0][KERNEL_SIZE-1:0][DATA_WIDTH-1:0] col_buffer;
    
    // Position counters
    logic [15:0] col_count;
    logic [15:0] row_count;
    
    // Valid signal generation
    logic window_valid_int;
    
    // Calculate when window is valid (after kernel_size/2 rows and columns)
    localparam int BORDER = KERNEL_SIZE / 2;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            col_count <= '0;
            row_count <= '0;
            line_buffers <= '0;
            col_buffer <= '0;
            window_valid_int <= 1'b0;
        end else begin
            if (frame_start) begin
                col_count <= '0;
                row_count <= '0;
                window_valid_int <= 1'b0;
            end else if (pixel_valid) begin
                // Shift line buffers
                for (int i = NUM_LINES-1; i > 0; i--) begin
                    line_buffers[i][col_count] <= line_buffers[i-1][col_count];
                end
                line_buffers[0][col_count] <= pixel_data;
                
                // Shift column buffer horizontally
                for (int row = 0; row < KERNEL_SIZE; row++) begin
                    for (int col = KERNEL_SIZE-1; col > 0; col--) begin
                        col_buffer[row][col] <= col_buffer[row][col-1];
                    end
                    // Load new column from line buffers
                    if (row < NUM_LINES) begin
                        col_buffer[row][0] <= line_buffers[row][col_count];
                    end
                end
                
                // Update position counters
                if (col_count == img_width - 1) begin
                    col_count <= '0;
                    row_count <= row_count + 1'b1;
                end else begin
                    col_count <= col_count + 1'b1;
                end
                
                // Window is valid after filling initial border
                if (row_count >= BORDER && col_count >= BORDER) begin
                    window_valid_int <= 1'b1;
                end else begin
                    window_valid_int <= 1'b0;
                end
            end
        end
    end
    
    // Output assignments
    assign window_valid = window_valid_int;
    assign window_data = col_buffer;

endmodule : line_buffer
