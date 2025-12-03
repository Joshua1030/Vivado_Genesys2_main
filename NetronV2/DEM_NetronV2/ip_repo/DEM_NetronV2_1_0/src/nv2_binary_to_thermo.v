`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/08/2024 11:20:01 AM
// Design Name: 
// Module Name: nv2_binary_to_thermo
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


module nv2_binary_to_thermo(
    input wire [2:0] binary_in,
    input wire clk,
    input wire rstb,
    output reg [6:0] thermo_out
    );
    
    always @(*) begin
        if(!rstb) begin
            thermo_out = 7'b0;
        end
        else begin
            case(binary_in)
                3'b000: thermo_out = 7'b000_0000;
                3'b001: thermo_out = 7'b000_0001;
                3'b010: thermo_out = 7'b000_0011;
                3'b011: thermo_out = 7'b000_0111;
                3'b100: thermo_out = 7'b000_1111;
                3'b101: thermo_out = 7'b001_1111;
                3'b110: thermo_out = 7'b011_1111;
                default: thermo_out = 7'b111_1111;
            endcase
        end
    end
    
endmodule
