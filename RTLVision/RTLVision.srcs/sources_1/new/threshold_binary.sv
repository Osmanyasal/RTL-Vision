`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.05.2026 18:40:52
// Design Name: 
// Module Name: threshold_binary
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


module threshold_binary(
    input logic clk,
    input logic rst,
    input logic [7:0] in_gray, // 0-255
    input logic [7:0] thresh, // 0-255
    input logic [7:0] in_ready, // 0 or 1
    output logic[7:0] out_gray,  // 0 or 255
    output logic out_valid  // 0 or 1
    );
     
    always_ff @(posedge clk or posedge rst) begin
        if(rst) begin
            out_gray <= 0;
            out_valid <= 0;
        end
        else if(in_ready) begin
            out_gray <= (thresh > in_gray) ? 0 : 255;
            out_valid <= 'b1;
        end
        else begin out_gray <= 0; out_valid <= 0; end
    end
endmodule
