/**
 * AXI-Vision: FPGA Image Processing Library
 * 
 * Module: rgb_to_gray
 * Description: RGB to Grayscale color space converter using AXI4-Stream
 * 
 * Features:
 * - ITU-R BT.601 standard conversion formula
 * - Y = 0.299*R + 0.587*G + 0.114*B
 * - Fixed-point arithmetic using integer approximation
 * - Single-cycle latency after pipeline
 * - Optimized for Artix-7 DSP48E1 slices
 * 
 * Input Format: 24-bit RGB (8 bits per channel)
 * Output Format: 8-bit Grayscale
 * 
 * Latency: 3 clock cycles
 * Target: Xilinx Artix-7
 */

module rgb_to_gray #(
    parameter int RGB_WIDTH = 24,  // Total RGB width (8 bits per channel)
    parameter int GRAY_WIDTH = 8   // Output grayscale width
) (
    input  logic                    clk,
    input  logic                    rst_n,
    
    // AXI4-Stream Slave Interface (RGB Input)
    input  logic                    s_axis_tvalid,
    output logic                    s_axis_tready,
    input  logic [RGB_WIDTH-1:0]    s_axis_tdata,  // {R, G, B}
    input  logic                    s_axis_tlast,
    input  logic                    s_axis_tuser,  // Start of frame
    
    // AXI4-Stream Master Interface (Grayscale Output)
    output logic                    m_axis_tvalid,
    input  logic                    m_axis_tready,
    output logic [GRAY_WIDTH-1:0]   m_axis_tdata,
    output logic                    m_axis_tlast,
    output logic                    m_axis_tuser   // Start of frame
);

    // Extract RGB channels
    logic [7:0] r, g, b;
    assign r = s_axis_tdata[23:16];
    assign g = s_axis_tdata[15:8];
    assign b = s_axis_tdata[7:0];
    
    // Fixed-point coefficients (scaled by 256 for integer math)
    // Y = (77*R + 150*G + 29*B) / 256
    // These coefficients approximate 0.299, 0.587, 0.114
    localparam int COEF_R = 77;   // 0.299 * 256 ≈ 77
    localparam int COEF_G = 150;  // 0.587 * 256 ≈ 150
    localparam int COEF_B = 29;   // 0.114 * 256 ≈ 29
    
    // Pipeline stage 1: Multiply
    logic [15:0] r_mult, g_mult, b_mult;
    logic        stage1_valid;
    logic        stage1_tlast;
    logic        stage1_tuser;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_mult <= '0;
            g_mult <= '0;
            b_mult <= '0;
            stage1_valid <= 1'b0;
            stage1_tlast <= 1'b0;
            stage1_tuser <= 1'b0;
        end else begin
            stage1_valid <= s_axis_tvalid;
            stage1_tlast <= s_axis_tlast;
            stage1_tuser <= s_axis_tuser;
            
            if (s_axis_tvalid) begin
                r_mult <= r * COEF_R;
                g_mult <= g * COEF_G;
                b_mult <= b * COEF_B;
            end
        end
    end
    
    // Pipeline stage 2: Add
    logic [17:0] sum;
    logic        stage2_valid;
    logic        stage2_tlast;
    logic        stage2_tuser;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum <= '0;
            stage2_valid <= 1'b0;
            stage2_tlast <= 1'b0;
            stage2_tuser <= 1'b0;
        end else begin
            stage2_valid <= stage1_valid;
            stage2_tlast <= stage1_tlast;
            stage2_tuser <= stage1_tuser;
            
            if (stage1_valid) begin
                sum <= r_mult + g_mult + b_mult;
            end
        end
    end
    
    // Pipeline stage 3: Divide by 256 (right shift by 8) and output
    logic [GRAY_WIDTH-1:0] gray;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gray <= '0;
            m_axis_tvalid <= 1'b0;
            m_axis_tlast <= 1'b0;
            m_axis_tuser <= 1'b0;
        end else begin
            m_axis_tvalid <= stage2_valid;
            m_axis_tlast <= stage2_tlast;
            m_axis_tuser <= stage2_tuser;
            
            if (stage2_valid) begin
                // Divide by 256 (shift right by 8)
                gray <= sum[15:8];
            end
        end
    end
    
    assign m_axis_tdata = gray;
    assign s_axis_tready = m_axis_tready;  // Simple flow control

endmodule : rgb_to_gray
