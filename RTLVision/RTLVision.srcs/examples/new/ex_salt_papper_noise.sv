`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/11/2026 03:09:51 PM
// Design Name: 
// Module Name: ex_dilation3x3
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
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/11/2026 02:52:14 PM
// Design Name: 
// Module Name: ex_erosion3x3
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


module ex_salt_papper_noise #(
    parameter string file_name = "../../../../../kaan.bmp", 
    parameter string out_file_name = "../../../../../kaan_salt_papper_noise.bmp"
)();
     
    // -----------------------------------------
    // 0. File settings & Variables (No image array!)
    // -----------------------------------------
    logic sim_done = 0; // Add this flag
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
    logic in_valid;
    logic [7:0] in_red, in_green, in_blue; 
    logic [7:0] out_red, out_green, out_blue;
    logic out_valid;

    salt_pepper_noise uut_grayscale (
        .clk(clk),
        .rst(rst),
        .in_valid(in_valid),
        .in_red(in_red),
        .in_green(in_green),
        .noise_level('d10),
        .in_blue(in_blue),
        .out_red(out_red),
        .out_green(out_green),
        .out_blue(out_blue),
        .out_valid(out_valid)
    );
     
    initial begin
        // Initialize DUT signals
        clk = 0;
        rst = 1;
        in_valid = 0;
        in_red = 0;
        in_green = 0;
        in_blue = 0;
        @(posedge clk);
        #1 rst = 0;
        @(posedge clk);
        #1;
        
        // --- A. Open Files ---
        file_h = $fopen(file_name, "rb");
        if(file_h == 0) begin
            $display("Error: couldn't open input file");
            $finish;
        end
        
        file_out = $fopen(out_file_name, "wb");
        if(file_out == 0) begin
            $display("Error: couldn't open output file");
            $finish;
        end
        
        // --- B. Read Header and Extract Metadata ---
        // Read just the first 54 bytes to get the dimensions
        for(int i = 0; i < 54; i++) begin
            bmp_header[i] = $fgetc(file_h);
        end
        
        start_address = {bmp_header[13], bmp_header[12], bmp_header[11], bmp_header[10]};
        width         = {bmp_header[21], bmp_header[20], bmp_header[19], bmp_header[18]};
        height        = {bmp_header[25], bmp_header[24], bmp_header[23], bmp_header[22]};
        
        $display("Image Info: %0d x %0d, Data starts at: %0d", width, height, start_address);
        
        // --- C. Copy the Entire Header to Output File ---
        // Rewind input file to the beginning to do a clean exact copy of the header
        status = $fseek(file_h, 0, 0); 
        for (int i = 0; i < start_address; i++) begin
             byte_val = $fgetc(file_h);
             $fwrite(file_out, "%c", byte_val);
        end
        // Now file_h is perfectly positioned at the first pixel, 
        // and file_out has the exact header structure.

        $display("Starting on-the-fly processing...");

        // --- D. On-The-Fly Streaming (Pipelined) ---
        fork
            // Thread 1: Read from file -> Feed to DUT
            begin
                for (int i = 0; i < height; i++) begin
                    for (int j = 0; j < width; j++) begin
                        in_blue  = $fgetc(file_h);
                        in_green = $fgetc(file_h);
                        in_red   = $fgetc(file_h);
                        in_valid = 1;
                        @(posedge clk);
                    end
                end
                in_valid = 0; // Stop feeding after the last pixel
            end
            
            // Thread 2: Catch from DUT -> Write to file
            begin
                for (int i = 0; i < height; i++) begin
                    for (int j = 0; j < width; j++) begin
                        
                        // Wait for clock edge, then wait 1ns for DUT to update
                        @(posedge clk);
                        #1; 
                         
                        if(out_valid) begin
                            // Write the grayscale byte to B, G, and R channels
                            $fwrite(file_out, "%c", out_blue); 
                            $fwrite(file_out, "%c", out_green); 
                            $fwrite(file_out, "%c", out_red);
                        end 
                    end
                end
            end
        join_any
        
        // --- E. Cleanup ---
        $display("Image processed and saved successfully.");
        $fclose(file_h);
        $fclose(file_out);
        sim_done = 1;
        $finish;
    end
endmodule
