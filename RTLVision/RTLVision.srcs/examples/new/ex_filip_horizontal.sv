`timescale 1ns / 1ps

module ex_filip_horizontal #(
    parameter string file_name =
        "../../../../../butterfly.bmp",

    parameter string out_file_name =
        "../../../../../butterfly_flipped.bmp"
)();

    ////////////////////////////////////////////////////////////////
    // FILE VARIABLES
    ////////////////////////////////////////////////////////////////

    int file_h;
    int file_out;
    int status;

    logic [7:0] bmp_header [0:53];

    int width;
    int height;
    int start_address;

    int row_padding;

    int byte_val;

    ////////////////////////////////////////////////////////////////
    // CLOCK
    ////////////////////////////////////////////////////////////////

    logic clk = 0;
    logic rst = 0;

    always #5 clk = ~clk;

    ////////////////////////////////////////////////////////////////
    // DUT SIGNALS
    ////////////////////////////////////////////////////////////////

    logic [23:0] in_pixel;
    logic        in_valid;
    logic        line_done;

    logic [23:0] out_pixel;
    logic        out_valid;

    flip_horizontal #(
        .DATA_WIDTH(24),
        .LINE_WIDTH(4096)
    ) dut (
        .clk(clk),
        .rst(rst),

        .in_pixel(in_pixel),
        .in_valid(in_valid),
        .line_done(line_done),

        .out_pixel(out_pixel),
        .out_valid(out_valid)
    );

    ////////////////////////////////////////////////////////////////
    // TEST
    ////////////////////////////////////////////////////////////////

    initial begin

        ////////////////////////////////////////////////////////////
        // INIT
        ////////////////////////////////////////////////////////////

        rst = 1;

        in_pixel  = 0;
        in_valid  = 0;
        line_done = 0;

        @(posedge clk);
        @(posedge clk);

        rst = 0;

        ////////////////////////////////////////////////////////////
        // OPEN FILES
        ////////////////////////////////////////////////////////////

        file_h = $fopen(file_name, "rb");

        if(file_h == 0) begin
            $display("ERROR opening input BMP");
            $finish;
        end

        file_out = $fopen(out_file_name, "wb");

        if(file_out == 0) begin
            $display("ERROR opening output BMP");
            $finish;
        end

        ////////////////////////////////////////////////////////////
        // READ BMP HEADER
        ////////////////////////////////////////////////////////////

        for(int i = 0; i < 54; i++) begin
            bmp_header[i] = $fgetc(file_h);
        end

        start_address = {
            bmp_header[13],
            bmp_header[12],
            bmp_header[11],
            bmp_header[10]
        };

        width = {
            bmp_header[21],
            bmp_header[20],
            bmp_header[19],
            bmp_header[18]
        };

        height = {
            bmp_header[25],
            bmp_header[24],
            bmp_header[23],
            bmp_header[22]
        };

        row_padding = (4 - ((width * 3) % 4)) % 4;

        $display("WIDTH  = %0d", width);
        $display("HEIGHT = %0d", height);
        $display("PADDING= %0d", row_padding);

        ////////////////////////////////////////////////////////////
        // COPY HEADER
        ////////////////////////////////////////////////////////////

        status = $fseek(file_h, 0, 0);

        for(int i = 0; i < start_address; i++) begin
            byte_val = $fgetc(file_h);
            $fwrite(file_out, "%c", byte_val);
        end

        ////////////////////////////////////////////////////////////
        // PROCESS IMAGE
        ////////////////////////////////////////////////////////////

        for(int row = 0; row < height; row++) begin

            ////////////////////////////////////////////////////////
            // SEND ONE ROW
            ////////////////////////////////////////////////////////

            for(int col = 0; col < width; col++) begin

                logic [7:0] blue;
                logic [7:0] green;
                logic [7:0] red;

                blue  = $fgetc(file_h);
                green = $fgetc(file_h);
                red   = $fgetc(file_h);

                in_pixel = {red, green, blue};

                in_valid = 1;

                if(col == width-1)
                    line_done = 1;
                else
                    line_done = 0;

                @(posedge clk);
            end

            in_valid  = 0;
            line_done = 0;

            ////////////////////////////////////////////////////////
            // SKIP INPUT BMP PADDING
            ////////////////////////////////////////////////////////

            for(int p = 0; p < row_padding; p++) begin
                byte_val = $fgetc(file_h);
            end

            ////////////////////////////////////////////////////////
            // RECEIVE FLIPPED ROW
            ////////////////////////////////////////////////////////

            for(int col = 0; col < width; col++) begin

                @(posedge clk);

                while(!out_valid)
                    @(posedge clk);

                $fwrite(file_out, "%c", out_pixel[7:0]);
                $fwrite(file_out, "%c", out_pixel[15:8]);
                $fwrite(file_out, "%c", out_pixel[23:16]);
            end

            ////////////////////////////////////////////////////////
            // WRITE OUTPUT BMP PADDING
            ////////////////////////////////////////////////////////

            for(int p = 0; p < row_padding; p++) begin
                $fwrite(file_out, "%c", 8'h00);
            end
        end

        ////////////////////////////////////////////////////////////
        // DONE
        ////////////////////////////////////////////////////////////

        $display("DONE");

        $fclose(file_h);
        $fclose(file_out);

        $finish;
    end

endmodule