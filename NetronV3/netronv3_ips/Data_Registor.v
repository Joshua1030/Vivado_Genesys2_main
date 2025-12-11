`timescale 1ns / 1ps
module Data_Registor(
    input wire [3:0] D,
    input wire reset,
    input wire clk,
    output wire [3:0] Q
    );    
    DFFR Data0(.D(D[0]), .Q(Q[0]), .clk(clk), .reset(reset));
    DFFR Data1(.D(D[1]), .Q(Q[1]), .clk(clk), .reset(reset));
    DFFR Data2(.D(D[2]), .Q(Q[2]), .clk(clk), .reset(reset));  
    DFFR Data3(.D(D[3]), .Q(Q[3]), .clk(clk), .reset(reset));  
endmodule
