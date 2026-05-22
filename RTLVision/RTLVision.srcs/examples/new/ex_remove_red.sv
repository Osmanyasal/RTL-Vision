`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.05.2026 19:24:01
// Design Name: 
// Module Name: ex_hsv_inrange
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


module ex_remove_red #(
    parameter string file_name     = "../../../../../butterfly.bmp",
    parameter string out_file_name = "../../../../../butterfly_remove_red.bmp",
    parameter int    IMG_WIDTH     = 1280  // must match BMP width
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
    logic [7:0] in_red, in_green, in_blue;

    // grayscale -> laplacian interconnect
    logic [7:0] out_hsv_inrange_pix, out_pix_red, out_pix_green, out_pix_blue;
    logic       out_hsv_inrange_valid, out_valid_red, out_valid_green, out_valid_blue;
    
hsv_inrange hsv_inrange_inst (
        .clk(clk),
        .rst(rst),
        .in_ready(rgb_valid),
        .in_blue(in_blue),
        .in_green(in_green),
        .in_red(in_red),
        
        // Literal values from color pickers!
        .h_low(9'd330),   .h_high(9'd355),  // Pure Red Window
        .s_low(7'd10),    .s_high(7'd100),  
        .v_low(7'd10),    .v_high(7'd100),  
        
        .out_pixel(out_hsv_inrange_pix),
        .out_valid(out_hsv_inrange_valid)
    );

mac mmac_blue(
        .clk(clk),
        .rst(rst),
        .in_ready(out_hsv_inrange_valid),
        .a1(out_hsv_inrange_pix == 255 ? 1 : 0), // Use the inrange output as the "redness" measure
        .a2(in_blue),              // Max intensity to keep red pixels bright
        .b1(8'd0),                // No offset
        .out_value(out_pix_blue), // Reuse same signal to save lines, just modified by mac
        .out_valid(out_valid_blue) // out_valid is the same for both modules since mac is combinational
    );

mac mmac_green(
        .clk(clk),
        .rst(rst),
        .in_ready(out_hsv_inrange_valid),
        .a1(out_hsv_inrange_pix == 255 ? 1 : 0), // Use the inrange output as the "redness" measure
        .a2(in_green),              // Max intensity to keep red pixels bright
        .b1(8'd0),                // No offset
        .out_value(out_pix_green), // Reuse same signal to save lines, just modified by mac
        .out_valid(out_valid_green) // out_valid is the same for both modules since mac is combinational
    );

mac mmac_red(
        .clk(clk),
        .rst(rst),
        .in_ready(out_hsv_inrange_valid),
        .a1(out_hsv_inrange_pix == 255 ? 1 : 0), // Use the inrange output as the "redness" measure
        .a2(in_red),              // Max intensity to keep red pixels bright
        .b1(8'd0),                // No offset
        .out_value(out_pix_red), // Reuse same signal to save lines, just modified by mac
        .out_valid(out_valid_red) // out_valid is the same for both modules since mac is combinational
    );


    initial begin
        // init
        rst       = 1;
        rgb_valid = 0;
        in_red    = 0;
        in_green  = 0;
        in_blue   = 0;
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
            $display("WARNING: BMP width (%0d) != IMG_WIDTH parameter (%0d). laplacian line buffer will misalign.",
                     width, IMG_WIDTH);
        end

        // --- C. Copy header verbatim ---
        status = $fseek(file_h, 0, 0);
        for (int i = 0; i < start_address; i++) begin
            byte_val = $fgetc(file_h);
            $fwrite(file_out, "%c", byte_val);
        end

        $display("Starting HSV inrange streaming...");

        // --- D. Streaming: producer / consumer ---
        fork
            // Producer: read BMP RGB and feed HSV inrange module
            begin
                for (int i = 0; i < height; i++) begin
                    for (int j = 0; j < width; j++) begin
                        in_blue   = $fgetc(file_h);
                        in_green  = $fgetc(file_h);
                        in_red    = $fgetc(file_h);
                        rgb_valid = 1;
                        @(posedge clk);
                    end
                end
                rgb_valid = 0;
            end

            // Consumer: capture out_laplacian, write BMP
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

                for (int i = 0; i < height; i++) begin
                    for (int j = 0; j < width; j++) begin
                    @(posedge clk);
                    #1;
                    if (out_valid_red && out_valid_green && out_valid_blue) begin
                        $fwrite(file_out, "%c", out_pix_blue); // B
                        $fwrite(file_out, "%c", out_pix_green); // G
                        $fwrite(file_out, "%c", out_pix_red); // R
                        produced++;
                    end
                end
                end
            end
        join_any

        // Drain any remaining cycles so consumer thread can finish if producer joined first
        repeat (8) @(posedge clk);

        $display("laplacian image processed and saved.");
        $fclose(file_h);
        $fclose(file_out);
        $finish;
    end

endmodule

