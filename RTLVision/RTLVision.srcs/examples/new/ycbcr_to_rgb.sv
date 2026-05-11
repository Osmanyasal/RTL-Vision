`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Osman Yasal 
// 
// Create Date: 05/01/2026
// Design Name: 
// Module Name: ycbcr_to_rgb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Converts 24-bit YCbCr back to standard 8-bit RGB channels.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module ycbcr_to_rgb(
    input  logic        clk,
    input  logic        rst,
    input  logic        in_ready,
    input  logic [23:0] in_ycbcr, // 24-bit packed vector {Y, Cb, Cr}
    output logic [7:0]  out_red,
    output logic [7:0]  out_green,
    output logic [7:0]  out_blue,
    output logic        out_ready
);
    
    // Extract the 8-bit channels from the 24-bit input bus
    logic [7:0] in_y, in_cb, in_cr;
    assign {in_y, in_cb, in_cr} = in_ycbcr;
    
    // Registered RGB outputs
    logic [7:0] r, g, b;
    
    // Signed variables for math (offset by 128 for Cb and Cr)
    logic signed [9:0] y_s, cb_s, cr_s;
    
    assign y_s  = $signed({1'b0, in_y});
    assign cb_s = $signed({1'b0, in_cb}) - 10'sd128;
    assign cr_s = $signed({1'b0, in_cr}) - 10'sd128;

    // 32-bit signed intermediates to prevent multiplier overflow 
    // before the bitwise shift back down to the 8-bit range.
    logic signed [31:0] r_calc, g_calc, b_calc;

    always_ff @(posedge clk) begin
        if (rst) begin
            out_ready <= 0;
            r  <= '0; 
            g  <= '0; 
            b  <= '0;
        end
        else if (in_ready) begin
            // Inverse YCbCr to RGB equations (multiplied by 256 for integer math)
            // R = Y + 1.402 * (Cr - 128)
            // G = Y - 0.344 * (Cb - 128) - 0.714 * (Cr - 128)
            // B = Y + 1.772 * (Cb - 128)
            
            r_calc = y_s + (( 359 * cr_s) >>> 8);
            g_calc = y_s - ((  88 * cb_s + 183 * cr_s) >>> 8);
            b_calc = y_s + (( 454 * cb_s) >>> 8);
            
            // Clamping logic: ensure outputs stay between 0 and 255
            r <= (r_calc < 0) ? 8'd0 : ((r_calc > 255) ? 8'd255 : r_calc[7:0]);
            g <= (g_calc < 0) ? 8'd0 : ((g_calc > 255) ? 8'd255 : g_calc[7:0]);
            b <= (b_calc < 0) ? 8'd0 : ((b_calc > 255) ? 8'd255 : b_calc[7:0]);

            out_ready <= 1;
        end
        else begin
            out_ready <= 0;
            r  <= '0; 
            g  <= '0; 
            b  <= '0;
        end
    end
    
    // Assign registered values to output ports
    assign out_red   = r;
    assign out_green = g;
    assign out_blue  = b;
    
endmodule