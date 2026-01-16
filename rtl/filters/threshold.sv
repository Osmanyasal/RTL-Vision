/**
 * AXI-Vision: FPGA Image Processing Library
 * 
 * Module: threshold
 * Description: Binary thresholding module using AXI4-Stream
 * 
 * Features:
 * - Configurable threshold value
 * - Single-cycle latency
 * - Binary or inverse binary thresholding modes
 * - Streaming architecture
 * 
 * Modes:
 * - BINARY: output = (input > threshold) ? max_val : 0
 * - BINARY_INV: output = (input > threshold) ? 0 : max_val
 * 
 * Latency: 1 clock cycle
 * Target: Xilinx Artix-7
 */

module threshold #(
    parameter int DATA_WIDTH = 8,
    parameter bit INVERSE    = 0  // 0 = binary, 1 = binary inverse
) (
    input  logic                    clk,
    input  logic                    rst_n,
    
    // AXI4-Stream Slave Interface (Input)
    input  logic                    s_axis_tvalid,
    output logic                    s_axis_tready,
    input  logic [DATA_WIDTH-1:0]   s_axis_tdata,
    input  logic                    s_axis_tlast,
    input  logic                    s_axis_tuser,  // Start of frame
    
    // AXI4-Stream Master Interface (Output)
    output logic                    m_axis_tvalid,
    input  logic                    m_axis_tready,
    output logic [DATA_WIDTH-1:0]   m_axis_tdata,
    output logic                    m_axis_tlast,
    output logic                    m_axis_tuser,  // Start of frame
    
    // Configuration
    input  logic [DATA_WIDTH-1:0]   threshold_value,
    input  logic [DATA_WIDTH-1:0]   max_value
);

    logic [DATA_WIDTH-1:0] result;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result <= '0;
            m_axis_tvalid <= 1'b0;
            m_axis_tlast <= 1'b0;
            m_axis_tuser <= 1'b0;
        end else begin
            m_axis_tvalid <= s_axis_tvalid;
            m_axis_tlast <= s_axis_tlast;
            m_axis_tuser <= s_axis_tuser;
            
            if (s_axis_tvalid) begin
                if (INVERSE) begin
                    // Binary inverse: output 0 if above threshold, max_value otherwise
                    result <= (s_axis_tdata > threshold_value) ? '0 : max_value;
                end else begin
                    // Binary: output max_value if above threshold, 0 otherwise
                    result <= (s_axis_tdata > threshold_value) ? max_value : '0;
                end
            end
        end
    end
    
    assign m_axis_tdata = result;
    assign s_axis_tready = m_axis_tready;  // Simple flow control

endmodule : threshold
