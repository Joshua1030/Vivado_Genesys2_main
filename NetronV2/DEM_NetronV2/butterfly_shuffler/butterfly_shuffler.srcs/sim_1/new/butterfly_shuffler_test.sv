`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/09/2024 09:31:05 AM
// Design Name: 
// Module Name: butterfly_shuffler_test
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


module butterfly_shuffler_test();
    reg [7:0] data_in;
    reg clk;
    reg rstb;
    wire [7:0] data_out;
    
    initial clk = 1'b1;
    always #5
        clk = ~clk;
    
    initial begin
        rstb = 1'b0;
        #5; rstb = 1'b1;
        data_in = 8'b0110_1110;
        #10; data_in = 8'b1101_0110;
        #10; data_in = 8'b0000_1000;
    end
    
    nv2_butterfly_shuffler test2(data_in, clk, rstb, data_out);
endmodule
