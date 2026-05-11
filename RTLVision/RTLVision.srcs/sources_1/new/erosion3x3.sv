`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Osman Yasal
// 
// Create Date: 05/11/2026 01:25:32 PM
// Design Name: 
// Module Name: erosion3x3
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


module erosion3x3 #(parameter IMG_WIDTH = 1280)(
        input logic clk,
        input logic rst,
        input logic in_valid,
        input logic [7:0] in_pixel,
        input logic [8:0] in_kernel,
        output logic [7:0] out_pixel,
        output logic out_valid
    );

    logic       pipeline_full;
    logic       pipeline_empty;
    logic       window_valid;
    logic [7:0] r_data [0:8];

    
    fifo_pipeline2 #(
        .DATA_WIDTH(8),
        .DEPTH(IMG_WIDTH)
    ) u_window (
        .clk(clk),
        .rst(rst),
        .w_data(in_pixel),
        .w_en(in_valid),
        .full(pipeline_full),
        .r_en(1'b1),                
        .r_data(r_data),
        .out_data_valid(window_valid)
    );
    
    // Combinational logic signals for the minimum tree
    logic [7:0] current_and;
    
    // -----------------------------------------------------------------
    // Combinational AND Tree with Dynamic Kernel Masking
    // -----------------------------------------------------------------
    always_comb begin
        // Initialize to 1 (True). A logical AND chain must start at 1.
        current_and = 8'b1111_1111; 
        
        for (int i = 0; i < 9; i++) begin
            // If the kernel bit is active, AND the current state with the pixel.
            // If the pixel is 0, it pulls the whole chain down to 0 permanently.
            if (in_kernel[i] == 1'b1) begin
                current_and = current_and & r_data[i]; 
            end
        end
    end

    // -----------------------------------------------------------------
    // Pipeline Output Register
    // -----------------------------------------------------------------
    always_ff @(posedge clk) begin
        if(rst) begin
            out_valid <= 0;
            out_pixel <= 0;
        end
        else if (window_valid) begin
            // Register the result of our combinational AND tree
            out_pixel <= current_and;
            out_valid <= 1'b1;
        end
        else begin
            out_valid <= 0;
            out_pixel <= 0;
        end
    end
endmodule
