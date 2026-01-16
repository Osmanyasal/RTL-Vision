/**
 * AXI-Vision: FPGA Image Processing Library
 * 
 * Testbench: line_buffer_tb
 * Description: Basic testbench for line_buffer module
 * 
 * Test scenarios:
 * - 3x3 kernel with small image (8x8)
 * - Verify window output timing
 * - Check border handling
 */

`timescale 1ns / 1ps

module line_buffer_tb;

    // Parameters
    localparam int DATA_WIDTH = 8;
    localparam int IMG_WIDTH = 8;
    localparam int KERNEL_SIZE = 3;
    localparam int CLK_PERIOD = 10;  // 100 MHz
    
    // Signals
    logic                    clk;
    logic                    rst_n;
    logic                    pixel_valid;
    logic [DATA_WIDTH-1:0]   pixel_data;
    logic                    window_valid;
    logic [KERNEL_SIZE-1:0][KERNEL_SIZE-1:0][DATA_WIDTH-1:0] window_data;
    logic [15:0]             img_width;
    logic                    frame_start;
    
    // DUT instantiation
    line_buffer #(
        .DATA_WIDTH(DATA_WIDTH),
        .IMG_WIDTH(IMG_WIDTH),
        .KERNEL_SIZE(KERNEL_SIZE)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .pixel_valid(pixel_valid),
        .pixel_data(pixel_data),
        .window_valid(window_valid),
        .window_data(window_data),
        .img_width(img_width),
        .frame_start(frame_start)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Test stimulus
    initial begin
        // Initialize
        rst_n = 0;
        pixel_valid = 0;
        pixel_data = 0;
        img_width = IMG_WIDTH;
        frame_start = 0;
        
        // Reset
        #(CLK_PERIOD * 5);
        rst_n = 1;
        #(CLK_PERIOD * 2);
        
        // Start frame
        frame_start = 1;
        #CLK_PERIOD;
        frame_start = 0;
        
        // Send 8x8 test image
        pixel_valid = 1;
        for (int i = 0; i < IMG_WIDTH * IMG_WIDTH; i++) begin
            pixel_data = i[7:0];  // Sequential pixel values
            #CLK_PERIOD;
        end
        
        pixel_valid = 0;
        #(CLK_PERIOD * 10);
        
        $display("Test completed");
        $finish;
    end
    
    // Monitor window output
    always @(posedge clk) begin
        if (window_valid) begin
            $display("Time=%0t Window valid:", $time);
            $display("  [%3d %3d %3d]", window_data[0][0], window_data[0][1], window_data[0][2]);
            $display("  [%3d %3d %3d]", window_data[1][0], window_data[1][1], window_data[1][2]);
            $display("  [%3d %3d %3d]", window_data[2][0], window_data[2][1], window_data[2][2]);
        end
    end

endmodule : line_buffer_tb
