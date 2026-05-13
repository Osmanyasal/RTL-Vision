`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Osman Yasal
// 
// Create Date: 05/13/2026 11:32:43 AM
// Design Name: 
// Module Name: sort2
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


module sort2(
    input logic [7:0] a, b,
    output logic [7:0] low, high
    );
    
    always_comb begin
        low = (a > b) ? b : a;
        high = (a > b) ? a : b;
    end
endmodule
