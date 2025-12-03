`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/09/2024 11:09:23 AM
// Design Name: 
// Module Name: tb_dem
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


module tb_dem();
    reg clk, rstb;
    reg [2:0] testdata;
    wire [6:0] result;
    reg [6:0] sampled_results;
    reg error, enable;
    reg [2:0] onecount;
    
    always #5 clk=~clk;
    
    integer i;
    
    always @(posedge clk) begin
        sampled_results <= result;
        onecount = 3'b000;
        for(i=0; i<7; i=i+1) begin
            if(result[i] == 1) begin
                onecount = onecount + 1'b1;
            end
        end
        
        if(onecount != testdata) begin
            error = 1'b1;
            $display("Input data is %b, output is %b, there are %d ones in the output ERROR", testdata, result, onecount);
        end
    end
    
    initial begin
        rstb= 1'b0;
        clk = 1'b0;
        error = 1'b0;
        testdata = 3'b000;
        enable = 1'b1;
        #20 rstb = ~rstb;
        #2000 testdata = 3'b101;
        #2000 testdata = 3'b100;
        #2000 testdata = 3'b001;
        #2000 testdata = 3'b111;
        #2000 testdata = 3'b100;
        #2000 testdata = 3'b010;
        #2000 testdata = 3'b100;
        #2000 testdata = 3'b110;
        #2000 testdata = 3'b000;
        #2000 testdata = 3'b010;
        #2000 enable = 1'b0;
        #2000 testdata = 3'b101;
        #2000 testdata = 3'b100;
        #2000 testdata = 3'b001;
        #2000 testdata = 3'b111;
        #2000 testdata = 3'b100;
        #2000 testdata = 3'b010;
        #2000 testdata = 3'b100;
        #2000 testdata = 3'b110;
        #2000 testdata = 3'b000;
        #2000 testdata = 3'b010;
        #100
        if(!error) $display("All tests passed");
        else $display("Error in the tests");
        $stop; 
    end
    
    dem_top dut(
        .data(testdata),
        .enable(enable),
        .clk(clk),
        .rstb(rstb),
        .CapSel(result)
    );
endmodule
