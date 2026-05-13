`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/09/2026 09:01:27 PM
// Design Name: 
// Module Name: threshold
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


module threshold(
    input logic clk,
    input logic [7:0] in_gray, // 0-255
    input logic [7:0] thresh, // 0-255
    input logic [7:0] in_ready, // 0 or 1
    output logic[7:0] out_gray,  // 0 or in_gray
    output logic out_valid  // 0 or 1
    );
     
    always_ff @(posedge clk) begin
        if(in_ready) begin
            out_gray <= (thresh > in_gray) ? 0 : 255;
            out_valid <= 'b1;
        end
        else begin out_gray <= 0; out_valid <= 0; end
    end
endmodule
