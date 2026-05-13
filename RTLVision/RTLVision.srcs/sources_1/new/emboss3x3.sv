`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/13/2026 01:10:06 PM
// Design Name: 
// Module Name: emboss3x3
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

 
module emboss3x3 #(parameter IMG_WIDTH = 1024)(
    input  logic       clk,
    input  logic       rst,
    input  logic       in_ready,
    input  logic [7:0] in_blue,
    input  logic [7:0] in_green,
    input  logic [7:0] in_red,
    output logic [7:0] out_blue,
    output logic [7:0] out_green,
    output logic [7:0] out_red,
    output logic       out_valid
);

    // ---------------------------------------------------------------------
    // 3x3 sliding-window line buffer
    // ---------------------------------------------------------------------
    logic [7:0] red_data [0:8];
    logic [7:0] green_data [0:8];
    logic [7:0] blue_data [0:8];

    logic       window_red_valid;
    logic       window_green_valid;
    logic       window_blue_valid;
    logic       win_red_full;
    logic       win_green_full;
    logic       win_blue_full;

    fifo_pipeline2 #(
        .DATA_WIDTH(8),
        .DEPTH(IMG_WIDTH)
    ) u_window_blue (
        .clk(clk),
        .rst(rst),
        .w_data(in_blue),
        .w_en(in_ready),
        .full(win_blue_full),
        .r_en(1'b1),                
        .r_data(blue_data),
        .out_data_valid(window_blue_valid)
    );
    
    fifo_pipeline2 #(
        .DATA_WIDTH(8),
        .DEPTH(IMG_WIDTH)
    ) u_window_green (
        .clk(clk),
        .rst(rst),
        .w_data(in_green),
        .w_en(in_ready),
        .full(win_green_full),
        .r_en(1'b1),                
        .r_data(green_data),
        .out_data_valid(window_green_valid)
    );
    
    fifo_pipeline2 #(
        .DATA_WIDTH(8),
        .DEPTH(IMG_WIDTH)
    ) u_window_red (
        .clk(clk),
        .rst(rst),
        .w_data(in_red),
        .w_en(in_ready),
        .full(win_red_full),
        .r_en(1'b1),                
        .r_data(red_data),
        .out_data_valid(window_red_valid)
    );

    // ---------------------------------------------------------------------
    // Stage 1: Convolution  
    // ---------------------------------------------------------------------
    logic signed [11:0] emboss_red_value;
    logic signed [11:0] emboss_green_value;
    logic signed [11:0] emboss_blue_value;
    logic               valid_p1;
    logic current_window_valid;
    assign current_window_valid = window_red_valid & window_green_valid & window_blue_valid;

    always_ff @(posedge clk) begin
        if (rst) begin
            emboss_red_value    <= 12'd0; 
            emboss_green_value  <= 12'd0;
            emboss_blue_value   <= 12'd0;
            valid_p1 <= 1'b0;
        end else begin
            // Shift the valid signal into Stage 1
            valid_p1 <= current_window_valid;
            
            // Only toggle data when valid to save dynamic power
            if (current_window_valid) begin
                emboss_red_value <= -$signed({3'b0, red_data[0], 1'b0}) // *2
                         -$signed({4'b0, red_data[1]})
                         -$signed({4'b0, red_data[3]})    
                         +$signed({4'b0, red_data[4]})    
                         +$signed({4'b0, red_data[5]})
                         +$signed({4'b0, red_data[7]})
                         +$signed({3'b0, red_data[8], 1'b0}); // *2
                         
                emboss_green_value <= -$signed({3'b0, green_data[0], 1'b0}) // *2
                         -$signed({4'b0, green_data[1]})
                         -$signed({4'b0, green_data[3]})    
                         +$signed({4'b0, green_data[4]})    
                         +$signed({4'b0, green_data[5]})
                         +$signed({4'b0, green_data[7]})
                         +$signed({3'b0, green_data[8], 1'b0}); // *2

                emboss_blue_value <= -$signed({3'b0, blue_data[0], 1'b0}) // *2
                         -$signed({4'b0, blue_data[1]})
                         -$signed({4'b0, blue_data[3]})    
                         +$signed({4'b0, blue_data[4]})    
                         +$signed({4'b0, blue_data[5]})
                         +$signed({4'b0, blue_data[7]})
                         +$signed({3'b0, blue_data[8], 1'b0}); // *2
            end
        end
    end
 
    // ---------------------------------------------------------------------
    // Stage 2: Output register (Clamp to 8 bits)
    // ---------------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (rst) begin
            out_red   <= 8'd0;
            out_green <= 8'd0;
            out_blue  <= 8'd0;
            out_valid <= 1'b0;
        end else begin
            out_valid <= valid_p1; 
            
            if (valid_p1) begin
                if (emboss_blue_value > 12'd255) 
                    out_blue <= 8'd255;
                else if (emboss_blue_value < 12'd0)
                    out_blue <= 8'd0;
                else 
                    out_blue <= emboss_blue_value[7:0];

                if (emboss_green_value > 12'd255) 
                    out_green <= 8'd255;
                else if (emboss_green_value < 12'd0)
                    out_green <= 8'd0;
                else 
                    out_green <= emboss_green_value[7:0];

                if (emboss_red_value > 12'd255) 
                    out_red <= 8'd255;
                else if (emboss_red_value < 12'd0)
                    out_red <= 8'd0;
                else 
                    out_red <= emboss_red_value[7:0];

            end else begin
                out_blue <= 8'd0;
                out_green <= 8'd0;
                out_red <= 8'd0;
            end
        end
    end

endmodule
