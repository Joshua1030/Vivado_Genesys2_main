`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Toronto
// Engineer: Jianxiong Xu
// 
// Create Date: 08/31/2019 08:56:46 PM
// Design Name: 
// Module Name: addr_sel
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: This block is used for control the address of the discrete memory 
// block, at each trigger signal the address of the discrete memory will change.
// The streaming data will be stored in the register.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//////////////////////////////////////////////////////////////////////////////////
module addr_sel(
    input wire reset,
    input wire trg, // This signal should be synchronized with the ADC sampling frequency.
    output reg [12:0] addr,
    output reg [1:0] outer_read_addr,
    output reg start_sending_buf
   );
always@(negedge trg or posedge reset)begin
     if(reset) begin
         addr <= 13'd0;
     end
     else if(addr[10:0] == 11'd1038) begin
        outer_read_addr <= addr[12:11];
        addr <= addr + 1'b1;
        
     end
     else if(addr[10:0] == 11'd1039) begin
         addr <= (addr & 13'b1100000000000) + 13'b0100000000000;
         start_sending_buf <=1'b1;
     end
     else begin
         addr <= addr + 1'b1;
         start_sending_buf <=1'b0;
     end
  end
  
//  always@(posedge start_sending_buf or posedge reset) begin
//     if(reset) begin
//         //outer_read_addr <= 2'b11;
//         outer_read_addr <= 2'b00;
//     end
//     else begin
//           outer_read_addr <= addr[12:11] - 1'b1;
//     end
//  end
  
  
endmodule
