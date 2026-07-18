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