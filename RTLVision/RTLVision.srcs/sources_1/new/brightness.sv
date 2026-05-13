`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.05.2026 15:43:50
// Design Name: 
// Module Name: brightness
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

module brightness(
    input  logic        clk,
    input  logic        rst,
    input  logic        in_ready,
    input  logic signed [7:0] brightness_factor, 
    input  logic [7:0]  in_red,
    input  logic [7:0]  in_green,
    input  logic [7:0]  in_blue,
    output logic [7:0]  out_red,
    output logic [7:0]  out_green,
    output logic [7:0]  out_blue,
    output logic        out_ready
);

    logic [23:0] ycbcr_raw;
    logic        out_ready_ycbcr;
    
    // Internal registers for the adjusted Y and control
    logic [7:0]  sy_reg;
    logic [7:0]  cb_reg, cr_reg;
    logic        pipe_ready;

    // 1. RGB to YCbCr Conversion
    rgb_to_ycbcr u_rgb_to_ycbcr (
        .clk(clk),
        .rst(rst),
        .in_ready(in_ready),
        .in_red(in_red),
        .in_green(in_green),
        .in_blue(in_blue),
        .out_ycbcr(ycbcr_raw),
        .out_ready(out_ready_ycbcr)
    );

    // 2. Brightness Adjustment with Saturation 
    logic signed [9:0] y_calc;
    assign y_calc = $signed({2'b0, ycbcr_raw[23:16]}) + brightness_factor;
     
    always_ff @(posedge clk) begin
        if (rst) begin
            pipe_ready <= 1'b0;
            sy_reg     <= 8'd0;
            cb_reg     <= 8'd0;
            cr_reg     <= 8'd0;
        end else begin
            // Pulse the ready signal for exactly one cycle
            pipe_ready <= out_ready_ycbcr;

            if (out_ready_ycbcr) begin
                // Saturation Logic (Clip to 0-255)
                if (y_calc > 10'sd255) 
                    sy_reg <= 8'd255;
                else if (y_calc < 10'sd0) 
                    sy_reg <= 8'd0;
                else 
                    sy_reg <= y_calc[7:0];

                // Pass through Chroma components
                cb_reg <= ycbcr_raw[15:8];
                cr_reg <= ycbcr_raw[7:0];
            end
        end
    end

    // 3. YCbCr back to RGB
    ycbcr_to_rgb u_ycbcr_to_rgb (
        .clk(clk),
        .rst(rst),
        .in_ready(pipe_ready),
        .in_ycbcr({sy_reg, cb_reg, cr_reg}),
        .out_red(out_red),
        .out_green(out_green),
        .out_blue(out_blue),
        .out_ready(out_ready)
    );

endmodule