`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Osman Yasal
// 
// Create Date: 05/02/2026 03:31:16 PM
// Design Name: 
// Module Name: blur3x3_ycbcr
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
 
module blur3x3_ycbcr #(parameter IMG_WIDTH = 1024)(
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

// 9 pixels * 255 = 2295 (Requires 12 bits)
    logic [11:0] window_sum; 
    
    // 2295 * 57 = 130815 (Requires 18 bits)
    logic [17:0] blurred_mult;
    
    logic [7:0] blurred_y_raw;

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

    // --- Combinational Math for Blur ---
    assign window_sum = {4'd0, r_data[0]} + {4'd0, r_data[1]} + {4'd0, r_data[2]} + 
                            {4'd0, r_data[3]} + {4'd0, r_data[4]} + {4'd0, r_data[5]} + 
                            {4'd0, r_data[6]} + {4'd0, r_data[7]} + {4'd0, r_data[8]};
    assign blurred_mult = window_sum * 18'd57;  // 1/9 ~= 57/512
    assign blurred_y_raw = blurred_mult[16:9];
    
    // --- Sequential Output & Clamping ---
    always_ff @(posedge clk) begin
        if(rst) begin
            ready_out <= 0;
            ycbcr_out <= 0;
        end
        else if(window_valid) begin
            
            // Procedural clipping
            if (blurred_y_raw > 255) 
                ycbcr_out[23:16] <= 8'd255;
            else if (blurred_y_raw < 0) 
                ycbcr_out[23:16] <= 8'd0;
            else 
                ycbcr_out[23:16] <= blurred_y_raw[7:0]; 
            ycbcr_out[15:0] <= ycbcr_in[15:0];
            
            ready_out <= 1;
        end 
        else begin
            ready_out <= 0;
            ycbcr_out <= 0;
        end
    end
endmodule