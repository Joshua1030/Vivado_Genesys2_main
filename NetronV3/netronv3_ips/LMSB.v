`timescale 1ns / 1ps
module LMSB(
    input wire decision_higher,
    input wire decision_lower,
    input wire Vop,
    input wire clk_sample,
    output wire DATA,
    output wire feedback
    );
    wire [1:0] internal_logic;  
    DFFR Data(.D(Vop), .Q(DATA), .clk(decision_lower), .reset(clk_sample));
    assign internal_logic[0] = ~(DATA && decision_lower);
    assign internal_logic[1] = ~((~decision_lower) && decision_higher);
    assign feedback = ~(internal_logic[0] && internal_logic[1]);
endmodule
