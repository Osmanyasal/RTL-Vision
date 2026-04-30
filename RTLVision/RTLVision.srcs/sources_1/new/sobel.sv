`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Osman Yasal
// 
// Create Date: 04/24/2026 02:27:24 PM
// Design Name: 
// Module Name: sobel
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

module sobel #(parameter IMG_WIDTH = 1024)(
    input  logic       clk,
    input  logic       rst,
    input  logic       ready_in,
    input  logic [7:0] gray_in,
    output logic [7:0] sobel_out,
    output logic       ready_out
    );

    // ---------------------------------------------------------------------
    // 3x3 sliding-window line buffer
    // r_data layout:
    //   [0] [1] [2]   <- row 0 (oldest line)
    //   [3] [4] [5]   <- row 1
    //   [6] [7] [8]   <- row 2 (newest line)
    // ---------------------------------------------------------------------
    logic [7:0] r_data [0:8];
    logic       window_valid;
    logic       win_full;

    fifo_pipeline #(
        .DATA_WIDTH(8),
        .DEPTH(IMG_WIDTH)
    ) u_window (
        .clk(clk),
        .rst(rst),
        .w_data(gray_in),
        .w_en(ready_in),
        .full(win_full),
        .r_en(1'b1),                // pull as soon as a window is ready
        .r_data(r_data),
        .out_data_valid(window_valid)
    );

    // ---------------------------------------------------------------------
    // Sobel kernels
    //   Gx = [-1  0 +1]      Gy = [-1 -2 -1]
    //        [-2  0 +2]           [ 0  0  0]
    //        [-1  0 +1]           [+1 +2 +1]
    // ---------------------------------------------------------------------
    logic signed [11:0] gx_c, gy_c;
    logic        [11:0] abs_gx_c, abs_gy_c;
    logic        [12:0] mag_c;

    always_comb begin
        gx_c =  -$signed({4'b0, r_data[0]})
                +$signed({4'b0, r_data[2]})
                -$signed({3'b0, r_data[3], 1'b0})    // -2 * r_data[3]
                +$signed({3'b0, r_data[5], 1'b0})    // +2 * r_data[5]
                -$signed({4'b0, r_data[6]})
                +$signed({4'b0, r_data[8]});

        gy_c =  -$signed({4'b0, r_data[0]})
                -$signed({3'b0, r_data[1], 1'b0})    // -2 * r_data[1]
                -$signed({4'b0, r_data[2]})
                +$signed({4'b0, r_data[6]})
                +$signed({3'b0, r_data[7], 1'b0})    // +2 * r_data[7]
                +$signed({4'b0, r_data[8]});

        abs_gx_c = gx_c[11] ? 12'(-gx_c) : 12'(gx_c);
        abs_gy_c = gy_c[11] ? 12'(-gy_c) : 12'(gy_c);
        mag_c    = abs_gx_c + abs_gy_c;            // |Gx| + |Gy| approximation
    end

    // ---------------------------------------------------------------------
    // Output register (clamp to 8 bits)
    // ready_out is the registered window_valid -> aligns with sobel_out.
    // ---------------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (rst) begin
            sobel_out <= 8'd0;
            ready_out <= 1'b0;
        end else begin
            sobel_out <= (mag_c > 13'd255) ? 8'd255 : mag_c[7:0];
            ready_out <= window_valid;
        end
    end

endmodule