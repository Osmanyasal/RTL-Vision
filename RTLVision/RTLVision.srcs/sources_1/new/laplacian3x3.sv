`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Osman Yasal
// 
// Create Date: 04/24/2026 02:27:24 PM
// Design Name: 
// Module Name: laplacian3x3
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: Pipelined
// 
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps

module laplacian3x3 #(parameter IMG_WIDTH = 1024)(
    input  logic       clk,
    input  logic       rst,
    input  logic       in_ready,
    input  logic [7:0] in_gray,
    output logic [7:0] out_laplacian,
    output logic       out_valid
);

    // ---------------------------------------------------------------------
    // 3x3 sliding-window line buffer
    // ---------------------------------------------------------------------
    logic [7:0] r_data [0:8];
    logic       window_valid;
    logic       win_full;

    fifo_pipeline2 #(
        .DATA_WIDTH(8),
        .DEPTH(IMG_WIDTH)
    ) u_window (
        .clk(clk),
        .rst(rst),
        .w_data(in_gray),
        .w_en(in_ready),
        .full(win_full),
        .r_en(1'b1),                
        .r_data(r_data),
        .out_data_valid(window_valid)
    );

    logic signed [11:0] laplacian_p1;
    logic valid_p1;

    // Stage 1: Convolution
    always_ff @(posedge clk) begin
        if (rst) begin
            laplacian_p1 <= 12'd0;
            valid_p1 <= 1'b0;
        end else begin
            valid_p1 <= window_valid;
            
            if (window_valid) begin
                laplacian_p1 <= -$signed({4'b0, r_data[1]}) // Top
                                -$signed({4'b0, r_data[3]}) // Left
                                +$signed({2'b0, r_data[4], 2'b0}) // Center * 4
                                -$signed({4'b0, r_data[5]}) // Right (Fixed width to 4'b0)
                                -$signed({4'b0, r_data[7]}); // Bottom
            end
        end
    end

    // Stage 2: Output register (Clamping)
    always_ff @(posedge clk) begin
        if (rst) begin
            out_laplacian <= 8'd0;
            out_valid <= 1'b0;
        end else begin
            out_valid <= valid_p1;
            
            if (valid_p1) begin
                // Fixed Clamping: Handle both negative values and overflows
                if (laplacian_p1[11]) begin // Check sign bit
                    out_laplacian <= 8'd0;   // If negative, set to black
                end else if (laplacian_p1 > 12'd255) begin
                    out_laplacian <= 8'd255; // If overflow, set to white
                end else begin
                    out_laplacian <= laplacian_p1[7:0]; // Standard range
                end
            end else begin
                out_laplacian <= 8'd0;
            end
        end
    end
    
endmodule