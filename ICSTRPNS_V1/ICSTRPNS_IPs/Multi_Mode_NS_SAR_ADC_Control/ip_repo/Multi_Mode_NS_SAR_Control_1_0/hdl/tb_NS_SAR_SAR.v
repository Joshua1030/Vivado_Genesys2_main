`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/10/2026 11:32:31 PM
// Design Name: 
// Module Name: tb_NS_SAR_SAR
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


module tb_NS_SAR_SAR();
    // --------------------------------------------------------
    // Testbench Signals
    // --------------------------------------------------------
    reg         main_clock;
    reg         sw;             // NEW: External switch input
    reg  [3:0]  DATA;
    reg  [31:0] slv_reg [0:27]; // UPDATED: Array expanded to easily initialize all 28 registers
    
    // Outputs from DUT
    wire        reset;          // NEW: Reset output
    wire [3:0]  sampled_data;
    
    wire        A4;
    wire        A3;
    wire        A2;
    wire        M0;
    wire        M1;
    wire [1:0]  OUT_SEL;
    wire        DEM_EN;
    wire        CLK_S;      // Also acts as DATA_VALID
    wire        PINT1;
    wire        PINT2;
    wire        CLK;        // Also acts as NS_SAR_ADC_DIN_CLK
    wire        CLK_CHOP;
    wire        DEM_CLK;

    // NEW: Outputs from DUT for AMP Clocks
    wire        AMP_CLK_Sample;
    wire        AMP_CLK_Push;
    wire        AMP_CLK_Chop;

    // --------------------------------------------------------
    // Device Under Test (DUT) Instantiation
    // --------------------------------------------------------
    Multi_Mode_NS_SAR_ADC_Control uut (
        .main_clock     (main_clock),
        .sw             (sw),             // Map new sw input
        .reset          (reset),          // Map new reset output
        .DATA           (DATA),
        .sampled_data   (sampled_data),
        
        // Counter control registers
        .slv_reg0       (slv_reg[0]),  .slv_reg1       (slv_reg[1]),  .slv_reg2       (slv_reg[2]),
        .slv_reg3       (slv_reg[3]),  .slv_reg4       (slv_reg[4]),  .slv_reg5       (slv_reg[5]),
        .slv_reg6       (slv_reg[6]),  .slv_reg7       (slv_reg[7]),  .slv_reg8       (slv_reg[8]),
        .slv_reg9       (slv_reg[9]),  .slv_reg10      (slv_reg[10]), .slv_reg11      (slv_reg[11]),
        .slv_reg12      (slv_reg[12]), .slv_reg13      (slv_reg[13]), .slv_reg14      (slv_reg[14]),
        .slv_reg15      (slv_reg[15]), .slv_reg16      (slv_reg[16]), .slv_reg17      (slv_reg[17]),
        .slv_reg18      (slv_reg[18]), .slv_reg19      (slv_reg[19]), .slv_reg20      (slv_reg[20]),
        .slv_reg21      (slv_reg[21]), // Static control register
        
        // NEW: AMP Clock control registers
        .slv_reg22      (slv_reg[22]), .slv_reg23      (slv_reg[23]),
        .slv_reg24      (slv_reg[24]), .slv_reg25      (slv_reg[25]),
        .slv_reg26      (slv_reg[26]), .slv_reg27      (slv_reg[27]),
        
        // Output Mappings
        .A4             (A4), 
        .A3             (A3), 
        .A2             (A2), 
        .M0             (M0), 
        .M1             (M1), 
        .OUT_SEL        (OUT_SEL), 
        .DEM_EN         (DEM_EN), 
        .CLK_S          (CLK_S), 
        .PINT1          (PINT1), 
        .PINT2          (PINT2), 
        .CLK            (CLK), 
        .CLK_CHOP       (CLK_CHOP), 
        .DEM_CLK        (DEM_CLK),
        
        // NEW: AMP Clock outputs
        .AMP_CLK_Sample (AMP_CLK_Sample),
        .AMP_CLK_Push   (AMP_CLK_Push),
        .AMP_CLK_Chop   (AMP_CLK_Chop)
    );

    // --------------------------------------------------------
    // Clock Generation (100MHz)
    // Period = 10ns (5ns high, 5ns low)
    // --------------------------------------------------------
    initial begin
        main_clock = 0;
        forever #5 main_clock = ~main_clock;
    end

    // --------------------------------------------------------
    // Stimulus & Initialization
    // --------------------------------------------------------
    initial begin
        // Setup for EDA Playground / waveform viewers
        //$dumpfile("dump.vcd");
        //$dumpvars(0, tb_NS_SAR_SAR);
        
        sw = 0; // Initialize switch (reset inactive)
        
        // 1. Initialize all registers to 0 safely
        begin : INIT_REGS
            integer i;
            for (i = 0; i <= 27; i = i + 1) begin
                slv_reg[i] = 0;
            end
        end

        DATA = 4'b0000;
        
        // 2. Configure main counter parameters
        slv_reg[0]  = 32'd1;   // Step increment by 1
        slv_reg[2]  = 32'd99;  // Wrap around at 99 (0 to 99 = 100 cycles = 1us total period)
        
        // 3. Configure CMP windows to generate 4 pulses on CLK
        slv_reg[3]  = 32'd15; slv_reg[4]  = 32'd20; // Pulse 1 (CMP1)
        slv_reg[5]  = 32'd25; slv_reg[6]  = 32'd30; // Pulse 2 (CMP2)
        slv_reg[7]  = 32'd35; slv_reg[8]  = 32'd40; // Pulse 3 (CMP3)
        slv_reg[9]  = 32'd45; slv_reg[10] = 32'd50; // Pulse 4 (CMP4)
        
        // 4. Configure CLK_S (Data Valid & Sampling Trigger)
        // Happens after the last comparator pulse
        slv_reg[14] = 32'd0; slv_reg[13] = 32'd9; // CLK_S goes high between count 70 and 75
        
        // 5. Configure Standard Chopper parameters
        slv_reg[12] = 32'd1; // Trigger evaluate at count 5
        slv_reg[11] = 32'd1; // Chopper counter threshold
        
        // 6. Provide dummy windows for the other clocks so they aren't floating
        slv_reg[16] = 32'd62; slv_reg[15] = 32'd84; // PINT1
        slv_reg[18] = 32'd86; slv_reg[17] = 32'd98; // PINT2
        slv_reg[20] = 32'd0;  slv_reg[19] = 32'd9;  // DEM_CLK
        
        // 7. Configure NEW AMP Clocks and Chopper
        slv_reg[23] = 32'd0; slv_reg[22] = 32'd9; // AMP_CLK_Sample
        slv_reg[25] = 32'd11; slv_reg[24] = 32'd98; // AMP_CLK_Push
        slv_reg[27] = 32'd1;                       // AMP_CLK_Chop trigger point
        slv_reg[26] = 32'd1;                        // AMP_CLK_Chop division threshold

        // ----------------------------------------------------
        // Apply Test Vectors over time
        // ----------------------------------------------------
        
        // Toggle the 'sw' to test the reset functionality early on
        #15  sw = 1; 
        #20  sw = 0; 
        
        #100;
        
        // Modify slv_reg21 to control static output signals
        // Set A4=1, A3=1, DEM_EN=0 (Bits 0, 1, 7)
        // Binary: 0001_1011 -> Hex: 1b
        slv_reg[21] = 32'h0000_001b; 

        #200;
        // Provide DATA. 
        DATA = 4'b1101; 
        
        #1200;
        // Change DATA for the next period
        DATA = 4'b0110;
        
        #1200;
        // Change DATA for the next period
        DATA = 4'b0111;
        
        #1000;
        $display("Simulation Finished Successfully.");
        $finish;
    end

endmodule