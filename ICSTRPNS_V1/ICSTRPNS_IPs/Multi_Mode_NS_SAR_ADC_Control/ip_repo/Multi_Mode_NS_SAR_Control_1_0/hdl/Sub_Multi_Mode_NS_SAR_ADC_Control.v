`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/10/2026 11:21:54 PM
// Design Name: 
// Module Name: Multi_Mode_NS_SAR_ADC_Control
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

//////////////////////////////////////////////////////////////////////////////////
// Module Name: Multi_Mode_NS_SAR_ADC_Control
// Description: Updated with main clock frequency divider and registered, 
//              glitch-free output clocks.
//////////////////////////////////////////////////////////////////////////////////

module Multi_Mode_NS_SAR_ADC_Control(
    input  wire        main_clock,
    input  wire        sw,            // External switch input
    output wire        reset,         // Reset output driven by 'sw'
    input  wire [3:0]  DATA,
    output reg  [3:0]  sampled_data,
    
    // Counter control registers (slv_reg0 - slv_reg20)
    input  wire [31:0] slv_reg0,  // Step size
    input  wire [31:0] slv_reg1,  // NOW USED: Main clock divider value
    input  wire [31:0] slv_reg2,  // Counter period
    input  wire [31:0] slv_reg3,  input  wire [31:0] slv_reg4,  // CMP1 window
    input  wire [31:0] slv_reg5,  input  wire [31:0] slv_reg6,  // CMP2 window
    input  wire [31:0] slv_reg7,  input  wire [31:0] slv_reg8,  // CMP3 window
    input  wire [31:0] slv_reg9,  input  wire [31:0] slv_reg10, // CMP4 window
    input  wire [31:0] slv_reg11, // Chopper frequency division count
    input  wire [31:0] slv_reg12, // Chopper toggle trigger point
    input  wire [31:0] slv_reg13, input  wire [31:0] slv_reg14, // CLK_S window (Data Valid)
    input  wire [31:0] slv_reg15, input  wire [31:0] slv_reg16, // PINT1 window
    input  wire [31:0] slv_reg17, input  wire [31:0] slv_reg18, // PINT2 window
    input  wire [31:0] slv_reg19, input  wire [31:0] slv_reg20, // DEM_CLK window 1
    
    // Static control register (slv_reg21)
    input  wire [31:0] slv_reg21,

    // Control registers for AMP clocks (slv_reg22 - slv_reg27)
    input  wire [31:0] slv_reg22, input  wire [31:0] slv_reg23, // AMP_CLK_Sample window
    input  wire [31:0] slv_reg24, input  wire [31:0] slv_reg25, // AMP_CLK_Push window
    input  wire [31:0] slv_reg26, // AMP_CLK_Chop frequency division count
    input  wire [31:0] slv_reg27, // AMP_CLK_Chop toggle trigger point

    // Additional DEM_CLK windows (slv_reg28 - slv_reg33)
    input  wire [31:0] slv_reg28, input  wire [31:0] slv_reg29, // DEM_CLK window 2
    input  wire [31:0] slv_reg30, input  wire [31:0] slv_reg31, // DEM_CLK window 3
    input  wire [31:0] slv_reg32, input  wire [31:0] slv_reg33, // DEM_CLK window 4

    // Output ports (Changed clock outputs to reg to prevent glitches)
    output reg         A4,
    output reg         A3,
    output reg         A2,
    output reg         M0,
    output reg         M1,
    output reg  [1:0]  OUT_SEL,
    output reg         DEM_EN,
    output reg         CLK_S,       // Acts as DATA_VALID
    output reg         PINT1,
    output reg         PINT2,
    output reg         CLK,         // Acts as NS_SAR_ADC_DIN_CLK
    output reg         CLK_CHOP,
    output reg         DEM_CLK,
    
    // Output ports for AMP (Changed to reg)
    output reg         AMP_CLK_Sample,
    output reg         AMP_CLK_Push,
    output reg         AMP_CLK_Chop
);

    // --------------------------------------------------------
    // 0. Reset Routing
    // --------------------------------------------------------
    assign reset = sw;

    // --------------------------------------------------------
    // 1. Static Control Signal Mapping (Extracted from slv_reg21)
    // --------------------------------------------------------
    always @(*) begin
        A4       = slv_reg21[0];
        A3       = slv_reg21[1];
        A2       = slv_reg21[2];
        M0       = slv_reg21[3];
        M1       = slv_reg21[4];
        OUT_SEL  = slv_reg21[6:5];
        DEM_EN   = slv_reg21[7];
    end

    // --------------------------------------------------------
    // 2. Main Clock Frequency Divider (using slv_reg1)
    // --------------------------------------------------------
    // Instead of driving a routed clock directly (which causes skew), 
    // we use a clock-enable pulse.
    reg [31:0] div_counter = 0;
    wire clk_en = (slv_reg1 == 0) || (div_counter >= slv_reg1);

    always @(posedge main_clock) begin
        if (reset) begin
            div_counter <= 32'd0;
        end else if (clk_en) begin
            div_counter <= 32'd0;
        end else begin
            div_counter <= div_counter + 1;
        end
    end

    // --------------------------------------------------------
    // 3. Data Sampling (Sample DATA on CLK_S rising edge)
    // --------------------------------------------------------
    reg clk_s_d;
    always @(posedge main_clock) begin
        if (reset) begin
            clk_s_d      <= 1'b0;
            sampled_data <= 4'b0;
        end else begin
            clk_s_d <= CLK_S;
            // check CLK_S rising edge
            if (CLK_S && !clk_s_d) begin
                sampled_data <= DATA;
            end
        end
    end

    // --------------------------------------------------------
    // 4. Main Counter Logic (Updates on clock enable)
    // --------------------------------------------------------
    reg [31:0] clk_counter = 0;
    always @(posedge main_clock) begin
        if (reset) begin
            clk_counter <= 32'd0;
        end else if (clk_en) begin
            if (clk_counter >= slv_reg2) begin
                clk_counter <= 32'd0; 
            end else begin
                clk_counter <= clk_counter + slv_reg0;
            end
        end
    end

    // --------------------------------------------------------
    // 5. Output Clock and Window Signal Generation (Registered)
    // --------------------------------------------------------
    // Combinational evaluation of windows
    wire first_cmp  = (clk_counter <= slv_reg4)  && (clk_counter >= slv_reg3);
    wire second_cmp = (clk_counter <= slv_reg6)  && (clk_counter >= slv_reg5);
    wire third_cmp  = (clk_counter <= slv_reg8)  && (clk_counter >= slv_reg7);
    wire fourth_cmp = (clk_counter <= slv_reg10) && (clk_counter >= slv_reg9);
    
    wire dem_first_cmp  = (clk_counter <= slv_reg19) && (clk_counter >= slv_reg20);
    wire dem_second_cmp = (clk_counter <= slv_reg28) && (clk_counter >= slv_reg29);
    wire dem_third_cmp  = (clk_counter <= slv_reg30) && (clk_counter >= slv_reg31);
    wire dem_fourth_cmp = (clk_counter <= slv_reg32) && (clk_counter >= slv_reg33);

    // Registering the outputs to main_clock to guarantee zero glitches
    always @(posedge main_clock) begin
        if (reset) begin
            CLK            <= 1'b0;
            DEM_CLK        <= 1'b0;
            CLK_S          <= 1'b0;
            PINT1          <= 1'b0;
            PINT2          <= 1'b0;
            AMP_CLK_Sample <= 1'b0;
            AMP_CLK_Push   <= 1'b0;
        end else if (clk_en) begin
            CLK            <= first_cmp || second_cmp || third_cmp || fourth_cmp;
            DEM_CLK        <= dem_first_cmp || dem_second_cmp || dem_third_cmp || dem_fourth_cmp;
            CLK_S          <= (clk_counter <= slv_reg13) && (clk_counter >= slv_reg14);
            PINT1          <= (clk_counter <= slv_reg15) && (clk_counter >= slv_reg16);
            PINT2          <= (clk_counter <= slv_reg17) && (clk_counter >= slv_reg18);
            AMP_CLK_Sample <= (clk_counter <= slv_reg22) && (clk_counter >= slv_reg23);
            AMP_CLK_Push   <= (clk_counter <= slv_reg24) && (clk_counter >= slv_reg25);
        end
    end

    // --------------------------------------------------------
    // 6. Standard Chopper Logic (Now updates on clk_en)
    // --------------------------------------------------------
    wire switch_chopper = (clk_counter >= slv_reg12);
    reg [31:0] chopper_counter = 0; 
    reg        switch_chopper_d;

    always @(posedge main_clock) begin
        if (reset) begin
            switch_chopper_d <= 1'b0;
            chopper_counter  <= 32'd0;
            CLK_CHOP         <= 1'b0;
        end else if (clk_en) begin
            switch_chopper_d <= switch_chopper;
            // check switch_chopper rising edge
            if (switch_chopper && !switch_chopper_d) begin
                if (chopper_counter >= slv_reg11) begin
                    CLK_CHOP        <= ~CLK_CHOP;
                    chopper_counter <= 32'd0;
                end else begin
                    chopper_counter <= chopper_counter + 1;
                end
            end
        end
    end

    // --------------------------------------------------------
    // 7. AMP Chopper Logic (Now updates on clk_en)
    // --------------------------------------------------------
    wire switch_amp_chopper = (clk_counter >= slv_reg27);
    reg [31:0] amp_chopper_counter = 0;
    reg        switch_amp_chopper_d;

    always @(posedge main_clock) begin
        if (reset) begin
            switch_amp_chopper_d <= 1'b0;
            amp_chopper_counter  <= 32'd0;
            AMP_CLK_Chop         <= 1'b0;
        end else if (clk_en) begin
            switch_amp_chopper_d <= switch_amp_chopper;
            // check switch_amp_chopper rising edge
            if (switch_amp_chopper && !switch_amp_chopper_d) begin
                if (amp_chopper_counter >= slv_reg26) begin
                    AMP_CLK_Chop        <= ~AMP_CLK_Chop;
                    amp_chopper_counter <= 32'd0;
                end else begin
                    amp_chopper_counter <= amp_chopper_counter + 1;
                end
            end
        end
    end

endmodule
