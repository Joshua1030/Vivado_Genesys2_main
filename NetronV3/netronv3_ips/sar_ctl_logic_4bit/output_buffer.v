`timescale 1ns / 1ps
module output_buffer(
    input wire [3:0] D,
    input wire reset,
    input wire clk,
    output reg [3:0] Q
    );   
    always @ (posedge clk or posedge reset) begin
        if (reset) begin
            Q <= 4'b0000;
        end
        else begin 
            Q <= D;
        end        
    end
endmodule