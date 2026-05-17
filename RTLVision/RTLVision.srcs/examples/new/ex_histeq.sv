`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 17.05.2026
// Design Name:
// Module Name: ex_histeq
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

module ex_histeq #(
    parameter string file_name = "../../../../../togg.bmp",
    parameter string gray_out_file_name = "../../../../../togg_gray.bmp",
    parameter string out_file_name = "../../../../../togg_histeq.bmp",
    parameter int IMG_WIDTH    = 1024
)();

    localparam int ADDR_WIDTH   = 8;
    localparam int DATA_WIDTH   = 32;
    localparam int FRAME_PIXELS = 1024 * 768;

    int file_h;
    int out_file_h;
    int row_padding;
    int width;
    int height;
    int start_address;
    int byte_val;
    int eq_valid_count;

    logic [7:0] bmp_header [0:53];
    logic [7:0] first_gray_value;
    logic [7:0] first_eq_pixel;
    byte bmp_prefix[];
    byte gray_pixels[];
    byte eq_pixels[];

    logic clk = 0;
    logic rst = 0;
    always #5 clk = ~clk;

    logic rgb_valid;
    logic [7:0] in_red;
    logic [7:0] in_green;
    logic [7:0] in_blue;

    logic [7:0] gray_pixel;
    logic gray_valid;

    logic [7:0] hist_passthrough_gray;
    logic hist_valid;
    logic hist_clear_done;
    logic hist_query_enable;
    logic [7:0] hist_query_addr;
    logic [31:0] hist_query_count;
    logic hist_query_valid;

    logic build_enable;
    logic lut_busy;
    logic lut_done;
    logic eq_query_enable;
    logic [7:0] eq_query_addr;
    logic [7:0] eq_pixel;
    logic eq_valid;

    grayscale u_gray (
        .clk(clk),
        .rst(rst),
        .in_ready(rgb_valid),
        .in_red(in_red),
        .in_green(in_green),
        .in_blue(in_blue),
        .out_gray(gray_pixel),
        .out_valid(gray_valid)
    );

    histogram #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) u_histogram (
        .clk(clk),
        .rst(rst),
        .in_ready(gray_valid),
        .in_gray(gray_pixel),
        .out_gray(hist_passthrough_gray),
        .out_valid(hist_valid),
        .out_clear_done(hist_clear_done),
        .in_query_enable(eq_query_enable | hist_query_enable),
        .in_query_pixel_addr(eq_query_enable ? eq_query_addr : hist_query_addr),
        .out_query_count(hist_query_count),
        .out_query_valid(hist_query_valid)
    );

    histeq #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .FRAME_PIXELS(FRAME_PIXELS)
    ) u_histeq (
        .clk(clk),
        .rst(rst),
        .in_ready(gray_valid),
        .in_gray(gray_pixel),
        .out_gray(eq_pixel),
        .out_valid(eq_valid),
        .in_build_enable(build_enable),
        .out_lut_busy(lut_busy),
        .out_lut_done(lut_done),
        .out_hist_query_enable(eq_query_enable),
        .out_hist_query_addr(eq_query_addr),
        .in_hist_query_count(hist_query_count),
        .in_hist_query_valid(hist_query_valid)
    );

    task automatic open_bmp();
        begin
            file_h = $fopen(file_name, "rb");
            if (file_h == 0) begin
                $display("ERROR: couldn't open input file %s", file_name);
                $finish;
            end

            for (int i = 0; i < 54; i++) begin
                bmp_header[i] = $fgetc(file_h);
            end

            start_address = {bmp_header[13], bmp_header[12], bmp_header[11], bmp_header[10]};
            width         = {bmp_header[21], bmp_header[20], bmp_header[19], bmp_header[18]};
            height        = {bmp_header[25], bmp_header[24], bmp_header[23], bmp_header[22]};
            row_padding   = (4 - ((width * 3) % 4)) % 4;

            if (width != IMG_WIDTH) begin
                $display("WARNING: BMP width (%0d) != IMG_WIDTH parameter (%0d).", width, IMG_WIDTH);
            end

            if ((width * height) != FRAME_PIXELS) begin
                $display("WARNING: BMP pixel count (%0d) != FRAME_PIXELS parameter (%0d).", width * height, FRAME_PIXELS);
            end

            bmp_prefix = new[start_address];
            for (int i = 0; i < 54; i++) begin
                bmp_prefix[i] = bmp_header[i];
            end

            for (int i = 54; i < start_address; i++) begin
                byte_val = $fgetc(file_h);
                bmp_prefix[i] = byte_val;
            end
        end
    endtask

    task automatic close_bmp();
        begin
            if (file_h != 0) begin
                $fclose(file_h);
                file_h = 0;
            end
        end
    endtask

    task automatic write_grayscale_bmp();
        begin
            out_file_h = $fopen(gray_out_file_name, "wb");
            if (out_file_h == 0) begin
                $display("ERROR: couldn't open grayscale output file %s", gray_out_file_name);
                $finish;
            end

            for (int i = 0; i < start_address; i++) begin
                $fwrite(out_file_h, "%c", bmp_prefix[i]);
            end

            for (int row = 0; row < height; row++) begin
                for (int col = 0; col < width; col++) begin
                    byte_val = gray_pixels[row * width + col];
                    $fwrite(out_file_h, "%c", byte_val);
                    $fwrite(out_file_h, "%c", byte_val);
                    $fwrite(out_file_h, "%c", byte_val);
                end

                for (int pad = 0; pad < row_padding; pad++) begin
                    $fwrite(out_file_h, "%c", 8'd0);
                end
            end

            $fclose(out_file_h);
            out_file_h = 0;
        end
    endtask

    task automatic write_equalized_bmp();
        begin
            out_file_h = $fopen(out_file_name, "wb");
            if (out_file_h == 0) begin
                $display("ERROR: couldn't open output file %s", out_file_name);
                $finish;
            end

            for (int i = 0; i < start_address; i++) begin
                $fwrite(out_file_h, "%c", bmp_prefix[i]);
            end

            for (int row = 0; row < height; row++) begin
                for (int col = 0; col < width; col++) begin
                    byte_val = eq_pixels[row * width + col];
                    $fwrite(out_file_h, "%c", byte_val);
                    $fwrite(out_file_h, "%c", byte_val);
                    $fwrite(out_file_h, "%c", byte_val);
                end

                for (int pad = 0; pad < row_padding; pad++) begin
                    $fwrite(out_file_h, "%c", 8'd0);
                end
            end

            $fclose(out_file_h);
            out_file_h = 0;
        end
    endtask

    task automatic stream_frame(
        input bit capture_first_gray,
        input bit capture_gray_output,
        input bit capture_eq_output
    );
        logic [7:0] blue_val;
        logic [7:0] green_val;
        logic [7:0] red_val;
        logic [7:0] gray_calc;
        begin
            for (int row = 0; row < height; row++) begin
                for (int col = 0; col < width; col++) begin
                    blue_val  = $fgetc(file_h);
                    green_val = $fgetc(file_h);
                    red_val   = $fgetc(file_h);

                    in_blue   = blue_val;
                    in_green  = green_val;
                    in_red    = red_val;

                    gray_calc = (red_val >> 2) + (red_val >> 5) +
                                (green_val >> 1) + (green_val >> 4) +
                                (blue_val >> 4) + (blue_val >> 5);

                    if (capture_first_gray && (row == 0) && (col == 0)) begin
                        first_gray_value = gray_calc;
                    end

                    if (capture_gray_output) begin
                        gray_pixels[row * width + col] = gray_calc;
                    end

                    rgb_valid = 1'b1;
                    @(posedge clk);

                    if (capture_eq_output && eq_valid) begin
                        if (eq_valid_count < (width * height)) begin
                            eq_pixels[eq_valid_count] = eq_pixel;
                        end
                        eq_valid_count = eq_valid_count + 1;
                        if (eq_valid_count == 1) begin
                            first_eq_pixel = eq_pixel;
                        end
                    end
                end

                for (int pad = 0; pad < row_padding; pad++) begin
                    byte_val = $fgetc(file_h);
                end
            end

            rgb_valid = 1'b0;
            repeat (8) begin
                @(posedge clk);
                if (capture_eq_output && eq_valid) begin
                    if (eq_valid_count < (width * height)) begin
                        eq_pixels[eq_valid_count] = eq_pixel;
                    end
                    eq_valid_count = eq_valid_count + 1;
                    if (eq_valid_count == 1) begin
                        first_eq_pixel = eq_pixel;
                    end
                end
            end
        end
    endtask

    initial begin
        rst = 1'b1;
        rgb_valid = 1'b0;
        in_red = '0;
        in_green = '0;
        in_blue = '0;
        build_enable = 1'b0;
        hist_query_enable = 1'b0;
        hist_query_addr = '0;
        eq_valid_count = 0;
        first_gray_value = '0;
        first_eq_pixel = '0;
        file_h = 0;

        @(posedge clk);
        #1 rst = 1'b0;

        wait (hist_clear_done == 1'b1);
        @(posedge clk);

        open_bmp();
        $display("Pass 1: building histogram for %0d x %0d image.", width, height);
        gray_pixels = new[width * height];
        eq_pixels = new[width * height];
        stream_frame(1'b1, 1'b1, 1'b0);
        close_bmp();

        write_grayscale_bmp();

        hist_query_addr = first_gray_value;
        hist_query_enable = 1'b1;
        @(posedge clk);
        hist_query_enable = 1'b0;
        @(posedge clk);

        if (!hist_query_valid) begin
            $display("ERROR: histogram query handshake failed.");
            $finish;
        end

        if (hist_query_count == 0) begin
            $display("ERROR: histogram bin %0d is zero after first pass.", first_gray_value);
            $finish;
        end

        $display("Histogram[%0d] = %0d", first_gray_value, hist_query_count);

        build_enable = 1'b1;
        @(posedge clk);
        build_enable = 1'b0;

        wait (lut_done == 1'b1);
        @(posedge clk);

        open_bmp();
        eq_valid_count = 0;
        $display("Pass 2: applying histogram equalization.");
        stream_frame(1'b0, 1'b0, 1'b1);
        close_bmp();

        if (eq_valid_count == 0) begin
            $display("ERROR: equalizer produced no valid pixels.");
            $finish;
        end

        if (eq_valid_count != (width * height)) begin
            $display("ERROR: equalizer produced %0d valid pixels, expected %0d.", eq_valid_count, width * height);
            $finish;
        end

        write_equalized_bmp();

        $display("First grayscale pixel = %0d", first_gray_value);
        $display("First equalized pixel = %0d", first_eq_pixel);
        $display("Equalized valid pixel count = %0d", eq_valid_count);
        $display("Grayscale BMP written to %s", gray_out_file_name);
        $display("Equalized grayscale BMP written to %s", out_file_name);
        $display("Histogram equalization example completed.");
        $finish;
    end

endmodule