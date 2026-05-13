`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Osman Yasal
// 
// Create Date: 05/13/2026 11:38:09 AM
// Design Name: 
// Module Name: sort3
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


module sort3 (
    input  logic [7:0] d0, d1, d2,
    output logic [7:0] min, mid, max
);
    logic [7:0] s01_l, s01_h, s02_l, s02_h, s12_l, s12_h;

    // Stage 1: Sort d0 and d1
    sort2 c1 (d0, d1, s01_l, s01_h);
    // Stage 2: Sort the high of previous with d2 (this finds the max)
    sort2 c2 (s01_h, d2, s12_l, s12_h);
    // Stage 3: Sort the lows to find the true min and true mid
    sort2 c3 (s01_l, s12_l, min, mid);
    
    assign max = s12_h;
endmodule
