`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/31/2019 07:48:04 PM
// Design Name: 
// Module Name: wirte_en_gen
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
//////////////////////////////////////////////////////////////////////////////////
module start_sending_gen(
    input wire reset,
    input wire clk100MHz, // Has to be 100MHz
    input wire [10:0] addr,
    output reg start_sending
    ); 
    reg flag;
    always@(posedge clk100MHz or posedge reset)begin
       if(reset) begin                                        
           start_sending <= 1'b0;
           flag <= 1'b0;                                
       end
       else if ((addr == 11'd1039) && (flag == 1'b1))begin
           start_sending <= 1'b1;
           flag <= 1'b1;
       end
       else if (addr == 11'd0 && flag == 1'b1)begin     
           flag <= 1'b0;                                      
           start_sending <= 1'b0; 
       end
       else if (addr >= 11'd0 && flag == 1'b0)begin     
           flag <= 1'b1;                                 
           start_sending <= 1'b0; 
       end
       else begin
           flag <= 1'b1;                          
       end
    end       
endmodule
