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

// ============================================================================
//  PER-MODE CLOCK CONFIGURATION for the Multi_Mode_NS_SAR_ADC_Control IP
// ----------------------------------------------------------------------------
//  IP input clock: 100 MHz (fixed). Fs = 100 MHz / ((divider+1) * (wrap+1)).
//
//  Every mode below is a fully independent register set - edit any mode
//  without affecting the others.
//
//  100 kHz..2 MHz : proven 2 MHz conversion timing (counts 0..49), longer
//                   idle tail.
//  3 MHz / 4 MHz  : compressed sequences. ** PLACEHOLDER TIMING - verify
//                   comparator regeneration & PINT settling before use. **
// ============================================================================

// ----------------------------------------------------------------------------
//  slv_reg[21] static control register builder
//  Bit map (from RTL): DEM_EN=b7 | OUT_SEL=b6:5 | M1=b4 | M0=b3 | A2=b2 |
//                      A3=b1 | A4=b0
// ----------------------------------------------------------------------------
#define CTRL(dem_en, out_sel, order, a2, a3, a4)               \
    ( (((dem_en)  & 0x1u) << 7) |                              \
      (((out_sel) & 0x3u) << 5) |                              \
      (((order)   & 0x3u) << 3) |    /* {M1,M0} = bits 4:3 */  \
      (((a2)      & 0x1u) << 2) |                              \
      (((a3)      & 0x1u) << 1) |                              \
      (((a4)      & 0x1u) << 0) )

#define DEM_OFF        0
#define DEM_ON         1

// Loop-filter order select, 2-bit {M1,M0} value:
#define ORDER_0TH      0x0   // M1=0, M0=0
#define ORDER_1ST      0x1   // M1=0, M0=1
#define ORDER_2ND      0x2   // M1=1, M0=0
#define ORDER_4TH      0x3   // M1=1, M0=1

// Reference presets (verified against the macro):
//                DEM_EN   OUT_SEL  ORDER      A2 A3 A4
//   CTRL(        DEM_OFF, 3,       ORDER_4TH, 0, 0, 0 ) = 0x78  ADC0, 4th, DEM OFF
//   CTRL(        DEM_ON,  3,       ORDER_4TH, 0, 0, 0 ) = 0xF8  ADC0, 4th, DEM ON
//   CTRL(        DEM_OFF, 3,       ORDER_4TH, 0, 1, 1 ) = 0x7B  ADC1 (bits per orig comment)
//   CTRL(        DEM_OFF, 3,       ORDER_4TH, 0, 0, 1 ) = 0x79  ADC1 (hex per orig comment)
//   NOTE: original source said bits "0 11 1 1 0 1 1 --> 79" but those bits are
//   0x7B, not 0x79. Confirm which A3/A4 setting ADC1 actually needs.

// ----------------------------------------------------------------------------

typedef struct { u32 start, end; } pulse_t;

typedef struct {
    const char *name;

    // Main counter
    u32 step;             // slv_reg[0]
    u32 clk_divider;      // slv_reg[1]
    u32 wrap_around;      // slv_reg[2]

    // SAR comparator clock: 4 pulses
    pulse_t cmp[4];       // slv_reg[3..10]

    // Chopper
    u32 chop_trigger;     // slv_reg[12]
    u32 chop_threshold;   // slv_reg[11]

    // Sampling clock CLK_S
    pulse_t clk_s;        // start=slv_reg[14], end=slv_reg[13]

    // Loop-filter integration phases
    pulse_t pint1;        // start=slv_reg[16], end=slv_reg[15]
    pulse_t pint2;        // start=slv_reg[18], end=slv_reg[17]

    // DEM clock: 4 pulses (separate counter domain in the IP)
    pulse_t dem[4];       // start/end regs: (20,19) (29,28) (31,30) (33,32)

    // Amplifier clocks (separate counter domain in the IP)
    pulse_t amp_sample;   // start=slv_reg[23], end=slv_reg[22]
    pulse_t amp_push;     // start=slv_reg[25], end=slv_reg[24]
    u32 amp_chop_trigger; // slv_reg[27]
    u32 amp_chop_div;     // slv_reg[26]

    // Static control (build with CTRL(...))
    u32 ctrl;             // slv_reg[21]
} fs_config_t;

typedef enum {
    FS_100KHZ = 0,
    FS_250KHZ,
    FS_500KHZ,
    FS_1MHZ,
    FS_2MHZ,
    FS_3MHZ,
    FS_4MHZ,
    FS_NUM_MODES
} fs_mode_t;

static const fs_config_t FS_CONFIGS[FS_NUM_MODES] = {

    // ---- 100 kHz -------------------------------------------------------------
    [FS_100KHZ] = {
        .name = "100 kHz", .step = 1, .clk_divider = 0, .wrap_around = 999,
        .cmp   = { {22,24}, {27,29}, {32,34}, {37,39} },
        .chop_trigger = 2, .chop_threshold = 3,
        .clk_s = {0,14},
        .pint1 = {41,44}, .pint2 = {46,49},
        .dem   = { {130,131}, {150,160}, {170,175}, {185,190} },
        .amp_sample = {112,118}, .amp_push = {122,198},
        .amp_chop_trigger = 1, .amp_chop_div = 1000,
        .ctrl = CTRL( /*DEM_EN*/ DEM_OFF, /*OUT_SEL*/ 3, /*ORDER(M1,M0)*/ ORDER_4TH,
                      /*A2*/ 0, /*A3*/ 0, /*A4*/ 0 ),
    },

    // ---- 250 kHz -------------------------------------------------------------
    [FS_250KHZ] = {
        .name = "250 kHz", .step = 1, .clk_divider = 0, .wrap_around = 399,
        .cmp   = { {22,24}, {27,29}, {32,34}, {37,39} },
        .chop_trigger = 2, .chop_threshold = 3,
        .clk_s = {0,14},
        .pint1 = {41,44}, .pint2 = {46,49},
        .dem   = { {130,131}, {150,160}, {170,175}, {185,190} },
        .amp_sample = {112,118}, .amp_push = {122,198},
        .amp_chop_trigger = 1, .amp_chop_div = 1000,
        .ctrl = CTRL( /*DEM_EN*/ DEM_OFF, /*OUT_SEL*/ 3, /*ORDER(M1,M0)*/ ORDER_4TH,
                      /*A2*/ 0, /*A3*/ 0, /*A4*/ 0 ),
    },

    // ---- 500 kHz -------------------------------------------------------------
    [FS_500KHZ] = {
        .name = "500 kHz", .step = 1, .clk_divider = 0, .wrap_around = 199,
        .cmp   = { {22,24}, {27,29}, {32,34}, {37,39} },
        .chop_trigger = 2, .chop_threshold = 3,
        .clk_s = {0,14},
        .pint1 = {41,44}, .pint2 = {46,49},
        .dem   = { {130,131}, {150,160}, {170,175}, {185,190} },
        .amp_sample = {112,118}, .amp_push = {122,198},
        .amp_chop_trigger = 1, .amp_chop_div = 1000,
        .ctrl = CTRL( /*DEM_EN*/ DEM_OFF, /*OUT_SEL*/ 3, /*ORDER(M1,M0)*/ ORDER_4TH,
                      /*A2*/ 0, /*A3*/ 0, /*A4*/ 0 ),
    },

    // ---- 1 MHz ---------------------------------------------------------------
    [FS_1MHZ] = {
        .name = "1 MHz", .step = 1, .clk_divider = 0, .wrap_around = 99,
        .cmp   = { {22,24}, {27,29}, {32,34}, {37,39} },
        .chop_trigger = 2, .chop_threshold = 3,
        .clk_s = {0,14},
        .pint1 = {41,44}, .pint2 = {46,49},
        .dem   = { {130,131}, {150,160}, {170,175}, {185,190} },
        .amp_sample = {112,118}, .amp_push = {122,198},
        .amp_chop_trigger = 1, .amp_chop_div = 1000,
        .ctrl = CTRL( /*DEM_EN*/ DEM_OFF, /*OUT_SEL*/ 3, /*ORDER(M1,M0)*/ ORDER_4TH,
                      /*A2*/ 0, /*A3*/ 0, /*A4*/ 0 ),
    },

    // ---- 2 MHz: original verified layout (reference) --------------------------
    [FS_2MHZ] = {
        .name = "2 MHz", .step = 1, .clk_divider = 0, .wrap_around = 49,
        .cmp   = { {29,31}, {34,36}, {39,41}, {44,46} },
        .chop_trigger = 2, .chop_threshold = 3,
        .clk_s = {0,14},
        .pint1 = {1,14}, .pint2 = {16,26},
        .dem   = { {29,31}, {34,36}, {39,41}, {44,46} },
        .amp_sample = {112,118}, .amp_push = {122,198},
        .amp_chop_trigger = 1, .amp_chop_div = 1000,
        .ctrl = CTRL( /*DEM_EN*/ DEM_OFF, /*OUT_SEL*/ 3, /*ORDER(M1,M0)*/ ORDER_4TH,
                      /*A2*/ 0, /*A3*/ 0, /*A4*/ 0 ),
    },

    // ---- 3 MHz (actual 3.03 MHz): x2/3 compressed. PLACEHOLDER - verify! ------
    [FS_3MHZ] = {
        .name = "3 MHz (3.03)", .step = 1, .clk_divider = 0, .wrap_around = 32,
        .cmp   = { {18,19}, {22,23}, {26,27}, {30,31} },
        .chop_trigger = 2, .chop_threshold = 3,
        .clk_s = {0,9},
        .pint1 = {1,9}, .pint2 = {11,16},
        .dem   = { {87,88}, {100,107}, {113,117}, {123,127} },
        .amp_sample = {75,79}, .amp_push = {81,132},
        .amp_chop_trigger = 1, .amp_chop_div = 1000,
        .ctrl = CTRL( /*DEM_EN*/ DEM_OFF, /*OUT_SEL*/ 3, /*ORDER(M1,M0)*/ ORDER_4TH,
                      /*A2*/ 0, /*A3*/ 0, /*A4*/ 0 ),
    },

    // ---- 4 MHz: x1/2 compressed. PLACEHOLDER - verify! ------------------------
    [FS_4MHZ] = {
        .name = "4 MHz", .step = 1, .clk_divider = 0, .wrap_around = 24,
        .cmp   = { {11,11}, {13,13}, {15,15}, {17,17} },
        .chop_trigger = 2, .chop_threshold = 3,
        .clk_s = {0,7},
        .pint1 = {20,22}, .pint2 = {23,24},
        .dem   = { {65,66}, {75,80}, {85,87}, {92,95} },
        .amp_sample = {56,59}, .amp_push = {61,99},
        .amp_chop_trigger = 1, .amp_chop_div = 1000,
        .ctrl = CTRL( /*DEM_EN*/ DEM_OFF, /*OUT_SEL*/ 0, /*ORDER(M1,M0)*/ ORDER_1ST,
                      /*A2*/ 0, /*A3*/ 0, /*A4*/ 0 ),
    },
};

// >>> SELECT THE CONFIGURATION TO RUN HERE <<<
static const fs_mode_t g_fs_mode = FS_2MHZ;

// ============================================================================

static void apply_config(const fs_config_t *c)
{
    // Main counter
    Xil_Out32(NS_SAR_BASE_ADDR + (0  * 4), c->step);
    Xil_Out32(NS_SAR_BASE_ADDR + (1  * 4), c->clk_divider);
    Xil_Out32(NS_SAR_BASE_ADDR + (2  * 4), c->wrap_around);

    // CMP: 4 pulses on CLK
    Xil_Out32(NS_SAR_BASE_ADDR + (3  * 4), c->cmp[0].start);
    Xil_Out32(NS_SAR_BASE_ADDR + (4  * 4), c->cmp[0].end);
    Xil_Out32(NS_SAR_BASE_ADDR + (5  * 4), c->cmp[1].start);
    Xil_Out32(NS_SAR_BASE_ADDR + (6  * 4), c->cmp[1].end);
    Xil_Out32(NS_SAR_BASE_ADDR + (7  * 4), c->cmp[2].start);
    Xil_Out32(NS_SAR_BASE_ADDR + (8  * 4), c->cmp[2].end);
    Xil_Out32(NS_SAR_BASE_ADDR + (9  * 4), c->cmp[3].start);
    Xil_Out32(NS_SAR_BASE_ADDR + (10 * 4), c->cmp[3].end);

    // CLK_S (note: start=reg14, end=reg13)
    Xil_Out32(NS_SAR_BASE_ADDR + (14 * 4), c->clk_s.start);
    Xil_Out32(NS_SAR_BASE_ADDR + (13 * 4), c->clk_s.end);

    // Chopper
    Xil_Out32(NS_SAR_BASE_ADDR + (12 * 4), c->chop_trigger);
    Xil_Out32(NS_SAR_BASE_ADDR + (11 * 4), c->chop_threshold);

    // PINT windows (start regs are the higher index)
    Xil_Out32(NS_SAR_BASE_ADDR + (16 * 4), c->pint1.start);
    Xil_Out32(NS_SAR_BASE_ADDR + (15 * 4), c->pint1.end);
    Xil_Out32(NS_SAR_BASE_ADDR + (18 * 4), c->pint2.start);
    Xil_Out32(NS_SAR_BASE_ADDR + (17 * 4), c->pint2.end);

    // DEM_CLK: 4 pulses (start regs are the higher index)
    Xil_Out32(NS_SAR_BASE_ADDR + (20 * 4), c->dem[0].start);
    Xil_Out32(NS_SAR_BASE_ADDR + (19 * 4), c->dem[0].end);
    Xil_Out32(NS_SAR_BASE_ADDR + (29 * 4), c->dem[1].start);
    Xil_Out32(NS_SAR_BASE_ADDR + (28 * 4), c->dem[1].end);
    Xil_Out32(NS_SAR_BASE_ADDR + (31 * 4), c->dem[2].start);
    Xil_Out32(NS_SAR_BASE_ADDR + (30 * 4), c->dem[2].end);
    Xil_Out32(NS_SAR_BASE_ADDR + (33 * 4), c->dem[3].start);
    Xil_Out32(NS_SAR_BASE_ADDR + (32 * 4), c->dem[3].end);

    // AMP clocks
    Xil_Out32(NS_SAR_BASE_ADDR + (23 * 4), c->amp_sample.start);
    Xil_Out32(NS_SAR_BASE_ADDR + (22 * 4), c->amp_sample.end);
    Xil_Out32(NS_SAR_BASE_ADDR + (25 * 4), c->amp_push.start);
    Xil_Out32(NS_SAR_BASE_ADDR + (24 * 4), c->amp_push.end);
    Xil_Out32(NS_SAR_BASE_ADDR + (27 * 4), c->amp_chop_trigger);
    Xil_Out32(NS_SAR_BASE_ADDR + (26 * 4), c->amp_chop_div);

    // Static control
    Xil_Out32(NS_SAR_BASE_ADDR + (21 * 4), c->ctrl);
}

int main()
{
    const fs_config_t *cfg = &FS_CONFIGS[g_fs_mode];

    xil_printf("Initializing Multi_Mode_NS_SAR_ADC_Control IP...\n\r");
    xil_printf("Mode: %s | divider=%d wrap=%d (Fs = 100MHz / %d) | ctrl=0x%02x\n\r",
               cfg->name, cfg->clk_divider, cfg->wrap_around,
               (cfg->clk_divider + 1) * (cfg->wrap_around + 1), cfg->ctrl);

    apply_config(cfg);

    xil_printf("Configuration Complete. IP is now running.\n\r");
    return 0;
}