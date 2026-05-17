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
`timescale 1ns / 1ps

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
    output logic out_clear_done, 

    // inquiry
    input  logic in_query_enable,
    input  logic [ADDR_WIDTH-1:0] in_query_pixel_addr,
    output logic [DATA_WIDTH-1:0] out_query_count,
    output logic out_query_valid
);

    // Memory declaration (Will infer as Distributed LUTRAM)
    logic [DATA_WIDTH-1:0] hist_mem [0:(1<<ADDR_WIDTH)-1];
    
    logic [ADDR_WIDTH-1:0] clear_addr;
    logic clearing;
    
    logic [ADDR_WIDTH-1:0] prev_gray;
    logic [DATA_WIDTH-1:0] count_plus_one;
    logic pipe_valid;

    always_ff @(posedge clk) begin
        if (rst) begin
            clearing       <= 1'b1;
            clear_addr     <= '0;
            out_clear_done <= 1'b0;
            out_query_valid    <= 1'b0;
            out_query_count    <= '0;
            pipe_valid     <= 1'b0;
            prev_gray      <= '0;
            count_plus_one <= '0;
        end else if (clearing) begin
            hist_mem[clear_addr] <= '0;
            clear_addr           <= clear_addr + 1'b1;
            if (clear_addr == (1<<ADDR_WIDTH)-1) begin
                clearing       <= 1'b0;
                out_clear_done <= 1'b1;
            end
        end else if (in_query_enable) begin
            out_query_count <= hist_mem[in_query_pixel_addr];
            out_query_valid <= 1'b1;
            pipe_valid  <= 1'b0;
        end else if (in_ready) begin
            out_query_valid <= 1'b0;
            out_query_count <= '0;
            
            // Read-Modify-Write Forwarding Logic
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
            pipe_valid  <= 1'b0;
            out_query_valid <= 1'b0;
            out_query_count <= '0;
        end
    end

    // 3. Pipeline Passthrough
    always_ff @(posedge clk) begin
        if (rst) begin
            out_gray  <= '0;
            out_valid <= 1'b0;
        end else begin
            out_gray  <= in_gray;
            out_valid <= in_ready && !clearing;
        end
    end

endmodule