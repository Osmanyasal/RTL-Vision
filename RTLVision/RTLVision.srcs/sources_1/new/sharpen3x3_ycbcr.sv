`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/01/2026 06:20:36 PM
// Design Name: 
// Module Name: sharpen3x3_ycbcr
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Y-channel spatial sharpening. 
//              WARNING: CbCr channels are NOT delayed. Output will exhibit 
//              a 1-line + 1-pixel diagonal chroma shift.
// 
//////////////////////////////////////////////////////////////////////////////////

module sharpen3x3_ycbcr #(parameter IMG_WIDTH = 1024)(
    input  logic        clk,
    input  logic        rst,
    input  logic        ready_in,
    input  logic [23:0] ycbcr_in,  // 24-bit packed vector {Y, Cb, Cr} 
    output logic [23:0] ycbcr_out, // 24-bit packed vector {Y, Cb, Cr} 
    output logic        ready_out
);
    
    logic [7:0] y;
    logic [7:0] r_data [0:8];
    logic       window_valid;
    logic       win_full;

    logic [10:0]        center_val;
    logic [9:0]         surround_val;
    logic signed [12:0] sharpened_y_raw; 

    // Extract Y component continuously
    assign y = ycbcr_in[23:16]; 

    fifo_pipeline2 #(
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

    // --- Combinational Math for Laplacian ---
    assign center_val   = ({3'b000, r_data[4]} << 2) + r_data[4]; 
    assign surround_val = {2'b00, r_data[1]} + {2'b00, r_data[3]} + 
                          {2'b00, r_data[5]} + {2'b00, r_data[7]};
    
    assign sharpened_y_raw  = $signed({2'b00, center_val}) - $signed({3'b000, surround_val});


    // --- Sequential Output & Clamping ---
    always_ff @(posedge clk) begin
        if(rst) begin
            ready_out <= 0;
            ycbcr_out <= 0;
        end
        else if(window_valid) begin
            
            // Procedural clipping
            if (sharpened_y_raw > 255) 
                ycbcr_out[23:16] <= 8'd255;
            else if (sharpened_y_raw < 0) 
                ycbcr_out[23:16] <= 8'd0;
            else 
                ycbcr_out[23:16] <= sharpened_y_raw[7:0]; 
            ycbcr_out[15:0] <= ycbcr_in[15:0];
            
            ready_out <= 1;
        end 
        else begin
            ready_out <= 0;
            ycbcr_out <= 0;
        end
    end
endmodule