`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/27/2024 05:29:25 PM
// Design Name: 
// Module Name: mux
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

module mux (
    input wire clk1,    
    input wire data1,    
    input wire clk2,
    input wire [2:0] data2,
    input wire sel,  // Select signal
    output wire outclk,    
    output wire [7:0] outdata
);

    assign outclk = (sel) ? clk2 : clk1;
    assign outdata = (sel) ? {5'b0, data2} : {7'b0, data1};

endmodule

