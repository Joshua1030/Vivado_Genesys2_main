`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/08/2024 10:08:09 AM
// Design Name: 
// Module Name: dem_top
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


module dem_top(
    input wire [2:0] data,
    input wire enable,
    input wire clk,
    input wire rstb,
    output reg [6:0] CapSel
    );
    
    wire [6:0] data_thermo;
    wire [7:0] butterfly_in;
    wire [7:0] butterfly_out;
    wire [6:0] barrel_out;
    
    always@(*) begin
        if (!rstb) begin
            CapSel = 7'b0000000;
        end
        else begin
            if(enable) begin
            // edge cases -> all capacitors are off or on
                if(data == 3'b000) begin
                    CapSel = 7'b000_0000;
                end
                else if(data == 3'b111) begin
                    CapSel = 7'b111_1111;
                end
                else begin
                // output logic
                // output logic block ->input: [7:0] butterfly_out (8'b ideal capacitor selection), output: [6:0] CapSel (7'b CapSel)
                    if(butterfly_out[7] == 0)
                        CapSel = butterfly_out[6:0];
                    else if(butterfly_out[1] == 0 && butterfly_out[0] == 0)
                        CapSel = butterfly_out[7:1];
                    else
                    // shift the output until there's a 0 at MSB or LSB
                        CapSel = barrel_out;
                end      
            end
            else begin
            // bypass butterfly
                CapSel = {{4{data[2]}}, {2{data[1]}}, data[0]};
            end
        end
    end
    
    
    // binary to thermo ->input: [2:0] data (3'b data), output: [6:0] data_thermo (7'b, must be fed to butterfly shuffler)
    nv2_binary_to_thermo binary_to_thermo(
            .binary_in(data),
            .clk(clk),
            .rstb(rstb),
            .thermo_out(data_thermo)
    );
    
    // butterfly shuffler ->input: [7:0] butterfly_in (8'b output of bin-to-therm), 
    //                      output: [7:0] butterfly_out(8'b ideal capacitor selection)
    nv2_butterfly_shuffler butterfly(
            .data_in(butterfly_in),
            .clk(clk),
            .rstb(rstb),
            .data_out(butterfly_out)
    );

    // barrel shifter ->input: [7:0] butterfly_out (8'b ideal cap selection (with 0 not at LSB or MSB)), output: [6:0] barrel_out (7'b shifted cap selection)
    nv2_barrel_shifter barrel_shifter(
            .data_in(butterfly_out),
            .clk(clk),
            .rstb(rstb),
            .data_out(barrel_out) 
    );
    
    // assign butterfly_in
    assign butterfly_in = {1'b0, data_thermo};
    
endmodule
