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
// Additional Comments: Pipelined
// 
//////////////////////////////////////////////////////////////////////////////////

module rgb_to_hsv( 
    input  logic        clk,
    input  logic        rst,            
    input  logic        in_ready,       
    input  logic [7:0]  in_red,
    input  logic [7:0]  in_green,
    input  logic [7:0]  in_blue,
    output logic [8:0]  out_hue,         // UPGRADED: 9-bit (0-359)
    output logic [6:0]  out_saturation,  // UPGRADED: 7-bit (0-100)
    output logic [6:0]  out_value,       // UPGRADED: 7-bit (0-100)
    output logic        out_valid       
);

    // 17-bit Reciprocal ROM to prevent overflow at i=1
    logic [16:0] inv_table [0:255];
    initial begin
        inv_table[0] = 17'd0; 
        for (int i = 1; i <= 255; i++) begin
            inv_table[i] = (1 << 16) / i;
        end
    end

    // Stage 0 Signals
    logic [7:0] cmax_c, cmin_c, delta_c;
    logic [1:0] max_color_c; 
    logic signed [9:0] hue_diff_c;

    always_comb begin
        if (in_red >= in_green && in_red >= in_blue) begin
            cmax_c = in_red; max_color_c = 2'd0;
        end else if (in_green >= in_red && in_green >= in_blue) begin
            cmax_c = in_green; max_color_c = 2'd1;
        end else begin
            cmax_c = in_blue; max_color_c = 2'd2;
        end

        if (in_red <= in_green && in_red <= in_blue)       cmin_c = in_red;
        else if (in_green <= in_red && in_green <= in_blue) cmin_c = in_green;
        else                                                cmin_c = in_blue;
        
        delta_c = cmax_c - cmin_c;

        case (max_color_c)
            2'd0: hue_diff_c = $signed({1'b0, in_green}) - $signed({1'b0, in_blue});
            2'd1: hue_diff_c = $signed({1'b0, in_blue})  - $signed({1'b0, in_red});
            2'd2: hue_diff_c = $signed({1'b0, in_red})   - $signed({1'b0, in_green});
            default: hue_diff_c = '0;
        endcase
    end

    // Stage 1 Registers
    logic        vld1;
    logic [7:0]  cmax1, delta1;
    logic [1:0]  max_color1;
    logic [15:0] sat_num1;
    logic signed [15:0] hue_num1; 
    logic [16:0] inv_cmax1;
    logic [16:0] inv_delta1;

    always_ff @(posedge clk) begin
        if (rst) begin
            vld1 <= 1'b0;
        end else begin
            vld1 <= in_ready;
            if (in_ready) begin
                cmax1      <= cmax_c;
                delta1     <= delta_c;
                max_color1 <= max_color_c;
                
                // Saturation Numerator: Delta * 100 (for 0-100%)
                sat_num1   <= delta_c * 7'd100; 
                
                // Hue Numerator: Diff * 60 (for true 0-60 degree sectors)
                hue_num1   <= hue_diff_c * 16'sd60;

                inv_cmax1  <= inv_table[cmax_c];
                inv_delta1 <= inv_table[delta_c];
            end
        end
    end

    // Stage 2 Registers
    logic        vld2;
    logic [7:0]  cmax2;
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
                max_color2 <= max_color1;
                
                sat_mult2  <= sat_num1 * inv_cmax1;
                hue_mult2  <= hue_num1 * $signed({1'b0, inv_delta1});
            end
        end
    end

    // Stage 3: Output Formatting
    always_ff @(posedge clk) begin
        if (rst) begin
            out_valid <= 1'b0;
            out_hue   <= '0;
            out_saturation <= '0;
            out_value <= '0;
        end else begin
            out_valid <= vld2;
            if (vld2) begin
                // 1. Value Calculation (Scale 0-255 down to 0-100%)
                // 25700 / 65536 is structurally equivalent to multiplying by 100/255
                out_value <= (cmax2 * 16'd25700 + 32'd32768) >> 16;

                // 2. Saturation Calculation (0-100%)
                if (cmax2 == 0) begin
                    out_saturation <= 7'd0;
                end else begin
                    out_saturation <= (sat_mult2 + 32'd32768) >> 16;
                end

                // 3. Hue Calculation (0-359 Degrees)
                if (delta1 == 0) begin
                    out_hue <= 9'd0;
                end else begin
                    logic signed [15:0] hue_base;
                    hue_base = (hue_mult2 + 32'sd32768) >>> 16;
                    
                    case (max_color2)
                        2'd0: begin // Red Sector
                            if (hue_base < 0) out_hue <= 9'd360 + hue_base; // Handles the 356 deg wrap cleanly
                            else              out_hue <= hue_base[8:0];
                        end                 
                        2'd1: out_hue <= 9'd120 + hue_base; // Green offset       
                        2'd2: out_hue <= 9'd240 + hue_base; // Blue offset       
                        default: out_hue <= '0;
                    endcase
                end
            end
        end
    end
endmodule