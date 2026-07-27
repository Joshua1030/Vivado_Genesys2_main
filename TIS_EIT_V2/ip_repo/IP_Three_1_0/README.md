# IP_Three — ADC sense-MUX controller (AXI4-Lite)

`IP_Three` selects which electrode the single LTC2500 ADC reads, by driving the two
differential 8→1 sense muxes on the **JA PMOD**. Both muxes are always driven to the
**same** channel address. It supports a **manual** mode (board slide switches) and an
**automatic** time-multiplexing mode with two schemes.

- HDL: [`hdl/myip_slave_lite_v1_0_S00_AXI.v`](hdl/myip_slave_lite_v1_0_S00_AXI.v) (user
  logic), [`hdl/myip.v`](hdl/myip.v) (wrapper).
- Base address: **`0x44A40000`** (= `three_addr` in the app).

## Register map

| Offset | Register | Field | Meaning |
|:---:|:---:|:---:|---|
| `0x00` | slv_reg0 | `[0]` | `enable` → old FMC `enable_0` pin (retained) |
| `0x04` | slv_reg1 | `[0]` | **mode**: `0` = automatic scan, `1` = manual (board switches) |
| `0x08` | slv_reg2 | `[1:0]` | **auto scheme**: `00` = free-run sweep (per-conversion), `01` = nested 8×8 legacy (per-conversion, reset on `done_tick`), `10` = **cycle-paced** (sense mux +1 every N sine cycles, on `done_tick`) |
| `0x0C` | slv_reg3 | `[31:0]` | **ADC sample period N** (100 MHz clocks) → sample rate = 100 MHz / N. `0` = free-run (default). Also gates the ADC start (`adc_start` → `ltc_driver_fsm/i_start`, AND-ed with the GPIO `run`). Max rate is capped by the FSM conversion-loop time (~a few hundred clocks). |

## Inputs / outputs

| Signal | Dir | Wired to | Meaning |
|---|---|---|---|
| `master_clk` | in | `ltc_driver_fsm/o_mclk` | ADC conversion strobe; sense counter advances on its falling edge |
| `sw_ch0/1/2` | in | board `sw0/sw1/sw2` | manual channel (0–7), used when `slv_reg1[0]=1` |
| `done_tick` | in | `IP_1/done_tick` | DAC channel switch; resets the sense sweep in nested mode |
| `run` | in | `axi_gpio_0/gpio2_io_o` | ADC run/enable (the old `i_start` GPIO); gates `adc_start` |
| `adc_start` | out | `ltc_driver_fsm/i_start` | ADC conversion-start; paced at 100 MHz / `slv_reg3` (rate control) |
| `o_ja1..o_ja6` | out | JA1..JA6 | the two muxes' address lines (same address on both) |
| `adc_ch[2:0]` | out | `ethernet_debug/adc_ch` | current sense channel (0–7) for the packet header |
| `mux[2:0]`, `enable` | out | FMC `mux_0`, `enable_0` | legacy FMC outputs, retained (vestigial) |

## JA PMOD pinout (both muxes = same channel)

`JA0 = EIT_IN_EN` (from IP_Two reg0, the shared mux enable). The two differential muxes
take the address in pin order **A0 / A2 / A1**:

| Pin | mux | signal | Pin | mux | signal |
|:---:|:---:|:---:|:---:|:---:|:---:|
| JA1 | 1 | Addr0 | JA4 | 2 | Addr0 |
| JA2 | 1 | Addr2 | JA5 | 2 | Addr2 |
| JA3 | 1 | Addr1 | JA6 | 2 | Addr1 |

## Channel ↔ address mapping (CH1–CH8)

| Channel (index) | 0 (CH1) | 1 (CH2) | 2 (CH3) | 3 (CH4) | 4 (CH5) | 5 (CH6) | 6 (CH7) | 7 (CH8) |
|---|---|---|---|---|---|---|---|---|
| Address `[2:0]` | 111 | 110 | 101 | 100 | 000 | 001 | 010 | 011 |

## Modes

- **Manual** (`slv_reg1[0]=1`): channel = `{sw2,sw1,sw0}`; both muxes park there.
- **Auto free-run** (`slv_reg1[0]=0`, `slv_reg2[1:0]=00`): the sense counter advances 0→7 on
  every ADC conversion (`o_mclk`), independent of the DAC. Fastest.
- **Auto nested 8×8 legacy** (`slv_reg2[1:0]=01`): same per-conversion advance, but the sense
  counter **resets to 0 on each DAC channel switch** (`IP_1/done_tick`). Assumes the DAC
  dwell (`IP_1/slv_reg1` cycles-per-channel) spans ≥8 ADC conversions.
- **Auto cycle-paced** (`slv_reg2[1:0]=10`): the sense counter advances **once per N sine
  cycles** (on each `IP_1/done_tick`), decoupled from the conversion rate. Paired with
  `IP_1/slv_reg2[0]=1` (DAC advances every 8·N cycles), this gives a true nested 8×8 frame:
  each injection channel is measured against all 8 sense channels for N cycles each. The
  ADC sample rate (`slv_reg3`) then sets how many samples are captured per sense channel.

## Software

```c
volatile int *three_addr = (int*)0x44A40000;
three_addr[0] = 1;   // enable (legacy FMC)
three_addr[1] = 0;   // mode: 0=auto, 1=manual
three_addr[2] = 2;   // auto scheme: 0=free-run, 1=nested-legacy, 2=cycle-paced (pair w/ IP_1 reg2=1)
three_addr[3] = 0;   // ADC sample period N (100 MHz clks); 0=free-run, else rate=100MHz/N
```

The per-sample DAC/ADC channel tag is added downstream in `ethernet_debug` — see its
README for the 6-byte wire format.
