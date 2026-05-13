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
// Additional Comments: Pipelined
// 
//////////////////////////////////////////////////////////////////////////////////
module rgb_to_ycbcr(
    input  logic        clk,
    input  logic        rst,
    input  logic        in_ready,
    input  logic [7:0]  in_red,
    input  logic [7:0]  in_green,
    input  logic [7:0]  in_blue,
    output logic [23:0] out_ycbcr,
    output logic        out_valid
);
    
    // Stage 1: Input Registration (Making sure inputs are "ready")
    logic signed [9:0] r_s1, g_s1, b_s1;
    logic              vld1;

    always_ff @(posedge clk) begin
        if (rst) begin
            vld1 <= 1'b0;
        end else begin
            vld1 <= in_ready;
            r_s1 <= $signed({1'b0, in_red});
            g_s1 <= $signed({1'b0, in_green});
            b_s1 <= $signed({1'b0, in_blue});
        end
    end
    
    // Stage 2: Product Calculation (The "Heavy" Math)
    // We calculate the products and register them to break the timing path
    logic signed [17:0] y_prod, cb_prod, cr_prod;
    logic               vld2;

    always_ff @(posedge clk) begin
        vld2 <= vld1;
        if (vld1) begin
            y_prod  <= (77 * r_s1)  + (150 * g_s1) + (29 * b_s1);
            cb_prod <= (-43 * r_s1) - (85 * g_s1)  + (128 * b_s1);
            cr_prod <= (128 * r_s1) - (107 * g_s1) - (21 * b_s1);
        end
    end

    // Stage 3: Final Scaling, Offsets, and Packing
    logic [7:0] y_reg, cb_reg, cr_reg;
    
    always_ff @(posedge clk) begin
        if (rst) begin
            out_valid <= 1'b0;
        end else begin
            out_valid <= vld2;
            if (vld2) begin
                y_reg  <= y_prod[15:8];            // Logical shift right by 8
                cb_reg <= cb_prod[15:8] + 8'd128;  // Apply chrominance offset
                cr_reg <= cr_prod[15:8] + 8'd128;
            end
        end
    end

    assign out_ycbcr = {y_reg, cb_reg, cr_reg};
    
endmodule