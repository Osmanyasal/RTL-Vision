`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/13/2026 11:47:50 AM
// Design Name: 
// Module Name: ex_median_filter
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

module ex_median_filter #(
    parameter string file_name = "../../../../../butterfly_salt_papper_noise.bmp", 
    parameter string out_file_name = "../../../../../butterfly_salt_papper_filtered.bmp"
)();
     
    // -----------------------------------------
    // 0. File settings & Variables
    // -----------------------------------------
    logic sim_done = 0; 
    int file_h;
    int file_out;
    int status;
    
    logic [7:0] bmp_header[0:53];
    int width, height, start_address;
    int byte_val;
    
    // -----------------------------------------
    // 1. Clock and Reset Generation
    // -----------------------------------------
    logic clk = 0;
    logic rst = 0;
    always #5 clk = ~clk; // 100MHz clock

    // -----------------------------------------
    // 2. DUT Signals & Instantiation
    // -----------------------------------------
    logic       in_valid;
    logic [7:0] in_blue, in_green, in_red;
    logic [7:0] out_blue, out_green, out_red;
    logic       out_valid;
 
    median3x3 uut_red ( 
        .clk(clk),
        .rst(rst),
        .in_valid(in_valid),
        .in_pixel(in_red),
        .out_pixel(out_red),
        .out_valid(out_valid)
    );
        
    median3x3 uut_green ( 
        .clk(clk),
        .rst(rst),
        .in_valid(in_valid),
        .in_pixel(in_green),
        .out_pixel(out_green),
        .out_valid(out_valid)
    );
        
    median3x3 uut_blue ( 
        .clk(clk),
        .rst(rst),
        .in_valid(in_valid),
        .in_pixel(in_blue),
        .out_pixel(out_blue),
        .out_valid(out_valid)
    );
        
    initial begin
        // Initialize DUT signals
        clk = 0;
        rst = 1;
        in_valid = 0;
        in_blue = 0;
        in_green = 0;
        in_red = 0;
        
        // --- A. Open Files ---
        file_h = $fopen(file_name, "rb");
        if(file_h == 0) begin
            $display("Error: couldn't open input file %s", file_name);
            $finish;
        end
        
        file_out = $fopen(out_file_name, "wb");
        if(file_out == 0) begin
            $display("Error: couldn't open output file %s", out_file_name);
            $finish;
        end
        
        // --- B. Read Header and Extract Metadata ---
        for(int i = 0; i < 54; i++) begin
            bmp_header[i] = $fgetc(file_h);
        end
        
        start_address = {bmp_header[13], bmp_header[12], bmp_header[11], bmp_header[10]};
        width         = {bmp_header[21], bmp_header[20], bmp_header[19], bmp_header[18]};
        height        = {bmp_header[25], bmp_header[24], bmp_header[23], bmp_header[22]};
        
        $display("Image Info: %0d x %0d, Data starts at: %0d", width, height, start_address);
        
        // --- C. Copy the Entire Header to Output File ---
        status = $fseek(file_h, 0, 0); 
        for (int i = 0; i < start_address; i++) begin
             byte_val = $fgetc(file_h);
             $fwrite(file_out, "%c", byte_val);
        end

        // Release Reset
        @(posedge clk);
        #1 rst = 0;
        @(posedge clk);
        
        $display("Starting Pipelined Median Filtering...");

        // --- D. On-The-Fly Streaming (Pipelined) ---
        fork
            // Thread 1: Read BGR -> Convert to Gray -> Feed to DUT
            begin
                for (int i = 0; i < height; i++) begin
                    for (int j = 0; j < width; j++) begin
                        logic [7:0] b, g, r;
                        b = $fgetc(file_h);
                        g = $fgetc(file_h);
                        r = $fgetc(file_h);
                        
                        // Feed as grayscale (using simple average or green channel)
                        in_red <= r;
                        in_green <= g;
                        in_blue <= b; 
                        in_valid <= 1;
                        @(posedge clk);
                    end
                end
                in_valid <= 0;
                $display("All pixels sent to DUT.");
            end
            
            // Thread 2: Catch from DUT -> Write to file
            // Note: We count pixels because the valid data is delayed by the line buffers
            begin
                
                for (int i = 0; i < height; i++) begin
                    for (int j = 0; j < width; j++) begin
                    @(posedge clk);
                    if (out_valid) begin
                        // Write the filtered pixel back to 3 channels (B, G, R)
                        $fwrite(file_out, "%c", out_blue); 
                        $fwrite(file_out, "%c", out_green); 
                        $fwrite(file_out, "%c", out_red);
                    end
                    end
                end
                $display("All pixels received and written to file.");
            end
        join
        
        // --- E. Cleanup ---
        $display("Simulation complete.");
        $fclose(file_h);
        $fflush(file_out);
        $fclose(file_out);
        sim_done = 1;
        $finish;
    end
endmodule 