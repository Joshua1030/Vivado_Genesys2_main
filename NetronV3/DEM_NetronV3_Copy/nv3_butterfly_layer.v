`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/09/2024 02:11:12 PM
// Design Name: 
// Module Name: nv3_butterfly_layer
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


module nv3_butterfly_layer(
    input wire [15:0] bits_in,
    input wire clk,
    input wire rstb,
    output wire [15:0] swapped_bits
    );
    
    //instantiate 8 swappers
    nv3_swapper_unit u0(.data_in(bits_in[1:0]), .clk(clk), .rstb(rstb), .top(swapped_bits[1]), .bottom(swapped_bits[0]));
    nv3_swapper_unit u1(.data_in(bits_in[3:2]), .clk(clk), .rstb(rstb), .top(swapped_bits[3]), .bottom(swapped_bits[2]));
    nv3_swapper_unit u2(.data_in(bits_in[5:4]), .clk(clk), .rstb(rstb), .top(swapped_bits[5]), .bottom(swapped_bits[4]));
    nv3_swapper_unit u3(.data_in(bits_in[7:6]), .clk(clk), .rstb(rstb), .top(swapped_bits[7]), .bottom(swapped_bits[6]));
    nv3_swapper_unit u4(.data_in(bits_in[9:8]), .clk(clk), .rstb(rstb), .top(swapped_bits[9]), .bottom(swapped_bits[8]));
    nv3_swapper_unit u5(.data_in(bits_in[11:10]), .clk(clk), .rstb(rstb), .top(swapped_bits[11]), .bottom(swapped_bits[10]));
    nv3_swapper_unit u6(.data_in(bits_in[13:12]), .clk(clk), .rstb(rstb), .top(swapped_bits[13]), .bottom(swapped_bits[12]));
    nv3_swapper_unit u7(.data_in(bits_in[15:14]), .clk(clk), .rstb(rstb), .top(swapped_bits[15]), .bottom(swapped_bits[14]));
    
endmodule
