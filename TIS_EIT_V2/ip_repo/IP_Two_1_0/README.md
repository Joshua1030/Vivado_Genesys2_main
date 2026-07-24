# IP_Two — Source/Sense MUX Controller (AXI4-Lite)

`IP_Two` is an AXI4-Lite peripheral that drives the EIT (Electrical Impedance
Tomography) analog front-end. It controls the two 3-bit analog multiplexers —
**MUX1 = Source MUX** (current injection) and **MUX2 = Sense MUX** (voltage
measurement) — plus three simple enable/config lines (`EIT_IN_EN`, `gain`,
`reset`).

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
| `total_tick`   | end-of-full-scan flag (currently **unused** in IP_Two) |

---

## Register map

| Offset | Register | Field | Meaning |
|:---:|:---:|:---:|---|
| `0x00` | slv_reg0 | `[0]`   | `EIT_IN_EN` |
| `0x04` | slv_reg1 | `[0]`   | `gain` |
| `0x08` | slv_reg2 | `[0]`   | `reset` |
| `0x0C` | slv_reg3 | `[0]`   | **MUX mode**: `0` = automatic scan (default), `1` = manual |
| `0x10` | slv_reg4 | `[2:0]` | **manual channel** `0..7` (used only when `slv_reg3[0] = 1`) |

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

No changes to `IP_Two.v`, the block design connections, or the address map are
required.
