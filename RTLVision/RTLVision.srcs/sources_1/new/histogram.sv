`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/13/2026 02:41:41 PM
// Design Name: 
// Module Name: histogram
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

module histogram #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32
)(
    input  logic clk,
    input  logic rst,
    input  logic in_ready,
    input  logic [ADDR_WIDTH-1:0] in_gray, 
    output logic [ADDR_WIDTH-1:0] out_gray,
    output logic out_valid,
    output logic clear_done // High when memory is ready for use
);

    // Memory declaration (Synthesizable as BRAM)
    logic [DATA_WIDTH-1:0] hist_mem [0:(1<<ADDR_WIDTH)-1];
    
    logic [ADDR_WIDTH-1:0] clear_addr;
    logic clearing;
    
    logic [ADDR_WIDTH-1:0] prev_gray;
    logic [DATA_WIDTH-1:0] count_plus_one;
    logic pipe_valid;

    // 1. Reset/Clear Logic
    always_ff @(posedge clk) begin
        if (rst) begin
            clearing   <= 1'b1;
            clear_addr <= '0;
            clear_done <= 1'b0;
        end else if (clearing) begin
            hist_mem[clear_addr] <= '0;
            clear_addr <= clear_addr + 1'b1;
            if (clear_addr == (1<<ADDR_WIDTH)-1) begin
                clearing   <= 1'b0;
                clear_done <= 1'b1;
            end
        end
    end

    // 2. Histogram Accumulation (Read-Modify-Write with Forwarding)
    always_ff @(posedge clk) begin
        if (!clearing && in_ready) begin
            // Stage 1: Read and Check for Hazard & apply forwarding
            if (pipe_valid && (in_gray == prev_gray)) begin
                hist_mem[in_gray] <= count_plus_one + 1'b1;
                count_plus_one    <= count_plus_one + 1'b1;
            end else begin
                hist_mem[in_gray] <= hist_mem[in_gray] + 1'b1;
                count_plus_one    <= hist_mem[in_gray] + 1'b1;
            end
            
            prev_gray  <= in_gray;
            pipe_valid <= 1'b1;
        end else begin
            pipe_valid <= 1'b0;
        end
    end

    // 3. Pipeline Passthrough
    always_ff @(posedge clk) begin
        out_gray  <= in_gray;
        out_valid <= in_ready && !clearing;
    end

endmodule
