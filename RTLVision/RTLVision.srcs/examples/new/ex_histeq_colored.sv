`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: ex_histeq_colored
// Description: Testbench for True YCbCr-based Histogram Equalization
//              Using custom rgb_to_ycbcr and ycbcr_to_rgb modules
//////////////////////////////////////////////////////////////////////////////////

module ex_histeq_colored #(
    parameter string file_name = "../../../../../butterfly.bmp",
    parameter string gray_out_file_name = "../../../../../butterfly_gray_y.bmp",
    parameter string out_file_name = "../../../../../butterfly_histeq_ycbcr.bmp",
    parameter int IMG_WIDTH    = 4096
)();

    localparam int ADDR_WIDTH   = 8;
    localparam int DATA_WIDTH   = 32;
    localparam int FRAME_PIXELS = 4096 * 2160;

    int file_h;
    int out_file_h;
    int row_padding;
    int width;
    int height;
    int start_address;
    int byte_val;

    // Capture trackers
    int gray_valid_count;
    int eq_valid_count;

    logic [7:0] bmp_header [0:53];
    logic [7:0] first_y_value;
    logic [7:0] first_eq_pixel;
    
    byte bmp_prefix[];
    byte gray_pixels[];
    byte eq_pixels_b[];
    byte eq_pixels_g[];
    byte eq_pixels_r[];

    logic clk = 0;
    logic rst = 0;
    always #5 clk = ~clk;
 
    // =========================================================================
    // Pipeline Signals
    // =========================================================================
    
    // 1. RGB Stimulus
    logic rgb_valid;
    logic [7:0] in_blue, in_green, in_red;
    
    // 2. RGB to YCbCr Output
    logic ycbcr_valid;
    logic [23:0] ycbcr_wire;
    logic [7:0] y_wire, cb_wire, cr_wire;
    
    assign y_wire  = ycbcr_wire[23:16];
    assign cb_wire = ycbcr_wire[15:8];
    assign cr_wire = ycbcr_wire[7:0];

    // 3. Histogram / LUT Signals
    logic hist_y_valid, hist_clear_done_y;
    logic [7:0] hist_passthrough_y;
    logic hist_query_enable;
    logic [7:0] hist_query_addr;
    logic [31:0] hist_query_count_y;
    logic hist_query_valid_y;

    logic build_enable;
    logic lut_busy_y, lut_done_y;
    logic eq_query_enable_y;
    logic [7:0] eq_query_addr_y;
    
    // 4. Equalizer Output
    logic [7:0] eq_y_pixel;
    logic eq_y_valid;
    
    // 5. Delay Line for Cb and Cr (To match histeq's 2-cycle read latency)
    logic [7:0] cb_d1, cb_d2;
    logic [7:0] cr_d1, cr_d2;
    
    always_ff @(posedge clk) begin
        if (rst) begin
            cb_d1 <= 8'd0; cb_d2 <= 8'd0;
            cr_d1 <= 8'd0; cr_d2 <= 8'd0;
        end else begin
            cb_d1 <= cb_wire; cb_d2 <= cb_d1;
            cr_d1 <= cr_wire; cr_d2 <= cr_d1;
        end
    end

    // 6. YCbCr to RGB Output
    logic rgb_out_valid;
    logic [7:0] rgb_out_red, rgb_out_green, rgb_out_blue;

    // Control flags for the testbench
    logic capture_gray_output = 0;
    logic capture_eq_output = 0;

    // =========================================================================
    // Module Instantiations
    // =========================================================================

    rgb_to_ycbcr u_rgb2ycbcr (
        .clk(clk),
        .rst(rst),
        .in_ready(rgb_valid),
        .in_red(in_red),
        .in_green(in_green),
        .in_blue(in_blue),
        .out_ycbcr(ycbcr_wire),
        .out_valid(ycbcr_valid)
    );

    // ONLY ONE Histogram and Equalizer (for the Y channel)
    histogram #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) u_histogram_y (
        .clk(clk),
        .rst(rst),
        .in_ready(ycbcr_valid),
        .in_gray(y_wire),
        .out_gray(hist_passthrough_y),
        .out_valid(hist_y_valid),
        .out_clear_done(hist_clear_done_y),
        .in_query_enable(eq_query_enable_y | hist_query_enable),
        .in_query_pixel_addr(eq_query_enable_y ? eq_query_addr_y : hist_query_addr),
        .out_query_count(hist_query_count_y),
        .out_query_valid(hist_query_valid_y)
    );
    
    histeq #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .FRAME_PIXELS(FRAME_PIXELS)
    ) u_histeq_y (
        .clk(clk),
        .rst(rst),
        .in_ready(ycbcr_valid),
        .in_gray(y_wire),
        .out_gray(eq_y_pixel),
        .out_valid(eq_y_valid),
        .in_build_enable(build_enable),
        .out_lut_busy(lut_busy_y),
        .out_lut_done(lut_done_y),
        .out_hist_query_enable(eq_query_enable_y),
        .out_hist_query_addr(eq_query_addr_y),
        .in_hist_query_count(hist_query_count_y),
        .in_hist_query_valid(hist_query_valid_y)
    );

    // Your custom module instance
    ycbcr_to_rgb u_ycbcr2rgb (
        .clk(clk),
        .rst(rst),
        .in_ready(eq_y_valid),        // Driven by Equalizer's valid signal
        .in_ycbcr({eq_y_pixel, cb_d2, cr_d2}), // Pack the synced signals into 24-bits
        .out_red(rgb_out_red),
        .out_green(rgb_out_green),
        .out_blue(rgb_out_blue),
        .out_valid(rgb_out_valid)
    );

// =========================================================================
    // Concurrent Pixel Capture Blocks
    // =========================================================================
    
    // Capture the pure Y channel during Pass 1 for debug verification
    always_ff @(posedge clk) begin
        if (capture_gray_output && ycbcr_valid) begin
            if (gray_valid_count == 0) begin
                first_y_value <= y_wire;
            end
            if (gray_valid_count < (width * height)) begin
                // Use blocking assignment (=) for dynamic arrays to satisfy XSIM
                gray_pixels[gray_valid_count] = y_wire;
            end
            gray_valid_count <= gray_valid_count + 1;
        end
    end

    // Capture the Equalized RGB image during Pass 2
    always_ff @(posedge clk) begin
        if (capture_eq_output && rgb_out_valid) begin
            if (eq_valid_count == 0) begin
                first_eq_pixel <= eq_y_pixel;
            end
            if (eq_valid_count < (width * height)) begin
                // Use blocking assignment (=) for dynamic arrays to satisfy XSIM
                eq_pixels_r[eq_valid_count] = rgb_out_red;
                eq_pixels_g[eq_valid_count] = rgb_out_green;
                eq_pixels_b[eq_valid_count] = rgb_out_blue;
            end
            eq_valid_count <= eq_valid_count + 1;
        end
    end

    // =========================================================================
    // File I/O Tasks
    // =========================================================================

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

            bmp_prefix = new[start_address];
            for (int i = 0; i < 54; i++) begin bmp_prefix[i] = bmp_header[i]; end
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
            for (int i = 0; i < start_address; i++) $fwrite(out_file_h, "%c", bmp_prefix[i]);
            for (int row = 0; row < height; row++) begin
                for (int col = 0; col < width; col++) begin
                    byte_val = gray_pixels[row * width + col];
                    $fwrite(out_file_h, "%c%c%c", byte_val, byte_val, byte_val);
                end
                for (int pad = 0; pad < row_padding; pad++) $fwrite(out_file_h, "%c", 8'd0);
            end
            $fclose(out_file_h);
        end
    endtask

    task automatic write_equalized_bmp();
        begin
            out_file_h = $fopen(out_file_name, "wb");
            for (int i = 0; i < start_address; i++) $fwrite(out_file_h, "%c", bmp_prefix[i]);
            for (int row = 0; row < height; row++) begin
                for (int col = 0; col < width; col++) begin
                    // Write B, G, R correctly for BMP format
                    $fwrite(out_file_h, "%c", eq_pixels_b[row * width + col]);
                    $fwrite(out_file_h, "%c", eq_pixels_g[row * width + col]);
                    $fwrite(out_file_h, "%c", eq_pixels_r[row * width + col]);
                end
                for (int pad = 0; pad < row_padding; pad++) $fwrite(out_file_h, "%c", 8'd0);
            end
            $fclose(out_file_h);
        end
    endtask

    // Pure stimulus streaming task
    task automatic stream_frame();
        begin
            for (int row = 0; row < height; row++) begin
                for (int col = 0; col < width; col++) begin
                    in_blue  = $fgetc(file_h);
                    in_green = $fgetc(file_h);
                    in_red   = $fgetc(file_h);
                    rgb_valid = 1'b1;
                    @(posedge clk);
                end
                for (int pad = 0; pad < row_padding; pad++) begin
                    byte_val = $fgetc(file_h);
                end
            end
            rgb_valid = 1'b0;
            // Wait 20 cycles to ensure the pipeline flushes completely
            repeat (20) @(posedge clk);
        end
    endtask

    // =========================================================================
    // Main Simulation Execution
    // =========================================================================

    initial begin
        rst = 1'b1;
        rgb_valid = 1'b0;
        in_red = '0; in_green = '0; in_blue = '0;
        build_enable = 1'b0;
        hist_query_enable = 1'b0; hist_query_addr = '0;
        gray_valid_count = 0; eq_valid_count = 0;
        first_y_value = '0; first_eq_pixel = '0;
        file_h = 0;

        @(posedge clk);
        #1 rst = 1'b0;

        wait (hist_clear_done_y);
        @(posedge clk);

        // --- PASS 1: Build Y-Channel Histogram ---
        open_bmp();
        $display("Pass 1: Converting RGB to YCbCr and building Y Histogram.");
        gray_pixels = new[width * height];
        eq_pixels_b = new[width * height];
        eq_pixels_g = new[width * height];
        eq_pixels_r = new[width * height];
        
        capture_gray_output = 1'b1; // Turn on Y channel capture
        stream_frame();
        capture_gray_output = 1'b0;
        close_bmp();

        write_grayscale_bmp();

        // Debug check for bin 0-255
        hist_query_addr = first_y_value;
        hist_query_enable = 1'b1;
        @(posedge clk);
        hist_query_enable = 1'b0;
        @(posedge clk);
        $display("Histogram[%0d] = %0d", first_y_value, hist_query_count_y);

        // --- VBLANK: Build LUT ---
        build_enable = 1'b1;
        @(posedge clk);
        build_enable = 1'b0;

        wait (lut_done_y == 1'b1);
        @(posedge clk);

        // --- PASS 2: Apply Equalization & Rebuild RGB ---
        open_bmp();
        $display("Pass 2: Applying YCbCr histogram equalization.");
        
        capture_eq_output = 1'b1; // Turn on RGB Output capture
        stream_frame();
        capture_eq_output = 1'b0;
        close_bmp();

        if (eq_valid_count != (width * height)) begin
            $display("ERROR: equalizer produced %0d valid pixels, expected %0d.", eq_valid_count, width * height);
            $finish;
        end

        write_equalized_bmp();

        $display("First Y Pixel (Pass 1) = %0d", first_y_value);
        $display("First Equalized Y Pixel (Pass 2) = %0d", first_eq_pixel);
        $display("Total Pipeline Latency Flushed. Pixels captured = %0d", eq_valid_count);
        $display("Completed. Check %s for proper color retention.", out_file_name);
        $finish;
    end

endmodule