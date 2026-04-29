`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Osman Yasal
// 
// Create Date: 04/29/2026 02:30:30 PM
// Design Name: 
// Module Name: fifo_pipeline
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


module fifo_pipeline #(parameter DATA_WIDTH = 8, parameter DEPTH = 1280, parameter ADDR_WIDTH=$clog2(DEPTH))
(
    input logic clk,
    input logic rst,

    // write interface
    input logic [DATA_WIDTH-1:0] w_data,
    input logic w_en,
    output logic full,

    // read interface
    input logic r_en,
    output logic [DATA_WIDTH-1:0] r_data[0:8],   // get 8 data outputs (3x3 kernel window)
    output logic out_data_valid // indicates that the output data is valid and can be read by the consumer

);

logic fifo_0_full, fifo_0_empty;
logic fifo_1_full, fifo_1_empty;
logic fifo_0_write_en, fifo_0_read_en, fifo_1_write_en, fifo_1_read_en;
logic [DATA_WIDTH-1:0] fifo_0_to_fifo_1_data;
logic [DATA_WIDTH-1:0] fifo_1_to_kernel_data;
logic [DATA_WIDTH-1:0] input_p0, input_p1, input_p2;

assign fifo_0_write_en = w_en && !fifo_0_full;
assign fifo_0_read_en = !fifo_0_empty && (!fifo_1_full || fifo_1_read_en);;
assign fifo_1_write_en = fifo_0_read_en;
assign fifo_1_read_en = r_en && !fifo_1_empty;
assign full = fifo_0_full && fifo_1_full; // if both fifos are full, then the pipeline is full.

always_ff @(posedge clk) begin
    if (rst) begin
        input_p0 <= '0;
        input_p1 <= '0;
        input_p2 <= '0;
    end else if (fifo_0_write_en) begin
        input_p0 <= input_p1;
        input_p1 <= input_p2;
        input_p2 <= w_data;
    end
end


logic [DATA_WIDTH-1:0] p0,p1,p2, p3,p4,p5, p6,p7,p8; // kernel
always_ff @(posedge clk) begin
    if (rst) begin
        p0 <= 0; p1 <= 0; p2 <= 0;
        p3 <= 0; p4 <= 0; p5 <= 0;
        p6 <= 0; p7 <= 0; p8 <= 0;
        out_data_valid <= 0; // reset the output data valid signal
    end else if (fifo_1_read_en) begin
        p0 <= p1; p1 <= p2; p2 <= fifo_1_to_kernel_data;
        p3 <= p4; p4 <= p5; p5 <= fifo_0_to_fifo_1_data;
        p6 <= input_p0;
        p7 <= input_p1;
        p8 <= input_p2;
        out_data_valid <= 1; // output data is valid after the first read 
    end
    else begin
        out_data_valid <= 0; // reset the output data valid signal
    end
end

assign r_data[0] = p0;
assign r_data[1] = p1;
assign r_data[2] = p2;
assign r_data[3] = p3;
assign r_data[4] = p4;
assign r_data[5] = p5;
assign r_data[6] = p6;
assign r_data[7] = p7;
assign r_data[8] = p8;

sync_fifo  #(    // first receiver, transfers to fifo_1
    .DATA_WIDTH(DATA_WIDTH),
    .DEPTH(DEPTH),  // becomes 1280
    .ADDR_WIDTH(ADDR_WIDTH) // becomes 11
 ) fifo_0 (
    .clk(clk),
    .rst(rst),
    
    // write interface
    .w_data(w_data),
    .w_en(fifo_0_write_en),
    .full(fifo_0_full),
    
    // read interface
    .r_en(fifo_0_read_en),
    .empty(fifo_0_empty),
    .r_data(fifo_0_to_fifo_1_data)
);


sync_fifo #(    // second receiver, transfers to fifo_2 if exists...
    .DATA_WIDTH(DATA_WIDTH),
    .DEPTH(DEPTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) fifo_1 (
    .clk(clk),
    .rst(rst),
    
    // write interface
    .w_data(fifo_0_to_fifo_1_data),
    .w_en(fifo_1_write_en),
    .full(fifo_1_full),
    
    // read interface
    .r_en(fifo_1_read_en),
    .empty(fifo_1_empty),
    .r_data(fifo_1_to_kernel_data)
);


endmodule
