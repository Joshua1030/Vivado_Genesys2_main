# IP_Two — Source/Sense MUX Controller (AXI4-Lite)

`IP_Two` is an AXI4-Lite peripheral that drives the EIT (Electrical Impedance
Tomography) analog front-end. It controls the two 3-bit analog multiplexers —
**MUX1 = Source MUX** (current injection) and **MUX2 = Sense MUX** (voltage
measurement) — plus three simple enable/config lines (`EIT_IN_EN`, `gain`,
`reset`) and the **electrode discharge** output (`Electrode_Discharge`).

- HDL: [`hdl/IP_Two_slave_lite_v1_0_S00_AXI.v`](hdl/IP_Two_slave_lite_v1_0_S00_AXI.v)
  (all user logic), [`hdl/IP_Two.v`](hdl/IP_Two.v) (pass-through wrapper).
- Base address in the block design: **`0x44A50000`** (MicroBlaze data space).

---

## What the block does

The module is the standard Xilinx AXI4-Lite-lite slave template (32 write
registers `slv_reg0..slv_reg31`) with custom logic appended at the bottom of the
`S00_AXI` file. The custom logic has two parts:

1. **Simple control bits** driven straight from registers:
   - `EIT_IN_EN = slv_reg0[0]`
   - `gain      = slv_reg1[0]`
   - `reset     = slv_reg2[0]`

2. **MUX control**, which now supports **two modes** (automatic scan / manual),
   both feeding a shared safety net.

### Inputs from `IP_1`

`IP_1` sequences the channel scan and provides:

| Signal | Meaning |
|---|---|
| `cha_cnt[2:0]` | current scan channel (0..7) |
| `done_tick`    | 1-cycle pulse at the end of each sine period (advances the channel) |
| `total_tick`   | 1-cycle pulse at the end of a full 8-position scan = **one injection cycle**; used by the discharge timer below |

---

## Register map

| Offset | Register | Field | Meaning |
|:---:|:---:|:---:|---|
| `0x00` | slv_reg0 | `[0]`   | `EIT_IN_EN` |
| `0x04` | slv_reg1 | `[0]`   | `gain` |
| `0x08` | slv_reg2 | `[0]`   | `reset` |
| `0x0C` | slv_reg3 | `[0]`   | **MUX mode**: `0` = automatic scan (default), `1` = manual |
| `0x10` | slv_reg4 | `[2:0]` | **manual channel** `0..7` (used only when `slv_reg3[0] = 1`) |
| `0x14` | slv_reg5 | `[0]`   | **Discharge mode**: `0` = manual (default), `1` = automatic |
| `0x18` | slv_reg6 | `[0]`   | **manual discharge**: `1` = discharging (pin low), `0` = off (used only when `slv_reg5[0] = 0`) |
| `0x1C` | slv_reg7 | `[15:0]`| **N** = injection cycles between discharges, automatic mode only. `0` maps to `1` |

All other registers are unused. `slv_reg3`/`slv_reg4` were previously unused, so
adding manual mode required **no port, address-map, or IP-packaging changes** —
only the RTL inside the packaged IP.

---

## Channel → MUX lookup table

Both modes use the same table (`chan_lut` function). Each entry is a
`{mux1, mux2}` pair, deliberately chosen so that **`mux1 != mux2` in every
state** (the source line never equals the sense line):

| Channel | MUX1 (Source) | MUX2 (Sense) |
|:---:|:---:|:---:|
| 0 | `111` | `011` |
| 1 | `011` | `010` |
| 2 | `010` | `001` |
| 3 | `001` | `000` |
| 4 | `000` | `110` |
| 5 | `110` | `101` |
| 6 | `101` | `100` |
| 7 | `100` | `111` |

Reset / parking pair: `mux1 = 111`, `mux2 = 011`.

### Automatic mode (`slv_reg3[0] = 0`, default)

On every **falling edge of `done_tick`**, the block latches
`chan_lut(cha_cnt)` into the outputs — i.e. the muxes follow the scan driven by
`IP_1`. Behavior is identical to the original design.

### Manual mode (`slv_reg3[0] = 1`)

The muxes are parked on the channel written to `slv_reg4[2:0]` via a
combinational lookup (`chan_lut(slv_reg4[2:0])`), so they update **immediately**
when software writes the channel. `done_tick`/`cha_cnt` are ignored while in
manual mode.

---

## Electrode discharge (`Electrode_Discharge`)

Output pin that bleeds accumulated charge off the electrode/tissue interface.
It is **active low**: `0` = discharging, `1` = off. Top-level port
`Electrode_Discharge` → FMC `HB10_N`, package pin **J12** (`LVCMOS25`).

The register bits use the software-friendly sense (`1` = discharge ON); the RTL
inverts once on the way to the pin. Reset state is *manual + off* → pin high →
not discharging, so the default is safe.

### Manual mode (`slv_reg5[0] = 0`, default)

`slv_reg6[0]` drives the pin directly: write `1` to discharge, `0` to stop.

### Automatic mode (`slv_reg5[0] = 1`)

Counts `total_tick` pulses from `IP_1`. After **N** = `slv_reg7[15:0]` completed
injection cycles, the pin is held low for exactly **one further `total_tick`
interval** — one complete injection cycle — then the count restarts:

```
total_tick  ─┐  ┐  ┐  ┐  ┐  ┐  ┐  ┐        (N = 3)
             1  2  3  ╰──╯  1  2  3  ╰──╯
                    discharge      discharge
```

Duration follows the scan configuration: with `SCAN_NESTED = 1`,
`CYCLES_PER_CHANNEL = 5` and a 2 kHz excitation, one injection cycle is
8 × 5 = 40 sine periods = 20 ms, so `N = 4` gives a 20 ms discharge every 100 ms.

The discharge window touches **only this pin** — the DAC, both muxes and
`EIT_IN_EN` keep running unchanged. Switching back to manual mode resets the
counter, so re-enabling automatic mode always starts a fresh count.

`total_tick` is a 1-clock pulse generated by `IP_1` in the same 100 MHz domain
as `IP_Two/clk`, so it is sampled synchronously — no CDC synchronizer needed.

---

## Safety invariant: MUX1 and MUX2 are never shorted

A final stage enforces, unconditionally and in hardware, that the two mux
outputs can never select the same line:

```verilog
if (mux1_sel == mux2_sel) begin
    mux1 = SAFE_MUX1; // 111
    mux2 = SAFE_MUX2; // 011
end else begin
    mux1 = mux1_sel;
    mux2 = mux2_sel;
end
```

Because the lookup table already guarantees `mux1 != mux2` for every valid
channel, this net is pure defense-in-depth — it never fires in normal operation,
but it protects against any future change (e.g. raw-code manual control) that
could otherwise short the source drive into the sense front-end.

---

## Software usage

`IP_Two` lives at `0x44A50000`. Using a `volatile int *base_addr` (word index =
register number), as in `vitis/ltc2500_read_v1/src/main.c`:

```c
volatile int *base_addr = (int*)0x44A50000;

base_addr[0] = 0;   // EIT_IN_EN
base_addr[1] = 1;   // gain
base_addr[2] = 1;   // reset

// --- automatic scan (default) ---
base_addr[3] = 0;   // mode = auto

// --- OR manual: park on channel 5 ---
base_addr[3] = 1;   // mode = manual
base_addr[4] = 5;   // channel 0..7

// --- electrode discharge ---
// manual: discharge on/off directly
base_addr[5] = 0;   // discharge mode = manual
base_addr[6] = 1;   // 1 = discharging (pin low), 0 = off

// OR automatic: discharge one injection cycle out of every 5
base_addr[7] = 4;   // N = 4 injection cycles between discharges
base_addr[5] = 1;   // discharge mode = automatic (write N first)
```

---

## Rebuilding after an RTL change

Because the change is inside the packaged IP, refresh it through the toolchain:

1. In Vivado: **Reports → IP Status → Upgrade** `IP_Two` (or re-package the IP if
   editing it in the IP packager), so the block design picks up the new HDL.
2. Re-run **Synthesis → Implementation → Generate Bitstream**.
3. **Export Hardware** (XSA, include bitstream).
4. In Vitis: update the platform to the new XSA and rebuild the
   `ltc2500_read_v1` application.

Behaviour-only RTL changes need nothing else. A change that **adds or removes a
port** (as `Electrode_Discharge` did) additionally requires re-packaging the IP
so `component.xml` learns the port, plus a new `create_bd_port`/`connect_bd_net`
pair in `bd/ltc2500_bd.tcl` and a pin constraint in
`constraints/Genesys-2-Master.xdc`. The address map is unaffected either way —
the 32 slave registers already exist.
