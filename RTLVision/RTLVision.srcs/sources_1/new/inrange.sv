`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.05.2026 19:18:51
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


module inrange(
    input  logic clk,
    input  logic rst,
    input  logic in_ready,
    input  logic [7:0] in_pixel, 
    input logic [7:0] lower_bound,
    input logic [7:0] upper_bound,
    output logic [7:0] out_pixel,
    output logic out_valid
);

always_ff @( posedge clk ) begin : blockName
    if ( rst ) begin
        out_pixel <= '0;
        out_valid <= 1'b0;
    end else if ( in_ready ) begin
        if (in_pixel >= lower_bound && in_pixel <= upper_bound) begin
            out_pixel <= 8'hFF; // Pixel is within the range, set to white
        end else begin
            out_pixel <= 8'h00; // Pixel is outside the range, set to black
        end
        out_valid <= 1'b1; // Output is valid
    end else begin
        out_valid <= 1'b0; // Output is not valid
    end
end

endmodule
