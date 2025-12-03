`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/24/2024 05:22:10 PM
// Design Name: 
// Module Name: sar_sim
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


module sar_sim(
    input wire NS_ADC_CLKS,  // Clock signal for the 3-bit counter
    input wire NS_ADC_CLK,   // Clock signal for the 2-bit counter
    input wire reset_n,      // Active-low reset signal
    output reg NS_ADC_OUT,   // Output selected bit from the 3-bit counter
    output reg NS_ADC_OUTB,   // Inverted output
    output reg [2:0] counter_3bit,
    output reg [1:0] counter_2bit
    
);

    // 3-bit counter
    
    always @(posedge NS_ADC_CLKS) begin
        if (!reset_n) begin
            counter_3bit <= 3'b000;  // Reset the 3-bit counter to 0
        end else begin
            counter_3bit <= counter_3bit + 1;
        end
    end

    // 2-bit counter
    reg [1:0] counter_2bit;
    always @(negedge NS_ADC_CLK) begin
        if (!reset_n) begin
            counter_2bit <= 2'b00;  // Reset the 2-bit counter to 0
        end else begin
            if (counter_2bit == 2'b00) begin
                counter_2bit <= 2'b01;
            end
            else if (counter_2bit == 2'b01) begin
                counter_2bit <= 2'b10;
            end
            else if (counter_2bit == 2'b10) begin
                counter_2bit <= 2'b00;
            end
            else begin
                counter_2bit <= 2'b00;
            end
        end
    end

    // Combinational logic for output based on NS_ADC_CLK
    always @(*) begin
        if (!NS_ADC_CLK) begin
            NS_ADC_OUT = 1'b1;    // Set NS_ADC_OUT to 1 when NS_ADC_CLK is low
            NS_ADC_OUTB = 1'b1;   // Set NS_ADC_OUTB to 1 when NS_ADC_CLK is low
        end else begin
            NS_ADC_OUT = counter_3bit[counter_2bit];  // Select bit from 3-bit counter when NS_ADC_CLK is high
            NS_ADC_OUTB = ~NS_ADC_OUT;                // Invert the selected bit
        end
    end

endmodule

