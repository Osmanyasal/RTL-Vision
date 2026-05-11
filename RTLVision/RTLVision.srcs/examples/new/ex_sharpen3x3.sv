`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/02/2026 12:59:39 PM
// Design Name: 
// Module Name: ex_sharpen3x3
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: File-driven sharpen pipeline example.
//              Streams a 24-bit BMP through RGB->YCbCr->sharpen->RGB and writes
//              the processed image back to disk.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ex_sharpen3x3 #(
    parameter string file_name     = "/home/rt7/Desktop/RTLVision/kaan.bmp",
    parameter string out_file_name = "/home/rt7/Desktop/RTLVision/kaan_sharpen.bmp",
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
    logic [7:0] in_red, in_green, in_blue;

    logic [23:0] ycbcr_pix;
    logic        ycbcr_valid;

    logic [23:0] sharpen_ycbcr_pix;
    logic        sharpen_valid;

    logic [7:0] out_red, out_green, out_blue;
    logic       out_rgb_valid;

    rgb_to_ycbcr u_rgb_to_ycbcr (
        .clk(clk),
        .rst(rst),
        .in_ready(rgb_valid),
        .in_red(in_red),
        .in_green(in_green),
        .in_blue(in_blue),
        .out_ycbcr(ycbcr_pix),
        .out_ready(ycbcr_valid)
    );

    sharpen3x3_ycbcr #(
        .IMG_WIDTH(IMG_WIDTH)
    ) u_sharpen (
        .clk(clk),
        .rst(rst),
        .in_ready(ycbcr_valid),
        .in_ycbcr(ycbcr_pix),
        .out_ycbcr(sharpen_ycbcr_pix),
        .out_ready(sharpen_valid)
    );

    ycbcr_to_rgb u_ycbcr_to_rgb (
        .clk(clk),
        .rst(rst),
        .in_ready(sharpen_valid),
        .in_ycbcr(sharpen_ycbcr_pix),
        .out_red(out_red),
        .out_green(out_green),
        .out_blue(out_blue),
        .out_ready(out_rgb_valid)
    );

    initial begin
        rst       = 1;
        rgb_valid = 0;
        in_red    = 0;
        in_green  = 0;
        in_blue   = 0;
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
            $display("WARNING: BMP width (%0d) != IMG_WIDTH parameter (%0d). Sharpen line buffer will misalign.",
                     width, IMG_WIDTH);
        end

        status = $fseek(file_h, 0, 0);
        for (int i = 0; i < start_address; i++) begin
            byte_val = $fgetc(file_h);
            $fwrite(file_out, "%c", byte_val);
        end

        $display("Starting sharpen streaming...");

        fork
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

            begin
                int produced;
                int valid_target;

                // The sharpen window needs two lines of history before outputs are valid.
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
                    if (out_rgb_valid) begin
                        $fwrite(file_out, "%c", out_blue);
                        $fwrite(file_out, "%c", out_green);
                        $fwrite(file_out, "%c", out_red);
                        produced++;
                    end
                end
            end
        join_any

        repeat (8) @(posedge clk);

        $display("Sharpen image processed and saved.");
        $fclose(file_h);
        $fclose(file_out);
        $finish;
    end

endmodule
