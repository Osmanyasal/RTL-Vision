`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Osman Yasal
// 
// Create Date: 05/09/2026
// Design Name: 
// Module Name: blur5x5_ycbcr
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 5x5 box blur applied to the Y channel of a YCbCr stream.
// 
// Dependencies: fifo_pipeline5, sync_fifo
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module blur5x5_ycbcr #(parameter IMG_WIDTH = 1024)(
    input  logic        clk,
    input  logic        rst,
    input  logic        ready_in,
    input  logic [23:0] ycbcr_in,  // 24-bit packed vector {Y, Cb, Cr}
    output logic [23:0] ycbcr_out, // 24-bit packed vector {Y, Cb, Cr}
    output logic        ready_out
);

    logic [7:0] y;
    logic [7:0] r_data [0:24];
    logic       window_valid;
    logic       win_full;

    // 25 pixels * 255 = 6375 -> requires 13 bits
    logic [12:0] window_sum;

    // 1/25 approximated as 41/1024 (= 0.040039, error ~0.1%).
    // Max product: 6375 * 41 = 261,375 -> requires 18 bits.
    logic [17:0] blurred_mult;
    logic [7:0]  blurred_y_raw;

    // Extract Y component continuously
    assign y = ycbcr_in[23:16];

    fifo_pipeline5 #(
        .DATA_WIDTH(8),
        .DEPTH(IMG_WIDTH)
    ) u_window (
        .clk(clk),
        .rst(rst),
        .w_data(y),
        .w_en(ready_in),
        .full(win_full),
        .r_en(1'b1),
        .r_data(r_data),
        .out_data_valid(window_valid)
    );

    // --- Combinational Math for 5x5 Box Blur ---
    assign window_sum =
        {5'd0, r_data[0]}  + {5'd0, r_data[1]}  + {5'd0, r_data[2]}  + {5'd0, r_data[3]}  + {5'd0, r_data[4]}  +
        {5'd0, r_data[5]}  + {5'd0, r_data[6]}  + {5'd0, r_data[7]}  + {5'd0, r_data[8]}  + {5'd0, r_data[9]}  +
        {5'd0, r_data[10]} + {5'd0, r_data[11]} + {5'd0, r_data[12]} + {5'd0, r_data[13]} + {5'd0, r_data[14]} +
        {5'd0, r_data[15]} + {5'd0, r_data[16]} + {5'd0, r_data[17]} + {5'd0, r_data[18]} + {5'd0, r_data[19]} +
        {5'd0, r_data[20]} + {5'd0, r_data[21]} + {5'd0, r_data[22]} + {5'd0, r_data[23]} + {5'd0, r_data[24]};

    assign blurred_mult  = window_sum * 18'd41;   // 1/25 ~= 41/1024
    assign blurred_y_raw = blurred_mult[17:10];

    // --- Sequential Output & Clamping ---
    always_ff @(posedge clk) begin
        if (rst) begin
            ready_out <= 0;
            ycbcr_out <= 0;
        end
        else if (window_valid) begin
            // Procedural clipping
            if (blurred_y_raw > 8'd255)
                ycbcr_out[23:16] <= 8'd255;
            else
                ycbcr_out[23:16] <= blurred_y_raw[7:0];

            ycbcr_out[15:0] <= ycbcr_in[15:0];
            ready_out       <= 1;
        end
        else begin
            ready_out <= 0;
            ycbcr_out <= 0;
        end
    end
endmodule
