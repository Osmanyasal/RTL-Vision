/**
 * AXI-Vision: FPGA Image Processing Library
 * 
 * Module: gaussian_filter
 * Description: Real-time Gaussian blur filter using AXI4-Stream
 * 
 * Features:
 * - 3x3 or 5x5 Gaussian kernel (parameterizable)
 * - Streaming architecture with deterministic latency
 * - Optimized fixed-point arithmetic
 * - Efficient BRAM usage for line buffers
 * 
 * 3x3 Gaussian Kernel (σ ≈ 1.0):
 * [1  2  1]
 * [2  4  2] / 16
 * [1  2  1]
 * 
 * Latency: ~4 + IMG_WIDTH*(KERNEL_SIZE-1) + KERNEL_SIZE/2 clock cycles
 * Target: Xilinx Artix-7
 */

module gaussian_filter #(
    parameter int DATA_WIDTH  = 8,
    parameter int IMG_WIDTH   = 1920,
    parameter int KERNEL_SIZE = 3  // 3 or 5 supported
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
    input  logic [15:0]             img_width
);

    // Line buffer signals
    logic                                                   window_valid;
    logic [KERNEL_SIZE-1:0][KERNEL_SIZE-1:0][DATA_WIDTH-1:0] window_data;
    
    // Instantiate line buffer
    line_buffer #(
        .DATA_WIDTH(DATA_WIDTH),
        .IMG_WIDTH(IMG_WIDTH),
        .KERNEL_SIZE(KERNEL_SIZE)
    ) u_line_buffer (
        .clk(clk),
        .rst_n(rst_n),
        .pixel_valid(s_axis_tvalid && s_axis_tready),
        .pixel_data(s_axis_tdata),
        .window_valid(window_valid),
        .window_data(window_data),
        .img_width(img_width),
        .frame_start(s_axis_tuser && s_axis_tvalid)
    );
    
    // Pipeline stage 1: Multiply by kernel coefficients
    logic [DATA_WIDTH+7:0] sum;
    logic                   stage1_valid;
    logic                   stage1_tlast;
    logic                   stage1_tuser;
    
    generate
        if (KERNEL_SIZE == 3) begin : gen_3x3
            // 3x3 Gaussian kernel: [1 2 1; 2 4 2; 1 2 1] / 16
            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    sum <= '0;
                    stage1_valid <= 1'b0;
                    stage1_tlast <= 1'b0;
                    stage1_tuser <= 1'b0;
                end else begin
                    stage1_valid <= window_valid;
                    stage1_tlast <= s_axis_tlast;
                    stage1_tuser <= s_axis_tuser;
                    
                    if (window_valid) begin
                        sum <= ({4'b0, window_data[0][0], 4'b0})  // Corner * 1
                             + ({3'b0, window_data[0][1], 5'b0})  // Edge * 2
                             + ({4'b0, window_data[0][2], 4'b0})  // Corner * 1
                             + ({3'b0, window_data[1][0], 5'b0})  // Edge * 2
                             + ({2'b0, window_data[1][1], 6'b0})  // Center * 4
                             + ({3'b0, window_data[1][2], 5'b0})  // Edge * 2
                             + ({4'b0, window_data[2][0], 4'b0})  // Corner * 1
                             + ({3'b0, window_data[2][1], 5'b0})  // Edge * 2
                             + ({4'b0, window_data[2][2], 4'b0}); // Corner * 1
                    end
                end
            end
        end else if (KERNEL_SIZE == 5) begin : gen_5x5
            // 5x5 Gaussian kernel (approximation): divide by 256
            // [1  4  6  4  1]
            // [4 16 24 16  4]
            // [6 24 36 24  6]
            // [4 16 24 16  4]
            // [1  4  6  4  1] / 256
            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    sum <= '0;
                    stage1_valid <= 1'b0;
                    stage1_tlast <= 1'b0;
                    stage1_tuser <= 1'b0;
                end else begin
                    stage1_valid <= window_valid;
                    stage1_tlast <= s_axis_tlast;
                    stage1_tuser <= s_axis_tuser;
                    
                    if (window_valid) begin
                        // Row 0
                        sum <= ({8'b0, window_data[0][0]})          // 1
                             + ({6'b0, window_data[0][1], 2'b0})    // 4
                             + ({5'b0, window_data[0][2], 3'b0}) - ({7'b0, window_data[0][2], 1'b0})  // 6
                             + ({6'b0, window_data[0][3], 2'b0})    // 4
                             + ({8'b0, window_data[0][4]})          // 1
                        // Row 1
                             + ({6'b0, window_data[1][0], 2'b0})    // 4
                             + ({4'b0, window_data[1][1], 4'b0})    // 16
                             + ({3'b0, window_data[1][2], 5'b0}) - ({5'b0, window_data[1][2], 3'b0})  // 24
                             + ({4'b0, window_data[1][3], 4'b0})    // 16
                             + ({6'b0, window_data[1][4], 2'b0})    // 4
                        // Row 2
                             + ({5'b0, window_data[2][0], 3'b0}) - ({7'b0, window_data[2][0], 1'b0})  // 6
                             + ({3'b0, window_data[2][1], 5'b0}) - ({5'b0, window_data[2][1], 3'b0})  // 24
                             + ({2'b0, window_data[2][2], 6'b0}) - ({4'b0, window_data[2][2], 4'b0})  // 36
                             + ({3'b0, window_data[2][3], 5'b0}) - ({5'b0, window_data[2][3], 3'b0})  // 24
                             + ({5'b0, window_data[2][4], 3'b0}) - ({7'b0, window_data[2][4], 1'b0})  // 6
                        // Row 3
                             + ({6'b0, window_data[3][0], 2'b0})    // 4
                             + ({4'b0, window_data[3][1], 4'b0})    // 16
                             + ({3'b0, window_data[3][2], 5'b0}) - ({5'b0, window_data[3][2], 3'b0})  // 24
                             + ({4'b0, window_data[3][3], 4'b0})    // 16
                             + ({6'b0, window_data[3][4], 2'b0})    // 4
                        // Row 4
                             + ({8'b0, window_data[4][0]})          // 1
                             + ({6'b0, window_data[4][1], 2'b0})    // 4
                             + ({5'b0, window_data[4][2], 3'b0}) - ({7'b0, window_data[4][2], 1'b0})  // 6
                             + ({6'b0, window_data[4][3], 2'b0})    // 4
                             + ({8'b0, window_data[4][4]});         // 1
                    end
                end
            end
        end
    endgenerate
    
    // Pipeline stage 2: Divide and output
    logic [DATA_WIDTH-1:0] result;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result <= '0;
            m_axis_tvalid <= 1'b0;
            m_axis_tlast <= 1'b0;
            m_axis_tuser <= 1'b0;
        end else begin
            m_axis_tvalid <= stage1_valid;
            m_axis_tlast <= stage1_tlast;
            m_axis_tuser <= stage1_tuser;
            
            if (stage1_valid) begin
                if (KERNEL_SIZE == 3) begin
                    // Divide by 16 (shift right by 4)
                    result <= sum[DATA_WIDTH+3:4];
                end else begin
                    // Divide by 256 (shift right by 8)
                    result <= sum[DATA_WIDTH+7:8];
                end
            end
        end
    end
    
    assign m_axis_tdata = result;
    assign s_axis_tready = m_axis_tready;  // Simple flow control

endmodule : gaussian_filter
