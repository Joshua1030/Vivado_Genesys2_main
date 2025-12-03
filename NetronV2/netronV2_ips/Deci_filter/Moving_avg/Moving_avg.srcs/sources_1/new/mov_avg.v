`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/23/2024 10:23:18 AM
// Design Name: 
// Module Name: mov_avg
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


module mov_avg(
    input clk,
    input rst,
    input x,
    output reg [3:0]y,
    output reg [5:0]z
    );
    
    
    
    reg [7 : 0] x_reg;  // Shift register for x[n]
    reg [3 : 0] y_reg [7:0]; 

	integer i;

    always @ (posedge clk)
    begin
        if (rst == 1'b1)
        begin
            x_reg <= 8'b0; // Initialize reg_x to 0
            // Initialize reg_y array elements to 0
            for (i = 0; i < 8; i = i + 1)
                y_reg[i] <= 4'b0;
            y <= 4'b0; // Initialize y to 0
            z <= 6'b0; // Initialize z to 0    
        end
        else
        begin
            x_reg <= {x_reg[6:0], x};
            for (i = 0; i < 7; i = i + 1)
                y_reg[i] <= y_reg[i+1]; // Shift reg_y values
            y_reg[7] <= y; // Insert new y value
            
            y <= x_reg[7] + x_reg[6] + x_reg[5] + x_reg[4] + x_reg[3] + x_reg[2] + x_reg[1] + x_reg[0];      
            z <= (y_reg[7] + y_reg[6] + y_reg[5] + y_reg[4] + y_reg[3] + y_reg[2] + y_reg[1] + y_reg[0] < 7'b1000000) 
                 ? (y_reg[7] + y_reg[6] + y_reg[5] + y_reg[4] + y_reg[3] + y_reg[2] + y_reg[1] + y_reg[0]) 
                 : 6'b111111; // Saturate z to 63 if the sum exceeds 63
        end
    end
endmodule
