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
    localparam int COUNT_WIDTH = $clog2(FRAME_PIXELS + 1);
    localparam logic [ADDR_WIDTH-1:0] MAX_GRAY = {ADDR_WIDTH{1'b1}};
    localparam logic [COUNT_WIDTH-1:0] FRAME_PIXELS_CONST = FRAME_PIXELS;

    typedef enum logic [2:0] {
        ST_IDLE,
        ST_WAIT_QUERY,
        ST_PREPARE,
        ST_DIVIDE_CHECK,
        ST_DIVIDE,
        ST_COMMIT
    } state_t;

    state_t state;

    logic [ADDR_WIDTH-1:0] eq_lut [0:LUT_DEPTH-1];
    logic [ADDR_WIDTH-1:0] query_addr;
    logic [COUNT_WIDTH-1:0] cdf_accum;
    logic [COUNT_WIDTH-1:0] cdf_min;
    logic cdf_min_valid;

    logic [ADDR_WIDTH-1:0] resp_addr;
    logic [COUNT_WIDTH-1:0] resp_count;
    logic [COUNT_WIDTH-1:0] resp_cdf_accum;
    logic [COUNT_WIDTH-1:0] resp_cdf_min;
    logic resp_cdf_min_valid;

    logic [ADDR_WIDTH-1:0] calc_addr;
    logic [COUNT_WIDTH-1:0] calc_cdf_after;
    logic [COUNT_WIDTH-1:0] calc_cdf_min_next;
    logic calc_cdf_min_valid_next;
    logic calc_use_zero;
    logic calc_use_addr;
    logic [COUNT_WIDTH-1:0] calc_denominator;
    logic [COUNT_WIDTH+ADDR_WIDTH-1:0] calc_numerator;
    logic [COUNT_WIDTH-1:0] calc_cdf_span;

    logic [ADDR_WIDTH-1:0] commit_addr;
    logic [COUNT_WIDTH-1:0] commit_cdf_accum;
    logic [COUNT_WIDTH-1:0] commit_cdf_min;
    logic commit_cdf_min_valid;
    logic [ADDR_WIDTH-1:0] commit_mapped_gray;

    logic [COUNT_WIDTH+ADDR_WIDTH-1:0] divide_remainder;
    logic [COUNT_WIDTH+ADDR_WIDTH-1:0] divide_denominator;
    logic [ADDR_WIDTH-1:0] divide_result;
    logic divide_should_subtract;
    logic [ADDR_WIDTH-1:0] out_gray_stage;
    logic out_valid_stage;

    always_comb begin
        logic [COUNT_WIDTH-1:0] cdf_min_effective;

        calc_addr = resp_addr;
        calc_cdf_after = resp_cdf_accum + resp_count;
        calc_cdf_min_next = resp_cdf_min;
        calc_cdf_min_valid_next = resp_cdf_min_valid;
        calc_use_zero = 1'b0;
        calc_use_addr = 1'b0;
        calc_denominator = '0;
        calc_numerator = '0;
        calc_cdf_span = '0;

        if (!resp_cdf_min_valid && (resp_count != '0)) begin
            calc_cdf_min_next = calc_cdf_after;
            calc_cdf_min_valid_next = 1'b1;
        end

        cdf_min_effective = calc_cdf_min_valid_next ? calc_cdf_min_next : '0;
        calc_denominator = FRAME_PIXELS_CONST - cdf_min_effective;

        if (!calc_cdf_min_valid_next) begin
            calc_use_zero = 1'b1;
        end else if (FRAME_PIXELS_CONST <= cdf_min_effective) begin
            calc_use_addr = 1'b1;
        end else if (calc_cdf_after <= cdf_min_effective) begin
            calc_use_zero = 1'b1;
        end else begin
            calc_cdf_span = calc_cdf_after - cdf_min_effective;
            calc_numerator = ({calc_cdf_span, 8'b0} - calc_cdf_span);
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            state <= ST_IDLE;
            query_addr <= '0;
            cdf_accum <= '0;
            cdf_min <= '0;
            cdf_min_valid <= 1'b0;
            resp_addr <= '0;
            resp_count <= '0;
            resp_cdf_accum <= '0;
            resp_cdf_min <= '0;
            resp_cdf_min_valid <= 1'b0;
            commit_addr <= '0;
            commit_cdf_accum <= '0;
            commit_cdf_min <= '0;
            commit_cdf_min_valid <= 1'b0;
            commit_mapped_gray <= '0;
            divide_remainder <= '0;
            divide_denominator <= '0;
            divide_result <= '0;
            divide_should_subtract <= 1'b0;
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
                        state <= ST_PREPARE;
                        resp_addr <= query_addr;
                        resp_count <= in_hist_query_count[COUNT_WIDTH-1:0];
                        resp_cdf_accum <= cdf_accum;
                        resp_cdf_min <= cdf_min;
                        resp_cdf_min_valid <= cdf_min_valid;
                    end
                end

                ST_PREPARE: begin
                    out_lut_busy <= 1'b1;
                    commit_addr <= calc_addr;
                    commit_cdf_accum <= calc_cdf_after;
                    commit_cdf_min <= calc_cdf_min_next;
                    commit_cdf_min_valid <= calc_cdf_min_valid_next;

                    if (calc_use_zero) begin
                        commit_mapped_gray <= '0;
                        state <= ST_COMMIT;
                    end else if (calc_use_addr) begin
                        commit_mapped_gray <= calc_addr;
                        state <= ST_COMMIT;
                    end else begin
                        divide_remainder <= calc_numerator;
                        divide_denominator <= {{ADDR_WIDTH{1'b0}}, calc_denominator};
                        divide_result <= '0;
                        state <= ST_DIVIDE_CHECK;
                    end
                end

                ST_DIVIDE_CHECK: begin
                    out_lut_busy <= 1'b1;
                    divide_should_subtract <= (divide_remainder >= divide_denominator) && (divide_result != MAX_GRAY);
                    state <= ST_DIVIDE;
                end

                ST_DIVIDE: begin
                    out_lut_busy <= 1'b1;

                    if (divide_should_subtract) begin
                        divide_remainder <= divide_remainder - divide_denominator;
                        divide_result <= divide_result + 1'b1;
                        state <= ST_DIVIDE_CHECK;
                    end else begin
                        commit_mapped_gray <= divide_result;
                        state <= ST_COMMIT;
                    end
                end

                ST_COMMIT: begin
                    out_lut_busy <= 1'b1;
                    eq_lut[commit_addr] <= commit_mapped_gray;
                    cdf_accum <= commit_cdf_accum;
                    cdf_min <= commit_cdf_min;
                    cdf_min_valid <= commit_cdf_min_valid;

                    if (commit_addr == LUT_DEPTH - 1) begin
                        state <= ST_IDLE;
                        out_lut_busy <= 1'b0;
                        out_lut_done <= 1'b1;
                    end else begin
                        state <= ST_WAIT_QUERY;
                        query_addr <= commit_addr + 1'b1;
                        out_hist_query_enable <= 1'b1;
                        out_hist_query_addr <= commit_addr + 1'b1;
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
            out_gray_stage <= '0;
            out_valid_stage <= 1'b0;
            out_gray <= '0;
            out_valid <= 1'b0;
        end else begin
            if (in_ready && out_lut_done && !out_lut_busy) begin
                out_gray_stage <= eq_lut[in_gray];
                out_valid_stage <= 1'b1;
            end else begin
                out_gray_stage <= '0;
                out_valid_stage <= 1'b0;
            end

            out_gray <= out_gray_stage;
            out_valid <= out_valid_stage;
        end
    end

endmodule
