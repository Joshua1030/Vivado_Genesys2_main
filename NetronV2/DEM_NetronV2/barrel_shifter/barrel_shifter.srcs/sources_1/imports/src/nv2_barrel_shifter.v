`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/08/2024 11:18:34 AM
// Design Name: 
// Module Name: nv2_barrel_shifter
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


module nv2_barrel_shifter(
    input wire [7:0] data_in,
    input wire clk,
    input wire rstb,
    output reg [6:0] data_out
    );
    
    parameter left  = 1'b0;
    parameter right = 1'b1;
    
    reg shift_dir;
    
    always @(data_in) begin
    // bidirectional circular shifting depending on which shift direction is chosen
        if(shift_dir == left) begin
        // circular shift left
            if(data_in[6] == 0)
                data_out = {data_in[5:0], data_in[7]};
            else if(data_in[5] == 0)
                data_out = {data_in[4:0], data_in[7:6]};
            else if(data_in[4] == 0)
                data_out = {data_in[3:0], data_in[7:5]};
            else if(data_in[3] == 0)
                data_out = {data_in[2:0], data_in[7:4]};
            else if(data_in[2] == 0)
                data_out = {data_in[1:0], data_in[7:3]};
            else
                data_out = {data_in[0], data_in[7:2]};
        end
        else begin
        // circular shift right
            if(data_in[1] == 0)
                data_out = {data_in[0], data_in[7:2]};
            else if(data_in[2] == 0)
                data_out = {data_in[1:0], data_in[7:3]};
            else if(data_in[3] == 0)
                data_out = {data_in[2:0], data_in[7:4]};
            else if(data_in[4] == 0)
                data_out = {data_in[3:0], data_in[7:5]};
            else if(data_in[5] == 0)
                data_out = {data_in[4:0], data_in[7:6]};
            else
                data_out = {data_in[5:0], data_in[7]}; // FIX THIS
        end
    end
    
    // switch direction of shift each time
    always @(posedge clk) begin
        if(!rstb) begin
            shift_dir <= left;
        end
        else begin
            if(shift_dir == left)
                shift_dir <= right;
            else
                shift_dir <= left;
        end
    end

endmodule
