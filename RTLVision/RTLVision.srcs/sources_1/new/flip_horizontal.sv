`timescale 1ns / 1ps

module flip_horizontal #(
    parameter DATA_WIDTH = 24,
    parameter LINE_WIDTH = 1024,
    parameter ADDR_WIDTH = $clog2(LINE_WIDTH)
)(
    input  logic                    clk,
    input  logic                    rst,

    input  logic [DATA_WIDTH-1:0]   in_pixel,
    input  logic                    in_valid,
    input  logic                    line_done,

    output logic [DATA_WIDTH-1:0]   out_pixel,
    output logic                    out_valid
);

    typedef enum logic [1:0] {
        IDLE,
        FILLING,
        OUTPUTTING
    } state_t;

    state_t state;

    logic [DATA_WIDTH-1:0] mem [0:LINE_WIDTH-1];

    logic [ADDR_WIDTH-1:0] write_ptr;
    logic [ADDR_WIDTH-1:0] read_ptr;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state      <= IDLE;
            write_ptr  <= 0;
            read_ptr   <= 0;
            out_valid  <= 0;
            out_pixel  <= 0;
        end
        else begin
            out_valid <= 0;

            case(state)

                ////////////////////////////////////////////////////////////
                // IDLE
                ////////////////////////////////////////////////////////////
                IDLE: begin
                    write_ptr <= 0;

                    if (in_valid) begin
                        mem[0] <= in_pixel;
                        write_ptr <= 1;

                        if (line_done) begin
                            read_ptr <= 0;
                            state <= OUTPUTTING;
                        end
                        else begin
                            state <= FILLING;
                        end
                    end
                end

                ////////////////////////////////////////////////////////////
                // FILLING
                ////////////////////////////////////////////////////////////
                FILLING: begin
                    if (in_valid) begin
                        mem[write_ptr] <= in_pixel;

                        if (line_done) begin
                            read_ptr <= write_ptr;
                            state <= OUTPUTTING;
                        end

                        write_ptr <= write_ptr + 1;
                    end
                end

                ////////////////////////////////////////////////////////////
                // OUTPUTTING
                ////////////////////////////////////////////////////////////
                OUTPUTTING: begin
                    out_pixel <= mem[read_ptr];
                    out_valid <= 1;

                    if (read_ptr == 0) begin
                        state <= IDLE;
                    end
                    else begin
                        read_ptr <= read_ptr - 1;
                    end
                end

            endcase
        end
    end

endmodule