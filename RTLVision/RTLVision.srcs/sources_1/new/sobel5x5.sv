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
       // ---------------------------------------------------------------------
    // Stage 1: The Convolution (Calculate Gx and Gy)
    // ---------------------------------------------------------------------
    logic signed [24:0] gx_p1, gy_p1;
    logic               valid_p1;

    function automatic logic signed [24:0] pix_s(input logic [7:0] pixel);
        pix_s = $signed({17'b0, pixel});
    endfunction

    always_ff @(posedge clk) begin
        if (rst) begin
            gx_p1    <= '0;
            gy_p1    <= '0;
            valid_p1 <= 1'b0;
        end else begin
            // Shift the valid signal into stage 1
            valid_p1 <= window_valid; 
            
            if (window_valid) begin
                // The synthesis tool will easily route this single stage of math
                gx_p1 <=  - pix_s(r_data[0])
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

                gy_p1 <=  - pix_s(r_data[0])
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
            end
        end
    end

    // ---------------------------------------------------------------------
    // Stage 2: Absolute Value and Magnitude
    // ---------------------------------------------------------------------
    logic [24:0] mag_p2;
    logic        valid_p2;

    always_ff @(posedge clk) begin
        if (rst) begin
            mag_p2   <= '0;
            valid_p2 <= 1'b0;
        end else begin
            // Shift the valid signal into stage 2
            valid_p2 <= valid_p1;
            
            if (valid_p1) begin
                // Compute |Gx| + |Gy|
                mag_p2 <= (gx_p1[24] ? $unsigned(-gx_p1) : $unsigned(gx_p1)) + 
                          (gy_p1[24] ? $unsigned(-gy_p1) : $unsigned(gy_p1));
            end
        end
    end

    // ---------------------------------------------------------------------
    // Stage 3: Output Register (Clamp to 8 bits)
    // ---------------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (rst) begin
            sobel_out <= 8'd0;
            ready_out <= 1'b0;
        end else begin
            // Shift the valid signal to the final output
            ready_out <= valid_p2;
            
            if (valid_p2) begin
                sobel_out <= (mag_p2 > 25'd255) ? 8'd255 : mag_p2[7:0];
            end
        end
    end

endmodule