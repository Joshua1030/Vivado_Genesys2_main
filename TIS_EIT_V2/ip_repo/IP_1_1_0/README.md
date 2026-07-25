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
| `chanel_cnt[2:0]` | out | `IP_Two_0/cha_cnt` | active electrode channel, 0→7 repeating |
| `done_tick` | out | `IP_Two_0/done_tick` | channel-switch tick (latches the IP_Two mux) |
| `total_tick` | out | `IP_Two_0/total_tick` | pulses once per full 8-channel scan |
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

## Register map

| Offset | Register | Field | Meaning |
|:---:|:---:|:---:|---|
| `0x00` | slv_reg0 | `[31:0]` | `phase_step` — DDS phase increment (frequency); low 16 bits used for the wrap test |
| `0x04` | slv_reg1 | `[15:0]` | **cycles-per-channel N** — sine cycles to dwell on each channel before switching. **0 or 1 = switch every cycle** (original behavior). Range 1…65535. |

`slv_reg1` resets to 0, so an unwritten register keeps the original
switch-every-cycle behavior.

## Software usage

```c
volatile int *ip1_base = (int*)0x44A30000;
ip1_base[0] = phase_step;          // frequency (matches addr_gen channel A)
ip1_base[1] = CYCLES_PER_CHANNEL;  // N sine cycles per electrode channel (0/1 = every cycle)
```

## Rebuilding after an RTL change

`slv_reg1` already exists (no port/interface change), so no IP re-packaging or block
design edit is needed. Refresh the design through the normal flow: delete `work/`,
`recreate_project.tcl`, `build.tcl` (bitstream + XSA), then rebuild the Vitis platform
and app — see the top-level [`README.md`](../../README.md).
