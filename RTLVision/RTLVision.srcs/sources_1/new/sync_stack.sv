`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 20.05.2026 09:16:56
// Design Name: 
// Module Name: sync_stack
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

module sync_stack #(
    parameter DATA_WIDTH = 8, 
    parameter DEPTH = 16, 
    parameter ADDR_WIDTH = $clog2(DEPTH)
)(
    input  logic clk,
    input  logic rst,
    
    // write interface
    input  logic [DATA_WIDTH-1:0] w_data,
    input  logic w_en,
    output logic full,
    
    // read interface
    input  logic r_en,
    output logic empty,
    output logic [DATA_WIDTH-1:0] r_data
);
    
    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    
    // The Stack Pointer needs an extra bit to distinguish between full and empty
    logic [ADDR_WIDTH:0] sp; 

    assign empty = (sp == 0);
    assign full  = (sp == DEPTH); 
    

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            sp <= '0;
        end 
        else begin
            // 1. Push and Pop
            if (w_en && r_en && !empty) begin
                mem[sp - 1] <= w_data; // Replace the current top of the stack
                // sp remains the same, as depth doesn't change
            end 
            // 2. Push
            else if (w_en && !full) begin
                mem[sp] <= w_data;     // Write to the next available slot
                sp <= sp + 1;          // Increment stack depth
            end 
            // 3. Pop
            else if (r_en && !empty) begin
                sp <= sp - 1;          // Decrement stack depth
            end
        end
    end
    
    // Continuous Read Output
    assign r_data = empty ? '0 : mem[sp - 1];
endmodule
 