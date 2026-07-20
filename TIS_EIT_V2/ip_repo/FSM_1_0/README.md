# FSM:1.0 — AD5686R quad-DAC SPI driver

AXI4-Lite peripheral that drives an Analog Devices **AD5686R** quad 16-bit DAC over
its 3-wire serial port. It sequences four channels of DDS sine data out to the DAC
and issues a single synchronous **LDAC** update so all four analog outputs change at
once. The SPI clock frequency and the DAC update (sample) rate are both
**software-programmable** through two AXI registers.

VLNV `xilinx.com:user:FSM:1.0`. RTL: [hdl/myip.v](hdl/myip.v) (top wrapper) and
[hdl/myip_slave_lite_v1_0_S00_AXI.v](hdl/myip_slave_lite_v1_0_S00_AXI.v) (AXI
registers + the user FSM, in the *user logic* section).

## Data flow

While `update_tick` is high, the FSM free-runs. Each pass over the four channels it:

1. latches `sine_data_A..D` (16-bit unsigned codes coming from the four sine-LUT
   block RAMs, addressed by the `addr_gen` IP),
2. shifts a 24-bit AD5686R word per channel out `dac_sdo`, framed by `dac_sync`
   and clocked by `dac_sclk` (writing each channel's *input register*),
3. after all four channels, pulses `dac_ldac` low to copy every input register into
   its DAC register — so A/B/C/D update **simultaneously**.

It also emits four one-hot channel strobes `clk_A..D`. These are consumed as clocks
by the `addr_gen` phase accumulators (and `IP_1`), so **one strobe = one DDS phase
step**: the DAC update loop rate and the DDS sample rate are the same thing (see
[Update rate](#update-rate--rate-table)).

## Clocking

`clk` runs at **100 MHz** — the same net as `s00_axi_aclk`, so the AXI registers and
the FSM are in one clock domain (no CDC on the register reads).

```
SCLK = clk / (2 * N)            with N = slv_reg0[7:0]   (N == 0 → default N = 2)
```

| N (slv_reg0) | SCLK | Notes |
|---|---|---|
| 1  | 50 MHz   | AD5686R datasheet maximum — see [bring-up](#hardware-bring-up) |
| 2  | 25 MHz   | **power-on default** (used when slv_reg0 = 0) |
| 4  | 12.5 MHz | |
| 40 | 1.25 MHz | equivalent to the pre-2026 fixed divider |

`div_n` is latched from `slv_reg0` only at the start of each frame (in `IDLE`), so a
mid-transfer register write never glitches an in-flight SPI word. Two derived pulse
widths track `N` automatically:

- **SYNC high** between channel words = 1 SCLK period = `2·N` clk cycles.
- **LDAC low** pulse = 2 SCLK periods = `4·N` clk cycles (40 ns at N=1, 80 ns at
  N=2) — comfortably above the AD5686R minimum at every setting.

## Register map

Base address `0x44A2_0000` (64 KB AXI-Lite window).

| Offset | Register | Field | Meaning |
|--------|----------|-------|---------|
| `0x00` | slv_reg0 | `[7:0] N` | SCLK divider. `SCLK = 100 MHz / (2·N)`. `0` selects the default N = 2 (25 MHz). Latched each frame in `IDLE`. |
| `0x04` | slv_reg1 | `[31:0]` | DAC update period in `clk` cycles (10 ns units). `0` = free-run (update as fast as the SPI allows). Any value larger than one loop time fixes the update/sample rate independent of SCLK. |
| `0x08`–`0x3C` | slv_reg2..15 | — | unused |

MicroBlaze example:

```c
#include "xparameters.h"
#include "xil_io.h"

// 50 MHz SCLK (N = 1)
Xil_Out32(XPAR_FSM_0_S00_AXI_BASEADDR + 0x00, 1);

// Fix the DAC update rate at 100 kSPS: 100 MHz / 100 kHz = 1000 clk cycles
Xil_Out32(XPAR_FSM_0_S00_AXI_BASEADDR + 0x04, 1000);
```

## SPI frame format

Each channel sends one 24-bit AD5686R word, MSB first:

```
 23 .... 20 19 .... 16 15 ................ 0
| C[3:0]  | A[3:0]   |      D[15:0]         |
| 0x1     | one-hot  |  16-bit DAC code     |
```

- **Command `C = 0x1`** — *write to input register n* (the DAC register is updated
  later, together, by the LDAC pulse).
- **Address `A`** — one-hot channel select: A=`0001`, B=`0010`, C=`0100`, D=`1000`.
- **Data `D`** — the 16-bit unsigned sine sample for that channel.

Line behavior: `dac_sclk` idles **high**; `dac_sync` is **active-low** and frames the
24-bit word; `dac_sdo` changes on the SCLK **rising** edge and the DAC samples it on
the **falling** edge. The shift register is 32 bits (`{C, A, D, 8'h00}`) but only the
top 24 bits are clocked out — the trailing `8'h00` pad is never shifted.

## FSM states

Six one-hot states (`myip_slave_lite_v1_0_S00_AXI.v`, user logic):

| State | Action |
|-------|--------|
| `IDLE` | Idle high on all lines; latch `div_n`; wait for the update trigger. |
| `SYNC_HIGH` | Hold `dac_sync` high for `2·N` clk (inter-word gap). |
| `LOAD_DATA` | Build the 24-bit word for the current channel. |
| `SPI_TX` | Shift 24 bits out `dac_sdo` on `dac_sclk`. |
| `CHECK_CH` | Advance the channel counter and pulse the `clk_A..D` strobe. |
| `PULSE_LDAC` | After channel D, hold `dac_ldac` low `4·N` clk, then return to `IDLE`. |

Loop: `IDLE → (SYNC_HIGH → LOAD_DATA → SPI_TX → CHECK_CH) ×4 → PULSE_LDAC → IDLE`.

## Update rate / rate table

In free-run (`slv_reg1 = 0`), one loop is ≈ `204·N + 9` clk cycles, so:

| N | SCLK | DAC update rate ≈ `100 MHz / (204·N + 9)` |
|---|------|-------------------------------------------|
| 1  | 50 MHz   | ~469 kSPS |
| 2  | 25 MHz   | ~240 kSPS |
| 40 | 1.25 MHz | ~12 kSPS  |

Because `clk_A..D` step the DDS accumulators once per loop, the **output sine
frequency is proportional to this update rate** — so in free-run, changing SCLK also
rescales every sine. Write `slv_reg1` with a fixed period (in `clk` cycles) to pin the
sample rate; then the SCLK divider and the sine frequencies are independent, and the
`addr_gen` `phase_step` values no longer need recomputing when you change SCLK.

## Ports

External pins of the IP (see [hdl/myip.v](hdl/myip.v)):

| Port | Dir | Width | Description | Current BD source/sink |
|------|-----|-------|-------------|------------------------|
| `clk` | in | 1 | Main/SPI clock | 100 MHz net (`clk_wiz_1/clk_100Mhz`) |
| `rst_n` | in | 1 | Active-low reset | tied to constant-1 (`xlconstant_1`) |
| `update_tick` | in | 1 | Start/enable strobe | tied to constant-1 → free-run |
| `sine_data_A..D` | in | 16 | Per-channel DAC codes | `blk_mem_gen_0..3/douta` |
| `dac_sclk` | out | 1 | SPI clock | top-level pin + ILA |
| `dac_sync` | out | 1 | Frame / chip-select (active low) | top-level pin + ILA |
| `dac_sdo` | out | 1 | Serial data to DAC | top-level pin + ILA |
| `dac_ldac` | out | 1 | Synchronous update (active low) | top-level pin + ILA |
| `clk_A..D` | out | 1 | One-hot channel strobes | `addr_gen/clk_A..D` (`clk_A` also `IP_1/CLK_A`) |
| `s00_axi_*` | — | — | AXI4-Lite slave (32-bit data, 6-bit addr) | `axi_smc/M03_AXI` |

## Simulation

Self-checking testbench: [../../sim/tb_dac_fsm.v](../../sim/tb_dac_fsm.v) — verifies
the default divider, `N = 1/4`, the LDAC pulse width, and the `slv_reg1` update-rate
decoupling (8 checks, all pass). Pure-Verilog DUT, so XSim behavioral mode needs no
license.

Standalone XSim (fast, from `TIS_EIT_V2/`):

```
xvlog ip_repo/FSM_1_0/hdl/myip.v \
      ip_repo/FSM_1_0/hdl/myip_slave_lite_v1_0_S00_AXI.v \
      sim/tb_dac_fsm.v
xelab -debug typical tb_dac_fsm -s tb_sim
xsim tb_sim -runall
```

Or through the project flow (auto-adds `sim/` files):

```
vivado -mode batch -source scripts/sim.tcl -tclargs tb_dac_fsm
```

(Vivado 2025.2 lives at `E:\Xilinx\2025.2\Vivado\bin` and is not on `PATH`.)

## Hardware bring-up

- Bring up at the **25 MHz default first** and scope `dac_sclk`/`dac_sync`/`dac_sdo`/
  `dac_ldac`. **50 MHz (N=1) is the AD5686R's datasheet maximum** — switch to it only
  after checking signal quality; it is just a register write.
- The design's ILA samples at 100 MHz, so it **cannot faithfully display a 50 MHz
  SCLK** — use a scope for the N=1 check.
- This is packaged IP: after editing the HDL here, **Reset Output Products → Generate
  Output Products** on `FSM_0` in the BD (or delete `work/` and re-run
  `scripts/recreate_project.tcl`) so the generated project picks up the change.

## Files

| Path | Contents |
|------|----------|
| `hdl/myip.v` | Top wrapper; instantiates the AXI-Lite slave |
| `hdl/myip_slave_lite_v1_0_S00_AXI.v` | AXI4-Lite registers **and** the DAC-driver FSM (user logic) |
| `component.xml` | IP-XACT packaging metadata |
| `xgui/` | IP customization GUI (Tcl) |
| `bd/bd.tcl` | Example BD fragment from packaging |
