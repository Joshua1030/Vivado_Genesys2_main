`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/08/2024 12:22:06 PM
// Design Name: 
// Module Name: nv2_butterfly_layer
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


module nv2_butterfly_layer(
    input [7:0] bits_in,
    input clk,
    input rstb,
    output [7:0] swapped_bits
    );
    
    // instantiate 4 swappers
    nv2_swapper ()
    
    
endmodule
