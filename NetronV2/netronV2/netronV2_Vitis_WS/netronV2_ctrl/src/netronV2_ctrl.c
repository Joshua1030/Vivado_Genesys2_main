
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
//#include "platform.h"
#include "xil_printf.h"

volatile unsigned int* addr_base_amp_clk_gen = (unsigned int*) 0x44A00000;


volatile unsigned int* addr_base_DEM_NetronV2 = (unsigned int*) 0x44A30000;


volatile unsigned int* addr_base_2nd_clock_gen = (unsigned int*) 0x44A10000;


volatile unsigned int* addr_base_sar_ctl_logic = (unsigned int*) 0x44A20000;



int main()
{
    //init_platform();
    //DS_2ND
    //clock: 100MHz
    // Counter to adjust clock
	// slv_reg0 is middle value for when clock goes high
	// slv_reg1 is step size
	// slv_reg2 is max count before reset
    volatile unsigned int* DS_2nd_slv_reg0 = addr_base_2nd_clock_gen;
    volatile unsigned int* DS_2nd_slv_reg1 = addr_base_2nd_clock_gen+1;
    volatile unsigned int* DS_2nd_slv_reg2 = addr_base_2nd_clock_gen+2;
    *DS_2nd_slv_reg0 = 50;
    *DS_2nd_slv_reg1 = 1;
    *DS_2nd_slv_reg2 = 99;  //0~99 

    
    //DEM config
    volatile unsigned int* DEM_enable = addr_base_DEM_NetronV2;    
    //enable DEM
    *DEM_enable = 0b1;       
    //disable DEM
    // *DEM_enable = 0b0;  


    //SAR control logic config
    //counter clk 100MHz
    //slv_reg0: counter step size
    volatile unsigned int* counter_step_size = addr_base_sar_ctl_logic;
    *counter_step_size = 1;
    //slv_reg1: CLKS fall
    volatile unsigned int* CLKS_fall = addr_base_sar_ctl_logic+1;
    *CLKS_fall = 30;    
    // * = 8;  
    //slv_reg2: conuter reset
    volatile unsigned int* counter_reset = addr_base_sar_ctl_logic+2;
    *counter_reset = 99;
    // *counter_reset = 32;
    //slv_reg3, 4, 5, 6, 7, 8 for three rises and falls of CLK
    volatile unsigned int* SAR_CLK_rise1 = addr_base_sar_ctl_logic+3;
    volatile unsigned int* SAR_CLK_fall1 = addr_base_sar_ctl_logic+4;
    volatile unsigned int* SAR_CLK_rise2 = addr_base_sar_ctl_logic+5;
    volatile unsigned int* SAR_CLK_fall2 = addr_base_sar_ctl_logic+6;
    volatile unsigned int* SAR_CLK_rise3 = addr_base_sar_ctl_logic+7;
    volatile unsigned int* SAR_CLK_fall3 = addr_base_sar_ctl_logic+8;
    
    *(addr_base_sar_ctl_logic+3) = (unsigned) 40;
    *(addr_base_sar_ctl_logic+4) = (unsigned) 50;
    *(addr_base_sar_ctl_logic+5) = (unsigned) 60;
    *(addr_base_sar_ctl_logic+6) = (unsigned) 70;
    *(addr_base_sar_ctl_logic+7) = (unsigned) 80;
    *(addr_base_sar_ctl_logic+8) = (unsigned) 89; 
    
    // *(addr_base_sar_ctl_logic+3) = (unsigned) 12;
    // *(addr_base_sar_ctl_logic+4) = (unsigned) 15;
    // *(addr_base_sar_ctl_logic+5) = (unsigned) 18;
    // *(addr_base_sar_ctl_logic+6) = (unsigned) 21;
    // *(addr_base_sar_ctl_logic+7) = (unsigned) 24;
    // *(addr_base_sar_ctl_logic+8) = (unsigned) 27; 
    
    volatile unsigned int* data_valid_rise = addr_base_sar_ctl_logic+11;//also used for data_valid start
    *data_valid_rise = (unsigned) 90; //data_valid fall after this
    // *data_valid_rise = (unsigned) 29; //data_valid fall after this
    volatile unsigned int* data_valid_fall = addr_base_sar_ctl_logic+12;
    *data_valid_fall = (unsigned) 98; //data_valid fall after this
    // *data_valid_fall = (unsigned) 32; //data_valid fall after this

    //slv_reg10: chopper switch, should be half of slv_reg1; high when counter >= slv_reg10
    volatile unsigned int* slv_reg10 = addr_base_sar_ctl_logic+10;
    // *slv_reg10 = slv_reg10/3;
    *slv_reg10 = 15;
    // *slv_reg10 = 40000;

    //slv_reg9: chopper_counter counts up at rising edge of chopper switch, this specifies the upper limit
    //chopper clk invert itself when chopper_counter counts to this number
    volatile unsigned int* slv_reg9 = addr_base_sar_ctl_logic+9;
    *slv_reg9 = 0;



    /* AMP Setup ************************************************************************/
    // Using slv_reg0, 1, 2 for Chopper. Should be at 100kHz
	// 0 for step size, 1 for turn on, 2 for reset count
	// @ 100MHz clock, slv_reg2 should be 100M/100k = 1000 (or 999)
	// slv_reg1 should be 500
	
	// Using slv_reg3, 4, 5 for AZ. Should be twice of Chopper
	// 3 for step size, 4 for turn on, 5 for reset count
	// @ 100MHz clock, slv_reg4 should be 500 (or 499)
	// slv_reg5 should be 250

    volatile unsigned int* amp_reg0 = addr_base_amp_clk_gen;
    volatile unsigned int* amp_reg1 = addr_base_amp_clk_gen+1;
    volatile unsigned int* amp_reg2 = addr_base_amp_clk_gen+2;
    volatile unsigned int* amp_reg3 = addr_base_amp_clk_gen+3;
    volatile unsigned int* amp_reg4 = addr_base_amp_clk_gen+4;
    volatile unsigned int* amp_reg5 = addr_base_amp_clk_gen+5;


    *amp_reg0 = 1;
    // *amp_reg1 = 500;
    *amp_reg1 = 10000;
    *amp_reg2 = 999;

    *amp_reg3 = 1;
    // *amp_reg4 = 25000;
    *amp_reg4 = 100000;
    *amp_reg5 = 49999;


    print("Hello World\n\r");
    print("Successfully ran Hello World application");
    //cleanup_platform();
    return 0;
}
