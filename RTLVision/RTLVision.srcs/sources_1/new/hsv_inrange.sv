`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.05.2026 19:24:47
// Design Name: 
// Module Name: hsv_inrange
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

`timescale 1ns / 1ps
module hsv_inrange(
    input  logic        clk,
    input  logic        rst,
    input  logic        in_ready,
    input  logic [7:0]  in_blue, 
    input  logic [7:0]  in_green, 
    input  logic [7:0]  in_red, 
    
    // Direct inputs straight from standard color pickers!
    input  logic [8:0]  h_low,  h_high,  // 0 to 359
    input  logic [6:0]  s_low,  s_high,  // 0 to 100
    input  logic [6:0]  v_low,  v_high,  // 0 to 100
    
    output logic [7:0]  out_pixel,
    output logic        out_valid
);

    logic [8:0] out_hue;
    logic [6:0] out_saturation;
    logic [6:0] out_value;
    logic       out_hsv_valid;

    // Instance connected to upgraded ranges
    rgb_to_hsv rgb_to_hsv_inst (
        .clk(clk),
        .rst(rst),
        .in_ready(in_ready),
        .in_blue(in_blue),
        .in_green(in_green),
        .in_red(in_red),
        .out_hue(out_hue), 
        .out_saturation(out_saturation),
        .out_value(out_value), 
        .out_valid(out_hsv_valid)
    );

    // Dynamic handling of color picker wrap-around (e.g. Red limits 350 -> 10)
    logic hue_match;
    always_comb begin
        if (h_low <= h_high) begin
            hue_match = (out_hue >= h_low) && (out_hue <= h_high);
        end else begin
            hue_match = (out_hue >= h_low) || (out_hue <= h_high);
        end
    end

    // Sequential thresholding decision
    always_ff @(posedge clk) begin
        if (rst) begin
            out_pixel <= 8'h00;
            out_valid <= 1'b0;
        end else if (out_hsv_valid) begin
            if (hue_match &&
                (out_saturation >= s_low && out_saturation <= s_high) &&
                (out_value      >= v_low && out_value      <= v_high)) begin
                
                out_pixel <= 8'hFF; // Matches range (White)
            end else begin
                out_pixel <= 8'h00; // Outside range (Black)
            end
            out_valid <= 1'b1;
        end else begin
            out_valid <= 1'b0;
            out_pixel <= 8'h00; 
        end
    end
endmodule