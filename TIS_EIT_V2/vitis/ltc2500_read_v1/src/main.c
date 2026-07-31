#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xil_io.h"
#include "xparameters.h"
#include "xgpio.h"

/* =====================================================================
 * Hardware map — AXI4-Lite base addresses (MicroBlaze data space)
 * =====================================================================*/
#define ADDRGEN_BASE  0x44A10000u  // DDS 相位累加器 (相位步长 / 偏移 A..D)
#define FSM_BASE      0x44A20000u  // AD5686R 四通道 DAC SPI 驱动 (SCLK/更新率/增益)
#define IP1_BASE      0x44A30000u  // 正弦周期序列器 (每通道周期数 N / nested 模式)
#define IP3_BASE      0x44A40000u  // ADC 感测 MUX (JA PMOD 两个差分 8:1 MUX)
#define IP2_BASE      0x44A50000u  // 源/感 MUX (电流注入电极选择)

#define GPIO_BASEADDR XPAR_XGPIO_0_BASEADDR
#define START_CHANNEL 2            // GPIO 通道 2 = ADC run/使能脉冲

/* =====================================================================
 * User config — 所有可调参数集中于此
 * =====================================================================*/
/* ---- 时钟 / 更新率 ---- */
#define F_CLK_HZ        100000000UL // clk_wiz clk_100Mhz -> FSM_0/clk
#define FSM_UPD_PERIOD  500UL      // FSM reg1: DAC 更新率 = F_CLK_HZ / 此值 (=200 kSPS)
#define DAC_SCLK_DIV    2u          // FSM reg0: AD5686R SPI 分频, SCLK=100MHz/(2*N) (=25MHz)
                                    //   注意: 与 ADC ltc_driver_fsm 的 SCK_DIV 是两回事

/* ---- DDS 输出频率 (Hz)。须 < F_CLK_HZ/FSM_UPD_PERIOD/2 (奈奎斯特, 此处 50kHz) ---- */
#define FREQ_A_HZ   2000UL
#define FREQ_B_HZ   2010UL
#define FREQ_C_HZ   5000UL
#define FREQ_D_HZ   2000UL
#define PHASE_OFF_A 0x0000u         // 相位偏移 A..D [15:0]
#define PHASE_OFF_B 0x0000u
#define PHASE_OFF_C 0x0000u
#define PHASE_OFF_D 0x0000u

/* ---- 各通道幅度增益, Q12 (4096 = x1.0)。410 ~= /10 衰减, 共模码 0x8000 不变 ---- */
#define GAIN_A  410u
#define GAIN_B  410u
#define GAIN_C  92u
#define GAIN_D  410u

/* ---- IP_1 正弦周期序列器 ---- */
#define CYCLES_PER_CHANNEL 5u   // 每感测通道停留的正弦周期数 N (0/1 = 每周期换挡)
#define SCAN_NESTED        1   // 1 = 周期节拍嵌套: ADC 每 N 周期换挡, DAC 每 8N 周期换挡
                                //     (每注入通道扫过全部 8 个感测通道 -> 8x8 帧)
                                // 0 = legacy: DAC 每 N 周期换挡; ADC 见 ADC_AUTO_NESTED

/* ---- IP_Three ADC MUX ---- */
#define ADC_MODE_MANUAL    0   // 0=自动扫描, 1=手动(板载拨码开关 sw0/1/2)
#define ADC_AUTO_NESTED    0   // legacy 用: 0=自由扫描, 1=嵌套8x8(每次转换,DAC换挡复位)
// 期望 ADC 采样率(Hz); 0 = 自由运行(最大速率, 受 FSM 环路限制)。
// 400 kHz -> slv_reg3 N = 100MHz/400kHz = 250 个时钟。
//
// 注意 N 有下限：IP_Three 的启动脉冲只有 3 拍宽而且是自由运行的
// (myip_slave_lite_v1_0_S00_AXI.v:432-435)，FSM 只在 STATE_IDLE 看它。
// 如果 FSM 一圈比 N 还长，就会整个漏掉一个脉冲去等下一个 ——
// 采样率是【直接减半】，不是缓慢下降。
// ltc_driver_fsm 在 SCK_DIV=2 下一圈 = 215 个时钟（sim/tb_ltc_sdo_timing.v 量的），
// 所以 N 必须 >= 215；250 有 35 个时钟余量。
// (SCK_DIV=1 时一圈是 150 个时钟，但那个配置读回来的数据是错的，别用。)
#define ADC_SAMPLE_RATE_HZ 400000

/* ---- IP_Two DAC MUX ---- */
#define MUX_MODE_MANUAL 0   // 0=自动扫描/默认, 1=手动停靠某通道
#define MUX_MANUAL_CHAN 0   // 手动模式下的通道号 0..7

/* =====================================================================
 * Helpers
 * =====================================================================*/
// DDS 输出频率(Hz) -> 32 位相位步长。
//   采样率(DAC 更新率)由 FSM reg1 决定: f_update = F_CLK / N_update
//   (block design 中 update_tick 接常量 1, 故更新率仅由 reg1 决定)。
//   addr_gen 累加器仅用 acc[15:0] 索引 64K 正弦 ROM(一个整周期), 故
//     f_out = f_update * phase_step / 2^16
//     => phase_step = round( f_out * N_update * 2^16 / F_CLK )   (纯整数运算)
static inline u32 dds_phase_step(u32 f_out_hz) {
    return (u32)(((u64)f_out_hz * FSM_UPD_PERIOD * 65536ULL + (F_CLK_HZ/2)) / F_CLK_HZ);
}

XGpio Gpio;

/* =====================================================================
 * Per-IP configuration
 * =====================================================================*/

// addr_gen: reg0..3 = 相位步长 A..D, reg4..7 = 相位偏移 A..D[15:0]
static void addr_gen_config(void) {
    volatile u32 *p = (volatile u32*)ADDRGEN_BASE;
    p[0] = dds_phase_step(FREQ_A_HZ);
    p[1] = dds_phase_step(FREQ_B_HZ);
    p[2] = dds_phase_step(FREQ_C_HZ);
    p[3] = dds_phase_step(FREQ_D_HZ);
    p[4] = PHASE_OFF_A;
    p[5] = PHASE_OFF_B;
    p[6] = PHASE_OFF_C;
    p[7] = PHASE_OFF_D;
}

// FSM (AD5686R DAC 驱动):
//   reg0[7:0] = SCLK 分频 N     reg1[31:0] = DAC 更新周期
//   reg2..5[15:0] = 各通道增益 A..D  (偏移 0x08/0x0C/0x10/0x14)
static void dac_fsm_config(void) {
    volatile u32 *p = (volatile u32*)FSM_BASE;
    p[0] = DAC_SCLK_DIV;     // SCLK = 100MHz/(2*N) = 25MHz
    p[1] = FSM_UPD_PERIOD;   // 更新率 = 100 kSPS
    p[2] = GAIN_A;
    p[3] = GAIN_B;
    p[4] = GAIN_C;
    p[5] = GAIN_D;
}

// IP_1 (正弦周期序列器):
//   reg0 = 相位步长(通道A, 与 addr_gen reg0 相同)
//   reg1[15:0] = 每感测通道停留周期数 N
//   reg2[0] = nested_mode (1 -> DAC 注入每 8N 周期换挡)
static void sequencer_config(void) {
    volatile u32 *p   = (volatile u32*)IP1_BASE;
    volatile u32 *dds = (volatile u32*)ADDRGEN_BASE;
    p[0] = dds[0];                  // 与 phase step A 相同
    p[1] = CYCLES_PER_CHANNEL;
    p[2] = SCAN_NESTED ? 1u : 0u;
}

// IP_Three (ADC 感测 MUX, 驱动 JA PMOD 两个差分 8:1 MUX):
//   reg0[0] = enable (旧 FMC enable_0, 保留)
//   reg1[0] = 模式 0=自动, 1=手动(拨码开关 sw0/1/2)
//   reg2[1:0] = 扫描方式 00=自由连续, 01=legacy嵌套8x8, 10=周期节拍(每 N 周期换挡)
//   reg3[31:0] = ADC 采样周期 = F_CLK/采样率 (0 = 自由运行)
static void adc_mux_config(void) {
    volatile u32 *p = (volatile u32*)IP3_BASE;
    p[0] = 1u;                                        // enable (保留)
    p[1] = ADC_MODE_MANUAL;                           // 模式
    p[2] = SCAN_NESTED ? 2u : (u32)ADC_AUTO_NESTED;   // 扫描方式 (SCAN_NESTED -> 周期节拍 10)
    p[3] = (ADC_SAMPLE_RATE_HZ == 0) ? 0u             // 采样周期 (0 = 自由运行)
           : (u32)(F_CLK_HZ / (unsigned long)ADC_SAMPLE_RATE_HZ);
}

// IP_Two (源/感 MUX, 电流注入电极):
//   reg0[0]=EIT_IN_EN  reg1[0]=gain  reg2[0]=reset
//   reg3[0]=MUX 模式 (0=自动, 1=手动)  reg4[2:0]=手动通道 0..7
// 自动/手动共用同一换挡表, 源/感 MUX 永不短接。
static void source_mux_config(void) {
    volatile u32 *p = (volatile u32*)IP2_BASE;
    p[0] = 0x0001u;          // EIT_IN_EN
    p[1] = 0x0001u;          // gain
    p[2] = 0x0001u;          // reset
    p[3] = MUX_MODE_MANUAL;  // MUX 模式
    p[4] = MUX_MANUAL_CHAN;  // 手动通道
}

// GPIO: 将 START_CHANNEL 设为输出 (ADC run/使能脉冲源)
static int start_gpio(void) {
    int status = XGpio_Initialize(&Gpio, GPIO_BASEADDR);
    if (status != XST_SUCCESS)
        return status;
    XGpio_SetDataDirection(&Gpio, START_CHANNEL, 0x0); // 0 = 输出
    return XST_SUCCESS;
}

int main(void) {
    addr_gen_config();      // DDS 相位步长 / 偏移
    dac_fsm_config();       // AD5686R SCLK / 更新率 / 增益
    sequencer_config();     // IP_1: N, nested_mode
    adc_mux_config();       // IP_Three: 模式 / 扫描方式 / 采样率
    source_mux_config();    // IP_Two: EIT_IN_EN / MUX 模式

    if (start_gpio() != XST_SUCCESS)
        return XST_FAILURE;

    // 持续拉高 run 使能, ADC 按配置的速率自由转换
    while (1) {
        XGpio_DiscreteWrite(&Gpio, START_CHANNEL, 0x1);
    }
    return 0;
}
