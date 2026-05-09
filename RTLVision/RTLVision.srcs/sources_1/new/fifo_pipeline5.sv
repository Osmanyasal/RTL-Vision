`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/09/2026 08:13:10 PM
// Design Name: 
// Module Name: fifo_pipeline5
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




module fifo_pipeline5 #(parameter DATA_WIDTH = 8, parameter DEPTH = 1280, parameter ADDR_WIDTH=$clog2(DEPTH))
(
    input logic clk,
    input logic rst,

    // write interface
    input logic [DATA_WIDTH-1:0] w_data,
    input logic w_en,
    output logic full,

    // read interface
    input logic r_en,
    output logic [DATA_WIDTH-1:0] r_data[0:24],   // 25 data outputs (5x5 kernel window)
    output logic out_data_valid // indicates that the output data is valid and can be read by the consumer

);

// 5x5 sliding window requires 4 line buffers (one per inter-row delay).
// Pipeline ordering (top-to-bottom rows of the kernel window):
//   Row 0 (oldest) <- fifo_3 output
//   Row 1          <- fifo_2 output
//   Row 2          <- fifo_1 output
//   Row 3          <- fifo_0 output
//   Row 4 (newest) <- input column shift register
// Each row is 5 columns wide; newest sample enters at the rightmost column
// and shifts left every accepted cycle.

logic fifo_0_full, fifo_0_empty;
logic fifo_1_full, fifo_1_empty;
logic fifo_2_full, fifo_2_empty;
logic fifo_3_full, fifo_3_empty;

logic fifo_0_write_en, fifo_0_read_en;
logic fifo_1_write_en, fifo_1_read_en;
logic fifo_2_write_en, fifo_2_read_en;
logic fifo_3_write_en, fifo_3_read_en;

logic [DATA_WIDTH-1:0] fifo_0_to_fifo_1_data;
logic [DATA_WIDTH-1:0] fifo_1_to_fifo_2_data;
logic [DATA_WIDTH-1:0] fifo_2_to_fifo_3_data;
logic [DATA_WIDTH-1:0] fifo_3_to_kernel_data;

// last 5 inputs of the current (newest) row
logic [DATA_WIDTH-1:0] input_p0, input_p1, input_p2, input_p3, input_p4;

// Back-pressure / handshake chain.
// Allow write when full IF a read is also happening this cycle
// (concurrent r/w keeps fill constant in sync_fifo).
assign fifo_0_write_en = w_en          && (!fifo_0_full || fifo_0_read_en);
assign fifo_0_read_en  = !fifo_0_empty && (!fifo_1_full || fifo_1_read_en);

assign fifo_1_write_en = fifo_0_read_en;
assign fifo_1_read_en  = !fifo_1_empty && (!fifo_2_full || fifo_2_read_en);

assign fifo_2_write_en = fifo_1_read_en;
assign fifo_2_read_en  = !fifo_2_empty && (!fifo_3_full || fifo_3_read_en);

assign fifo_3_write_en = fifo_2_read_en;
assign fifo_3_read_en  = r_en && !fifo_3_empty;

// pipeline is full only when all four line buffers are full.
assign full = fifo_0_full && fifo_1_full && fifo_2_full && fifo_3_full;

// Newest-row column shift register: advances on every accepted input write.
always_ff @(posedge clk) begin
    if (rst) begin
        input_p0 <= '0;
        input_p1 <= '0;
        input_p2 <= '0;
        input_p3 <= '0;
        input_p4 <= '0;
    end else if (fifo_0_write_en) begin
        input_p0 <= input_p1;
        input_p1 <= input_p2;
        input_p2 <= input_p3;
        input_p3 <= input_p4;
        input_p4 <= w_data;
    end
end

// 5x5 kernel window registers (row-major, p0 = top-left, p24 = bottom-right).
logic [DATA_WIDTH-1:0] p0,  p1,  p2,  p3,  p4;   // row 0 (top, oldest)
logic [DATA_WIDTH-1:0] p5,  p6,  p7,  p8,  p9;   // row 1
logic [DATA_WIDTH-1:0] p10, p11, p12, p13, p14;  // row 2 (center)
logic [DATA_WIDTH-1:0] p15, p16, p17, p18, p19;  // row 3
logic [DATA_WIDTH-1:0] p20, p21, p22, p23, p24;  // row 4 (bottom, newest)

always_ff @(posedge clk) begin
    if (rst) begin
        {p0, p1, p2, p3, p4}       <= '0;
        {p5, p6, p7, p8, p9}       <= '0;
        {p10,p11,p12,p13,p14}      <= '0;
        {p15,p16,p17,p18,p19}      <= '0;
        {p20,p21,p22,p23,p24}      <= '0;
        out_data_valid <= 1'b0;
    end else if (fifo_3_read_en) begin
        // Each row shifts left by one; the new rightmost sample comes from
        // the corresponding line-buffer output (or input pipeline for row 4).
        p0  <= p1;  p1  <= p2;  p2  <= p3;  p3  <= p4;  p4  <= fifo_3_to_kernel_data;
        p5  <= p6;  p6  <= p7;  p7  <= p8;  p8  <= p9;  p9  <= fifo_2_to_fifo_3_data;
        p10 <= p11; p11 <= p12; p12 <= p13; p13 <= p14; p14 <= fifo_1_to_fifo_2_data;
        p15 <= p16; p16 <= p17; p17 <= p18; p18 <= p19; p19 <= fifo_0_to_fifo_1_data;
        p20 <= p21; p21 <= p22; p22 <= p23; p23 <= p24; p24 <= input_p4;
        out_data_valid <= 1'b1;
    end else begin
        out_data_valid <= 1'b0;
    end
end

assign r_data[0]  = p0;   assign r_data[1]  = p1;   assign r_data[2]  = p2;
assign r_data[3]  = p3;   assign r_data[4]  = p4;   assign r_data[5]  = p5;   
assign r_data[6]  = p6;   assign r_data[7]  = p7;   assign r_data[8]  = p8;   
assign r_data[9]  = p9;   assign r_data[10] = p10;  assign r_data[11] = p11;  
assign r_data[12] = p12;  assign r_data[13] = p13;  assign r_data[14] = p14;
assign r_data[15] = p15;  assign r_data[16] = p16;  assign r_data[17] = p17;
assign r_data[18] = p18;  assign r_data[19] = p19;  assign r_data[20] = p20;  
assign r_data[21] = p21;  assign r_data[22] = p22;  assign r_data[23] = p23;  
assign r_data[24] = p24;

sync_fifo #( // line buffer 0 -> feeds row 3
    .DATA_WIDTH(DATA_WIDTH),
    .DEPTH(DEPTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) fifo_0 (
    .clk(clk),
    .rst(rst),
    .w_data(w_data),
    .w_en(fifo_0_write_en),
    .full(fifo_0_full),
    .r_en(fifo_0_read_en),
    .empty(fifo_0_empty),
    .r_data(fifo_0_to_fifo_1_data)
);

sync_fifo #( // line buffer 1 -> feeds row 2 (center)
    .DATA_WIDTH(DATA_WIDTH),
    .DEPTH(DEPTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) fifo_1 (
    .clk(clk),
    .rst(rst),
    .w_data(fifo_0_to_fifo_1_data),
    .w_en(fifo_1_write_en),
    .full(fifo_1_full),
    .r_en(fifo_1_read_en),
    .empty(fifo_1_empty),
    .r_data(fifo_1_to_fifo_2_data)
);

sync_fifo #( // line buffer 2 -> feeds row 1
    .DATA_WIDTH(DATA_WIDTH),
    .DEPTH(DEPTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) fifo_2 (
    .clk(clk),
    .rst(rst),
    .w_data(fifo_1_to_fifo_2_data),
    .w_en(fifo_2_write_en),
    .full(fifo_2_full),
    .r_en(fifo_2_read_en),
    .empty(fifo_2_empty),
    .r_data(fifo_2_to_fifo_3_data)
);

sync_fifo #( // line buffer 3 -> feeds row 0 (top, oldest)
    .DATA_WIDTH(DATA_WIDTH),
    .DEPTH(DEPTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) fifo_3 (
    .clk(clk),
    .rst(rst),
    .w_data(fifo_2_to_fifo_3_data),
    .w_en(fifo_3_write_en),
    .full(fifo_3_full),
    .r_en(fifo_3_read_en),
    .empty(fifo_3_empty),
    .r_data(fifo_3_to_kernel_data)
);

endmodule
