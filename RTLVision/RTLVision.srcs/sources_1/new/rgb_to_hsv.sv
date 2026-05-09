`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/09/2026 10:21:21 PM
// Design Name: 
// Module Name: rgb_to_hsv
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


module rgb_to_hsv( 
    input  logic        clk,
    input  logic        rst,            
    input  logic        ready_in,       // Pipeline valid input
    input  logic [7:0]  red_in,
    input  logic [7:0]  green_in,
    input  logic [7:0]  blue_in,
    output logic [7:0]  hue_out,        
    output logic [7:0]  saturation_out, 
    output logic [7:0]  value_out,      
    output logic        ready_out       // Pipeline valid output
);

    // ---------------------------------------------------------
    // Reciprocal ROM Definition
    // Stores (1 << 16) / x to turn division into multiplication
    // ---------------------------------------------------------
    logic [15:0] inv_table [0:255];
    initial begin
        inv_table[0] = 16'd0; // Prevent divide by zero corruption
        for (int i = 1; i <= 255; i++) begin
            inv_table[i] = (1 << 16) / i;
        end
    end

    // ---------------------------------------------------------
    // Stage 0: Combinatorial Extrema & Difference 
    // ---------------------------------------------------------
    logic [7:0] cmax_c, cmin_c, delta_c;
    logic [1:0] max_color_c; // 0=Red, 1=Green, 2=Blue
    logic signed [9:0] hue_diff_c;

    always_comb begin
        // Find Max
        if (red_in >= green_in && red_in >= blue_in) begin
            cmax_c = red_in; max_color_c = 2'd0;
        end else if (green_in >= red_in && green_in >= blue_in) begin
            cmax_c = green_in; max_color_c = 2'd1;
        end else begin
            cmax_c = blue_in; max_color_c = 2'd2;
        end

        // Find Min
        if (red_in <= green_in && red_in <= blue_in) begin
            cmin_c = red_in;
        end else if (green_in <= red_in && green_in <= blue_in) begin
            cmin_c = green_in;
        end else begin
            cmin_c = blue_in;
        end
        
        delta_c = cmax_c - cmin_c;

        // Calculate raw hue difference based on dominant color
        case (max_color_c)
            2'd0: hue_diff_c = $signed({1'b0, green_in}) - $signed({1'b0, blue_in});
            2'd1: hue_diff_c = $signed({1'b0, blue_in})  - $signed({1'b0, red_in});
            2'd2: hue_diff_c = $signed({1'b0, red_in})   - $signed({1'b0, green_in});
            default: hue_diff_c = '0;
        endcase
    end

    // ---------------------------------------------------------
    // Stage 1: Register Inputs, Prepare Numerators, Read ROM
    // ---------------------------------------------------------
    logic        vld1;
    logic [7:0]  cmax1, delta1;
    logic [1:0]  max_color1;
    logic [15:0] sat_num1;
    logic signed [15:0] hue_num1; 
    logic [15:0] inv_cmax1;
    logic [15:0] inv_delta1;

    always_ff @(posedge clk) begin
        if (rst) begin
            vld1 <= 1'b0;
        end else begin
            vld1 <= ready_in;
            if (ready_in) begin
                cmax1      <= cmax_c;
                delta1     <= delta_c;
                max_color1 <= max_color_c;
                
                // Saturation Numerator: Delta * 255
                // Trick: Delta * 255 == (Delta << 8) - Delta
                sat_num1   <= {delta_c, 8'd0} - delta_c; 
                
                // Hue Numerator: Diff * 43 
                // 43 is approx 256/6, scaling the 360 degree circle to 8-bit space
                hue_num1   <= hue_diff_c * 16'sd43;

                // Trigger ROM reads (Vivado infers BRAM or distributed RAM here)
                inv_cmax1  <= inv_table[cmax_c];
                inv_delta1 <= inv_table[delta_c];
            end
        end
    end

    // ---------------------------------------------------------
    // Stage 2: Multiply Numerators by Reciprocals (DSP Stage)
    // ---------------------------------------------------------
    logic        vld2;
    logic [7:0]  cmax2, delta2;
    logic [1:0]  max_color2;
    logic [31:0] sat_mult2;
    logic signed [31:0] hue_mult2;

    always_ff @(posedge clk) begin
        if (rst) begin
            vld2 <= 1'b0;
        end else begin
            vld2 <= vld1;
            if (vld1) begin
                cmax2      <= cmax1;
                delta2     <= delta1;
                max_color2 <= max_color1;
                
                // Unsigned multiplication for saturation
                sat_mult2  <= sat_num1 * inv_cmax1;
                
                // Signed multiplication for hue
                // Force inv_delta1 to be treated as a positive signed value
                hue_mult2  <= hue_num1 * $signed({1'b0, inv_delta1});
            end
        end
    end

    // ---------------------------------------------------------
    // Stage 3: Apply Shifts and Hue Offsets
    // ---------------------------------------------------------
    always_ff @(posedge clk) begin
        if (rst) begin
            ready_out <= 1'b0;
            hue_out   <= '0;
            saturation_out <= '0;
            value_out <= '0;
        end else begin
            ready_out <= vld2;
            if (vld2) begin
                // 1. Value Calculation
                value_out <= cmax2;

                // 2. Saturation Calculation
                if (cmax2 == 0) begin
                    saturation_out <= 8'd0;
                end else begin
                    // Equivalent to dividing by 65536
                    saturation_out <= sat_mult2[23:16];
                end

                // 3. Hue Calculation
                if (delta2 == 0) begin
                    hue_out <= 8'd0;
                end else begin
                    // Shift signed result right by 16 bits
                    logic signed [15:0] hue_base;
                    hue_base = hue_mult2 >>> 16;
                    
                    // Apply phase offsets (85 = 120 deg, 171 = 240 deg)
                    // Standard 8-bit unsigned addition naturally handles negative wrap-around
                    case (max_color2)
                        2'd0: hue_out <= hue_base[7:0];                 
                        2'd1: hue_out <= 8'd85  + hue_base[7:0];        
                        2'd2: hue_out <= 8'd171 + hue_base[7:0];        
                        default: hue_out <= '0;
                    endcase
                end
            end
        end
    end

endmodule