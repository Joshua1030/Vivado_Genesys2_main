# IP_1 — Sine-period / electrode-cycle sequencer (AXI4-Lite)

`IP_1` watches the channel-A DDS accumulator, detects when a full sine period
completes, and sequences the electrode/mux scan for the EIT front-end. It tells the
rest of the design *when* one excitation cycle ends and *which* electrode channel is
active.

- HDL: [`hdl/IP_1_slave_lite_v1_0_S00_AXI.v`](hdl/IP_1_slave_lite_v1_0_S00_AXI.v)
  (all user logic), [`hdl/IP_1.v`](hdl/IP_1.v) (pass-through wrapper).
- Base address in the block design: **`0x44A30000`** (MicroBlaze data space).

## Inputs / outputs (block-design nets)

| Port | Direction | Wired to | Meaning |
|---|---|---|---|
| `CLK_A` | in | `addr_gen_0/clk_A` | channel-A DDS update strobe (the block clocks on its `negedge`) |
| `address` | in | `addr_gen_0/lut_addr_A` | current channel-A accumulator (low 16 bits) |
| `chanel_cnt[2:0]` | out | *(unconnected / debug)* | inner scan counter, +1 every N cycles, 0→7 repeating |
| `dac_ch_sel[2:0]` | out | `IP_Two_0/cha_cnt`, `ethernet_debug_0/dac_ch` | **DAC injection channel** (see nested_mode below) |
| `done_tick` | out | `IP_Two_0/done_tick`, `IP_Three_0/done_tick` | N-cycle tick — latches IP_Two mux; paces IP_Three ADC scan |
| `total_tick` | out | `IP_Two_0/total_tick` | pulses once per full 8-channel scan (every 8·N cycles) |
| `sync` | out | `addr_gen_0/dds_sync` | DDS phase reset, once per sine cycle |
| `enable` | out | `EIT_IN_EN_0` (pin) | excitation enable; briefly blanked at each channel switch |

## How it works

On each `negedge CLK_A` the block evaluates
`cycle_done = (address + phase_step[15:0] >= 0x10000)` — i.e. the channel-A
accumulator is about to wrap one full sine period. When a cycle completes it always
pulses `sync` (re-zeroing the DDS phase so every cycle is identical). It counts
completed cycles per channel in `cycle_cnt`; after **N** cycles it switches the
channel — pulsing `done_tick`, briefly dropping `enable` (the mux "switch guard"),
and advancing `chanel_cnt` (wrapping 7→0 with `total_tick`).

During the N−1 non-switching cycles the channel holds, `done_tick`/`enable` stay
idle (excitation runs continuously), and only `sync` keeps pulsing.

### Nested (cycle-paced) mode — `slv_reg2[0]`

`dac_ch_sel` (the value driving the DAC injection mux via `IP_Two/cha_cnt`) is a mux
between two counters:

- **legacy** (`slv_reg2[0]=0`, default): `dac_ch_sel = chanel_cnt` → DAC injection
  advances **every N sine cycles** (the original behavior).
- **nested** (`slv_reg2[0]=1`): `dac_ch_sel = dac_cnt`, a counter that increments on
  `total_tick` → DAC injection advances **every 8·N sine cycles**. Combined with
  `IP_Three` in cycle-paced mode (ADC sense mux advances every N cycles on `done_tick`),
  this produces a nested 8×8 frame: each injection channel is measured against all 8
  sense channels, N cycles each.

IP_Two is unchanged in both modes — it re-latches `cha_cnt` on every `done_tick`; in
nested mode the value only changes at the 8·N boundary, so the injection mux effectively
switches every 8·N cycles.

## Register map

| Offset | Register | Field | Meaning |
|:---:|:---:|:---:|---|
| `0x00` | slv_reg0 | `[31:0]` | `phase_step` — DDS phase increment (frequency); low 16 bits used for the wrap test |
| `0x04` | slv_reg1 | `[15:0]` | **cycles-per-channel N** — sine cycles to dwell on each channel before switching. **0 or 1 = switch every cycle** (original behavior). Range 1…65535. |
| `0x08` | slv_reg2 | `[0]` | **nested_mode**: `0` = legacy (`dac_ch_sel = chanel_cnt`, DAC every N cycles); `1` = nested (`dac_ch_sel = dac_cnt`, DAC every 8·N cycles). Resets to 0. |

`slv_reg1`/`slv_reg2` reset to 0, so an unwritten IP keeps the original
switch-every-cycle, legacy-DAC behavior.

## Software usage

```c
volatile int *ip1_base = (int*)0x44A30000;
ip1_base[0] = phase_step;          // frequency (matches addr_gen channel A)
ip1_base[1] = CYCLES_PER_CHANNEL;  // N sine cycles per electrode channel (0/1 = every cycle)
ip1_base[2] = 1;                   // nested_mode: 1 = DAC every 8N cycles (pair with IP_Three reg2=2)
```

## Rebuilding after an RTL change

`dac_ch_sel` is a **new output port** (added for nested mode), so the IP must be
re-packaged (headless: in-memory project + `ipx::merge_project_changes ports`) before
`recreate_project.tcl` can wire it in the block design. Then run the normal flow:
delete `work/`, `recreate_project.tcl`, `build.tcl` (bitstream + XSA), and rebuild the
Vitis platform and app — see the top-level [`README.md`](../../README.md).
