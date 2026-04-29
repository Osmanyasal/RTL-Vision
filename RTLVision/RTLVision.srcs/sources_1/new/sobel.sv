`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Osman Yasal
// 
// Create Date: 04/24/2026 02:27:24 PM
// Design Name: 
// Module Name: sobel
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

module sobel #(parameter IMG_WIDTH = 1024, parameter KERNEL_WIDTH = 3)(
    input logic clk,
    input logic rst,
    input logic ready_in,
    input logic [7:0] gray_in,
    output logic [7:0] sobel_out,
    output logic ready_out
    );
    
    logic [IMG_WIDTH-1:0] buffer [0:KERNEL_WIDTH-1];
    always_ff @(posedge clk) begin
        
        if(rst) begin
            sobel_out <= 0;
            ready_out <= 0;
        end 
        else if(ready_in) begin
        
        end
        else begin
            sobel_out <= 0;
            ready_out <= 0;
        end
        end
     
endmodule