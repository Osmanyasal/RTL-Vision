`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.05.2026 18:45:34
// Design Name: 
// Module Name: threshold_adaptive_mean
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

module threshold_adaptive_mean #(parameter IMG_WIDTH = 1024)(
    input logic clk,
    input logic rst,
    input logic [7:0] in_gray,  
    input logic [7:0] thresh,   
    input logic in_ready,
    output logic[7:0] out_gray,
    output logic out_valid  
);
    logic [7:0] r_data [0:24];
    logic       window_valid;
    logic       win_full;

    fifo_pipeline5 #(
        .DATA_WIDTH(8),
        .DEPTH(IMG_WIDTH)
    ) u_window (
        .clk(clk),
        .rst(rst),
        .w_data(in_gray),
        .w_en(in_ready),
        .full(win_full),
        .r_en(1'b1),                // pull as soon as a window is ready
        .r_data(r_data),
        .out_data_valid(window_valid)
    );

    // --- PIPELINE REGISTERS FOR TIMING CLOSURE ---
    // Stage 1: Combinational Accumulator
    logic [12:0] sum_stage1; // 25 * 255 max = 6375 (fits in 13 bits)
    logic [7:0]  center_pixel_stage1;
    logic        val_stage1;

    // Stage 2: Fixed-Point Multiplier (Divide by 25 alternative)
    logic [7:0]  mean_stage2;
    logic [7:0]  center_pixel_stage2;
    logic        val_stage2;

    always_ff @( posedge clk ) begin
        if(rst) begin
            out_gray            <= 0;
            out_valid           <= 0;
            val_stage1          <= 0;
            val_stage2          <= 0;
            sum_stage1          <= 0;
            mean_stage2         <= 0;
            center_pixel_stage1 <= 0;
            center_pixel_stage2 <= 0;
        end
        else begin
            // Stage 1: Capture the window data and compute the sum
            val_stage1          <= window_valid;
            center_pixel_stage1 <= r_data[12]; // Center pixel of the 5x5 window
            sum_stage1          <= ({5'd0, r_data[0]}  + {5'd0, r_data[1]}  + {5'd0, r_data[2]}  + {5'd0, r_data[3]}  + {5'd0, r_data[4]}  +
                                    {5'd0, r_data[5]}  + {5'd0, r_data[6]}  + {5'd0, r_data[7]}  + {5'd0, r_data[8]}  + {5'd0, r_data[9]}  +
                                    {5'd0, r_data[10]} + {5'd0, r_data[11]} + {5'd0, r_data[12]} + {5'd0, r_data[13]} + {5'd0, r_data[14]} +
                                    {5'd0, r_data[15]} + {5'd0, r_data[16]} + {5'd0, r_data[17]} + {5'd0, r_data[18]} + {5'd0, r_data[19]} +
                                    {5'd0, r_data[20]} + {5'd0, r_data[21]} + {5'd0, r_data[22]} + {5'd0, r_data[23]} + {5'd0, r_data[24]});

            // Stage 2: Compute the mean and apply the threshold
            val_stage2          <= val_stage1;
            center_pixel_stage2 <= center_pixel_stage1;
            mean_stage2         <= (25'(sum_stage1) * 25'd2621) >> 16;
            
            // Stage 3: Output logic
            out_valid <= val_stage2;
            if (val_stage2) begin
                if ((9'(center_pixel_stage2) + 9'(thresh)) > 9'(mean_stage2)) begin
                    out_gray <= center_pixel_stage2; // Keep original pixel value if above threshold
                end else begin
                    out_gray <= 8'h00;               // Drop to black background
                end
            end else begin
                out_gray <= 8'h00;
            end
        end
    end
endmodule