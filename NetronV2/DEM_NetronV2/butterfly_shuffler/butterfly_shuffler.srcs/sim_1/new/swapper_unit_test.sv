`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/08/2024 04:15:43 PM
// Design Name: 
// Module Name: swapper_unit_test
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


module swapper_unit_test();
    reg [1:0] data_in;
    reg clk;
    reg rstb;
    wire top;
    wire bottom;
    
    initial clk = 1'b0;
    always #5
        clk = ~clk;
    
    initial begin
    rstb = 1'b0;
    #5; rstb = 1'b1;
    data_in = 2'b11;
    #10; data_in = 2'b00;
    #10 data_in = 2'b10;
    #10 data_in = 2'b10;
    #10 data_in = 2'b01;
    #10 data_in = 2'b00;
    #10 data_in = 2'b01;
    end
    
    nv2_swapper_unit test0(data_in, clk, rstb, top, bottom);
    
endmodule
