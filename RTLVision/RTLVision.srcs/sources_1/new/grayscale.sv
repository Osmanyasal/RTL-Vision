`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Osman Yasal 
// 
// Create Date: 04/23/2026 03:21:03 PM
// Design Name: 
// Module Name: grayscale
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

 
module grayscale(
    input logic clk,
    input logic rst,
    input logic in_ready,
    input logic[7:0] in_red,
    input logic[7:0] in_green,
    input logic[7:0] in_blue,
    output logic[7:0] out_gray,
    output logic out_valid
    );
    
    always_ff @(posedge clk) begin
         
        if(in_ready) begin
            out_gray <= (in_red >> 2) + (in_red >> 5) + 
                        (in_green >> 1) + (in_green >> 4) + 
                        (in_blue >> 4) + (in_blue >> 5);
            out_valid <= 1;   
            
        end
        else begin
            out_valid <= 0;
            out_gray <= 0;
        end
    end
endmodule
