`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Osman Yasal
// 
// Create Date: 04/30/2026 07:49:47 PM
// Design Name: 
// Module Name: rgb_to_ycbcr
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

module rgb_to_ycbcr(
    input  logic        clk,
    input  logic        rst,
    input  logic        ready_in,
    input  logic [7:0]  red_in,
    input  logic [7:0]  green_in,
    input  logic [7:0]  blue_in,
    output logic [23:0] ycbcr_out, // Changed to a 24-bit packed vector
    output logic        ready_out
);
    
    // Fixed: 8-bit outputs
    logic [7:0] y, cb, cr;
    
    // We need signed intermediate variables for the math to work correctly.
    logic signed [9:0] r_s, g_s, b_s;
    
    assign r_s = $signed({1'b0, red_in});
    assign g_s = $signed({1'b0, green_in});
    assign b_s = $signed({1'b0, blue_in});

    always_ff @(posedge clk) begin
        if (rst) begin
            ready_out <= 0;
            y  <= '0; 
            cb <= '0; 
            cr <= '0;
        end
        else if (ready_in) begin
            // Math is safely signed. 
            y  <= (  77*r_s + 150*g_s +  29*b_s) >> 8;
            cb <= (( -43*r_s -  85*g_s + 128*b_s) >> 8) + 128;
            cr <= (( 128*r_s - 107*g_s -  21*b_s) >> 8) + 128;
            ready_out <= 1;
        end
        else begin
            ready_out <= 0;
            y  <= '0; 
            cb <= '0; 
            cr <= '0;
        end
    end
    
    // Pack the 8-bit channels into the 24-bit output bus
    assign ycbcr_out = {y, cb, cr};
    
endmodule