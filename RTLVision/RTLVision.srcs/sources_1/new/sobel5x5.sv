`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/09/2026 08:43:06 PM
// Design Name: 
// Module Name: sobel5x5
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


module sobel5x5 #(parameter IMG_WIDTH = 1024)(
    input  logic       clk,
    input  logic       rst,
    input  logic       ready_in,
    input  logic [7:0] gray_in,
    output logic [7:0] sobel_out,
    output logic       ready_out
    );

    // ---------------------------------------------------------------------
    // 5x5 sliding-window line buffer
    // r_data layout:
    //   [0]  [1]  [2] [3] [4]   <- row 0 (oldest line)
    //   [5]  [6]  [7] [8] [9]   <- row 1
    //   [10] [11] [12] [13] [14] <- row 2 (middle line)
    //   [15] [16] [17] [18] [19] <- row 3 
    //   [20] [21] [22] [23] [24] <- row 4 (newest line)
    // ---------------------------------------------------------------------
    logic [7:0] r_data [0:24];
    logic       window_valid;
    logic       win_full;

    fifo_pipeline5 #(
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
    //   Gx = [-1 -2  0 +2 +1]      Gy = [-1 -4 -6  -4 -1]
    //        [-4 -8  0 +8 +4]           [-2 -8 -12 -8 -2]
    //        [-6 -12 0 +12 +6]          [ 0  0  0   0  0]
    //        [-4 -8  0 +8 +4]           [+2 +8 +12 +8 +2]
    //        [-1 -2  0 +2 +1]           [+1 +4 +6  +4 +1]
    // ---------------------------------------------------------------------
        logic signed [24:0] gx_c, gy_c;
        logic        [24:0] abs_gx_c, abs_gy_c;
        logic        [24:0] mag_c;

        function automatic logic signed [24:0] pix_s(input logic [7:0] pixel);
        pix_s = $signed({17'b0, pixel});
        endfunction

    always_comb begin
        gx_c =  - pix_s(r_data[0])
            - (pix_s(r_data[1]) <<< 1)
            + (pix_s(r_data[3]) <<< 1)
            + pix_s(r_data[4])

            - (pix_s(r_data[5]) <<< 2)
            - (pix_s(r_data[6]) <<< 3)
            + (pix_s(r_data[8]) <<< 3)
            + (pix_s(r_data[9]) <<< 2)

            - ((pix_s(r_data[10]) <<< 2) + (pix_s(r_data[10]) <<< 1))
            - ((pix_s(r_data[11]) <<< 3) + (pix_s(r_data[11]) <<< 2))
            + ((pix_s(r_data[13]) <<< 3) + (pix_s(r_data[13]) <<< 2))
            + ((pix_s(r_data[14]) <<< 2) + (pix_s(r_data[14]) <<< 1))

            - (pix_s(r_data[15]) <<< 2)
            - (pix_s(r_data[16]) <<< 3)
            + (pix_s(r_data[18]) <<< 3)
            + (pix_s(r_data[19]) <<< 2)

            - pix_s(r_data[20])
            - (pix_s(r_data[21]) <<< 1)
            + (pix_s(r_data[23]) <<< 1)
            + pix_s(r_data[24]);

        gy_c =  - pix_s(r_data[0])
            - (pix_s(r_data[1]) <<< 2)
            - ((pix_s(r_data[2]) <<< 2) + (pix_s(r_data[2]) <<< 1))
            - (pix_s(r_data[3]) <<< 2)
            - pix_s(r_data[4])

            - (pix_s(r_data[5]) <<< 1)
            - (pix_s(r_data[6]) <<< 3)
            - ((pix_s(r_data[7]) <<< 3) + (pix_s(r_data[7]) <<< 2))
            - (pix_s(r_data[8]) <<< 3)
            - (pix_s(r_data[9]) <<< 1)

            + (pix_s(r_data[15]) <<< 1)
            + (pix_s(r_data[16]) <<< 3)
            + ((pix_s(r_data[17]) <<< 3) + (pix_s(r_data[17]) <<< 2))
            + (pix_s(r_data[18]) <<< 3)
            + (pix_s(r_data[19]) <<< 1)

            + pix_s(r_data[20])
            + (pix_s(r_data[21]) <<< 2)
            + ((pix_s(r_data[22]) <<< 2) + (pix_s(r_data[22]) <<< 1))
            + (pix_s(r_data[23]) <<< 2)
            + pix_s(r_data[24]);

        abs_gx_c = gx_c[24] ? $unsigned(-gx_c) : $unsigned(gx_c);
        abs_gy_c = gy_c[24] ? $unsigned(-gy_c) : $unsigned(gy_c);
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
            sobel_out <= (mag_c > 25'd255) ? 8'd255 : mag_c[7:0];
            ready_out <= window_valid;
        end
    end

endmodule