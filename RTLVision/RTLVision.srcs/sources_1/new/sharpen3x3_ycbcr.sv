`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/01/2026 06:20:36 PM
// Design Name: 
// Module Name: sharpen3x3_ycbcr
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Pipelined
// 
//////////////////////////////////////////////////////////////////////////////////


module sharpen3x3_ycbcr #(parameter IMG_WIDTH = 1024)(
    input  logic        clk,
    input  logic        rst,
    input  logic        ready_in,
    input  logic [23:0] ycbcr_in,  
    output logic [23:0] ycbcr_out, 
    output logic        ready_out
);
    
    logic [7:0] y_in;
    logic [7:0] r_data [0:8];
    logic       window_valid;
    logic       win_full;

    // Extract Y component for the window buffer
    assign y_in = ycbcr_in[23:16]; 

    // ---------------------------------------------------------------------
    // 1. Sliding Window Buffer (Line Buffers)
    // ---------------------------------------------------------------------
    fifo_pipeline2 #(
        .DATA_WIDTH(8),
        .DEPTH(IMG_WIDTH)
    ) u_window (
        .clk(clk),
        .rst(rst),
        .w_data(y_in),
        .w_en(ready_in),
        .full(win_full),
        .r_en(1'b1),                
        .r_data(r_data),
        .out_data_valid(window_valid)
    );

    // ---------------------------------------------------------------------
    // Balancing Delay for Cb and Cr
    // The Y window buffer outputs the 'center' pixel (r_data[4]) which is 
    // delayed by roughly 1 line + 1 pixel. We must delay Cb/Cr to match.
    // ---------------------------------------------------------------------
    logic [15:0] cbcr_delayed;
     
    // ---------------------------------------------------------------------
    // Stage 1: Laplacian Components
    // ---------------------------------------------------------------------
    logic [10:0]        center_p1;
    logic [9:0]         surround_p1;
    logic [15:0]        cbcr_p1;
    logic               vld1;

    always_ff @(posedge clk) begin
        if (rst) begin
            vld1 <= 1'b0;
        end else begin
            vld1 <= window_valid;
            if (window_valid) begin
                // center * 5
                center_p1   <= ({3'b000, r_data[4]} << 2) + r_data[4]; 
                // sum of neighbors
                surround_p1 <= {2'b00, r_data[1]} + {2'b00, r_data[3]} + 
                               {2'b00, r_data[5]} + {2'b00, r_data[7]};
                
                // IMPORTANT: You need a way to pass the CbCr through the 
                // window buffer to keep them aligned. 
                cbcr_p1     <= ycbcr_in[15:0]; // Placeholder for aligned Chroma
            end
        end
    end

    // ---------------------------------------------------------------------
    // Stage 2: Sharpen Calculation (Signed Math)
    // ---------------------------------------------------------------------
    logic signed [12:0] sharp_raw_p2;
    logic [15:0]        cbcr_p2;
    logic               vld2;

    always_ff @(posedge clk) begin
        if (rst) begin
            vld2 <= 1'b0;
        end else begin
            vld2 <= vld1;
            if (vld1) begin
                sharp_raw_p2 <= $signed({2'b00, center_p1}) - $signed({3'b000, surround_p1});
                cbcr_p2      <= cbcr_p1;
            end
        end
    end

    // ---------------------------------------------------------------------
    // Stage 3: Clamping & Final Output
    // ---------------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (rst) begin
            ready_out <= 1'b0;
            ycbcr_out <= 24'd0;
        end else begin
            ready_out <= vld2;
            if (vld2) begin
                if (sharp_raw_p2 > 13'sd255) 
                    ycbcr_out[23:16] <= 8'd255;
                else if (sharp_raw_p2 < 13'sd0) 
                    ycbcr_out[23:16] <= 8'd0;
                else 
                    ycbcr_out[23:16] <= sharp_raw_p2[7:0];

                ycbcr_out[15:0] <= cbcr_p2;
            end else begin
                ycbcr_out <= 24'd0;
            end
        end
    end
endmodule