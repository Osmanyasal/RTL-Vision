`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Osman Yasal
// 
// Create Date: 04/25/2026 11:26:11 AM
// Design Name: 
// Module Name: tb_sync_fifo
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


module tb_sync_fifo(

    );

    localparam int DATA_WIDTH = 4;
    localparam int DEPTH = 16;
    localparam int ADDR_WIDTH = $clog2(DEPTH);

    logic clk;
    logic rst;
    logic [DATA_WIDTH-1:0] w_data;
    logic w_en;
    logic full;
    logic r_en;
    logic empty;
    logic [ADDR_WIDTH-1:0] r_data;

    logic [DATA_WIDTH-1:0] expected_data [0:63];
    int expected_head;
    int expected_tail;
    int expected_count;

    sync_fifo #(
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
        expected_data[expected_tail] = data;
        expected_tail = expected_tail + 1;
        expected_count = expected_count + 1;
    endtask

    task automatic pop_and_check;
        logic [DATA_WIDTH-1:0] expected;
        begin
            if (expected_count == 0) begin
                $error("Reference model underflow at time %0t", $time);
                $fatal;
            end

            expected = expected_data[expected_head];

            @ (negedge clk);
            if (empty) begin
                $error("FIFO unexpectedly empty before read at time %0t", $time);
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

            expected_head = expected_head + 1;
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
        expected_head = 0;
        expected_tail = 0;
        expected_count = 0;

        repeat (2) @ (posedge clk);
        rst = 1'b0;
        #1;

        check_flag(empty, 1'b1, "empty after reset");
        check_flag(full, 1'b0, "full after reset");

        for (int index = 0; index < DEPTH; index++) begin
            write_data(index[DATA_WIDTH-1:0], 1'b1);
        end

        check_flag(full, 1'b1, "full after fill");
        check_flag(empty, 1'b0, "empty after fill");

        write_data(4'hf, 1'b0);
        check_flag(full, 1'b1, "full after blocked write");

        for (int index = 0; index < DEPTH; index++) begin
            pop_and_check();
        end

        check_flag(empty, 1'b1, "empty after drain");
        check_flag(full, 1'b0, "full after drain");

        @ (negedge clk);
        if (!empty) begin
            $error("FIFO should be empty before blocked read at time %0t", $time);
            $fatal;
        end
        r_en = 1'b1;
        @ (posedge clk);
        #1;
        r_en = 1'b0;
        check_flag(empty, 1'b1, "empty after blocked read");

        for (int index = 0; index < 10; index++) begin
            write_data((index + 4'h3) & 'hf, 1'b1);
        end

        for (int index = 0; index < 6; index++) begin
            pop_and_check();
        end

        for (int index = 0; index < 8; index++) begin
            write_data((index + 4'ha) & 'hf, 1'b1);
        end

        while (expected_count > 0) begin
            pop_and_check();
        end

        check_flag(empty, 1'b1, "empty after wrap-around sequence");
        check_flag(full, 1'b0, "full after wrap-around sequence");

        $display("tb_sync_fifo completed successfully.");
        $finish;
    end
endmodule
