`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/23/2023 08:04:05 AM
// Design Name: 
// Module Name: sim
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


module sim( );
    reg a;
    wire b;
    
    initial begin
        a = 1;
    end
    
    Inverter inverter(
    .inverter_in(a),
    .inverter_out(b)
    );
endmodule
