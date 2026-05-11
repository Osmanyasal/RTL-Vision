`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/23/2026 03:29:16 PM
// Design Name: 
// Module Name: tb_grayscale
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


module tb_grayscale;
    logic clk;
    logic rst;
    logic in_ready;
    logic [7:0] in_red;
    logic [7:0] in_green;
    logic [7:0] in_blue;
    logic [7:0] out_gray;
    logic out_ready;

    grayscale dut (
        .clk(clk),
        .rst(rst),
        .in_ready(in_ready),
        .in_red(in_red),
        .in_green(in_green),
        .in_blue(in_blue),
        .out_gray(out_gray),
        .out_ready(out_ready)
    );

    always #5 clk = ~clk;

    function automatic logic [7:0] expected_gray(
        input logic [7:0] red,
        input logic [7:0] green,
        input logic [7:0] blue
    );
        expected_gray = (red >> 2) + (red >> 5) +
                        (green >> 1) + (green >> 4) +
                        (blue >> 4) + (blue >> 5);
    endfunction

    task automatic check_outputs(
        input logic expected_ready,
        input logic [7:0] expected_value,
        input string test_name
    );
        if ((out_ready !== expected_ready) || (out_gray !== expected_value)) begin
            $error("%s failed: out_ready=%0b expected=%0b out_gray=0x%0h expected=0x%0h",
                   test_name, out_ready, expected_ready, out_gray, expected_value);
            $fatal;
        end
    endtask

    initial begin
        clk = 1'b0;
        rst = 1'b1;
        in_ready = 1'b0;
        in_red = 8'h00;
        in_green = 8'h00;
        in_blue = 8'h00;

        repeat (2) @(posedge clk);
        check_outputs(1'b0, 8'h00, "reset clears outputs");

        rst = 1'b0;

        in_red = 8'd120;
        in_green = 8'd200;
        in_blue = 8'd32;
        in_ready = 1'b1;
        @(posedge clk);
        #1;
        check_outputs(1'b1, expected_gray(8'd120, 8'd200, 8'd32), "valid input produces grayscale");

        in_ready = 1'b0;
        @(posedge clk);
        #1;
        check_outputs(1'b0, 8'h00, "idle cycle clears outputs");

        in_red = 8'd255;
        in_green = 8'd128;
        in_blue = 8'd64;
        in_ready = 1'b1;
        @(posedge clk);
        #1;
        check_outputs(1'b1, expected_gray(8'd255, 8'd128, 8'd64), "second sample matches expected grayscale");

        rst = 1'b1;
        in_ready = 1'b1;
        @(posedge clk);
        #1;
        check_outputs(1'b0, 8'h00, "reset has priority over in_ready");

        $display("tb_grayscale passed");
        $finish;
    end
endmodule
