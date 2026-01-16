/**
 * AXI-Vision: FPGA Image Processing Library
 * 
 * Module: sobel_filter
 * Description: Real-time Sobel edge detection filter using AXI4-Stream
 * 
 * Features:
 * - 3x3 Sobel operator (Gx and Gy gradients)
 * - Streaming architecture with deterministic latency
 * - Parameterizable data width
 * - Optimized for low-latency operation
 * 
 * Algorithm:
 * - Computes horizontal (Gx) and vertical (Gy) gradients
 * - Edge magnitude = |Gx| + |Gy| (Manhattan distance approximation)
 * - Output is normalized to input bit depth
 * 
 * Latency: ~3 + IMG_WIDTH*2 + 2 clock cycles
 * Target: Xilinx Artix-7
 */

module sobel_filter #(
    parameter int DATA_WIDTH = 8,
    parameter int IMG_WIDTH  = 1920
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

    // Sobel kernels
    // Gx = [-1  0  1]    Gy = [-1 -2 -1]
    //      [-2  0  2]         [ 0  0  0]
    //      [-1  0  1]         [ 1  2  1]
    
    // Line buffer signals
    logic                                           window_valid;
    logic [2:0][2:0][DATA_WIDTH-1:0]               window_data;
    
    // Instantiate line buffer
    line_buffer #(
        .DATA_WIDTH(DATA_WIDTH),
        .IMG_WIDTH(IMG_WIDTH),
        .KERNEL_SIZE(3)
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
    
    // Pipeline stage 1: Compute gradients
    logic signed [DATA_WIDTH+3:0] gx, gy;
    logic                          stage1_valid;
    logic                          stage1_tlast;
    logic                          stage1_tuser;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gx <= '0;
            gy <= '0;
            stage1_valid <= 1'b0;
            stage1_tlast <= 1'b0;
            stage1_tuser <= 1'b0;
        end else begin
            stage1_valid <= window_valid;
            stage1_tlast <= s_axis_tlast;
            stage1_tuser <= s_axis_tuser;
            
            if (window_valid) begin
                // Compute Gx (horizontal gradient)
                gx <= signed'({1'b0, window_data[0][2]}) - signed'({1'b0, window_data[0][0]})
                    + (signed'({1'b0, window_data[1][2]}) <<< 1) - (signed'({1'b0, window_data[1][0]}) <<< 1)
                    + signed'({1'b0, window_data[2][2]}) - signed'({1'b0, window_data[2][0]});
                
                // Compute Gy (vertical gradient)
                gy <= signed'({1'b0, window_data[2][0]}) - signed'({1'b0, window_data[0][0]})
                    + (signed'({1'b0, window_data[2][1]}) <<< 1) - (signed'({1'b0, window_data[0][1]}) <<< 1)
                    + signed'({1'b0, window_data[2][2]}) - signed'({1'b0, window_data[0][2]});
            end
        end
    end
    
    // Pipeline stage 2: Compute magnitude (Manhattan distance)
    logic [DATA_WIDTH+3:0] magnitude;
    logic                   stage2_valid;
    logic                   stage2_tlast;
    logic                   stage2_tuser;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            magnitude <= '0;
            stage2_valid <= 1'b0;
            stage2_tlast <= 1'b0;
            stage2_tuser <= 1'b0;
        end else begin
            stage2_valid <= stage1_valid;
            stage2_tlast <= stage1_tlast;
            stage2_tuser <= stage1_tuser;
            
            if (stage1_valid) begin
                // Compute |Gx| + |Gy|
                magnitude <= (gx[DATA_WIDTH+3] ? -gx : gx) + (gy[DATA_WIDTH+3] ? -gy : gy);
            end
        end
    end
    
    // Pipeline stage 3: Normalize and saturate
    logic [DATA_WIDTH-1:0] result;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result <= '0;
            m_axis_tvalid <= 1'b0;
            m_axis_tlast <= 1'b0;
            m_axis_tuser <= 1'b0;
        end else begin
            m_axis_tvalid <= stage2_valid;
            m_axis_tlast <= stage2_tlast;
            m_axis_tuser <= stage2_tuser;
            
            if (stage2_valid) begin
                // Divide by 4 and saturate to output range
                if (magnitude[DATA_WIDTH+3:DATA_WIDTH+2] != 2'b00) begin
                    // Saturate to max value
                    result <= {DATA_WIDTH{1'b1}};
                end else begin
                    result <= magnitude[DATA_WIDTH+1:2];
                end
            end
        end
    end
    
    assign m_axis_tdata = result;
    assign s_axis_tready = m_axis_tready;  // Simple flow control

endmodule : sobel_filter
