/**
 * AXI-Vision: FPGA Image Processing Library
 * 
 * Testbench: sobel_filter_tb
 * Description: Testbench for Sobel edge detection filter
 * 
 * Test scenarios:
 * - Simple gradient patterns
 * - Edge detection on synthetic image
 */

`timescale 1ns / 1ps

module sobel_filter_tb;

    // Parameters
    localparam int DATA_WIDTH = 8;
    localparam int IMG_WIDTH = 8;
    localparam int CLK_PERIOD = 10;  // 100 MHz
    
    // Signals
    logic                    clk;
    logic                    rst_n;
    logic                    s_axis_tvalid;
    logic                    s_axis_tready;
    logic [DATA_WIDTH-1:0]   s_axis_tdata;
    logic                    s_axis_tlast;
    logic                    s_axis_tuser;
    logic                    m_axis_tvalid;
    logic                    m_axis_tready;
    logic [DATA_WIDTH-1:0]   m_axis_tdata;
    logic                    m_axis_tlast;
    logic                    m_axis_tuser;
    logic [15:0]             img_width;
    
    // DUT instantiation
    sobel_filter #(
        .DATA_WIDTH(DATA_WIDTH),
        .IMG_WIDTH(IMG_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tlast(s_axis_tlast),
        .s_axis_tuser(s_axis_tuser),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tlast(m_axis_tlast),
        .m_axis_tuser(m_axis_tuser),
        .img_width(img_width)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Test stimulus
    initial begin
        // Initialize
        rst_n = 0;
        s_axis_tvalid = 0;
        s_axis_tdata = 0;
        s_axis_tlast = 0;
        s_axis_tuser = 0;
        m_axis_tready = 1;
        img_width = IMG_WIDTH;
        
        // Reset
        #(CLK_PERIOD * 5);
        rst_n = 1;
        #(CLK_PERIOD * 2);
        
        // Test pattern: vertical edge
        // Left half black (0), right half white (255)
        s_axis_tvalid = 1;
        s_axis_tuser = 1;  // Start of frame
        
        for (int row = 0; row < IMG_WIDTH; row++) begin
            for (int col = 0; col < IMG_WIDTH; col++) begin
                s_axis_tdata = (col < IMG_WIDTH/2) ? 8'd0 : 8'd255;
                s_axis_tlast = (col == IMG_WIDTH-1);
                #CLK_PERIOD;
                s_axis_tuser = 0;
            end
        end
        
        s_axis_tvalid = 0;
        #(CLK_PERIOD * 20);
        
        $display("Test completed");
        $finish;
    end
    
    // Monitor output
    always @(posedge clk) begin
        if (m_axis_tvalid) begin
            $display("Time=%0t Output: %3d %s", $time, m_axis_tdata, 
                     m_axis_tlast ? "(EOL)" : "");
        end
    end

endmodule : sobel_filter_tb
