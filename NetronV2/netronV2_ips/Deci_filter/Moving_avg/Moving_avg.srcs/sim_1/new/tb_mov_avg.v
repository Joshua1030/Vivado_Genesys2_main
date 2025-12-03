`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/23/2024 10:41:41 AM
// Design Name: 
// Module Name: tb_mov_avg
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


module tb_mov_avg;
    reg clk;
    reg rst;
    reg x;
    wire [3:0] y;
    wire [5:0] z;
    
    mov_avg uut (
        .clk(clk),
        .rst(rst),
        .x(x),
        .y(y),
        .z(z)
    );

    // Clock generation
    always #5 clk = ~clk; // 10 ns period for the clock

    // Test sequence
    initial begin
        // Initialize signals
        clk = 0;
        rst = 1;
        x = 0;

        // Apply reset
        #10 rst = 0;
        
        // Test with different input values
        #10 x = 1; // Apply input
        #10 x = 0; // Apply input
        #10 x = 1; // Apply input
        #10 x = 1; // Apply input
        #10 x = 0; // Apply input
        #10 x = 1; // Apply input
        #10 x = 0; // Apply input
        #10 x = 1; // Apply input

        // Add more test cases as needed
        #10 x = 0; // Apply input
        #10 x = 1; // Apply input
        
        
        #10 x = 1; // Apply input
        #10 x = 1; // Apply input
        #10 x = 1; // Apply input
        #10 x = 1; // Apply input
        #10 x = 1; // Apply input
        #10 x = 1; // Apply input
        #10 x = 1; // Apply input
        #10 x = 1; // Apply input
        #10 x = 1; // Apply input
        #10 x = 1; // Apply input
        #10 x = 1; // Apply input
        #10 x = 1; // Apply input
        #10 x = 1; // Apply input
        #10 x = 1; // Apply input
        #10 x = 1; // Apply input
        #10 x = 1; // Apply input
        #10 x = 1; // Apply input
        #10 x = 1; // Apply input
        #10 x = 1; // Apply input
        #10 x = 1; // Apply input
        #10 x = 1; // Apply input
        #10 x = 1; // Apply input
        #10 x = 1; // Apply input
        #10 x = 1; // Apply input
        #10 x = 1; // Apply input
        #10 x = 1; // Apply input
        #10 x = 0; // Apply input
        #10 x = 1; // Apply input
        #10 x = 0; // Apply input
        #10 x = 1; // Apply input
        #10 x = 0; // Apply input
        #10 x = 1; // Apply input
        #10 x = 0; // Apply input
        #10 x = 1; // Apply input
        #10 x = 0; // Apply input
        #10 x = 1; // Apply input
        #10 x = 0; // Apply input
        #10 x = 1; // Apply input
        #10 x = 0; // Apply input
        #10 x = 1; // Apply input
        #10 x = 0; // Apply input
        #10 x = 1; // Apply input
        #10 x = 0; // Apply input
        #10 x = 1; // Apply input
        #10 x = 0; // Apply input
        #10 x = 1; // Apply input
        #10 x = 0; // Apply input
        #10 x = 1; // Apply input
        #10 x = 0; // Apply input
        #10 x = 1; // Apply input
        #10 x = 0; // Apply input
        #10 x = 1; // Apply input
        #10 x = 0; // Apply input
        #10 x = 1; // Apply input
        #10 x = 0; // Apply input
        #10 x = 1; // Apply input
        #10 x = 0; // Apply input
        #10 x = 1; // Apply input
        #10 x = 0; // Apply input
        #10 x = 1; // Apply input
        #10 x = 0; // Apply input
        #10 x = 1; // Apply input
        #10 x = 0; // Apply input
        #10 x = 1; // Apply input
        #10 x = 0; // Apply input
        #10 x = 1; // Apply input
        #10 x = 0; // Apply input
        #10 x = 1; // Apply input
        #10 x = 0; // Apply input
        #10 x = 1; // Apply input
        #10 x = 0; // Apply input
        #10 x = 1; // Apply input
        #10 x = 0; // Apply input
        #10 x = 1; // Apply input
        #10 x = 0; // Apply input
        #10 x = 1; // Apply input
        #10 x = 0; // Apply input
        #10 x = 1; // Apply input
        #10 x = 0; // Apply input
        #10 x = 1; // Apply input
        #10 x = 0; // Apply input
        #10 x = 1; // Apply input
        #10 x = 0; // Apply input
        #10 x = 1; // Apply input
        #10 x = 0; // Apply input
        #10 x = 1; // Apply input
        #10 x = 0; // Apply input
        #10 x = 1; // Apply input
        #10 x = 0; // Apply input
        #10 x = 1; // Apply input
        #10 x = 0; // Apply input
        #10 x = 1; // Apply input
        #10 x = 0; // Apply input
        #10 x = 1; // Apply input
        #10 x = 0; // Apply input
        #10 x = 1; // Apply input
        // Finish simulation after some time
        #50 $finish;
    end

    // Monitor signal changes
//    initial begin
//        $monitor("Time: %0t | rst: %b | x: %b | z: %h", $time, rst, x, z);
//    end
    
endmodule
