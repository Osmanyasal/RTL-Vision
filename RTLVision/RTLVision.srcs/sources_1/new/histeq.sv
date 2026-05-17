`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.05.2026 13:29:40
// Design Name: 
// Module Name: histeq
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
module histeq #(
    parameter ADDR_WIDTH   = 8,
    parameter DATA_WIDTH   = 32,
    parameter FRAME_PIXELS = 1024 * 768
)(
    input  logic clk,
    input  logic rst,

    input  logic in_ready,
    input  logic [ADDR_WIDTH-1:0] in_gray,
    output logic [ADDR_WIDTH-1:0] out_gray,
    output logic out_valid,

    input  logic in_build_enable,
    output logic out_lut_busy,
    output logic out_lut_done,

    output logic out_hist_query_enable,
    output logic [ADDR_WIDTH-1:0] out_hist_query_addr,
    input  logic [DATA_WIDTH-1:0] in_hist_query_count,
    input  logic in_hist_query_valid
);

    localparam int LUT_DEPTH = (1 << ADDR_WIDTH);
    localparam logic [ADDR_WIDTH-1:0] MAX_GRAY = {ADDR_WIDTH{1'b1}};
    localparam logic [DATA_WIDTH:0] FRAME_PIXELS_CONST = FRAME_PIXELS;

    typedef enum logic [1:0] {
        ST_IDLE,
        ST_WAIT_QUERY
    } state_t;

    state_t state;

    logic [ADDR_WIDTH-1:0] eq_lut [0:LUT_DEPTH-1];
    logic [ADDR_WIDTH-1:0] query_addr;
    logic [DATA_WIDTH:0] cdf_accum;
    logic [DATA_WIDTH:0] cdf_min;
    logic cdf_min_valid;

    logic [DATA_WIDTH:0] cdf_after;
    logic [DATA_WIDTH:0] cdf_min_effective;
    logic [DATA_WIDTH:0] denominator;
    logic [DATA_WIDTH+ADDR_WIDTH:0] numerator;
    logic [ADDR_WIDTH-1:0] mapped_gray;

    assign cdf_after = cdf_accum + in_hist_query_count;
    assign cdf_min_effective = cdf_min_valid ? cdf_min : ((in_hist_query_count != '0) ? cdf_after : '0);
    assign denominator = FRAME_PIXELS_CONST - cdf_min_effective;
    assign numerator = (cdf_after - cdf_min_effective) * MAX_GRAY;

    always_comb begin
        mapped_gray = '0;

        if (!cdf_min_valid && (in_hist_query_count == '0)) begin
            mapped_gray = '0;
        end else if (FRAME_PIXELS_CONST <= cdf_min_effective) begin
            mapped_gray = query_addr;
        end else if (cdf_after <= cdf_min_effective) begin
            mapped_gray = '0;
        end else begin
            mapped_gray = numerator / denominator;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            state <= ST_IDLE;
            query_addr <= '0;
            cdf_accum <= '0;
            cdf_min <= '0;
            cdf_min_valid <= 1'b0;
            out_hist_query_enable <= 1'b0;
            out_hist_query_addr <= '0;
            out_lut_busy <= 1'b0;
            out_lut_done <= 1'b0;
        end else begin
            out_hist_query_enable <= 1'b0;

            case (state)
                ST_IDLE: begin
                    out_lut_busy <= 1'b0;

                    if (in_build_enable) begin
                        state <= ST_WAIT_QUERY;
                        query_addr <= '0;
                        cdf_accum <= '0;
                        cdf_min <= '0;
                        cdf_min_valid <= 1'b0;
                        out_lut_busy <= 1'b1;
                        out_lut_done <= 1'b0;
                        out_hist_query_enable <= 1'b1;
                        out_hist_query_addr <= '0;
                    end
                end

                ST_WAIT_QUERY: begin
                    out_lut_busy <= 1'b1;

                    if (in_hist_query_valid) begin
                        eq_lut[query_addr] <= mapped_gray;
                        cdf_accum <= cdf_after;

                        if (!cdf_min_valid && (in_hist_query_count != '0)) begin
                            cdf_min <= cdf_after;
                            cdf_min_valid <= 1'b1;
                        end

                        if (query_addr == LUT_DEPTH - 1) begin
                            state <= ST_IDLE;
                            out_lut_busy <= 1'b0;
                            out_lut_done <= 1'b1;
                        end else begin
                            query_addr <= query_addr + 1'b1;
                            out_hist_query_enable <= 1'b1;
                            out_hist_query_addr <= query_addr + 1'b1;
                        end
                    end
                end

                default: begin
                    state <= ST_IDLE;
                    out_lut_busy <= 1'b0;
                end
            endcase
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            out_gray <= '0;
            out_valid <= 1'b0;
        end else if (in_ready && out_lut_done && !out_lut_busy) begin
            out_gray <= eq_lut[in_gray];
            out_valid <= 1'b1;
        end else begin
            out_gray <= '0;
            out_valid <= 1'b0;
        end
    end

endmodule
