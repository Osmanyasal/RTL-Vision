`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Osman Yasal
// 
// Create Date: 05/10/2026 05:31:59 PM
// Design Name: 
// Module Name: mac
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Multiply Add module, value_out <= a1 * a2 + b1
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: Pipelined 
// 
//////////////////////////////////////////////////////////////////////////////////


module mac(
    input logic clk,
    input logic rst,
    input logic ready_in,
    input logic[7:0] a1,
    input logic[7:0] a2,
    input logic[7:0] b1,
    output logic[7:0] value_out,
    output logic ready_out
    );

    logic mul_valid;
    logic[15:0] mul_result;
    logic [7:0] carry_b1;

    always_ff @( posedge clk ) begin
        if(rst) begin
            mul_valid <= 0;
            mul_result <= 0;
            carry_b1 <= 0;
        end 
        else begin
            mul_valid <= ready_in;
            mul_result <= a1 * a2;
            carry_b1 <= b1;
        end
    end
    
    
    logic [15:0] full_sum;
    assign full_sum = mul_result + carry_b1;

    always_ff @( posedge clk ) begin
        if(rst) begin
            value_out <= 0;
            ready_out <= 0;
        end
        else begin
            ready_out <= mul_valid;
            value_out <= full_sum > 16'd255 ? 8'd255 : full_sum[7:0];        
end
    end
endmodule
