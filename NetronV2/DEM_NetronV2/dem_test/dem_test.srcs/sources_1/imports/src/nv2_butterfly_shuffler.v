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
    output wire [7:0] data_out // FIX THIS
    );
    // ADD ALL ARRANGED THINGS
    wire [7:0] internal1;
    wire [7:0] arranged_internal1;
    wire [7:0] internal2;
    wire [7:0] arranged_internal2;
    
    // instantiate 3 layers of 4 shufflers
    nv2_four_swapper layer1(.bits_in(data_in), .clk(clk), .rstb(rstb), .swapped_bits(internal1));
    nv2_four_swapper layer2(.bits_in(arranged_internal1), .clk(clk), .rstb(rstb), .swapped_bits(internal2));
    nv2_four_swapper layer3(.bits_in(arranged_internal2), .clk(clk), .rstb(rstb), .swapped_bits(data_out));
    
    assign arranged_internal1 = {internal1[7], internal1[5], internal1[6], internal1[4], 
                                    internal1[3], internal1[1], internal1[2], internal1[0]};
    
    assign arranged_internal2 = {internal2[7], internal2[3], internal2[5], internal2[1], 
                                    internal2[6], internal2[2], internal2[4], internal2[0]};
    
endmodule
