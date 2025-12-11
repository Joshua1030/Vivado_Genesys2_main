`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/09/2024 12:12:57 PM
// Design Name: 
// Module Name: nv3_dem_top
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


module nv3_dem_top(
    input wire [3:0] data,
    input wire enable,
    input wire clk,
    input wire rstb,
    output reg [15:0] CapSel
    );
    
    wire [15:0] butterfly_in; // same as thermometer data
    wire [15:0] butterfly_out; 
    // don't need barrel shifter or output logic at all
    
    always @(*) begin
        if(enable) begin
            if(data == 4'b0000)
                CapSel = 16'h0000;
            else if(data == 4'b1111)
                CapSel = 16'hFFFF;
            else begin
                CapSel = butterfly_out;
            end
        end
        else
            CapSel = {{8{data[3]}}, {4{data[2]}}, {2{data[1]}}, data[0], 1'b0};
    end
    
    nv3_binary_to_thermo binary_to_thermo(
        .binary_in(data),
        .clk(clk),
        .rstb(rstb),
        .thermo_out(butterfly_in)
    );
    
    nv3_butterfly_shuffler butterfly(
        .data_in(butterfly_in),
        .clk(clk),
        .rstb(rstb),
        .data_out(butterfly_out)
    );
    
endmodule
