`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/29/2026 04:01:19 PM
// Design Name: 
// Module Name: tb_fifo_pipeline
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


module tb_fifo_pipeline;
    `define depth 5

    logic clk;
    logic rst;
    logic [7:0] w_data;
    logic w_en;
    logic full;
    logic r_en;
    logic [7:0] r_data[0:8];
    logic out_data_valid;
    
    fifo_pipeline #(
        .DATA_WIDTH(8),
        .DEPTH(`depth)
    ) dut (
        .clk(clk),
        .rst(rst),
        .w_data(w_data),
        .w_en(w_en),
        .full(full),
        .r_en(r_en),
        .r_data(r_data),
        .out_data_valid(out_data_valid)
    );
    initial begin
        clk = 0;
        rst = 1; 
        w_en = 0;
        r_en = 0;
        #1;
        @(posedge clk);
        rst = 0;

        // Write some data into the FIFO
        w_en = 1;
        #1
        for (int i = 0; i < `depth * 2 ; i++) begin
            #1;
            w_data = $urandom_range(0,255);
            #1;
            @(posedge clk); 
            $display("data->%d",w_data);
        end 
        w_en = 0;
        #1;  
        
        for (int i = 0; i < `depth * 2; i++) begin
            w_data = i;
            r_en = 1;
            w_en = 1; // keep writing data while reading to test the pipeline behavior under continuous load
            #1;
            @(posedge clk);
            #1
            if (out_data_valid) begin
                $display("read data: \n\t%d %d %d \n\t%d %d %d \n\t%d %d %d", r_data[0], r_data[1], r_data[2], r_data[3], r_data[4], r_data[5], r_data[6], r_data[7], r_data[8]);
            end else begin
                $display("Output data not valid yet.");
            end
        end
        @(posedge clk);
        r_en = 0;
        #1;
        $display("read data: \n\t%d %d %d \n\t%d %d %d \n\t%d %d %d", r_data[0], r_data[1], r_data[2], r_data[3], r_data[4], r_data[5], r_data[6], r_data[7], r_data[8]);
        $finish;
    end

    always #5 clk = ~clk; // 100MHz clock
endmodule
