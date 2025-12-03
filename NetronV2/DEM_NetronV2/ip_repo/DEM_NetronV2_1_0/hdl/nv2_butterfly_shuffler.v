`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/08/2024 11:18:34 AM
// Design Name: 
// Module Name: nv2_butterfly_shuffler
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


module nv2_butterfly_shuffler(
    input wire [7:0] data_in,
    input wire clk,
    input wire rstb,
    output reg [7:0] data_out
    );
    wire [7:0] internal1;
    wire [7:0] internal2;
    
    // instantiate 3 layers of 4 shufflers
    nv2_butterfly_layer layer1(.bits_in(data_in), .clk(clk), .rstb(rstb), .swapped_bits(internal1));
    nv2_butterfly_layer layer2(.bits_in(internal1), .clk(clk), .rstb(rstb), .swapped_bits(internal2));
    nv2_butterfly_layer layer3(.bits_in(internal2), .clk(clk), .rstb(rstb), .swapped_bits(data_out));
endmodule
