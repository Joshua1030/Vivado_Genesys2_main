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

    // 1. Initialize all registers to 0 safely (matching the TB INIT_REGS loop)
    for (int i = 0; i <= 21; i++) {
        Xil_Out32(NS_SAR_BASE_ADDR + (i * 4), 0);
    }

    // 2. Configure main counter parameters
    Xil_Out32(NS_SAR_BASE_ADDR + (0 * 4), 1);   // slv_reg[0]  = Step increment
    Xil_Out32(NS_SAR_BASE_ADDR + (2 * 4), 99);  // slv_reg[2]  = Wrap around

    // 3. Configure CMP windows to generate 4 pulses on CLK
    Xil_Out32(NS_SAR_BASE_ADDR + (3 * 4), 15);  // slv_reg[3]  = Pulse 1 Start
    Xil_Out32(NS_SAR_BASE_ADDR + (4 * 4), 20);  // slv_reg[4]  = Pulse 1 End
    Xil_Out32(NS_SAR_BASE_ADDR + (5 * 4), 25);  // slv_reg[5]  = Pulse 2 Start
    Xil_Out32(NS_SAR_BASE_ADDR + (6 * 4), 30);  // slv_reg[6]  = Pulse 2 End
    Xil_Out32(NS_SAR_BASE_ADDR + (7 * 4), 35);  // slv_reg[7]  = Pulse 3 Start
    Xil_Out32(NS_SAR_BASE_ADDR + (8 * 4), 40);  // slv_reg[8]  = Pulse 3 End
    Xil_Out32(NS_SAR_BASE_ADDR + (9 * 4), 45);  // slv_reg[9]  = Pulse 4 Start
    Xil_Out32(NS_SAR_BASE_ADDR + (10 * 4), 50); // slv_reg[10] = Pulse 4 End

    // 4. Configure CLK_S (Data Valid & Sampling Trigger)
    Xil_Out32(NS_SAR_BASE_ADDR + (14 * 4), 0);  // slv_reg[14]
    Xil_Out32(NS_SAR_BASE_ADDR + (13 * 4), 9);  // slv_reg[13]

    // 5. Configure Chopper parameters
    Xil_Out32(NS_SAR_BASE_ADDR + (12 * 4), 5);  // slv_reg[12] = Trigger evaluate
    Xil_Out32(NS_SAR_BASE_ADDR + (11 * 4), 1);  // slv_reg[11] = Chopper counter threshold

    // 6. Provide dummy windows for the other clocks
    Xil_Out32(NS_SAR_BASE_ADDR + (16 * 4), 62); // slv_reg[16] = PINT1 Start
    Xil_Out32(NS_SAR_BASE_ADDR + (15 * 4), 84); // slv_reg[15] = PINT1 End
    Xil_Out32(NS_SAR_BASE_ADDR + (18 * 4), 86); // slv_reg[18] = PINT2 Start
    Xil_Out32(NS_SAR_BASE_ADDR + (17 * 4), 98); // slv_reg[17] = PINT2 End
    Xil_Out32(NS_SAR_BASE_ADDR + (20 * 4), 0);  // slv_reg[20] = DEM_CLK Start
    Xil_Out32(NS_SAR_BASE_ADDR + (19 * 4), 9);  // slv_reg[19] = DEM_CLK End

    // 7. Static control register
    // Set A4=1, A3=1, DEM_EN=0 (Bits 0, 1, 7) -> 0x1B
    Xil_Out32(NS_SAR_BASE_ADDR + (21 * 4), 0x0000001B); 

    xil_printf("Configuration Complete. IP is now running.\n\r");

    // Infinite loop to keep the processor running (optional depending on your application)
    // while(1) {
    //     // You can add code here to read back sampled_data if it is mapped to a register
    // }

    return 0;
}
