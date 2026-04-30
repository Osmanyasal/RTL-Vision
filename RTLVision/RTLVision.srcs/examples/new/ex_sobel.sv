`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/30/2026 03:09:05 PM
// Design Name: 
// Module Name: ex_sobel
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


module ex_sobel #(
    parameter string file_name     = "/home/rt7/Desktop/RTLVision/kaan.bmp",
    parameter string out_file_name = "/home/rt7/Desktop/RTLVision/kaan_sobel.bmp",
    parameter int    IMG_WIDTH     = 1024  // must match BMP width
)();

    // -----------------------------------------
    // 0. File settings & Variables
    // -----------------------------------------
    int file_h;
    int file_out;
    int status;

    logic [7:0] bmp_header[0:53];
    int width, height, start_address;
    int byte_val;

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
    logic [7:0] red_in, green_in, blue_in;

    // grayscale -> sobel interconnect
    logic [7:0] gray_pix;
    logic       gray_valid;

    // sobel outputs
    logic [7:0] sobel_pix;
    logic       ready_out;

    grayscale u_gray (
        .clk(clk),
        .rst(rst),
        .ready_in(rgb_valid),
        .red_in(red_in),
        .green_in(green_in),
        .blue_in(blue_in),
        .gray_out(gray_pix),
        .ready_out(gray_valid)
    );

    sobel #(
        .IMG_WIDTH(IMG_WIDTH)
    ) uut (
        .clk(clk),
        .rst(rst),
        .ready_in(gray_valid),
        .gray_in(gray_pix),
        .sobel_out(sobel_pix),
        .ready_out(ready_out)
    );

    initial begin
        // init
        rst       = 1;
        rgb_valid = 0;
        red_in    = 0;
        green_in  = 0;
        blue_in   = 0;
        @(posedge clk);
        #1 rst = 0;
        @(posedge clk);
        #1;

        // --- A. Open files ---
        file_h = $fopen(file_name, "rb");
        if (file_h == 0) begin
            $display("Error: couldn't open input file %s", file_name);
            $finish;
        end

        file_out = $fopen(out_file_name, "wb");
        if (file_out == 0) begin
            $display("Error: couldn't open output file %s", out_file_name);
            $finish;
        end

        // --- B. Read header ---
        for (int i = 0; i < 54; i++) bmp_header[i] = $fgetc(file_h);

        start_address = {bmp_header[13], bmp_header[12], bmp_header[11], bmp_header[10]};
        width         = {bmp_header[21], bmp_header[20], bmp_header[19], bmp_header[18]};
        height        = {bmp_header[25], bmp_header[24], bmp_header[23], bmp_header[22]};

        $display("Image Info: %0d x %0d, Data starts at: %0d", width, height, start_address);
        if (width != IMG_WIDTH) begin
            $display("WARNING: BMP width (%0d) != IMG_WIDTH parameter (%0d). Sobel line buffer will misalign.",
                     width, IMG_WIDTH);
        end

        // --- C. Copy header verbatim ---
        status = $fseek(file_h, 0, 0);
        for (int i = 0; i < start_address; i++) begin
            byte_val = $fgetc(file_h);
            $fwrite(file_out, "%c", byte_val);
        end

        $display("Starting Sobel streaming...");

        // --- D. Streaming: producer / consumer ---
        fork
            // Producer: read BMP RGB and feed grayscale module (which feeds sobel)
            begin
                for (int i = 0; i < height; i++) begin
                    for (int j = 0; j < width; j++) begin
                        blue_in   = $fgetc(file_h);
                        green_in  = $fgetc(file_h);
                        red_in    = $fgetc(file_h);
                        rgb_valid = 1;
                        @(posedge clk);
                    end
                end
                rgb_valid = 0;
            end

            // Consumer: capture sobel_out, write BMP
            begin
                int produced;
                int valid_target;

                // Pre-pad the top-of-image border pixels that have no valid 3x3 window
                // (line buffer needs ~2 full lines to warm up). Keeps BMP size correct.
                for (int k = 0; k < 2 * width; k++) begin
                    $fwrite(file_out, "%c", 8'd0);
                    $fwrite(file_out, "%c", 8'd0);
                    $fwrite(file_out, "%c", 8'd0);
                end

                produced     = 0;
                valid_target = width * height - 2 * width;
                while (produced < valid_target) begin
                    @(posedge clk);
                    #1;
                    if (ready_out) begin
                        $fwrite(file_out, "%c", sobel_pix); // B
                        $fwrite(file_out, "%c", sobel_pix); // G
                        $fwrite(file_out, "%c", sobel_pix); // R
                        produced++;
                    end
                end
            end
        join_any

        // Drain any remaining cycles so consumer thread can finish if producer joined first
        repeat (8) @(posedge clk);

        $display("Sobel image processed and saved.");
        $fclose(file_h);
        $fclose(file_out);
        $finish;
    end

endmodule
