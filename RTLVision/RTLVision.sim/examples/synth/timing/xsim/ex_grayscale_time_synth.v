// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2025 Advanced Micro Devices, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2025.2 (lin64) Build 6299465 Fri Nov 14 12:34:56 MST 2025
// Date        : Wed Apr 29 13:19:04 2026
// Host        : rt7-desktop1 running 64-bit Ubuntu 24.04.3 LTS
// Command     : write_verilog -mode timesim -nolib -sdf_anno true -force -file
//               /home/rt7/Desktop/RTLVision/RTLVision/RTLVision.sim/examples/synth/timing/xsim/ex_grayscale_time_synth.v
// Design      : grayscale
// Purpose     : This verilog netlist is a timing simulation representation of the design and should not be modified or
//               synthesized. Please ensure that this netlist is used with the corresponding SDF file.
// Device      : xc7a100tcsg324-1
// --------------------------------------------------------------------------------
`timescale 1 ps / 1 ps
`define XIL_TIMING

(* NotValidForBitStream *)
module grayscale
   (clk,
    rst,
    ready_in,
    red_in,
    green_in,
    blue_in,
    gray_out,
    ready_out);
  input clk;
  input rst;
  input ready_in;
  input [7:0]red_in;
  input [7:0]green_in;
  input [7:0]blue_in;
  output [7:0]gray_out;
  output ready_out;

  wire [7:0]blue_in;
  wire [7:4]blue_in_IBUF;
  wire [7:4]blue_reg;
  wire clk;
  wire clk_IBUF;
  wire clk_IBUF_BUFG;
  wire [7:0]gray_out;
  wire \gray_out[3]_i_10_n_0 ;
  wire \gray_out[3]_i_2_n_0 ;
  wire \gray_out[3]_i_3_n_0 ;
  wire \gray_out[3]_i_4_n_0 ;
  wire \gray_out[3]_i_5_n_0 ;
  wire \gray_out[3]_i_6_n_0 ;
  wire \gray_out[3]_i_7_n_0 ;
  wire \gray_out[3]_i_8_n_0 ;
  wire \gray_out[3]_i_9_n_0 ;
  wire \gray_out[7]_i_12_n_0 ;
  wire \gray_out[7]_i_13_n_0 ;
  wire \gray_out[7]_i_14_n_0 ;
  wire \gray_out[7]_i_15_n_0 ;
  wire \gray_out[7]_i_16_n_0 ;
  wire \gray_out[7]_i_17_n_0 ;
  wire \gray_out[7]_i_18_n_0 ;
  wire \gray_out[7]_i_19_n_0 ;
  wire \gray_out[7]_i_1_n_0 ;
  wire \gray_out[7]_i_20_n_0 ;
  wire \gray_out[7]_i_21_n_0 ;
  wire \gray_out[7]_i_22_n_0 ;
  wire \gray_out[7]_i_23_n_0 ;
  wire \gray_out[7]_i_24_n_0 ;
  wire \gray_out[7]_i_3_n_0 ;
  wire \gray_out[7]_i_4_n_0 ;
  wire \gray_out[7]_i_5_n_0 ;
  wire \gray_out[7]_i_6_n_0 ;
  wire \gray_out[7]_i_7_n_0 ;
  wire \gray_out[7]_i_8_n_0 ;
  wire \gray_out[7]_i_9_n_0 ;
  wire [7:0]gray_out_OBUF;
  wire \gray_out_reg[3]_i_1_n_0 ;
  wire \gray_out_reg[3]_i_1_n_1 ;
  wire \gray_out_reg[3]_i_1_n_2 ;
  wire \gray_out_reg[3]_i_1_n_3 ;
  wire \gray_out_reg[7]_i_10_n_0 ;
  wire \gray_out_reg[7]_i_10_n_2 ;
  wire \gray_out_reg[7]_i_10_n_3 ;
  wire \gray_out_reg[7]_i_10_n_5 ;
  wire \gray_out_reg[7]_i_10_n_6 ;
  wire \gray_out_reg[7]_i_10_n_7 ;
  wire \gray_out_reg[7]_i_11_n_0 ;
  wire \gray_out_reg[7]_i_11_n_1 ;
  wire \gray_out_reg[7]_i_11_n_2 ;
  wire \gray_out_reg[7]_i_11_n_3 ;
  wire \gray_out_reg[7]_i_11_n_4 ;
  wire \gray_out_reg[7]_i_11_n_5 ;
  wire \gray_out_reg[7]_i_11_n_6 ;
  wire \gray_out_reg[7]_i_11_n_7 ;
  wire \gray_out_reg[7]_i_2_n_1 ;
  wire \gray_out_reg[7]_i_2_n_2 ;
  wire \gray_out_reg[7]_i_2_n_3 ;
  wire [7:0]green_in;
  wire [7:1]green_in_IBUF;
  wire [7:1]green_reg;
  wire [7:0]p_1_in;
  wire ready_in;
  wire ready_in_IBUF;
  wire ready_out;
  wire ready_out_OBUF;
  wire ready_reg;
  wire [7:0]red_in;
  wire [7:2]red_in_IBUF;
  wire [7:2]red_reg;
  wire rst;
  wire rst_IBUF;
  wire [2:2]\NLW_gray_out_reg[7]_i_10_CO_UNCONNECTED ;
  wire [3:3]\NLW_gray_out_reg[7]_i_10_O_UNCONNECTED ;
  wire [3:3]\NLW_gray_out_reg[7]_i_2_CO_UNCONNECTED ;

initial begin
 $sdf_annotate("ex_grayscale_time_synth.sdf",,,,"tool_control");
end
  IBUF \blue_in_IBUF[4]_inst 
       (.I(blue_in[4]),
        .O(blue_in_IBUF[4]));
  IBUF \blue_in_IBUF[5]_inst 
       (.I(blue_in[5]),
        .O(blue_in_IBUF[5]));
  IBUF \blue_in_IBUF[6]_inst 
       (.I(blue_in[6]),
        .O(blue_in_IBUF[6]));
  IBUF \blue_in_IBUF[7]_inst 
       (.I(blue_in[7]),
        .O(blue_in_IBUF[7]));
  FDRE #(
    .INIT(1'b0)) 
    \blue_reg_reg[4] 
       (.C(clk_IBUF_BUFG),
        .CE(1'b1),
        .D(blue_in_IBUF[4]),
        .Q(blue_reg[4]),
        .R(rst_IBUF));
  FDRE #(
    .INIT(1'b0)) 
    \blue_reg_reg[5] 
       (.C(clk_IBUF_BUFG),
        .CE(1'b1),
        .D(blue_in_IBUF[5]),
        .Q(blue_reg[5]),
        .R(rst_IBUF));
  FDRE #(
    .INIT(1'b0)) 
    \blue_reg_reg[6] 
       (.C(clk_IBUF_BUFG),
        .CE(1'b1),
        .D(blue_in_IBUF[6]),
        .Q(blue_reg[6]),
        .R(rst_IBUF));
  FDRE #(
    .INIT(1'b0)) 
    \blue_reg_reg[7] 
       (.C(clk_IBUF_BUFG),
        .CE(1'b1),
        .D(blue_in_IBUF[7]),
        .Q(blue_reg[7]),
        .R(rst_IBUF));
  BUFG clk_IBUF_BUFG_inst
       (.I(clk_IBUF),
        .O(clk_IBUF_BUFG));
  IBUF clk_IBUF_inst
       (.I(clk),
        .O(clk_IBUF));
  (* SOFT_HLUTNM = "soft_lutpair0" *) 
  LUT3 #(
    .INIT(8'h96)) 
    \gray_out[3]_i_10 
       (.I0(green_reg[7]),
        .I1(\gray_out_reg[7]_i_11_n_4 ),
        .I2(green_reg[4]),
        .O(\gray_out[3]_i_10_n_0 ));
  LUT5 #(
    .INIT(32'hEEE8E888)) 
    \gray_out[3]_i_2 
       (.I0(green_reg[6]),
        .I1(\gray_out[3]_i_9_n_0 ),
        .I2(green_reg[2]),
        .I3(red_reg[6]),
        .I4(\gray_out_reg[7]_i_11_n_6 ),
        .O(\gray_out[3]_i_2_n_0 ));
  LUT5 #(
    .INIT(32'hE81717E8)) 
    \gray_out[3]_i_3 
       (.I0(green_reg[2]),
        .I1(red_reg[6]),
        .I2(\gray_out_reg[7]_i_11_n_6 ),
        .I3(green_reg[6]),
        .I4(\gray_out[3]_i_9_n_0 ),
        .O(\gray_out[3]_i_3_n_0 ));
  LUT4 #(
    .INIT(16'h6996)) 
    \gray_out[3]_i_4 
       (.I0(red_reg[6]),
        .I1(\gray_out_reg[7]_i_11_n_6 ),
        .I2(green_reg[2]),
        .I3(green_reg[5]),
        .O(\gray_out[3]_i_4_n_0 ));
  LUT5 #(
    .INIT(32'h99969666)) 
    \gray_out[3]_i_5 
       (.I0(\gray_out[3]_i_2_n_0 ),
        .I1(\gray_out[3]_i_10_n_0 ),
        .I2(\gray_out_reg[7]_i_11_n_5 ),
        .I3(red_reg[7]),
        .I4(green_reg[3]),
        .O(\gray_out[3]_i_5_n_0 ));
  LUT6 #(
    .INIT(64'h6999999699969666)) 
    \gray_out[3]_i_6 
       (.I0(\gray_out[3]_i_9_n_0 ),
        .I1(green_reg[6]),
        .I2(green_reg[2]),
        .I3(\gray_out_reg[7]_i_11_n_6 ),
        .I4(red_reg[6]),
        .I5(green_reg[5]),
        .O(\gray_out[3]_i_6_n_0 ));
  LUT4 #(
    .INIT(16'h566A)) 
    \gray_out[3]_i_7 
       (.I0(\gray_out[3]_i_4_n_0 ),
        .I1(green_reg[1]),
        .I2(red_reg[5]),
        .I3(\gray_out_reg[7]_i_11_n_7 ),
        .O(\gray_out[3]_i_7_n_0 ));
  LUT4 #(
    .INIT(16'h6996)) 
    \gray_out[3]_i_8 
       (.I0(red_reg[5]),
        .I1(\gray_out_reg[7]_i_11_n_7 ),
        .I2(green_reg[1]),
        .I3(green_reg[4]),
        .O(\gray_out[3]_i_8_n_0 ));
  LUT3 #(
    .INIT(8'h96)) 
    \gray_out[3]_i_9 
       (.I0(green_reg[3]),
        .I1(\gray_out_reg[7]_i_11_n_5 ),
        .I2(red_reg[7]),
        .O(\gray_out[3]_i_9_n_0 ));
  LUT2 #(
    .INIT(4'hB)) 
    \gray_out[7]_i_1 
       (.I0(rst_IBUF),
        .I1(ready_reg),
        .O(\gray_out[7]_i_1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair0" *) 
  LUT3 #(
    .INIT(8'hE8)) 
    \gray_out[7]_i_12 
       (.I0(\gray_out_reg[7]_i_11_n_4 ),
        .I1(green_reg[4]),
        .I2(green_reg[7]),
        .O(\gray_out[7]_i_12_n_0 ));
  LUT2 #(
    .INIT(4'hE)) 
    \gray_out[7]_i_13 
       (.I0(red_reg[6]),
        .I1(blue_reg[7]),
        .O(\gray_out[7]_i_13_n_0 ));
  LUT2 #(
    .INIT(4'hE)) 
    \gray_out[7]_i_14 
       (.I0(red_reg[5]),
        .I1(blue_reg[6]),
        .O(\gray_out[7]_i_14_n_0 ));
  LUT1 #(
    .INIT(2'h1)) 
    \gray_out[7]_i_15 
       (.I0(red_reg[7]),
        .O(\gray_out[7]_i_15_n_0 ));
  LUT3 #(
    .INIT(8'hE1)) 
    \gray_out[7]_i_16 
       (.I0(blue_reg[7]),
        .I1(red_reg[6]),
        .I2(red_reg[7]),
        .O(\gray_out[7]_i_16_n_0 ));
  LUT4 #(
    .INIT(16'h1EE1)) 
    \gray_out[7]_i_17 
       (.I0(blue_reg[6]),
        .I1(red_reg[5]),
        .I2(blue_reg[7]),
        .I3(red_reg[6]),
        .O(\gray_out[7]_i_17_n_0 ));
  LUT3 #(
    .INIT(8'hD4)) 
    \gray_out[7]_i_18 
       (.I0(blue_reg[7]),
        .I1(blue_reg[5]),
        .I2(red_reg[4]),
        .O(\gray_out[7]_i_18_n_0 ));
  LUT3 #(
    .INIT(8'h69)) 
    \gray_out[7]_i_19 
       (.I0(blue_reg[5]),
        .I1(blue_reg[7]),
        .I2(red_reg[4]),
        .O(\gray_out[7]_i_19_n_0 ));
  LUT2 #(
    .INIT(4'hB)) 
    \gray_out[7]_i_20 
       (.I0(blue_reg[4]),
        .I1(blue_reg[5]),
        .O(\gray_out[7]_i_20_n_0 ));
  LUT5 #(
    .INIT(32'h718E8E71)) 
    \gray_out[7]_i_21 
       (.I0(red_reg[4]),
        .I1(blue_reg[5]),
        .I2(blue_reg[7]),
        .I3(blue_reg[6]),
        .I4(red_reg[5]),
        .O(\gray_out[7]_i_21_n_0 ));
  LUT5 #(
    .INIT(32'h69966969)) 
    \gray_out[7]_i_22 
       (.I0(blue_reg[5]),
        .I1(blue_reg[7]),
        .I2(red_reg[4]),
        .I3(blue_reg[6]),
        .I4(red_reg[3]),
        .O(\gray_out[7]_i_22_n_0 ));
  LUT4 #(
    .INIT(16'h2DD2)) 
    \gray_out[7]_i_23 
       (.I0(blue_reg[5]),
        .I1(blue_reg[4]),
        .I2(blue_reg[6]),
        .I3(red_reg[3]),
        .O(\gray_out[7]_i_23_n_0 ));
  LUT3 #(
    .INIT(8'h96)) 
    \gray_out[7]_i_24 
       (.I0(blue_reg[5]),
        .I1(blue_reg[4]),
        .I2(red_reg[2]),
        .O(\gray_out[7]_i_24_n_0 ));
  LUT2 #(
    .INIT(4'h8)) 
    \gray_out[7]_i_3 
       (.I0(\gray_out_reg[7]_i_10_n_6 ),
        .I1(green_reg[6]),
        .O(\gray_out[7]_i_3_n_0 ));
  LUT5 #(
    .INIT(32'hEEE8E888)) 
    \gray_out[7]_i_4 
       (.I0(\gray_out_reg[7]_i_10_n_7 ),
        .I1(green_reg[5]),
        .I2(green_reg[7]),
        .I3(green_reg[4]),
        .I4(\gray_out_reg[7]_i_11_n_4 ),
        .O(\gray_out[7]_i_4_n_0 ));
  LUT6 #(
    .INIT(64'h9696960096000000)) 
    \gray_out[7]_i_5 
       (.I0(green_reg[4]),
        .I1(\gray_out_reg[7]_i_11_n_4 ),
        .I2(green_reg[7]),
        .I3(green_reg[3]),
        .I4(red_reg[7]),
        .I5(\gray_out_reg[7]_i_11_n_5 ),
        .O(\gray_out[7]_i_5_n_0 ));
  LUT3 #(
    .INIT(8'h87)) 
    \gray_out[7]_i_6 
       (.I0(green_reg[7]),
        .I1(\gray_out_reg[7]_i_10_n_5 ),
        .I2(\gray_out_reg[7]_i_10_n_0 ),
        .O(\gray_out[7]_i_6_n_0 ));
  LUT4 #(
    .INIT(16'h8778)) 
    \gray_out[7]_i_7 
       (.I0(green_reg[6]),
        .I1(\gray_out_reg[7]_i_10_n_6 ),
        .I2(\gray_out_reg[7]_i_10_n_5 ),
        .I3(green_reg[7]),
        .O(\gray_out[7]_i_7_n_0 ));
  LUT5 #(
    .INIT(32'hE81717E8)) 
    \gray_out[7]_i_8 
       (.I0(\gray_out[7]_i_12_n_0 ),
        .I1(green_reg[5]),
        .I2(\gray_out_reg[7]_i_10_n_7 ),
        .I3(\gray_out_reg[7]_i_10_n_6 ),
        .I4(green_reg[6]),
        .O(\gray_out[7]_i_8_n_0 ));
  LUT6 #(
    .INIT(64'h6969699669969696)) 
    \gray_out[7]_i_9 
       (.I0(\gray_out[7]_i_5_n_0 ),
        .I1(green_reg[5]),
        .I2(\gray_out_reg[7]_i_10_n_7 ),
        .I3(\gray_out_reg[7]_i_11_n_4 ),
        .I4(green_reg[4]),
        .I5(green_reg[7]),
        .O(\gray_out[7]_i_9_n_0 ));
  OBUF \gray_out_OBUF[0]_inst 
       (.I(gray_out_OBUF[0]),
        .O(gray_out[0]));
  OBUF \gray_out_OBUF[1]_inst 
       (.I(gray_out_OBUF[1]),
        .O(gray_out[1]));
  OBUF \gray_out_OBUF[2]_inst 
       (.I(gray_out_OBUF[2]),
        .O(gray_out[2]));
  OBUF \gray_out_OBUF[3]_inst 
       (.I(gray_out_OBUF[3]),
        .O(gray_out[3]));
  OBUF \gray_out_OBUF[4]_inst 
       (.I(gray_out_OBUF[4]),
        .O(gray_out[4]));
  OBUF \gray_out_OBUF[5]_inst 
       (.I(gray_out_OBUF[5]),
        .O(gray_out[5]));
  OBUF \gray_out_OBUF[6]_inst 
       (.I(gray_out_OBUF[6]),
        .O(gray_out[6]));
  OBUF \gray_out_OBUF[7]_inst 
       (.I(gray_out_OBUF[7]),
        .O(gray_out[7]));
  FDRE #(
    .INIT(1'b0)) 
    \gray_out_reg[0] 
       (.C(clk_IBUF_BUFG),
        .CE(1'b1),
        .D(p_1_in[0]),
        .Q(gray_out_OBUF[0]),
        .R(\gray_out[7]_i_1_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \gray_out_reg[1] 
       (.C(clk_IBUF_BUFG),
        .CE(1'b1),
        .D(p_1_in[1]),
        .Q(gray_out_OBUF[1]),
        .R(\gray_out[7]_i_1_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \gray_out_reg[2] 
       (.C(clk_IBUF_BUFG),
        .CE(1'b1),
        .D(p_1_in[2]),
        .Q(gray_out_OBUF[2]),
        .R(\gray_out[7]_i_1_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \gray_out_reg[3] 
       (.C(clk_IBUF_BUFG),
        .CE(1'b1),
        .D(p_1_in[3]),
        .Q(gray_out_OBUF[3]),
        .R(\gray_out[7]_i_1_n_0 ));
  (* ADDER_THRESHOLD = "35" *) 
  CARRY4 \gray_out_reg[3]_i_1 
       (.CI(1'b0),
        .CO({\gray_out_reg[3]_i_1_n_0 ,\gray_out_reg[3]_i_1_n_1 ,\gray_out_reg[3]_i_1_n_2 ,\gray_out_reg[3]_i_1_n_3 }),
        .CYINIT(1'b0),
        .DI({\gray_out[3]_i_2_n_0 ,\gray_out[3]_i_3_n_0 ,\gray_out[3]_i_4_n_0 ,green_reg[4]}),
        .O(p_1_in[3:0]),
        .S({\gray_out[3]_i_5_n_0 ,\gray_out[3]_i_6_n_0 ,\gray_out[3]_i_7_n_0 ,\gray_out[3]_i_8_n_0 }));
  FDRE #(
    .INIT(1'b0)) 
    \gray_out_reg[4] 
       (.C(clk_IBUF_BUFG),
        .CE(1'b1),
        .D(p_1_in[4]),
        .Q(gray_out_OBUF[4]),
        .R(\gray_out[7]_i_1_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \gray_out_reg[5] 
       (.C(clk_IBUF_BUFG),
        .CE(1'b1),
        .D(p_1_in[5]),
        .Q(gray_out_OBUF[5]),
        .R(\gray_out[7]_i_1_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \gray_out_reg[6] 
       (.C(clk_IBUF_BUFG),
        .CE(1'b1),
        .D(p_1_in[6]),
        .Q(gray_out_OBUF[6]),
        .R(\gray_out[7]_i_1_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \gray_out_reg[7] 
       (.C(clk_IBUF_BUFG),
        .CE(1'b1),
        .D(p_1_in[7]),
        .Q(gray_out_OBUF[7]),
        .R(\gray_out[7]_i_1_n_0 ));
  CARRY4 \gray_out_reg[7]_i_10 
       (.CI(\gray_out_reg[7]_i_11_n_0 ),
        .CO({\gray_out_reg[7]_i_10_n_0 ,\NLW_gray_out_reg[7]_i_10_CO_UNCONNECTED [2],\gray_out_reg[7]_i_10_n_2 ,\gray_out_reg[7]_i_10_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,red_reg[7],\gray_out[7]_i_13_n_0 ,\gray_out[7]_i_14_n_0 }),
        .O({\NLW_gray_out_reg[7]_i_10_O_UNCONNECTED [3],\gray_out_reg[7]_i_10_n_5 ,\gray_out_reg[7]_i_10_n_6 ,\gray_out_reg[7]_i_10_n_7 }),
        .S({1'b1,\gray_out[7]_i_15_n_0 ,\gray_out[7]_i_16_n_0 ,\gray_out[7]_i_17_n_0 }));
  CARRY4 \gray_out_reg[7]_i_11 
       (.CI(1'b0),
        .CO({\gray_out_reg[7]_i_11_n_0 ,\gray_out_reg[7]_i_11_n_1 ,\gray_out_reg[7]_i_11_n_2 ,\gray_out_reg[7]_i_11_n_3 }),
        .CYINIT(1'b0),
        .DI({\gray_out[7]_i_18_n_0 ,\gray_out[7]_i_19_n_0 ,\gray_out[7]_i_20_n_0 ,red_reg[2]}),
        .O({\gray_out_reg[7]_i_11_n_4 ,\gray_out_reg[7]_i_11_n_5 ,\gray_out_reg[7]_i_11_n_6 ,\gray_out_reg[7]_i_11_n_7 }),
        .S({\gray_out[7]_i_21_n_0 ,\gray_out[7]_i_22_n_0 ,\gray_out[7]_i_23_n_0 ,\gray_out[7]_i_24_n_0 }));
  (* ADDER_THRESHOLD = "35" *) 
  CARRY4 \gray_out_reg[7]_i_2 
       (.CI(\gray_out_reg[3]_i_1_n_0 ),
        .CO({\NLW_gray_out_reg[7]_i_2_CO_UNCONNECTED [3],\gray_out_reg[7]_i_2_n_1 ,\gray_out_reg[7]_i_2_n_2 ,\gray_out_reg[7]_i_2_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,\gray_out[7]_i_3_n_0 ,\gray_out[7]_i_4_n_0 ,\gray_out[7]_i_5_n_0 }),
        .O(p_1_in[7:4]),
        .S({\gray_out[7]_i_6_n_0 ,\gray_out[7]_i_7_n_0 ,\gray_out[7]_i_8_n_0 ,\gray_out[7]_i_9_n_0 }));
  IBUF \green_in_IBUF[1]_inst 
       (.I(green_in[1]),
        .O(green_in_IBUF[1]));
  IBUF \green_in_IBUF[2]_inst 
       (.I(green_in[2]),
        .O(green_in_IBUF[2]));
  IBUF \green_in_IBUF[3]_inst 
       (.I(green_in[3]),
        .O(green_in_IBUF[3]));
  IBUF \green_in_IBUF[4]_inst 
       (.I(green_in[4]),
        .O(green_in_IBUF[4]));
  IBUF \green_in_IBUF[5]_inst 
       (.I(green_in[5]),
        .O(green_in_IBUF[5]));
  IBUF \green_in_IBUF[6]_inst 
       (.I(green_in[6]),
        .O(green_in_IBUF[6]));
  IBUF \green_in_IBUF[7]_inst 
       (.I(green_in[7]),
        .O(green_in_IBUF[7]));
  FDRE #(
    .INIT(1'b0)) 
    \green_reg_reg[1] 
       (.C(clk_IBUF_BUFG),
        .CE(1'b1),
        .D(green_in_IBUF[1]),
        .Q(green_reg[1]),
        .R(rst_IBUF));
  FDRE #(
    .INIT(1'b0)) 
    \green_reg_reg[2] 
       (.C(clk_IBUF_BUFG),
        .CE(1'b1),
        .D(green_in_IBUF[2]),
        .Q(green_reg[2]),
        .R(rst_IBUF));
  FDRE #(
    .INIT(1'b0)) 
    \green_reg_reg[3] 
       (.C(clk_IBUF_BUFG),
        .CE(1'b1),
        .D(green_in_IBUF[3]),
        .Q(green_reg[3]),
        .R(rst_IBUF));
  FDRE #(
    .INIT(1'b0)) 
    \green_reg_reg[4] 
       (.C(clk_IBUF_BUFG),
        .CE(1'b1),
        .D(green_in_IBUF[4]),
        .Q(green_reg[4]),
        .R(rst_IBUF));
  FDRE #(
    .INIT(1'b0)) 
    \green_reg_reg[5] 
       (.C(clk_IBUF_BUFG),
        .CE(1'b1),
        .D(green_in_IBUF[5]),
        .Q(green_reg[5]),
        .R(rst_IBUF));
  FDRE #(
    .INIT(1'b0)) 
    \green_reg_reg[6] 
       (.C(clk_IBUF_BUFG),
        .CE(1'b1),
        .D(green_in_IBUF[6]),
        .Q(green_reg[6]),
        .R(rst_IBUF));
  FDRE #(
    .INIT(1'b0)) 
    \green_reg_reg[7] 
       (.C(clk_IBUF_BUFG),
        .CE(1'b1),
        .D(green_in_IBUF[7]),
        .Q(green_reg[7]),
        .R(rst_IBUF));
  IBUF ready_in_IBUF_inst
       (.I(ready_in),
        .O(ready_in_IBUF));
  OBUF ready_out_OBUF_inst
       (.I(ready_out_OBUF),
        .O(ready_out));
  FDRE #(
    .INIT(1'b0)) 
    ready_out_reg
       (.C(clk_IBUF_BUFG),
        .CE(1'b1),
        .D(ready_reg),
        .Q(ready_out_OBUF),
        .R(rst_IBUF));
  FDRE #(
    .INIT(1'b0)) 
    ready_reg_reg
       (.C(clk_IBUF_BUFG),
        .CE(1'b1),
        .D(ready_in_IBUF),
        .Q(ready_reg),
        .R(rst_IBUF));
  IBUF \red_in_IBUF[2]_inst 
       (.I(red_in[2]),
        .O(red_in_IBUF[2]));
  IBUF \red_in_IBUF[3]_inst 
       (.I(red_in[3]),
        .O(red_in_IBUF[3]));
  IBUF \red_in_IBUF[4]_inst 
       (.I(red_in[4]),
        .O(red_in_IBUF[4]));
  IBUF \red_in_IBUF[5]_inst 
       (.I(red_in[5]),
        .O(red_in_IBUF[5]));
  IBUF \red_in_IBUF[6]_inst 
       (.I(red_in[6]),
        .O(red_in_IBUF[6]));
  IBUF \red_in_IBUF[7]_inst 
       (.I(red_in[7]),
        .O(red_in_IBUF[7]));
  FDRE #(
    .INIT(1'b0)) 
    \red_reg_reg[2] 
       (.C(clk_IBUF_BUFG),
        .CE(1'b1),
        .D(red_in_IBUF[2]),
        .Q(red_reg[2]),
        .R(rst_IBUF));
  FDRE #(
    .INIT(1'b0)) 
    \red_reg_reg[3] 
       (.C(clk_IBUF_BUFG),
        .CE(1'b1),
        .D(red_in_IBUF[3]),
        .Q(red_reg[3]),
        .R(rst_IBUF));
  FDRE #(
    .INIT(1'b0)) 
    \red_reg_reg[4] 
       (.C(clk_IBUF_BUFG),
        .CE(1'b1),
        .D(red_in_IBUF[4]),
        .Q(red_reg[4]),
        .R(rst_IBUF));
  FDRE #(
    .INIT(1'b0)) 
    \red_reg_reg[5] 
       (.C(clk_IBUF_BUFG),
        .CE(1'b1),
        .D(red_in_IBUF[5]),
        .Q(red_reg[5]),
        .R(rst_IBUF));
  FDRE #(
    .INIT(1'b0)) 
    \red_reg_reg[6] 
       (.C(clk_IBUF_BUFG),
        .CE(1'b1),
        .D(red_in_IBUF[6]),
        .Q(red_reg[6]),
        .R(rst_IBUF));
  FDRE #(
    .INIT(1'b0)) 
    \red_reg_reg[7] 
       (.C(clk_IBUF_BUFG),
        .CE(1'b1),
        .D(red_in_IBUF[7]),
        .Q(red_reg[7]),
        .R(rst_IBUF));
  IBUF rst_IBUF_inst
       (.I(rst),
        .O(rst_IBUF));
endmodule
`ifndef GLBL
`define GLBL
`timescale  1 ps / 1 ps

module glbl ();

    parameter ROC_WIDTH = 100000;
    parameter TOC_WIDTH = 0;
    parameter GRES_WIDTH = 10000;
    parameter GRES_START = 10000;

//--------   STARTUP Globals --------------
    wire GSR;
    wire GTS;
    wire GWE;
    wire PRLD;
    wire GRESTORE;
    tri1 p_up_tmp;
    tri (weak1, strong0) PLL_LOCKG = p_up_tmp;

    wire PROGB_GLBL;
    wire CCLKO_GLBL;
    wire FCSBO_GLBL;
    wire [3:0] DO_GLBL;
    wire [3:0] DI_GLBL;
   
    reg GSR_int;
    reg GTS_int;
    reg PRLD_int;
    reg GRESTORE_int;

//--------   JTAG Globals --------------
    wire JTAG_TDO_GLBL;
    wire JTAG_TCK_GLBL;
    wire JTAG_TDI_GLBL;
    wire JTAG_TMS_GLBL;
    wire JTAG_TRST_GLBL;

    reg JTAG_CAPTURE_GLBL;
    reg JTAG_RESET_GLBL;
    reg JTAG_SHIFT_GLBL;
    reg JTAG_UPDATE_GLBL;
    reg JTAG_RUNTEST_GLBL;

    reg JTAG_SEL1_GLBL = 0;
    reg JTAG_SEL2_GLBL = 0 ;
    reg JTAG_SEL3_GLBL = 0;
    reg JTAG_SEL4_GLBL = 0;

    reg JTAG_USER_TDO1_GLBL = 1'bz;
    reg JTAG_USER_TDO2_GLBL = 1'bz;
    reg JTAG_USER_TDO3_GLBL = 1'bz;
    reg JTAG_USER_TDO4_GLBL = 1'bz;

    assign (strong1, weak0) GSR = GSR_int;
    assign (strong1, weak0) GTS = GTS_int;
    assign (weak1, weak0) PRLD = PRLD_int;
    assign (strong1, weak0) GRESTORE = GRESTORE_int;

    initial begin
	GSR_int = 1'b1;
	PRLD_int = 1'b1;
	#(ROC_WIDTH)
	GSR_int = 1'b0;
	PRLD_int = 1'b0;
    end

    initial begin
	GTS_int = 1'b1;
	#(TOC_WIDTH)
	GTS_int = 1'b0;
    end

    initial begin 
	GRESTORE_int = 1'b0;
	#(GRES_START);
	GRESTORE_int = 1'b1;
	#(GRES_WIDTH);
	GRESTORE_int = 1'b0;
    end

endmodule
`endif
