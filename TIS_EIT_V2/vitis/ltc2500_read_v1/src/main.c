#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xil_io.h"
#include "xparameters.h"
#include "xgpio.h"

// 关键修改：新版本 Vitis 使用 BASEADDR 宏
#define GPIO_BASEADDR  XPAR_XGPIO_0_BASEADDR
#define START_CHANNEL  2
#define XPAR_FSM_0_S00_AXI_BASEADDR 0x44A20000

// ---- DDS 输出频率 -> 相位步长换算 ----------------------------------------
// 采样率(DAC 更新率)由 FSM REG1(0x04) 决定：f_update = F_CLK / N_update
// (block design 中 update_tick 被接为常量 1，故更新率仅由 REG1 决定)。
// addr_gen 累加器每帧前进一次，且仅用 acc[15:0] 索引 64K 正弦 ROM(一个整周期)，
// 故 f_out = f_update * phase_step / 2^16
//        => phase_step = round( f_out * N_update * 2^16 / F_CLK )
#define F_CLK_HZ        100000000UL   // clk_wiz clk_100Mhz，接到 FSM_0/clk
#define FSM_UPD_PERIOD  1000UL        // 写入 FSM REG1(0x04)；采样率 = F_CLK_HZ / FSM_UPD_PERIOD

// 各通道期望输出频率(Hz)。必须 < F_CLK_HZ/FSM_UPD_PERIOD/2 (奈奎斯特, 此处 50kHz)。
#define FREQ_A_HZ  2000UL
#define FREQ_B_HZ  2010UL
#define FREQ_C_HZ  5000UL
#define FREQ_D_HZ  2000UL

// 将期望输出频率(Hz)换算为 32 位 DDS 相位步长(带四舍五入，纯整数运算)
static inline u32 dds_phase_step(u32 f_out_hz) {
    return (u32)(((u64)f_out_hz * FSM_UPD_PERIOD * 65536ULL + (F_CLK_HZ/2)) / F_CLK_HZ);
}

XGpio Gpio;

int main() {
    int status;
    volatile int* base_addr=(int*)0x44A50000;
    volatile int* three_addr=(int*)0x44A40000;
    volatile int* addr_gen_base=(int*)0x44A10000;
    //volatile int* fsm_0_base=(int*)0x44A20000;
    volatile int* ip1_base=(int*)0x44A30000;
    
    
    *(addr_gen_base + 0) = dds_phase_step(FREQ_A_HZ); // phase step A -> FREQ_A_HZ
    *(addr_gen_base + 1) = dds_phase_step(FREQ_B_HZ); // phase step B -> FREQ_B_HZ
    *(addr_gen_base + 2) = dds_phase_step(FREQ_C_HZ); // phase step C -> FREQ_C_HZ
    *(addr_gen_base + 3) = dds_phase_step(FREQ_D_HZ); // phase step D -> FREQ_D_HZ

    *(addr_gen_base + 4) = 0x0000; // phase offset A [15:0]
    *(addr_gen_base + 5) = 0x0000; // phase offset B [15:0]
    *(addr_gen_base + 6) = 0x0000; // phase offset C [15:0]
    *(addr_gen_base + 7) = 0x0000; // phase offset D [15:0]
    
    Xil_Out32(XPAR_FSM_0_S00_AXI_BASEADDR + 0x00, 2);              // SCLK divider N=2 -> 25 MHz
    Xil_Out32(XPAR_FSM_0_S00_AXI_BASEADDR + 0x04, FSM_UPD_PERIOD); // update period -> 100 kSPS

    // 各通道幅度增益，Q12 (4096 = x1.0)。410 ~= /10 衰减，共模码 0x8000 保持不变。
    Xil_Out32(XPAR_FSM_0_S00_AXI_BASEADDR + 0x08, 410);   // gain A = /10
    Xil_Out32(XPAR_FSM_0_S00_AXI_BASEADDR + 0x0C, 410);   // gain B = /10
    Xil_Out32(XPAR_FSM_0_S00_AXI_BASEADDR + 0x10, 41);   // gain C = /10
    Xil_Out32(XPAR_FSM_0_S00_AXI_BASEADDR + 0x14, 410);   // gain D = /10


    //*(fsm_0_base) = 1; // resetn
    //*(fsm_0_base+1) = 1; // update tick
    
    *(ip1_base) = *(addr_gen_base); // ip1 phase step input, same as phase step A

    // IP_1 (0x44A30000) 自动扫描：每个电极通道停留的正弦周期数 N。
    // reg1[15:0] = N；0/1 = 每个周期换挡（原行为）。默认 1。
    #define CYCLES_PER_CHANNEL 1u
    *(ip1_base+1) = CYCLES_PER_CHANNEL; // ip1 slv_reg1 = 每感测通道停留的正弦周期数 N

    // 扫描协调开关：
    //   1 = 周期节拍嵌套：ADC 感测 mux 每 N 个正弦周期换挡，DAC 注入每 8N 个正弦周期换挡
    //       (每个注入通道扫过全部 8 个感测通道 -> 8x8 帧)。
    //   0 = legacy：DAC 每 N 周期换挡；ADC 由 ADC_AUTO_NESTED 选择 free-run / legacy 嵌套。
    #define SCAN_NESTED 1
    // ip1 slv_reg2[0] = nested_mode，决定 DAC 注入通道(dac_ch_sel)推进速率。
    *(ip1_base+2) = SCAN_NESTED ? 1u : 0u;

    // ---- IP_Three (0x44A40000) ADC 感测 MUX 控制（驱动 JA PMOD 的两个差分 8:1 MUX）----
    //   reg0[0] = enable (旧 FMC enable_0，保留)
    //   reg1[0] = 模式    0 = 自动扫描, 1 = 手动(板载拨码开关 sw0/1/2 选通道)
    //   reg2[0] = 自动扫描方式  0 = 自由连续扫描, 1 = 嵌套8x8(每次DAC换挡复位感测扫描)
    // JA0 = EIT_IN_EN (来自 IP_Two reg0，两个 MUX 的使能)。
    // 手动模式下 ADC 通道来自拨码开关 sw0/1/2；两个差分 MUX 始终同一通道。
    //   reg3[31:0] = ADC 采样周期 N（100MHz 时钟数）；采样率 = 100MHz / N。
    //                0 = 自由运行（等同原 free-running，仅受 GPIO run 门控）。
    //                采样率上限受 FSM 转换环路时间限制（约 ~300 kSPS 量级）。
    #define ADC_MODE_MANUAL   0   // 0=自动, 1=手动(拨码开关)
    #define ADC_AUTO_NESTED   0   // legacy 用: 0=自由扫描, 1=嵌套8x8(每次转换,DAC换挡复位)
    #define ADC_SAMPLE_RATE_HZ 0  // 期望 ADC 采样率(Hz)；0 = 自由运行(最大速率)
    *three_addr      = 0x0000;          // reg0: enable (保留)
    *(three_addr+1)  = ADC_MODE_MANUAL; // reg1: 模式
    // reg2[1:0]: 00=自由连续扫描, 01=legacy嵌套8x8, 10=周期节拍(每 N 周期换挡)。
    // SCAN_NESTED=1 -> 10，与 IP_1 每 8N 周期的 DAC 步进配合成 8x8 帧。
    *(three_addr+2)  = SCAN_NESTED ? 2u : (u32)ADC_AUTO_NESTED; // reg2: 自动扫描方式
    // reg3: 采样周期 N = F_CLK / 采样率；0 保持自由运行
    *(three_addr+3)  = (ADC_SAMPLE_RATE_HZ == 0) ? 0u
                       : (u32)(F_CLK_HZ / (unsigned long)ADC_SAMPLE_RATE_HZ);

    // ---- IP_Two (0x44A50000) 控制寄存器 ----
    //   reg0[0] = EIT_IN_EN, reg1[0] = gain, reg2[0] = reset
    //   reg3[0] = MUX 模式  (0 = 自动扫描/默认, 1 = 手动停靠)
    //   reg4[2:0] = 手动通道 0..7 (仅在 reg3[0]=1 时生效)
    // 手动模式与自动模式共用同一张换挡表，源/感 MUX 永不短接。
    #define MUX_MODE_MANUAL   0   // 置 1 进入手动模式，将 MUX 停靠在某一通道
    #define MUX_MANUAL_CHAN   0   // 手动模式下的通道号 0..7

    *base_addr=0x0000;      //reg0: EIT_IN_EN
    *(base_addr+1)=0x0001;  //reg1: gain
    *(base_addr+2)=0x0001;  //reg2: reset
    *(base_addr+3)=MUX_MODE_MANUAL; //reg3: MUX 模式 (0=自动, 1=手动)
    *(base_addr+4)=MUX_MANUAL_CHAN; //reg4: 手动通道 0..7
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