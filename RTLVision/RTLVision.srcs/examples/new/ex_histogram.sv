`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.05.2026 13:05:44
// Design Name: 
// Module Name: ex_histogram
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module ex_histogram #(
    parameter string file_name     = "../../../../../butterfly.bmp",
    parameter int    IMG_WIDTH     = 4096  // must match BMP width
)();

    // -----------------------------------------
    // 0. File settings & Variables
    // -----------------------------------------
    int file_h;
    int status;

    logic [7:0] bmp_header[0:53];
    int width, height, start_address;
    int byte_val;
    logic [7:0] first_gray_value;

    // -----------------------------------------
    // 1. Clock and Reset
    // -----------------------------------------
    logic clk = 0;
    logic rst = 0;
    always #5 clk = ~clk; // 100 MHz

    // -----------------------------------------
    // 2. DUT Signals
    // -----------------------------------------
    // Producer drives RGB into the grayscale module.
    logic       rgb_valid;
    logic [7:0] in_red, in_green, in_blue;

    // grayscale -> sobel interconnect
    logic [7:0] out_gray_pix;
    logic       out_gray_valid;


    grayscale u_gray (
        .clk(clk),
        .rst(rst),
        .in_ready(rgb_valid),
        .in_red(in_red),
        .in_green(in_green),
        .in_blue(in_blue),
        .out_gray(out_gray_pix),
        .out_valid(out_gray_valid)
    );

    // histogram outputs
    logic [7:0] out_histogram_pix;
    logic       out_valid;
    logic out_clear_done;
    logic in_query_enable;
    logic [7:0] in_query_pixel_addr;
    logic [31:0] out_query_count;
    logic out_query_valid;

    histogram #(
        .ADDR_WIDTH(8),
        .DATA_WIDTH(32)
    ) uut (
        .clk(clk),
        .rst(rst),
        .in_ready(out_gray_valid),
        .in_gray(out_gray_pix),
        .out_gray(out_histogram_pix),
        .out_valid(out_valid),

        .out_clear_done(out_clear_done),
        .in_query_enable(in_query_enable),
        .in_query_pixel_addr(in_query_pixel_addr),
        .out_query_count(out_query_count),
        .out_query_valid(out_query_valid)
    );

    initial begin
        // init
        rst       = 1;
        rgb_valid = 0;
        in_red    = 0;
        in_green  = 0;
        in_blue   = 0;
        in_query_enable = 0;
        in_query_pixel_addr = 0;
        @(posedge clk);
        #1 rst = 0;
        wait (out_clear_done == 1'b1);
        @(posedge clk);
        #1;

        // --- A. Open files ---
        file_h = $fopen(file_name, "rb");
        if (file_h == 0) begin
            $display("Error: couldn't open input file %s", file_name);
            $finish;
        end

        // --- B. Read header ---
        for (int i = 0; i < 54; i++) bmp_header[i] = $fgetc(file_h);

        start_address = {bmp_header[13], bmp_header[12], bmp_header[11], bmp_header[10]};
        width         = {bmp_header[21], bmp_header[20], bmp_header[19], bmp_header[18]};
        height        = {bmp_header[25], bmp_header[24], bmp_header[23], bmp_header[22]};

        $display("Image Info: %0d x %0d, Data starts at: %0d", width, height, start_address);
        if (width != IMG_WIDTH) begin
            $display("WARNING: BMP width (%0d) != IMG_WIDTH parameter (%0d). Histogram example may read the image incorrectly.",
                     width, IMG_WIDTH);
        end

        for (int i = 54; i < start_address; i++) begin
            byte_val = $fgetc(file_h);
        end

        $display("Starting histogram streaming...");

        for (int i = 0; i < height; i++) begin
            for (int j = 0; j < width; j++) begin
                in_blue   = $fgetc(file_h);
                in_green  = $fgetc(file_h);
                in_red    = $fgetc(file_h);
                if ((i == 0) && (j == 0)) begin
                    first_gray_value = (in_red >> 2) + (in_red >> 5) +
                                       (in_green >> 1) + (in_green >> 4) +
                                       (in_blue >> 4) + (in_blue >> 5);
                end
                rgb_valid = 1;
                @(posedge clk);
            end
        end
        rgb_valid = 0;
        repeat (8) @(posedge clk);

        in_query_pixel_addr = first_gray_value;
        in_query_enable = 1'b1;
        #1;
        @(posedge clk);
        
        if (!out_query_valid) begin
            $display("ERROR: histogram query did not produce a valid response.");
            $finish;
        end
        
        if (out_query_count == 0) begin
            $display("ERROR: histogram bin %0d was not incremented.", first_gray_value);
            $finish;
        end
        $display("Histogram[%0d] = %0d", first_gray_value, out_query_count);

        in_query_enable = 1'b0;
        #1;
        @(posedge clk);


        $display("Histogram image processed and saved.");
        $fclose(file_h);
        $finish;
    end

endmodule
