`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/08/2024 02:40:19 PM
// Design Name: 
// Module Name: barrel_shifter_test
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


module barrel_shifter_test();
    reg clk;
    reg rstb;
    reg [7:0] data_in;
    wire [6:0] data_out;
    
    initial clk = 1'b0;
    always #5
        clk = ~clk;
    initial begin
        #10; rstb = 1'b0;
        #10; rstb = 1'b1;
        data_in = 8'b1000_0001; // data_out = 000_0011
        #10; data_in = 8'b1000_0001; // data_out = 110_0000
        #10; data_in = 8'b1100_0001; // data_out = 000_0111
        #10; data_in = 8'b1000_0011; // data_out = 111_0000
        #10; data_in = 8'b1110_0001; // data_out = 000_1111
        #10; data_in = 8'b1000_0111; // data_out = 111_1000
        #10; data_in = 8'b1111_0001; // data_out = 001_1111
        #10; data_in = 8'b1000_1111; // data_out = 111_1100
        #10; data_in = 8'b1111_1001; // data_out = 011_1111
        #10; data_in = 8'b1001_1111; // data_out = 111_1110
        #10; data_in = 8'b1111_1101; // data_out = 111_1111
        #10; data_in = 8'b1011_1111; // data_out = 111_1111
    end
    
    nv2_barrel_shifter u0(data_in, clk, rstb, data_out);
    
endmodule
