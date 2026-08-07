# IP_1 — TIS/EIT master sequencer (AXI4-Lite)

`IP_1` is the timing master of the acquisition. It generates the stimulation
schedule from its own free-running 100 MHz counter: when a stimulation starts,
when the TIS burst is on, when the nerve-phantom pulse fires, which electrode
combination is active, and when a bounded measurement run ends.

- HDL: [`hdl/IP_1_slave_lite_v1_0_S00_AXI.v`](hdl/IP_1_slave_lite_v1_0_S00_AXI.v)
  (all user logic), [`hdl/IP_1.v`](hdl/IP_1.v) (pass-through wrapper).
- Base address in the block design: **`0x44A30000`** (MicroBlaze data space).

> **This block used to count sine periods.** It watched the channel-C DDS phase
> MSB roll over and emitted `done_tick` every N periods, which tied the whole
> scan cadence to whatever frequency channel C happened to be running at. TIS
> needs a fixed 200 ms / 100 ms time base *and* channel C has to stay an
> independent free-running tone, so the pacing is now a plain counter. The
> `address` and `CLK_A` ports still exist but are **vestigial** — nothing reads
> them; they are kept only so the existing block-design nets and ILA probes did
> not have to be torn up.

## Stimulation timing

One **stimulation** = `stim_period` clocks (default 200 ms → 5 Hz TIS onset):

```
 t=0                  t=tis_delay        t=tis_delay+tis_duration   t=stim_period
 ├────────────────────┼──────────────────┼──────────────────────────┤
 │ settle + BASELINE  │      TIS ON      │        off tail          │
 │ (TIS off, DAC A/B  │   F1+F2 burst    │                          │
 │  parked mid-scale) │                  │                          │
 └────────────────────┴──────────────────┴──────────────────────────┘
 ▲                     ▲   ▲
 │                     │   └ nerve_pulse: [+nerve_delay, +nerve_width)
 │                     └ tis_on rises; addr_gen acc_A/acc_B released from 0
 └ done_tick: IP_Two latches the DAC pair, IP_Three advances the sense channel
```

The pre-burst window does double duty: it is the electrode charge-settling time
after the mux switch **and** the baseline measurement window for that
stimulation. The ADC free-runs through the whole cycle; baseline and stimulation
samples are separated offline using the TIS tag bit in the data stream (see
[`ethernet_debug`](../ethernet_debug_1_0/README.md)).

Constraint: `tis_delay + tis_duration <= stim_period`. Nothing validates this on
write — if you exceed it the burst is simply truncated at the period boundary.

## Scan modes — `slv_reg2[0]`

A **frame** is always one full sweep of the 8 DAC injection pairs. The mode
decides how the 8 ADC sense channels are covered, and must be set together with
`IP_Three`'s scheme register (`main.c` derives both from one `SCAN_MODE` knob):

| | **mode A — held** (`scan_mode=1`) | **mode B — multiplexed** (`scan_mode=0`) |
|---|---|---|
| sense channel | fixed for the whole stimulation | sweeps all 8 within each stimulation |
| DAC pair advances | every 8 stimulations | every stimulation |
| stimulations per frame | 64 | 8 |
| `dac_ch_sel` source | `dac_cnt` (per `total_tick`) | `chanel_cnt` (per `done_tick`) |
| pair with `IP_Three` `slv_reg2` | `2'b10` cycle-paced | `2'b01` nested-legacy |

Both reach the same 64 `{injection pair, sense channel}` combinations per frame —
`sim/tb_scan_chain.v` regresses exactly that equivalence. Mode B covers a frame
8× faster; the cost is that its sense mux moves every conversion (~2.5 µs)
instead of once per stimulation, so it leans on the LTC2500 hold-window argument
in [`IP_Three`'s README](../IP_Three_1_0/README.md#when-the-mux-switches).

Internally the only difference is which counter's wrap ends a frame:
`frame_done = scan_mode ? dac_cnt_wrap : total_tick`.

## Starting a run

`btn_start` is wired to **BTNU** (B19, active high). It is synchronised, debounced
(`DEBOUNCE_CYCLES`, default 2,000,000 = 20 ms) and edge-detected **in hardware** —
no software polling. One clean press starts a run of `frame_count` frames and the
block returns to idle when it finishes.

In idle: `run_active=0`, `tis_on=0`, `nerve_pulse=0`, `dds_hold=1` — i.e. the two
TIS carriers are muted and their phase is parked at 0. That is also the reset
state, so the board is quiet until someone asks for a measurement.

`slv_reg9` provides a software equivalent for bench work (rising-edge triggered:
write 1 to fire, write 0 to re-arm).

## Register map

| Offset | Register | Field | Meaning |
|:---:|:---:|:---:|---|
| `0x00` | slv_reg0 | — | **reserved** (was the deprecated phase-step register) |
| `0x04` | slv_reg1 | — | **reserved** (was cycles-per-channel N; pacing is time-based now) |
| `0x08` | slv_reg2 | `[0]` | **scan_mode** — `1` = mode A (held), `0` = mode B (multiplexed) |
| `0x0C` | slv_reg3 | `[31:0]` | **stim_period** — clocks per stimulation. `0` ⇒ 20,000,000 (200 ms) |
| `0x10` | slv_reg4 | `[31:0]` | **tis_delay** — settle + baseline window before the burst |
| `0x14` | slv_reg5 | `[31:0]` | **tis_duration** — TIS burst length |
| `0x18` | slv_reg6 | `[31:0]` | **nerve_delay** — from TIS onset to the phantom pulse |
| `0x1C` | slv_reg7 | `[31:0]` | **nerve_width** — phantom pulse width |
| `0x20` | slv_reg8 | `[15:0]` | **frame_count** — frames per run. `0` ⇒ 1 |
| `0x24` | slv_reg9 | `[0]`/`[1]` | **soft_start** / **soft_abort** (rising-edge triggered) |
| `0x28` | *(read-only)* | `[0]`/`[1]`/`[2]` | **status**: `run_active` / `tis_on` / `nerve_pulse` |
| `0x2C` | *(read-only)* | `[15:0]`/`[21:16]` | **progress**: frame index / stimulation index within frame |

All timing registers are raw clock counts at 100 MHz, matching the convention
used by `FSM`'s update period and `IP_Three`'s sample period. `0x28`/`0x2C` read
back live hardware state rather than `slv_reg10`/`slv_reg11` (the read mux is
overridden for those two indices).

## Inputs / outputs (block-design nets)

| Port | Dir | Wired to | Meaning |
|---|---|---|---|
| `btn_start` | in | `btnu` port (B19) | start a run; debounced + edge-detected internally |
| `address`, `CLK_A` | in | `addr_gen_0/lut_addr_C`, `FSM_0/clk_C` | **vestigial**, unused by the logic |
| `done_tick` | out | `IP_Two_0/done_tick`, `IP_Three_0/done_tick` | one pulse per stimulation boundary |
| `total_tick` | out | `IP_Two_0/total_tick` | one pulse per 8 stimulations |
| `dac_ch_sel[2:0]` | out | `IP_Two_0/cha_cnt`, `ethernet_debug_0/dac_ch` | active injection pair |
| `chanel_cnt[2:0]` | out | *(ILA)* | inner 0→7 counter |
| `tis_on` | out | `FSM_0/tis_on`, `ethernet_debug_0/tis_on`, ILA probe36 | burst active |
| `dds_hold` | out | `addr_gen_0/dds_sync` | `= ~tis_on`; parks the A/B DDS phase at 0 |
| `run_active` | out | `ethernet_debug_0/run_active`, ILA probe37 | a run is in progress |
| `nerve_pulse` | out | `nerve_pulse` port (PMOD JD1, V27), ILA probe38 | nerve-phantom drive |
| `sync` | out | *(ILA)* | stimulation boundary marker |
| `enable` | out | `EIT_IN_EN_0` (pin) | one-cycle blanking at each switch |

`tis_on` does two jobs downstream: it gates the DAC A/B gain to zero inside
[`FSM`](../FSM_1_0/README.md) (software cannot mute those channels — gain `0`
means *unity* there), and it tags every ADC sample in `ethernet_debug`.

## Software usage

```c
volatile u32 *ip1 = (u32*)0x44A30000;
ip1[2] = 1;            // scan_mode: 1 = mode A (pair with IP_Three reg2 = 2)
ip1[3] = 20000000;     // stimulation period 200 ms
ip1[4] =  9000000;     // settle + baseline 90 ms
ip1[5] = 10000000;     // TIS burst 100 ms
ip1[6] =    50000;     // nerve pulse at +0.5 ms
ip1[7] =   100000;     // nerve pulse 1 ms wide
ip1[8] =       10;     // 10 frames per run
// then press BTNU; poll ip1[10] (status) / ip1[11] (progress) for progress
```

See [`vitis/ltc2500_read_v1/src/main.c`](../../vitis/ltc2500_read_v1/src/main.c)
for the full init sequence.

## Simulation

- [`sim/tb_tis_sequencer.v`](../../sim/tb_tis_sequencer.v) — this block alone:
  debounce, window placement, nerve pulse, `dds_hold == ~tis_on`, and the
  tick/run-length arithmetic in both modes.
- [`sim/tb_scan_chain.v`](../../sim/tb_scan_chain.v) — this block driving
  `IP_Two` + `IP_Three`: all 64 combinations per frame in both modes, and the
  source/sense mux never shorted.

Both scale the timing registers down by ~1e5 so a run completes in microseconds;
`DEBOUNCE_CYCLES` is a module parameter for the same reason. Note the window
outputs are **registered**, so an edge is visible one clock after the count it
was derived from — the benches model that explicitly.

## Rebuilding after an RTL change

`btn_start`, `tis_on`, `dds_hold`, `nerve_pulse` and `run_active` are new ports,
so `component.xml` has to be updated before the block design can wire them:

```powershell
& "E:\Xilinx\2025.2\Vivado\bin\vivado.bat" -mode batch -source scripts\repackage_ip.tcl -tclargs IP_1_1_0
```

Then the normal flow: delete `work/`, `recreate_project.tcl`, `build.tcl`, and
rebuild the Vitis platform and app — see the top-level [`README.md`](../../README.md).
The VLNV stays at `1.0`, so `bd/ltc2500_bd.tcl` needs no VLNV edits.
