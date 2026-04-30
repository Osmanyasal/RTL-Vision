`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Osman Yasal
// 
// Create Date: 04/25/2026 11:16:10 AM
// Design Name: 
// Module Name: sync_fifo
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


module sync_fifo #(parameter DATA_WIDTH = 8, parameter DEPTH = 16, parameter ADDR_WIDTH=$clog2(DEPTH))(
    input logic clk,
    input logic rst,
    
    // write interface
    input logic [DATA_WIDTH-1 : 0] w_data,
    input logic w_en,
    output logic full,
    
    // read interface
    input logic r_en,
    output logic empty,
    output logic [DATA_WIDTH-1:0] r_data
    );
    
    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    logic [ADDR_WIDTH:0] w_ptr, r_ptr; // extra bit for full/empty detection
    
    // Full and Empty Flags
    assign empty = (w_ptr == r_ptr);
    assign full  = (w_ptr[ADDR_WIDTH] != r_ptr[ADDR_WIDTH]) && 
                   (w_ptr[ADDR_WIDTH-1:0] == r_ptr[ADDR_WIDTH-1:0]);
                   // Full: When the MSBs are different but the remaining bits are the same, it means the write pointer has wrapped around the buffer and "caught up" to the read pointer from behind.
                  
                   
    // write logic                
    always_ff @(posedge clk or posedge rst) begin
        if(rst) begin
            w_ptr <= 0;
        end 
        // Allow write when full IF a read is also happening this cycle (slot is freed concurrently)
        else if (w_en && (!full || r_en)) begin
            mem[w_ptr[ADDR_WIDTH-1:0]] <= w_data;
            w_ptr <= ((w_ptr[ADDR_WIDTH-1:0] + 1) == DEPTH) ? {~w_ptr[ADDR_WIDTH], {ADDR_WIDTH{1'b0}}} : w_ptr + 1; // wrap around
        end
    end
    
    // Read Logic
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            r_ptr <= '0;
        end else if (r_en && !empty) begin
            r_ptr <= ((r_ptr[ADDR_WIDTH-1:0] + 1) == DEPTH) ? {~r_ptr[ADDR_WIDTH], {ADDR_WIDTH{1'b0}}} : r_ptr + 1;
        end
    end
           // Continuous Read Output
    assign r_data = mem[r_ptr[ADDR_WIDTH-1:0]];
endmodule
