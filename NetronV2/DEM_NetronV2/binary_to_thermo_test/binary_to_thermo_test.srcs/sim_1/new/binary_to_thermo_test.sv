`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/08/2024 03:55:42 PM
// Design Name: 
// Module Name: binary_to_thermo_test
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


module binary_to_thermo_test();
    reg clk;
    reg rstb;
    reg [2:0] binary_in;
    wire [6:0] thermo_out;
    
    initial clk = 1'b0;
    initial rstb = 1'b0;
    always #5
        clk = ~clk;
    
    initial begin
        
        #10; rstb = 1'b1;
        binary_in = 3'b000;
        #10; binary_in = 3'b001;
        #10; binary_in = 3'b010;
        #10; binary_in = 3'b011;
        #10; binary_in = 3'b100;
        #10; binary_in = 3'b101;
        #10; binary_in = 3'b110;
        #10; binary_in = 3'b111;
    end
    
    nv2_binary_to_thermo u0(binary_in, clk, rstb, thermo_out);
endmodule
