`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Osman Yasal
// 
// Create Date: 05/12/2026 09:59:42 PM
// Design Name: 
// Module Name: salt_papper_noise
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

module salt_pepper_noise (
    input  logic        clk,
    input  logic        rst,
    
    // Pixel Stream Input
    input  logic        in_valid,
    input  logic [7:0]  in_red,
    input  logic [7:0]  in_green,
    input  logic [7:0]  in_blue,
    
    // Noise Configuration (0 = no noise, higher = more noise) (0 to 255)
    input  logic [7:0] noise_level, 
    
    // Pixel Stream Output
    output logic        out_valid,
    output logic [7:0]  out_red,
    output logic [7:0]  out_green,
    output logic [7:0]  out_blue
);

    // -----------------------------------------------------------------
    // 1. Linear Feedback Shift Register (LFSR)
    // -----------------------------------------------------------------
    logic [15:0] lfsr;
    logic        feedback;

    // Galois LFSR taps for 16-bit: 16, 14, 13, 11
    assign feedback = lfsr[15];

    always_ff @(posedge clk) begin
        if (rst) begin
            lfsr <= 16'hACE1; 
        end else if (in_valid) begin
            lfsr[15:1] <= lfsr[14:0];
            lfsr[0]    <= feedback;
            
            if (feedback) begin
                lfsr[13] <= lfsr[12] ^ 1'b1;
                lfsr[12] <= lfsr[11] ^ 1'b1;
                lfsr[10] <= lfsr[9]  ^ 1'b1;
            end
        end
    end

    // -----------------------------------------------------------------
    // 2. Noise Injection Logic (Pipelined)
    // -----------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (rst) begin
            out_valid <= 1'b0;
            out_red <= 8'h00;
            out_green <= 8'h00;
            out_blue <= 8'h00;
        end else begin
            out_valid <= in_valid;

            if (in_valid) begin
                if (lfsr[7:0] < noise_level) begin
                    if (lfsr[0] == 1'b1) begin
                        out_red <= 8'hFF; // Salt (White)
                        out_green <= 8'hFF; // Salt (White)
                        out_blue <= 8'hFF; // Salt (White)
                    end else begin
                        out_red <= 8'h00; // Pepper (Black)
                        out_green <= 8'h00; // Pepper (Black)
                        out_blue <= 8'h00; // Pepper (Black)
                    end
                end else begin
                    out_red <= in_red;
                    out_green <= in_green;
                    out_blue <= in_blue;
                end
            end
        end
    end

endmodule