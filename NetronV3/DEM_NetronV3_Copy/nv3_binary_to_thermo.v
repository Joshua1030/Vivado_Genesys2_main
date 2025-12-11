`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/09/2024 01:29:06 PM
// Design Name: 
// Module Name: nv3_binary_to_thermo
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


module nv3_binary_to_thermo(
    input wire [3:0] binary_in,
    input wire clk,
    input wire rstb,
    output reg [15:0] thermo_out
    );
    
    always @(*) begin
        if(!rstb)
            thermo_out = 16'b0;
        else begin
            case(binary_in)
                4'h1: thermo_out = 16'h0001;
                4'h2: thermo_out = 16'h0003;
                4'h3: thermo_out = 16'h0007;
                4'h4: thermo_out = 16'h000F;
                4'h5: thermo_out = 16'h001F;
                4'h6: thermo_out = 16'h003F;
                4'h7: thermo_out = 16'h007F;
                4'h8: thermo_out = 16'h00FF;
                4'h9: thermo_out = 16'h01FF;
                4'hA: thermo_out = 16'h03FF;
                4'hB: thermo_out = 16'h07FF;
                4'hC: thermo_out = 16'h0FFF;
                4'hD: thermo_out = 16'h1FFF;
                default: thermo_out = 16'h3FFF;
            endcase
        end
    end
    
endmodule
