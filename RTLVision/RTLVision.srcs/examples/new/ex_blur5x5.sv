`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Osman Yasal
// 
// Create Date: 05/09/2026
// Design Name: 
// Module Name: ex_blur5x5
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: File-driven 5x5 blur pipeline example.
//              Streams a 24-bit BMP through RGB->YCbCr->blur5x5->RGB and writes
//              the processed image back to disk.
// 
// Dependencies: rgb_to_ycbcr, blur5x5_ycbcr, ycbcr_to_rgb
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ex_blur5x5 #(
    parameter string file_name     = "/home/rt7/Desktop/RTLVision/kaan.bmp",
    parameter string out_file_name = "/home/rt7/Desktop/RTLVision/kaan_blur5x5.bmp",
    parameter int    IMG_WIDTH     = 1024
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
    always #5 clk = ~clk;

    // -----------------------------------------
    // 2. DUT Signals
    // -----------------------------------------
    logic       rgb_valid;
    logic [7:0] red_in, green_in, blue_in;

    logic [23:0] ycbcr_pix;
    logic        ycbcr_valid;

    logic [23:0] blur_ycbcr_pix;
    logic        blur_valid;

    logic [7:0] red_out, green_out, blue_out;
    logic       rgb_out_valid;

    rgb_to_ycbcr u_rgb_to_ycbcr (
        .clk(clk),
        .rst(rst),
        .ready_in(rgb_valid),
        .red_in(red_in),
        .green_in(green_in),
        .blue_in(blue_in),
        .ycbcr_out(ycbcr_pix),
        .ready_out(ycbcr_valid)
    );

    blur5x5_ycbcr #(
        .IMG_WIDTH(IMG_WIDTH)
    ) u_blur (
        .clk(clk),
        .rst(rst),
        .ready_in(ycbcr_valid),
        .ycbcr_in(ycbcr_pix),
        .ycbcr_out(blur_ycbcr_pix),
        .ready_out(blur_valid)
    );

    ycbcr_to_rgb u_ycbcr_to_rgb (
        .clk(clk),
        .rst(rst),
        .ready_in(blur_valid),
        .ycbcr_in(blur_ycbcr_pix),
        .red_out(red_out),
        .green_out(green_out),
        .blue_out(blue_out),
        .ready_out(rgb_out_valid)
    );

    initial begin
        rst       = 1;
        rgb_valid = 0;
        red_in    = 0;
        green_in  = 0;
        blue_in   = 0;
        @(posedge clk);
        #1 rst = 0;
        @(posedge clk);
        #1;

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

        for (int i = 0; i < 54; i++) bmp_header[i] = $fgetc(file_h);

        start_address = {bmp_header[13], bmp_header[12], bmp_header[11], bmp_header[10]};
        width         = {bmp_header[21], bmp_header[20], bmp_header[19], bmp_header[18]};
        height        = {bmp_header[25], bmp_header[24], bmp_header[23], bmp_header[22]};

        $display("Image Info: %0d x %0d, Data starts at: %0d", width, height, start_address);
        if (width != IMG_WIDTH) begin
            $display("WARNING: BMP width (%0d) != IMG_WIDTH parameter (%0d). 5x5 blur line buffer will misalign.",
                     width, IMG_WIDTH);
        end

        status = $fseek(file_h, 0, 0);
        for (int i = 0; i < start_address; i++) begin
            byte_val = $fgetc(file_h);
            $fwrite(file_out, "%c", byte_val);
        end

        $display("Starting 5x5 blur streaming...");

        fork
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

            begin
                int produced;
                int valid_target;

                // The 5x5 window needs four lines of history before outputs are valid.
                for (int k = 0; k < 4 * width; k++) begin
                    $fwrite(file_out, "%c", 8'd0);
                    $fwrite(file_out, "%c", 8'd0);
                    $fwrite(file_out, "%c", 8'd0);
                end

                produced     = 0;
                valid_target = width * height - 4 * width;
                while (produced < valid_target) begin
                    @(posedge clk);
                    #1;
                    if (rgb_out_valid) begin
                        $fwrite(file_out, "%c", blue_out);
                        $fwrite(file_out, "%c", green_out);
                        $fwrite(file_out, "%c", red_out);
                        produced++;
                    end
                end
            end
        join_any

        repeat (8) @(posedge clk);

        $display("5x5 Blur image processed and saved.");
        $fclose(file_h);
        $fclose(file_out);
        $finish;
    end

endmodule
