`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/13/2026 11:39:37 AM
// Design Name: 
// Module Name: median3x3
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

module median3x3 #(parameter IMG_WIDTH = 1280)(
        input  logic clk,
        input  logic rst,
        input  logic in_valid,
        input  logic [7:0] in_pixel,
        output logic [7:0] out_pixel,
        output logic out_valid
    );
    
    // --- Window Signals ---
    logic [7:0] r_data [0:8];
    logic       window_valid;

    // --- Line Buffer / Window Generator ---
    fifo_pipeline2 #(
        .DATA_WIDTH(8),
        .DEPTH(IMG_WIDTH)
    ) u_window (
        .clk(clk),
        .rst(rst),
        .w_data(in_pixel),
        .w_en(in_valid),
        .r_en(1'b1),                
        .r_data(r_data),
        .out_data_valid(window_valid)
    );
    
    // -----------------------------------------------------------------
    // STAGE 1: Row Sorting
    // Logic: Sort pixels within each row to find their min, mid, and max.
    // -----------------------------------------------------------------
    logic [7:0] s1_lo0, s1_mi0, s1_hi0;
    logic [7:0] s1_lo1, s1_mi1, s1_hi1;
    logic [7:0] s1_lo2, s1_mi2, s1_hi2;
    logic       s1_valid;

    // Combinational outputs from Row Sorters
    logic [7:0] c_r0_lo, c_r0_mi, c_r0_hi;
    logic [7:0] c_r1_lo, c_r1_mi, c_r1_hi;
    logic [7:0] c_r2_lo, c_r2_mi, c_r2_hi;

    sort3 row0_sort (r_data[0], r_data[1], r_data[2], c_r0_lo, c_r0_mi, c_r0_hi);
    sort3 row1_sort (r_data[3], r_data[4], r_data[5], c_r1_lo, c_r1_mi, c_r1_hi);
    sort3 row2_sort (r_data[6], r_data[7], r_data[8], c_r2_lo, c_r2_mi, c_r2_hi);

    always_ff @(posedge clk) begin
        if (rst) s1_valid <= 1'b0;
        else     s1_valid <= window_valid;

        s1_lo0 <= c_r0_lo; s1_mi0 <= c_r0_mi; s1_hi0 <= c_r0_hi;
        s1_lo1 <= c_r1_lo; s1_mi1 <= c_r1_mi; s1_hi1 <= c_r1_hi;
        s1_lo2 <= c_r2_lo; s1_mi2 <= c_r2_mi; s1_hi2 <= c_r2_hi;
    end

    // -----------------------------------------------------------------
    // STAGE 2: Cross-Sorting
    // Logic: Find Max of Mins, Median of Mids, and Min of Maxes.
    // -----------------------------------------------------------------
    logic [7:0] s2_max_min, s2_mid_mid, s2_min_max;
    logic       s2_valid;

    // Combinational outputs for Cross Selection
    logic [7:0] c_max_min, c_mid_mid, c_min_max;
    logic [7:0] d1, d2, d3, d4; // Dummy wires for unused outputs

    // 1. Find Maximum of the three Minimums
    sort3 cross_lo (s1_lo0, s1_lo1, s1_lo2, d1, d2, c_max_min);
    // 2. Find Median of the three Mediums
    sort3 cross_mi (s1_mi0, s1_mi1, s1_mi2, d3, c_mid_mid, d4);
    // 3. Find Minimum of the three Maximums
    sort3 cross_hi (s1_hi0, s1_hi1, s1_hi2, c_min_max, d1, d2);

    always_ff @(posedge clk) begin
        if (rst) s2_valid <= 1'b0;
        else     s2_valid <= s1_valid;

        s2_max_min <= c_max_min;
        s2_mid_mid <= c_mid_mid;
        s2_min_max <= c_min_max;
    end

    // -----------------------------------------------------------------
    // STAGE 3: Final Median
    // Logic: The median of the 3 values from Stage 2 is the true median.
    // -----------------------------------------------------------------
    logic [7:0] c_final_median;

    sort3 final_sort (s2_max_min, s2_mid_mid, s2_min_max, d1, c_final_median, d2);

    always_ff @(posedge clk) begin
        if (rst) begin
            out_pixel <= 8'd0;
            out_valid <= 1'b0;
        end else begin
            out_pixel <= c_final_median;
            out_valid <= s2_valid;
        end
    end

endmodule