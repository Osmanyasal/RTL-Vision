`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.05.2026 19:14:19
// Design Name: 
// Module Name: inverse
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


module inverse(
    input  logic clk,
    input  logic rst,
    input  logic in_ready,
    input  logic [7:0] in_pixel, 
    output logic [7:0] out_pixel,
    output logic out_valid
);

    // Invert the pixel value
    always_ff @(posedge clk) begin
        if (rst) begin
            out_pixel <= '0;
            out_valid <= 1'b0;
        end else if (in_ready) begin
            out_pixel <= ~in_pixel; // Invert the pixel value
            out_valid <= 1'b1;     
        end else begin
            out_valid <= 1'b0;     
        end
    end
endmodule
