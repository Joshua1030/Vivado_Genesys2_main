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

/* ---- DDS 输出频率 (Hz)。须 < F_CLK_HZ/FSM_UPD_PERIOD/2 (奈奎斯特, 此处 100kHz) ----
 * A/B 是 TIS 的两个载波: 2000 与 2020Hz, 差频 = 20Hz 拍频, 一个 100ms 猝发正好装
 * 2 个完整拍周期。addr_gen 现在用 acc[31:16] 做索引(真正的 32 位 DDS), 分辨率
 * f_update/2^32 ~= 0.00005Hz, 两个频率都能精确落点; 旧的 acc[15:0] 只有 3.05Hz
 * 分辨率, 会把拍频量化到 ~21Hz。
 * C 是独立的常开音调, D 备用 —— 都不参与 TIS 门控。                                */
#define FREQ_A_HZ   2000UL          /* TIS 载波 F1 */
#define FREQ_B_HZ   2020UL          /* TIS 载波 F2 -> 拍频 20Hz */
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

/* ---- IP_1 TIS/EIT 主序列器 ----------------------------------------------
 * 一次「刺激(stimulation)」= 固定 200ms 的时间片, 由 IP_1 自己的 100MHz 计数器
 * 计时(不再依赖 DDS 回绕):
 *
 *   t=0            t=90ms            t=190ms   t=200ms
 *   ├──────────────┼─────────────────┼─────────┤
 *   │ 建立 + 基线   │     TIS ON       │ off 尾巴 │
 *   └──────────────┴─────────────────┴─────────┘
 *   ▲              ▲   ▲
 *   │              │   └ 神经模拟脉冲 (90.5ms 起, 持续 1ms)
 *   │              └ TIS 开; A/B 相位从 0 释放
 *   └ DAC/ADC MUX 换挡
 *
 * 前 90ms 既是换挡后的电荷建立时间, 也是这一次刺激的【基线】测量窗口
 * (ADC 一直在采, 靠数据里的 TIS 标签位区分基线段和刺激段)。
 * 约束: TIS_DELAY_CY + TIS_DURATION_CY <= STIM_PERIOD_CY (此处 190ms <= 200ms)。 */
#define MS_TO_CY(ms)       ((u32)((ms) * (F_CLK_HZ / 1000UL)))
#define STIM_PERIOD_CY     MS_TO_CY(200UL)   /* 刺激周期 200ms -> TIS 起始频率 5Hz */
#define TIS_DELAY_CY       MS_TO_CY(90UL)    /* 换挡后建立 + 基线窗口 */
#define TIS_DURATION_CY    MS_TO_CY(100UL)   /* TIS 猝发时长 = 2 个 20Hz 拍周期 */
#define NERVE_DELAY_CY     50000u            /* TIS 开始后 0.5ms 触发神经模拟脉冲 */
#define NERVE_WIDTH_CY     100000u           /* 神经模拟脉冲宽度 1ms */
#define FRAME_COUNT        2u               /* 每次测量跑多少帧(8 个 DAC 注入对一轮) */

/* 扫描模式 —— 同时决定 IP_1 与 IP_Three 的配置, 二者【必须】成对设置:
 *   1 = 模式A「保持」    ADC 通道整个刺激期不变, DAC 每 8 次刺激换挡
 *                       -> 64 次刺激/帧; FRAME_COUNT=10 时 640 次 = 128s
 *   0 = 模式B「时分复用」 ADC 在一次刺激内扫完 8 个通道, DAC 每次刺激换挡
 *                       -> 8 次刺激/帧; FRAME_COUNT=10 时 80 次 = 16s
 * 两种模式下每个样本都带真实的 dac_ch/adc_ch 标签, 上位机解包方式相同。      */
#define SCAN_MODE          1

/* ---- IP_Three ADC MUX ---- */
#define ADC_MODE_MANUAL    0   // 0=自动扫描, 1=手动(板载拨码开关 sw0/1/2)
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

/* ---- IP_Two 电极放电 (Electrode_Discharge, FMC HB10_N / J12, 低电平有效) ---- */
#define DISCHARGE_AUTO      0   // 0=手动(见 DISCHARGE_MANUAL_ON), 1=自动
#define DISCHARGE_MANUAL_ON 0   // 手动模式: 1=放电中(引脚拉低), 0=关闭(引脚拉高)
// 自动模式: 每 N 个注入周期(IP_1 的 total_tick)后, 整整放电一个完整注入周期。
// 一个注入周期 = 一次 total_tick 间隔。SCAN_NESTED=1 时 = 8*CYCLES_PER_CHANNEL
// 个正弦周期; 按当前配置(N=5, FREQ_A=2kHz) 即 40/2000 = 20ms。
// 故 DISCHARGE_EVERY_N=4 => 每 100ms 放电 20ms。0 视作 1。
#define DISCHARGE_EVERY_N   4u

/* =====================================================================
 * Helpers
 * =====================================================================*/
// DDS 输出频率(Hz) -> 32 位相位步长。
//   采样率(DAC 更新率)由 FSM reg1 决定: f_update = F_CLK / N_update
//   (block design 中 update_tick 接常量 1, 故更新率仅由 reg1 决定)。
//   addr_gen 用 acc[31:16] 索引 64K 正弦 ROM —— 标准 32 位相位累加器, 故
//     f_out = f_update * phase_step / 2^32
//     => phase_step = round( f_out * N_update * 2^32 / F_CLK )   (纯整数运算)
//   中间值最大约 2020*500*2^32 ~= 4.3e15, u64 装得下(上限 1.8e19)。
//   注意: 这里的 2^32 曾经是 2^16(旧的 acc[15:0] 索引)。改动 addr_gen 后
//   两处必须一起改, 否则所有频率会差 65536 倍。
//   宏而【不是】static inline 函数 —— 这不是风格问题。-O0 下 GCC 不会内联/折叠
//   函数调用, 于是这段 64 位运算把 libgcc 的 __udivdi3 (3928 字节) 和 __muldi3
//   (636 字节) 一起链进来 —— 4.5KB, 占整个 .text 的 48%, 16KB 的 LMB 直接溢出。
//   写成宏之后, 参数是字面量, 整个表达式是【整型常量表达式】, GCC 前端在编译期
//   就折出常数, 与 -O 等级无关, 那两个 libgcc 例程根本不会被引用。
//   注意: 哪天往这里传运行时变量, 这 4.5KB 就会原样回来。
#define DDS_PHASE_STEP(f_out_hz) \
    ((u32)(((u64)(f_out_hz) * FSM_UPD_PERIOD * 4294967296ULL + (F_CLK_HZ/2)) / F_CLK_HZ))

XGpio Gpio;

/* =====================================================================
 * Per-IP configuration
 * =====================================================================*/

// addr_gen: reg0..3 = 相位步长 A..D, reg4..7 = 相位偏移 A..D[15:0]
static void addr_gen_config(void) {
    volatile u32 *p = (volatile u32*)ADDRGEN_BASE;
    p[0] = DDS_PHASE_STEP(FREQ_A_HZ);
    p[1] = DDS_PHASE_STEP(FREQ_B_HZ);
    p[2] = DDS_PHASE_STEP(FREQ_C_HZ);
    p[3] = DDS_PHASE_STEP(FREQ_D_HZ);
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

// IP_1 (TIS/EIT 主序列器):
//   reg0/reg1 = 保留(旧的 phase_step / cycles-per-channel, 写了也不起作用)
//   reg2[0]  = scan_mode (1=模式A 保持, 0=模式B 时分复用)
//   reg3..7  = 刺激周期 / TIS 延迟 / TIS 时长 / 神经脉冲延迟 / 神经脉冲宽度 (clk 周期数)
//   reg8[15:0] = 帧数(每帧 = 8 个 DAC 注入对扫一轮)
//   reg9[0]/[1] = 软件启动/中止(上升沿触发); reg10/11 = 只读状态/进度
// 测量的启动靠板上 BTNU 按键(IP_1 内部硬件消抖+取沿), 软件只负责配置。
static void sequencer_config(void) {
    volatile u32 *p = (volatile u32*)IP1_BASE;
    p[2] = SCAN_MODE ? 1u : 0u;
    p[3] = STIM_PERIOD_CY;
    p[4] = TIS_DELAY_CY;
    p[5] = TIS_DURATION_CY;
    p[6] = NERVE_DELAY_CY;
    p[7] = NERVE_WIDTH_CY;
    p[8] = FRAME_COUNT;
    p[9] = 0u;                      // 软启动位清零, 等按键(或后续写 1)
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
    // 扫描方式必须与 IP_1 的 scan_mode 配套(见上面 SCAN_MODE 的说明):
    //   模式A -> 2 (周期节拍: 每个 done_tick 感测通道 +1)
    //   模式B -> 1 (嵌套legacy: 每次转换 +1, 每个 done_tick 归零, 一次刺激扫完 8 个)
    // 用同一个 SCAN_MODE 宏推导两边, 避免两个 IP 被配成互相矛盾的组合。
    p[2] = SCAN_MODE ? 2u : 1u;
    p[3] = (ADC_SAMPLE_RATE_HZ == 0) ? 0u             // 采样周期 (0 = 自由运行)
           : (u32)(F_CLK_HZ / (unsigned long)ADC_SAMPLE_RATE_HZ);
}

// IP_Two (源/感 MUX, 电流注入电极):
//   reg0[0]=EIT_IN_EN  reg1[0]=gain  reg2[0]=reset
//   reg3[0]=MUX 模式 (0=自动, 1=手动)  reg4[2:0]=手动通道 0..7
//   reg5[0]=放电模式 (0=手动, 1=自动)  reg6[0]=手动放电 (1=放电, 引脚拉低)
//   reg7[15:0]=自动模式下每 N 个注入周期放电一次 (0 视作 1)
// 自动/手动共用同一换挡表, 源/感 MUX 永不短接。
static void source_mux_config(void) {
    volatile u32 *p = (volatile u32*)IP2_BASE;
    p[0] = 0x0001u;             // EIT_IN_EN
    p[1] = 0x0001u;             // gain
    p[2] = 0x0001u;             // reset
    p[3] = MUX_MODE_MANUAL;     // MUX 模式
    p[4] = MUX_MANUAL_CHAN;     // 手动通道
    // 先写参数(reg6/reg7)再写模式(reg5): 复位默认 reg5=0(手动),
    // 这样自动状态机启用时看到的 N 一定已经是最终值。
    p[6] = DISCHARGE_MANUAL_ON; // 手动放电
    p[7] = DISCHARGE_EVERY_N;   // 自动: 每 N 个注入周期放电一次
    p[5] = DISCHARGE_AUTO;      // 放电模式 (最后写)
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
    sequencer_config();     // IP_1: 扫描模式 / TIS 时序 / 帧数
    adc_mux_config();       // IP_Three: 模式 / 扫描方式 / 采样率
    source_mux_config();    // IP_Two: EIT_IN_EN / MUX 模式

    if (start_gpio() != XST_SUCCESS)
        return XST_FAILURE;

    // ADC 与 TIS 解耦: run 使能【写一次】就一直拉高, ADC 始终自由连续采样。
    // 是否属于刺激期由数据流里的标签位标明(表头字节 bit7=TIS, bit3=run),
    // 上位机离线切分基线段/刺激段, 硬件不去门控采样。
    XGpio_DiscreteWrite(&Gpio, START_CHANNEL, 0x1);

    // 注意: 这个 BD 里【没有】UART, 只有 MDM。这些 xil_printf 要么落到空实现,
    // 要么在 MDM 的 JTAG-UART 打开时才看得到; 真正可靠的现场观测手段是 ILA
    // (tis_on/nerve_pulse/run_active 已接到 probe36..38) 和 UDP 数据里的标签位。
    xil_printf("TIS/EIT ready. Mode %c (%d stim/frame), %d frames per run.\r\n",
               SCAN_MODE ? 'A' : 'B', SCAN_MODE ? 64 : 8, FRAME_COUNT);
    xil_printf("Press BTNU to start a measurement.\r\n");

    // 只读回报进度 —— 启动/停止是 BTNU 的事(IP_1 内部硬件消抖), 软件不参与控制。
    volatile u32 *ip1 = (volatile u32*)IP1_BASE;
    u32 prev_status = 0xFFFFFFFFu;
    u32 prev_frame  = 0xFFFFFFFFu;
    while (1) {
        u32 status   = ip1[10];                 // [0]=run_active [1]=tis_on [2]=nerve
        u32 progress = ip1[11];                 // [15:0]=帧序号 [21:16]=帧内刺激序号
        u32 running  = status & 1u;
        u32 frame    = progress & 0xFFFFu;

        if (running != (prev_status & 1u))
            xil_printf(running ? "run started\r\n" : "run finished\r\n");
        if (running && frame != prev_frame)
            xil_printf("  frame %u/%u\r\n", (unsigned)frame + 1u, FRAME_COUNT);

        prev_status = status;
        prev_frame  = running ? frame : 0xFFFFFFFFu;
    }

    return 0;
}
