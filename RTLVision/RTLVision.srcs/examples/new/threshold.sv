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
    input logic [7:0] gray_in, // 0-255
    input logic [7:0] thresh, // 0-255
    input logic [7:0] ready_in, // 0 or 1
    output logic[7:0] gray_out,  // 0 or gray_in
    output logic ready_out  // 0 or 1
    );
     
    always_ff @(posedge clk) begin
        if(ready_in) begin
            gray_out <= (thresh > gray_in) ? 0 : 255;
            ready_out <= 'b1;
        end
        else begin gray_out <= 0; ready_out <= 0; end
    end
endmodule
