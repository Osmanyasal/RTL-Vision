`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer: GitHub Copilot
//
// Create Date: 20.05.2026
// Design Name:
// Module Name: tb_sync_stack
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


module tb_sync_stack;

    localparam int DATA_WIDTH = 4;
    localparam int DEPTH = 4;
    localparam int ADDR_WIDTH = $clog2(DEPTH);

    logic clk;
    logic rst;
    logic [DATA_WIDTH-1:0] w_data;
    logic w_en;
    logic full;
    logic r_en;
    logic empty;
    logic [DATA_WIDTH-1:0] r_data;

    logic [DATA_WIDTH-1:0] expected_data [0:63];
    int expected_count;

    sync_stack #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .w_data(w_data),
        .w_en(w_en),
        .full(full),
        .r_en(r_en),
        .empty(empty),
        .r_data(r_data)
    );

    always #5 clk = ~clk;

    task automatic check_flag(input logic actual, input logic expected, input string flag_name);
        if (actual !== expected) begin
            $error("%s mismatch at time %0t. Expected=%0b Actual=%0b", flag_name, $time, expected, actual);
            $fatal;
        end
    endtask

    task automatic push_expected(input logic [DATA_WIDTH-1:0] data);
        expected_data[expected_count] = data;
        expected_count = expected_count + 1;
    endtask

    task automatic pop_and_check;
        logic [DATA_WIDTH-1:0] expected;
        begin
            if (expected_count == 0) begin
                $error("Reference model underflow at time %0t", $time);
                $fatal;
            end

            expected = expected_data[expected_count - 1];

            @ (negedge clk);
            if (empty) begin
                $error("Stack unexpectedly empty before read at time %0t", $time);
                $fatal;
            end

            if (r_data !== expected) begin
                $error("Read data mismatch at time %0t. Expected=0x%0h Actual=0x%0h", $time, expected, r_data);
                $fatal;
            end

            r_en = 1'b1;
            @ (posedge clk);
            #1;
            r_en = 1'b0;

            expected_count = expected_count - 1;
        end
    endtask

    task automatic write_data(input logic [DATA_WIDTH-1:0] data, input bit expect_accept);
        begin
            @ (negedge clk);
            w_data = data;
            w_en = 1'b1;
            @ (posedge clk);
            #1;
            w_en = 1'b0;

            if (expect_accept) begin
                push_expected(data);
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        rst = 1'b1;
        w_data = '0;
        w_en = 1'b0;
        r_en = 1'b0;
        expected_count = 0;

        repeat (2) @ (posedge clk);
        rst = 1'b0;
        #1;

        check_flag(empty, 1'b1, "empty after reset");
        check_flag(full, 1'b0, "full after reset");

        write_data(4'h1, 1'b1);
        write_data(4'h5, 1'b1);
        write_data(4'h9, 1'b1);
        check_flag(empty, 1'b0, "empty after writes");
        if (r_data !== 4'h9) begin
            $error("Top of stack mismatch after writes. Expected=0x9 Actual=0x%0h", r_data);
            $fatal;
        end

        pop_and_check();
        if (r_data !== 4'h5) begin
            $error("Top of stack mismatch after pop. Expected=0x5 Actual=0x%0h", r_data);
            $fatal;
        end

        write_data(4'ha, 1'b1);
        write_data(4'hc, 1'b1);
        check_flag(full, 1'b1, "full after fill");
        if (r_data !== 4'hc) begin
            $error("Top of stack mismatch at full. Expected=0xc Actual=0x%0h", r_data);
            $fatal;
        end

        write_data(4'hf, 1'b0);
        check_flag(full, 1'b1, "full after blocked write");
        if (r_data !== 4'hc) begin
            $error("Top of stack changed on blocked write. Expected=0xc Actual=0x%0h", r_data);
            $fatal;
        end

        while (expected_count > 0) begin
            pop_and_check();
        end

        check_flag(empty, 1'b1, "empty after drain");
        check_flag(full, 1'b0, "full after drain");
        if (r_data !== '0) begin
            $error("Read data should clear to zero when empty. Actual=0x%0h", r_data);
            $fatal;
        end

        @ (negedge clk);
        r_en = 1'b1;
        @ (posedge clk);
        #1;
        r_en = 1'b0;
        check_flag(empty, 1'b1, "empty after blocked read");

        write_data(4'h2, 1'b1);
        write_data(4'h7, 1'b1);

        @ (negedge clk);
        if (r_data !== 4'h7) begin
            $error("Top mismatch before simultaneous push/pop. Expected=0x7 Actual=0x%0h", r_data);
            $fatal;
        end
        w_data = 4'he;
        w_en = 1'b1;
        r_en = 1'b1;
        @ (posedge clk);
        #1;
        w_en = 1'b0;
        r_en = 1'b0;
        expected_data[expected_count - 1] = 4'he;
        if (r_data !== 4'he) begin
            $error("Top mismatch after simultaneous push/pop. Expected=0xe Actual=0x%0h", r_data);
            $fatal;
        end

        pop_and_check();
        pop_and_check();
        check_flag(empty, 1'b1, "empty after simultaneous sequence");

        $display("tb_sync_stack completed successfully.");
        $finish;
    end
endmodule