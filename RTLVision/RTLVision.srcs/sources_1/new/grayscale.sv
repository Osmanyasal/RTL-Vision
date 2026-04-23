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


(* keep_hierarchy = "yes" *)
(* dont_touch = "true" *)
module grayscale(
    input logic clk,
    input logic rst,
    input logic ready_in,
    input logic[7:0] red_in,
    input logic[7:0] green_in,
    input logic[7:0] blue_in,
    output logic[7:0] gray_out,
    output logic ready_out
    );
    
    always_ff @(posedge clk) begin
        
        if(rst) begin
            ready_out <= 0;
            gray_out <= 0;
        end
        else if(ready_in) begin
            gray_out <= (red_in >> 2) + (red_in >> 5) + 
                        (green_in >> 1) + (green_in >> 4) + 
                        (blue_in >> 4) + (blue_in >> 5);
            ready_out <= 1;   
            
        end
        else begin
            ready_out <= 0;
            gray_out <= 0;
        end
    end
endmodule
