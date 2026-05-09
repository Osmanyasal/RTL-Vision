`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Osman Yasal
// 
// Create Date: 04/24/2026 02:27:24 PM
// Design Name: 
// Module Name: sobel3x3
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

module sobel3x3 #(parameter IMG_WIDTH = 1024)(
    input  logic       clk,
    input  logic       rst,
    input  logic       ready_in,
    input  logic [7:0] gray_in,
    output logic [7:0] sobel_out,
    output logic       ready_out
);

    // ---------------------------------------------------------------------
    // 3x3 sliding-window line buffer
    // ---------------------------------------------------------------------
    logic [7:0] r_data [0:8];
    logic       window_valid;
    logic       win_full;

    fifo_pipeline2 #(
        .DATA_WIDTH(8),
        .DEPTH(IMG_WIDTH)
    ) u_window (
        .clk(clk),
        .rst(rst),
        .w_data(gray_in),
        .w_en(ready_in),
        .full(win_full),
        .r_en(1'b1),                
        .r_data(r_data),
        .out_data_valid(window_valid)
    );

    // ---------------------------------------------------------------------
    // Stage 1: Convolution (Gx, Gy)
    // ---------------------------------------------------------------------
    logic signed [11:0] gx_p1, gy_p1;
    logic               valid_p1;

    always_ff @(posedge clk) begin
        if (rst) begin
            gx_p1    <= 12'd0;
            gy_p1    <= 12'd0;
            valid_p1 <= 1'b0;
        end else begin
            // Shift the valid signal into Stage 1
            valid_p1 <= window_valid;
            
            // Only toggle data when valid to save dynamic power
            if (window_valid) begin
                gx_p1 <= -$signed({4'b0, r_data[0]})
                         +$signed({4'b0, r_data[2]})
                         -$signed({3'b0, r_data[3], 1'b0})    
                         +$signed({3'b0, r_data[5], 1'b0})    
                         -$signed({4'b0, r_data[6]})
                         +$signed({4'b0, r_data[8]});

                gy_p1 <= -$signed({4'b0, r_data[0]})
                         -$signed({3'b0, r_data[1], 1'b0})    
                         -$signed({4'b0, r_data[2]})
                         +$signed({4'b0, r_data[6]})
                         +$signed({3'b0, r_data[7], 1'b0})    
                         +$signed({4'b0, r_data[8]});
            end
        end
    end

    // ---------------------------------------------------------------------
    // Stage 2: Absolute Value & Magnitude
    // ---------------------------------------------------------------------
    logic [12:0] mag_p2;
    logic        valid_p2;

    always_ff @(posedge clk) begin
        if (rst) begin
            mag_p2   <= 13'd0;
            valid_p2 <= 1'b0;
        end else begin
            // Shift the valid signal into Stage 2
            valid_p2 <= valid_p1;
            
            if (valid_p1) begin
                // Compute absolute value combinatorially, then add and register it.
                // This fits easily within a 10ns clock cycle.
                mag_p2 <= (gx_p1[11] ? -gx_p1 : gx_p1) + 
                          (gy_p1[11] ? -gy_p1 : gy_p1);
            end
        end
    end

    // ---------------------------------------------------------------------
    // Stage 3: Output register (Clamp to 8 bits)
    // ---------------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (rst) begin
            sobel_out <= 8'd0;
            ready_out <= 1'b0;
        end else begin
            ready_out <= valid_p2;
            
            if (valid_p2) begin
                sobel_out <= (mag_p2 > 13'd255) ? 8'd255 : mag_p2[7:0];
            end
        end
    end

endmodule