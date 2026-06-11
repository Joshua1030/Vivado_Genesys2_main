/******************************************************************************
* Copyright (C) 2023 Advanced Micro Devices, Inc. All Rights Reserved.
* SPDX-License-Identifier: MIT
******************************************************************************/
/*
 * helloworld.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xil_io.h"

// Define the Base Address of NS SAR ADC
#define NS_SAR_BASE_ADDR 0x44A00000

int main()
{
    xil_printf("Initializing Multi_Mode_NS_SAR_ADC_Control IP...\n\r");

    // 2. Configure main counter parameters
    Xil_Out32(NS_SAR_BASE_ADDR + (0 * 4), 1);   // slv_reg[0]  = Step increment
    Xil_Out32(NS_SAR_BASE_ADDR + (1 * 4), 0);   // slv_reg[1]  = Main clock divider (0 = full speed, N = div by N+1)
    Xil_Out32(NS_SAR_BASE_ADDR + (2 * 4), 99);  // slv_reg[2]  = Wrap around

    // 3. Configure CMP windows to generate 4 pulses on CLK
    Xil_Out32(NS_SAR_BASE_ADDR + (3 * 4), 35);  // slv_reg[3]  = Pulse 1 Start
    Xil_Out32(NS_SAR_BASE_ADDR + (4 * 4), 40);  // slv_reg[4]  = Pulse 1 End
    Xil_Out32(NS_SAR_BASE_ADDR + (5 * 4), 50);  // slv_reg[5]  = Pulse 2 Start
    Xil_Out32(NS_SAR_BASE_ADDR + (6 * 4), 55);  // slv_reg[6]  = Pulse 2 End
    Xil_Out32(NS_SAR_BASE_ADDR + (7 * 4), 65);  // slv_reg[7]  = Pulse 3 Start
    Xil_Out32(NS_SAR_BASE_ADDR + (8 * 4), 70);  // slv_reg[8]  = Pulse 3 End
    Xil_Out32(NS_SAR_BASE_ADDR + (9 * 4), 80);  // slv_reg[9]  = Pulse 4 Start
    Xil_Out32(NS_SAR_BASE_ADDR + (10 * 4),85);  // slv_reg[10] = Pulse 4 End

    // 4. Configure CLK_S (Data Valid & Sampling Trigger)
    Xil_Out32(NS_SAR_BASE_ADDR + (14 * 4), 0);   // slv_reg[14] = CLK_S Start
    Xil_Out32(NS_SAR_BASE_ADDR + (13 * 4), 18); // slv_reg[13] = CLK_S End

    // 5. Configure Chopper parameters
    Xil_Out32(NS_SAR_BASE_ADDR + (12 * 4), 1); // slv_reg[12] = Trigger evaluate (updated to 1)
    Xil_Out32(NS_SAR_BASE_ADDR + (11 * 4), 4);    // slv_reg[11] = Chopper counter threshold

    // 6. Provide dummy windows for the other clocks
    // Xil_Out32(NS_SAR_BASE_ADDR + (16 * 4), 750); // slv_reg[16] = PINT1 Start
    // Xil_Out32(NS_SAR_BASE_ADDR + (15 * 4), 860); // slv_reg[15] = PINT1 End
    // Xil_Out32(NS_SAR_BASE_ADDR + (18 * 4), 880); // slv_reg[18] = PINT2 Start
    // Xil_Out32(NS_SAR_BASE_ADDR + (17 * 4), 990); // slv_reg[17] = PINT2 End
    Xil_Out32(NS_SAR_BASE_ADDR + (16 * 4), 01); // slv_reg[16] = PINT1 Start
    Xil_Out32(NS_SAR_BASE_ADDR + (15 * 4), 17); // slv_reg[15] = PINT1 End
    Xil_Out32(NS_SAR_BASE_ADDR + (18 * 4), 21); // slv_reg[18] = PINT2 Start
    Xil_Out32(NS_SAR_BASE_ADDR + (17 * 4), 30); // slv_reg[17] = PINT2 End
    
    // Configure DEM_CLK to generate 4 pulses
    Xil_Out32(NS_SAR_BASE_ADDR + (20 * 4), 25);   // slv_reg[20] = DEM_CLK Pulse 1 Start
    Xil_Out32(NS_SAR_BASE_ADDR + (19 * 4), 35);  // slv_reg[19] = DEM_CLK Pulse 1 End
    Xil_Out32(NS_SAR_BASE_ADDR + (29 * 4), 45);  // slv_reg[29] = DEM_CLK Pulse 2 Start
    Xil_Out32(NS_SAR_BASE_ADDR + (28 * 4), 55);  // slv_reg[28] = DEM_CLK Pulse 2 End
    Xil_Out32(NS_SAR_BASE_ADDR + (31 * 4), 65);  // slv_reg[31] = DEM_CLK Pulse 3 Start
    Xil_Out32(NS_SAR_BASE_ADDR + (30 * 4), 75);  // slv_reg[30] = DEM_CLK Pulse 3 End
    Xil_Out32(NS_SAR_BASE_ADDR + (33 * 4), 85);  // slv_reg[33] = DEM_CLK Pulse 4 Start
    Xil_Out32(NS_SAR_BASE_ADDR + (32 * 4), 95); // slv_reg[32] = DEM_CLK Pulse 4 End

    // 7. Configure NEW AMP Clocks and Chopper
    Xil_Out32(NS_SAR_BASE_ADDR + (23 * 4), 2);   // slv_reg[23] = AMP_CLK_Sample Start
    Xil_Out32(NS_SAR_BASE_ADDR + (22 * 4), 18);  // slv_reg[22] = AMP_CLK_Sample End
    Xil_Out32(NS_SAR_BASE_ADDR + (25 * 4), 22);  // slv_reg[25] = AMP_CLK_Push Start
    Xil_Out32(NS_SAR_BASE_ADDR + (24 * 4), 98);  // slv_reg[24] = AMP_CLK_Push End
    Xil_Out32(NS_SAR_BASE_ADDR + (27 * 4), 1);   // slv_reg[27] = AMP_CLK_Chop trigger point
    Xil_Out32(NS_SAR_BASE_ADDR + (26 * 4), 1000); // slv_reg[26] = AMP_CLK_Chop division threshold

    // 8. Static control register
    //DEM_EN   = slv_reg21[7];
    //OUT_SEL  = slv_reg21[6:5];
    //M1       = slv_reg21[4];
    //M0       = slv_reg21[3];
    //A2       = slv_reg21[2];
    //A3       = slv_reg21[1];
    //A4       = slv_reg21[0];

    //0 11 1 1 0 0 0  --> 78  ADC0, 4TH Order, DEM OFF
    //1 11 1 1 0 0 0  --> f8  ADC0, 4TH Order, DEM ON
    //0 11 1 1 0 1 1  --> 79  ADC1, 4TH Order, DEM FF  
    //0 01 1 0 0 0 0
    // Xil_Out32(NS_SAR_BASE_ADDR + (21 * 4), 0b00110000); 
    // Xil_Out32(NS_SAR_BASE_ADDR + (21 * 4), 0b00000000); //0th order
    // Xil_Out32(NS_SAR_BASE_ADDR + (21 * 4), 0b00110000); //2nd order DEM OFF
    // Xil_Out32(NS_SAR_BASE_ADDR + (21 * 4), 0b10101000); //1st order DEM OFF
    Xil_Out32(NS_SAR_BASE_ADDR + (21 * 4), 0b01111000); //4th order DEM OFF

    xil_printf("Configuration Complete. IP is now running.\n\r");

    // Infinite loop to keep the processor running (optional depending on your application)
    // while(1) {
    //     // You can add code here to read back sampled_data if it is mapped to a register
    // }

    return 0;
}

// // 2. Configure main counter parameters
//     Xil_Out32(NS_SAR_BASE_ADDR + (0 * 4), 1);   // slv_reg[0]  = Step increment
//     Xil_Out32(NS_SAR_BASE_ADDR + (2 * 4), 999);  // slv_reg[2]  = Wrap around

//     // 3. Configure CMP windows to generate 4 pulses on CLK
//     Xil_Out32(NS_SAR_BASE_ADDR + (3 * 4), 400);  // slv_reg[3]  = Pulse 1 Start
//     Xil_Out32(NS_SAR_BASE_ADDR + (4 * 4), 450);  // slv_reg[4]  = Pulse 1 End
//     Xil_Out32(NS_SAR_BASE_ADDR + (5 * 4), 500);  // slv_reg[5]  = Pulse 2 Start
//     Xil_Out32(NS_SAR_BASE_ADDR + (6 * 4), 550);  // slv_reg[6]  = Pulse 2 End
//     Xil_Out32(NS_SAR_BASE_ADDR + (7 * 4), 600);  // slv_reg[7]  = Pulse 3 Start
//     Xil_Out32(NS_SAR_BASE_ADDR + (8 * 4), 650);  // slv_reg[8]  = Pulse 3 End
//     Xil_Out32(NS_SAR_BASE_ADDR + (9 * 4), 700);  // slv_reg[9]  = Pulse 4 Start
//     Xil_Out32(NS_SAR_BASE_ADDR + (10 * 4),750);  // slv_reg[10] = Pulse 4 End

//     // 4. Configure CLK_S (Data Valid & Sampling Trigger)
//     Xil_Out32(NS_SAR_BASE_ADDR + (14 * 4), 0);   // slv_reg[14] = CLK_S Start
//     Xil_Out32(NS_SAR_BASE_ADDR + (13 * 4), 100); // slv_reg[13] = CLK_S End

//     // 5. Configure Chopper parameters
//     Xil_Out32(NS_SAR_BASE_ADDR + (12 * 4), 10000); // slv_reg[12] = Trigger evaluate (updated to 1)
//     Xil_Out32(NS_SAR_BASE_ADDR + (11 * 4), 2);    // slv_reg[11] = Chopper counter threshold

//     // 6. Provide dummy windows for the other clocks
//     // Xil_Out32(NS_SAR_BASE_ADDR + (16 * 4), 750); // slv_reg[16] = PINT1 Start
//     // Xil_Out32(NS_SAR_BASE_ADDR + (15 * 4), 860); // slv_reg[15] = PINT1 End
//     // Xil_Out32(NS_SAR_BASE_ADDR + (18 * 4), 880); // slv_reg[18] = PINT2 Start
//     // Xil_Out32(NS_SAR_BASE_ADDR + (17 * 4), 990); // slv_reg[17] = PINT2 End
//     Xil_Out32(NS_SAR_BASE_ADDR + (16 * 4), 0); // slv_reg[16] = PINT1 Start
//     Xil_Out32(NS_SAR_BASE_ADDR + (15 * 4), 200); // slv_reg[15] = PINT1 End
//     Xil_Out32(NS_SAR_BASE_ADDR + (18 * 4), 300); // slv_reg[18] = PINT2 Start
//     Xil_Out32(NS_SAR_BASE_ADDR + (17 * 4), 950); // slv_reg[17] = PINT2 End
    
//     // Configure DEM_CLK to generate 4 pulses
//     Xil_Out32(NS_SAR_BASE_ADDR + (20 * 4), 300);   // slv_reg[20] = DEM_CLK Pulse 1 Start
//     Xil_Out32(NS_SAR_BASE_ADDR + (19 * 4), 350);  // slv_reg[19] = DEM_CLK Pulse 1 End
//     Xil_Out32(NS_SAR_BASE_ADDR + (29 * 4), 400);  // slv_reg[29] = DEM_CLK Pulse 2 Start
//     Xil_Out32(NS_SAR_BASE_ADDR + (28 * 4), 450);  // slv_reg[28] = DEM_CLK Pulse 2 End
//     Xil_Out32(NS_SAR_BASE_ADDR + (31 * 4), 500);  // slv_reg[31] = DEM_CLK Pulse 3 Start
//     Xil_Out32(NS_SAR_BASE_ADDR + (30 * 4), 550);  // slv_reg[30] = DEM_CLK Pulse 3 End
//     Xil_Out32(NS_SAR_BASE_ADDR + (33 * 4), 600);  // slv_reg[33] = DEM_CLK Pulse 4 Start
//     Xil_Out32(NS_SAR_BASE_ADDR + (32 * 4), 650); // slv_reg[32] = DEM_CLK Pulse 4 End

//     // 7. Configure NEW AMP Clocks and Chopper
//     Xil_Out32(NS_SAR_BASE_ADDR + (23 * 4), 2);   // slv_reg[23] = AMP_CLK_Sample Start
//     Xil_Out32(NS_SAR_BASE_ADDR + (22 * 4), 18);  // slv_reg[22] = AMP_CLK_Sample End
//     Xil_Out32(NS_SAR_BASE_ADDR + (25 * 4), 22);  // slv_reg[25] = AMP_CLK_Push Start
//     Xil_Out32(NS_SAR_BASE_ADDR + (24 * 4), 98);  // slv_reg[24] = AMP_CLK_Push End
//     Xil_Out32(NS_SAR_BASE_ADDR + (27 * 4), 1);   // slv_reg[27] = AMP_CLK_Chop trigger point
//     Xil_Out32(NS_SAR_BASE_ADDR + (26 * 4), 1000); // slv_reg[26] = AMP_CLK_Chop division threshold