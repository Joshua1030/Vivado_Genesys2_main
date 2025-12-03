`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/08/2024 04:51:35 PM
// Design Name: 
// Module Name: four_swapper_test
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


module four_swapper_test();
    reg [7:0] bits_in;
    reg clk;
    reg rstb;
    wire [7:0] swapped_bits;
    
    initial clk = 1'b0;
    always #5
        clk = ~clk;
    
    initial begin
        rstb = 1'b0;
        #5; rstb = 1'b1;
        bits_in = 8'b1101_0010; // swapped = 1101_0001
        #10; bits_in = 8'b0110_0111; // swapped = 1010_0111
        #10; bits_in = 8'b1010_1101; // swapped = 1001_1110
    end
    
    nv2_four_swapper test1(bits_in, clk, rstb, swapped_bits);
    
endmodule
