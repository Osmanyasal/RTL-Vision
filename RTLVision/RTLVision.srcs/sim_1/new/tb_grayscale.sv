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
    logic ready_in;
    logic [7:0] red_in;
    logic [7:0] green_in;
    logic [7:0] blue_in;
    logic [7:0] gray_out;
    logic ready_out;

    grayscale dut (
        .clk(clk),
        .rst(rst),
        .ready_in(ready_in),
        .red_in(red_in),
        .green_in(green_in),
        .blue_in(blue_in),
        .gray_out(gray_out),
        .ready_out(ready_out)
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
        if ((ready_out !== expected_ready) || (gray_out !== expected_value)) begin
            $error("%s failed: ready_out=%0b expected=%0b gray_out=0x%0h expected=0x%0h",
                   test_name, ready_out, expected_ready, gray_out, expected_value);
            $fatal;
        end
    endtask

    initial begin
        clk = 1'b0;
        rst = 1'b1;
        ready_in = 1'b0;
        red_in = 8'h00;
        green_in = 8'h00;
        blue_in = 8'h00;

        repeat (2) @(posedge clk);
        check_outputs(1'b0, 8'h00, "reset clears outputs");

        rst = 1'b0;

        red_in = 8'd120;
        green_in = 8'd200;
        blue_in = 8'd32;
        ready_in = 1'b1;
        @(posedge clk);
        #1;
        check_outputs(1'b1, expected_gray(8'd120, 8'd200, 8'd32), "valid input produces grayscale");

        ready_in = 1'b0;
        @(posedge clk);
        #1;
        check_outputs(1'b0, 8'h00, "idle cycle clears outputs");

        red_in = 8'd255;
        green_in = 8'd128;
        blue_in = 8'd64;
        ready_in = 1'b1;
        @(posedge clk);
        #1;
        check_outputs(1'b1, expected_gray(8'd255, 8'd128, 8'd64), "second sample matches expected grayscale");

        rst = 1'b1;
        ready_in = 1'b1;
        @(posedge clk);
        #1;
        check_outputs(1'b0, 8'h00, "reset has priority over ready_in");

        $display("tb_grayscale passed");
        $finish;
    end
endmodule
