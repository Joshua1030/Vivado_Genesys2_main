`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/09/2024 01:30:29 PM
// Design Name: 
// Module Name: nv3_butterfly_shuffler
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


module nv3_butterfly_shuffler(
    input wire [15:0] data_in,
    input wire clk,
    input wire rstb,
    output wire [15:0] data_out
    );
    
    wire [15:0] internal1;
    wire [15:0] arranged_internal1;
    wire [15:0] internal2;
    wire [15:0] arranged_internal2;
    wire [15:0] internal3;
    wire [15:0] arranged_internal3;
    
    // intantiate 4 layers of 8 shufflers
    nv3_butterfly_layer layer1(.bits_in(data_in), .clk(clk), .rstb(rstb), .swapped_bits(internal1));
    nv3_butterfly_layer layer2(.bits_in(arranged_internal1), .clk(clk), .rstb(rstb), .swapped_bits(internal2));
    nv3_butterfly_layer layer3(.bits_in(arranged_internal2), .clk(clk), .rstb(rstb), .swapped_bits(internal3));
    nv3_butterfly_layer layer4(.bits_in(arranged_internal3), .clk(clk), .rstb(rstb), .swapped_bits(data_out));
    
    assign arranged_internal1 = {internal1[15], internal1[13], internal1[14], internal1[12], 
                                    internal1[11], internal1[9], internal1[10], internal1[8],
                                    internal1[7], internal1[5], internal1[6], internal1[4], 
                                    internal1[3], internal1[1], internal1[2], internal1[0]};
    
    assign arranged_internal2 = {internal2[15], internal2[11], internal2[13], internal2[9], 
                                    internal2[14], internal2[10], internal2[12], internal2[8],
                                    internal2[7], internal2[3], internal2[5], internal2[1], 
                                    internal2[6], internal2[2], internal2[4], internal2[0]};
                                    
    assign arranged_internal3 = {internal3[15], internal3[7], internal3[13], internal3[5], 
                                    internal3[11], internal3[3], internal3[9], internal3[1],
                                    internal3[14], internal3[6], internal3[12], internal3[4], 
                                    internal3[10], internal3[2], internal3[8], internal3[0]};
    
endmodule
