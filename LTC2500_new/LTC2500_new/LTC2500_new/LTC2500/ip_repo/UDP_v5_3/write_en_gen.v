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
module wirte_en_gen(
    input wire reset,
    input wire clk_ref, // Depend on the clock frequency, can be 10MHz for our channel (2MHz clk_freq).
    input wire trg, // the frequency of this trigger signal should be same as the clock frequncy.
    output reg wr_en
    ); 
    always @(*) begin
        if (reset) begin
            wr_en <= 1'b0;
        end
        else begin 
            wr_en <= trg;
        end
    end
    
    
//    reg flag;
//    always@(posedge clk_ref or posedge reset)begin
//      if(reset) begin                                     
//        wr_en <= 1'b0;                                 
//        flag <= 1'b1;                              
//      end
//      else if (flag == 1'b1 && trg == 1'b0) begin 
//        wr_en <= 1'b0;                              
//        flag <= 1'b1;                              
//      end
//      else if (flag == 1'b1 && trg == 1'b1) begin 
//        wr_en <=1'b0;                               
//        flag <=1'd0;                             
//      end
//      else if (flag == 1'b0 && trg == 1'b0) begin
//        wr_en <=1'b1;                                   
//        flag <=1'd1;                                     
//      end
//      else begin
//        flag <= 1'b0;                                  
//      end
//    end
endmodule
