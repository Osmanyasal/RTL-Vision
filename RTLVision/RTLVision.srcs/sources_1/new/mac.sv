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
// Description: Multiply Add module, out_value <= a1 * a2 + b1
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
    input logic in_ready,
    input logic[7:0] a1,
    input logic[7:0] a2,
    input logic[7:0] b1,
    output logic[7:0] out_value,
    output logic out_valid
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
            mul_valid <= in_ready;
            mul_result <= a1 * a2;
            carry_b1 <= b1;
        end
    end
    
    
    logic [15:0] full_sum;
    assign full_sum = mul_result + carry_b1;

    always_ff @( posedge clk ) begin
        if(rst) begin
            out_value <= 0;
            out_valid <= 0;
        end
        else begin
            out_valid <= mul_valid;
            out_value <= full_sum > 16'd255 ? 8'd255 : full_sum[7:0];        
end
    end
endmodule
