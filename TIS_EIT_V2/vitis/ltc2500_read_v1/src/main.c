#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xil_io.h"
#include "xparameters.h"
#include "xgpio.h"

// 关键修改：新版本 Vitis 使用 BASEADDR 宏
#define GPIO_BASEADDR  XPAR_XGPIO_0_BASEADDR 
#define START_CHANNEL  2 

XGpio Gpio;

int main() {
    int status;
    volatile int* base_addr=(int*)0x44A50000;
    volatile int* three_addr=(int*)0x44A40000;
    volatile int* addr_gen_base=(int*)0x44A10000;
    //volatile int* fsm_0_base=(int*)0x44A20000;
    volatile int* ip1_base=(int*)0x44A30000;
    
    
    *(addr_gen_base) = 0x20C49C; // phase step A [31:0], 5kHz
    *(addr_gen_base + 1) = 0x00000001; // phase step B [31:0]
    *(addr_gen_base + 2) = 0x00000001; // phase step C [31:0]
    *(addr_gen_base + 3) = 0x00000001; // phase step D [31:0]

    *(addr_gen_base + 4) = 0x0000; // phase offset A [15:0]
    *(addr_gen_base + 5) = 0x0000; // phase offset B [15:0]
    *(addr_gen_base + 6) = 0x0000; // phase offset C [15:0]
    *(addr_gen_base + 7) = 0x0000; // phase offset D [15:0]
    
    

    //*(fsm_0_base) = 1; // resetn
    //*(fsm_0_base+1) = 1; // update tick
    
    *(ip1_base) = *(addr_gen_base); // ip1 phase step input, same as phase step A
    
    *three_addr=0x0000;//ADC enable
    *base_addr=0x0000; //eit_in_enable
    *(base_addr+1)=0x0001; //offset eit
    *(base_addr+2)=0x0001; //reset eit
    // 新版本驱动初始化：直接传入基地址
    status = XGpio_Initialize(&Gpio, GPIO_BASEADDR); 
    
    if (status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    // 设置通道方向：0 代表输出
    XGpio_SetDataDirection(&Gpio, START_CHANNEL, 0x0);

    while(1) {
        // 产生脉冲逻辑保持不变
        XGpio_DiscreteWrite(&Gpio, START_CHANNEL, 0x1);
    }
    return 0;
}