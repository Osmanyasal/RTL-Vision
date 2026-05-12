`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Osman Yasal
// 
// Create Date: 05/11/2026 01:25:32 PM
// Design Name: 
// Module Name: dilation5x5
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


module dilation5x5 #(parameter IMG_WIDTH = 1280)(
        input logic clk,
        input logic rst,
        input logic in_valid,
        input logic [7:0] in_pixel,
        input logic [24:0] in_kernel,
        output logic [7:0] out_pixel,
        output logic out_valid
    );
    
    logic [7:0] r_data [0:24];
    logic       pipeline_full;
    logic       pipeline_empty;
    logic       window_valid;

    
    fifo_pipeline5 #(
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
    logic [7:0] current_or;
    
    // -----------------------------------------------------------------
    // Combinational OR Tree with Dynamic Kernel Masking
    // -----------------------------------------------------------------
    always_comb begin
        // Initialize to 0 (False). A logical OR chain must start at 0.
        current_or = 8'b0000_0000; 
        
        for (int i = 0; i < 25; i++) begin
            // If the kernel bit is active, OR the current state with the pixel.
            // If the pixel is 0, it pulls the whole chain down to 0 permanently.
            if (in_kernel[i] == 1'b1) begin
                current_or = current_or | r_data[i];
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
            out_pixel <= current_or;
            out_valid <= 1'b1;
        end
        else begin
            out_valid <= 0;
            out_pixel <= 0;
        end
    end
endmodule
