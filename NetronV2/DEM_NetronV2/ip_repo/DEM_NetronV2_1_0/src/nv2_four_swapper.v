`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/08/2024 12:39:58 PM
// Design Name: 
// Module Name: nv2_four_swapper
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


module nv2_four_swapper(
    input wire [7:0] bits_in,
    input wire clk,
    input wire rstb,
    output wire [7:0] swapped_bits
    );
    
    // instantiate 4 swappers
    nv2_swapper_unit u0(.data_in(bits_in[1:0]), .clk(clk), .rstb(rstb), .top(swapped_bits[1]), .bottom(swapped_bits[0]));
    nv2_swapper_unit u1(.data_in(bits_in[3:2]), .clk(clk), .rstb(rstb), .top(swapped_bits[3]), .bottom(swapped_bits[2]));
    nv2_swapper_unit u2(.data_in(bits_in[5:4]), .clk(clk), .rstb(rstb), .top(swapped_bits[5]), .bottom(swapped_bits[4]));
    nv2_swapper_unit u3(.data_in(bits_in[7:6]), .clk(clk), .rstb(rstb), .top(swapped_bits[7]), .bottom(swapped_bits[6]));
    
endmodule
