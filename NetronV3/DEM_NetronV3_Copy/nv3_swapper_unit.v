`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/09/2024 02:25:37 PM
// Design Name: 
// Module Name: nv3_swapper_unit
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


module nv3_swapper_unit(
    input wire [1:0] data_in,
    input wire clk,
    input wire rstb,
    output reg top,
    output reg bottom
    );
    parameter wastop = 1'b1;
    parameter wasbottom = 1'b0;
    reg oneflag;
    
    
    always @(*) begin
    // send straight through if bits are the same
        if(data_in[1] == data_in[0]) begin
            top = data_in[1];
            bottom = data_in[0];
        end
        else begin
        // based on where last 1 was sent, send elsewhere
            case(oneflag)
                wastop: begin
                    top = 1'b0;
                    bottom = 1'b1;
                end
                wasbottom: begin
                    top = 1'b1;
                    bottom = 1'b0;
                end
            endcase
        end
    end
    
    always @(posedge clk) begin
        if(!rstb) begin
            oneflag <= 1'b0;
        end
        else begin
            if(data_in[1] != data_in[0]) begin
                if(oneflag == wastop)
                    oneflag <= wasbottom;
                else
                    oneflag <= wastop;
            end
        end
    end
endmodule
