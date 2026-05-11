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


module Multi_Mode_NS_SAR_ADC_Control(
    input  wire        main_clock,
    input  wire [3:0]  DATA,
    output reg  [3:0]  sampled_data,
    
    // Counter control registers (slv_reg0 - slv_reg20)
    input  wire [31:0] slv_reg0,  // Step size
    input  wire [31:0] slv_reg1,  // Currently unused (formerly CLK toggle threshold)
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
    input  wire [31:0] slv_reg19, input  wire [31:0] slv_reg20, // DEM_CLK window
    
    // Static control register (slv_reg21)
    input  wire [31:0] slv_reg21,

    // Output ports
    output reg         A4,
    output reg         A3,
    output reg         A2,
    output reg         M0,
    output reg         M1,
    output reg  [1:0]  OUT_SEL,
    output reg         DEM_EN,
    output wire        CLK_S,       // Acts as DATA_VALID
    output wire        PINT1,
    output wire        PINT2,
    output wire        CLK,         // Acts as NS_SAR_ADC_DIN_CLK
    output wire        CLK_CHOP,
    output wire        DEM_CLK
);

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
    // 2. Data Sampling (Sample DATA on CLK_S rising edge)
    // --------------------------------------------------------
        
    reg clk_s_d;
    always @(posedge main_clock) begin
        clk_s_d <= CLK_S;
        // check CLK_S rising edge
        if (CLK_S && !clk_s_d) begin
            sampled_data <= DATA;
        end
    end

    // --------------------------------------------------------
    // 3. Main Counter Logic
    // --------------------------------------------------------
    reg [31:0] clk_counter = 0;
    always @(posedge main_clock) begin
        if (clk_counter >= slv_reg2) begin
            clk_counter <= 0; 
        end else begin
            clk_counter <= clk_counter + slv_reg0;
        end
    end

    // --------------------------------------------------------
    // 4. Output Clock and Window Signal Generation
    // --------------------------------------------------------
    
    // CLK is driven by the 4 comparator windows
    wire first_cmp  = (clk_counter <= slv_reg4)  && (clk_counter >= slv_reg3);
    wire second_cmp = (clk_counter <= slv_reg6)  && (clk_counter >= slv_reg5);
    wire third_cmp  = (clk_counter <= slv_reg8)  && (clk_counter >= slv_reg7);
    wire fourth_cmp = (clk_counter <= slv_reg10) && (clk_counter >= slv_reg9);
    assign CLK      = first_cmp || second_cmp || third_cmp || fourth_cmp;

    // CLK_S (Data Valid) and other control windows
    assign CLK_S    = (clk_counter >= slv_reg14) && (clk_counter <= slv_reg13);
    assign PINT1    = (clk_counter >= slv_reg16) && (clk_counter <= slv_reg15);
    assign PINT2    = (clk_counter >= slv_reg18) && (clk_counter <= slv_reg17);
    assign DEM_CLK  = (clk_counter >= slv_reg20) && (clk_counter <= slv_reg19);

    // --------------------------------------------------------
    // 5. Chopper Logic
    // --------------------------------------------------------
    wire switch_chopper = (clk_counter >= slv_reg12);
    reg [3:0] chopper_counter = 0;
    reg       din_chop_buf    = 0;

    reg switch_chopper_d;
    always @(posedge main_clock) begin
        switch_chopper_d <= switch_chopper;
        // check switch_chopper rising edge
        if (switch_chopper && !switch_chopper_d) begin
            if (chopper_counter >= slv_reg11) begin
                din_chop_buf <= ~din_chop_buf;
                chopper_counter <= 0;
            end else begin
                chopper_counter <= chopper_counter + 1;
            end
        end
    end
    assign CLK_CHOP = din_chop_buf;

endmodule