`timescale 1ns / 1ps
module MSB(    
    input wire MSB_in,
    input wire Vop,
    input wire clk_sample,
    output wire DATA,
    output wire feedback
    );
    wire [1:0] internal_logic;  
    DFFR Data(.D(Vop), .Q(DATA), .clk(MSB_in), .reset(clk_sample));
    assign internal_logic[0] = ~(DATA && MSB_in);
    assign feedback = ~(internal_logic[0] && MSB_in);
endmodule