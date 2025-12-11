`timescale 1ns / 1ps
module DFFR(
    input wire D,
    input wire reset,
    input wire clk,
    output reg Q
    );   
    always @ (posedge clk or posedge reset) begin
        if (reset) begin
            Q <= 1'b0;
        end
        else begin 
            Q <= D;
        end        
    end
endmodule
