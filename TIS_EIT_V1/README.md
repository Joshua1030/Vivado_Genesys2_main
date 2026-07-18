# TIS_EIT_V1 — LTC2500 EIT Acquisition System (Genesys2)

FPGA design for an electrical impedance tomography (EIT) acquisition system on the
Digilent **Genesys2** board (Kintex-7 `xc7k325tffg900-2`). A MicroBlaze soft CPU
supervises an LTC2500 ADC readout chain, DDS-style sine excitation (DAC + analog
mux control), and raw-UDP Ethernet streaming over the board's RGMII PHY.

This folder is a **source-only** layout: the Vivado project itself is *generated*
into `work/` (gitignored) by a Tcl script and is fully disposable. Never commit
`work/`.

| | |
|---|---|
| Vivado / Vitis | **2025.2** (the BD script checks the version) |
| Part | `xc7k325tffg900-2` (part-based project, no board files needed) |
| License | `xc7k325t` is **not** in the free Vivado tier — synthesis needs a full license. This machine uses the CMC floating server (`XILINXD_LICENSE_FILE=6062@a2.cmc.ca`), reachable only on VPN/campus network; on other machines any license covering `xc7k325t` works (e.g., the Genesys2 Digilent voucher) |
| Top module | `ltc2500_bd_wrapper` (generated from block design `ltc2500_bd`) |
| Soft CPU | MicroBlaze, 16 KB local BRAM, app `ltc2500_read_v1` |

**Contents:** [Directory layout](#directory-layout) ·
[Quick start](#quick-start-hardware) · [Program the board](#program-the-board) ·
[Software](#software-vitis-unified-20252) · [IP inventory](#ip-inventory-all-xilinxcomuser-sources-in-ip_repo) ·
[Design notes](#design-notes) · [Making changes](#making-changes) ·
[Maintainer reference](#maintainer--ai-assistant-reference)

## Directory layout

```
TIS_EIT_V1/
├── ip_repo/                  # 8 user-packaged IPs used by the block design (see inventory)
├── bd/ltc2500_bd.tcl         # block design, exported with write_bd_tcl (then hand-patched, see notes)
├── coe/sine_64k_16bit.coe    # 64k x 16 sine LUT loaded into 4 block RAMs
├── constraints/Genesys-2-Master.xdc
├── sim/                      # testbenches — auto-added to sim_1 by recreate_project.tcl
├── vitis/ltc2500_read_v1/    # Vitis Unified app component sources (MicroBlaze)
├── scripts/recreate_project.tcl   # regenerates the Vivado project into work/
├── scripts/build.tcl              # synth + impl + bitstream + XSA export
├── scripts/sim.tcl                # headless simulation runner (all 5 flavors)
└── work/                     # GENERATED, gitignored — safe to delete at any time
```

## Quick start (hardware)

```powershell
cd TIS_EIT_V1
& "E:\Xilinx\2025.2\Vivado\bin\vivado.bat" -mode batch -source scripts\recreate_project.tcl
```

(or open the Vivado GUI and run `source .../TIS_EIT_V1/scripts/recreate_project.tcl`
in the Tcl console). This creates `work/ltc2500_top/ltc2500_top.xpr` with the block
design built, validated, wrapper generated, and constraints attached. Open that
`.xpr` in the GUI to browse or edit the design.

To build a bitstream and export the hardware for Vitis:

```powershell
& "E:\Xilinx\2025.2\Vivado\bin\vivado.bat" -mode batch -source scripts\build.tcl
```

Outputs: `work/ltc2500_top/ltc2500_top.runs/impl_1/ltc2500_bd_wrapper.bit` and
`work/ltc2500_bd_wrapper.xsa` (bitstream included). Tip: if you want collaborators
to skip the hardware build, copy the XSA into `TIS_EIT_V1/` and commit it — the
repo `.gitignore` whitelists `*.xsa`.

## Program the board

Connect the Genesys2 over its USB-JTAG port (PROG connector), power it on, then
either:

- **GUI**: Flow Navigator → **Open Hardware Manager** → **Open Target → Auto
  Connect** → **Program Device** → select the bitstream above. The ILA debug
  probes file (`.ltx`, generated alongside the bitstream) is filled in
  automatically, so the ILA is usable from the Hardware Manager right after
  programming.
- **Tcl** (works in batch too):

  ```tcl
  open_hw_manager
  connect_hw_server
  open_hw_target
  set_property PROGRAM.FILE {work/ltc2500_top/ltc2500_top.runs/impl_1/ltc2500_bd_wrapper.bit} [current_hw_device]
  program_hw_devices [current_hw_device]
  ```

Notes:

- JTAG configuration is **volatile** — the FPGA loses it on power-cycle. For a
  self-booting board, write the bitstream to the Genesys2 QSPI flash instead
  (`write_cfgmem` → Hardware Manager *Add Configuration Memory Device*, and set
  the board's mode jumper to QSPI) — see the Genesys2 reference manual.
- Launching a **Vitis** debug session programs the bitstream for you (it is
  packed inside the XSA), so for software work you rarely program manually.

## Software (Vitis Unified 2025.2)

The MicroBlaze app currently initializes AXI GPIO and holds a start pulse high on
GPIO channel 2 (channel 1 reads 8 inputs). Sources: `vitis/ltc2500_read_v1/src/`.

1. Launch Vitis Unified, create a new workspace anywhere **outside** this repo
   (workspaces are disposable; `vitis_workspace/` is gitignored repo-wide).
2. **Create Platform Component** from `work/ltc2500_bd_wrapper.xsa`
   (processor `microblaze_0`, standalone OS).
3. **Create Application Component** (Empty C) targeting that platform, then copy
   `vitis/ltc2500_read_v1/src/{main.c, platform.c, platform.h, lscript.ld}` into
   the component's `src/` (replace the generated ones).
4. Build, program the FPGA with the bitstream, and run/debug over JTAG.

Each user IP also ships a bare-metal C driver under
`ip_repo/<ip>/drivers/*/src/` (register access helpers) if you extend the app.

## IP inventory (all `xilinx.com:user:*`, sources in `ip_repo/`)

| VLNV | Folder | Language | Role |
|---|---|---|---|
| `addr_gen:1.0` | `addr_gen_1_0` | Verilog | AXI-Lite; sweeps addresses into the 4 sine-LUT BRAMs (excitation waveform generator) |
| `FSM:1.0` | `FSM_1_0` | Verilog | AXI-Lite; top-level measurement sequencing FSM |
| `IP_1:1.0` | `IP_1_1_0` | Verilog | AXI-Lite; drives DAC serial interface (`dac_sclk/sync/sdo/ldac`) + `gain`, `EIT_IN_EN` |
| `IP_Two:1.0` | `IP_Two_1_0` | Verilog | AXI-Lite; electrode/analog mux control (`mux_dac1`, `mux_dac2`) |
| `IP_Three:1.0` | `IP_Three_1_0` | Verilog | AXI-Lite; electrode/analog mux control (`mux_0`) |
| `ethernet_debug:1.0` | `ethernet_debug_1_0` | Verilog | AXI-Lite; Ethernet-visible debug/control registers |
| `ltc_driver_fsm:1.1` | `ltc_driver_fsm_1_1` | SystemVerilog | LTC2500 ADC serial readout (`o_mclk/o_sync/o_sdi`, `i_busy/i_drl/i_sdob`, `o_sckb/o_rdlb`) with CDC synchronizers |
| `UDP:5.3` | `UDP_v5_3` | Verilog | AXI-Lite; raw-UDP MAC streaming ADC data over RGMII (`eth_*` pins) at 125 MHz |

Xilinx catalog IP in the BD (MicroBlaze, SmartConnect, clk_wiz, blk_mem_gen ×5,
dist_mem_gen, ILA, AXI GPIO, proc_sys_reset, LMB) is regenerated automatically.

## Design notes

- **Clocks** (`clk_wiz_1`, from the 200 MHz differential system clock):
  `clk_100Mhz` = 100 MHz (MicroBlaze, AXI, sine BRAMs — note: the BD net is
  historically named `clk_wiz_1_clk_400MHz`), `clk_125MHz` = 125 MHz (UDP/RGMII,
  dist_mem_gen), `clk_10MHz` = 10 MHz (addr_gen, FSM, IP_1/Two/Three).
- **MicroBlaze address map**: local BRAM 16 KB @ `0x0000_0000`; `axi_gpio_0`
  @ `0x4000_0000`; then 64 KB AXI-Lite windows: UDP `0x44A0_0000`, addr_gen
  `0x44A1_0000`, FSM `0x44A2_0000`, IP_1 `0x44A3_0000`, IP_Three `0x44A4_0000`,
  IP_Two `0x44A5_0000`, ethernet_debug `0x44A6_0000`.
- An ILA (27 probes, 16k deep) is instantiated in the BD for bring-up; remove it
  to save block RAM once the design is stable.
- **Clock-domain crossings**: with three domains (100/125/10 MHz), any new
  signal that crosses between them needs a synchronizer — see
  `cdc_sync_edge.sv`/`cdc_sync_edge1.sv` in `ip_repo/ltc_driver_fsm_1_1/` for
  the pattern already used here. Unsynchronized crossings usually *simulate*
  fine and then fail intermittently on hardware.
- **Excitation waveform**: `coe/sine_64k_16bit.coe` (65536 × 16-bit entries;
  the header line sets the radix). Replace the file to change the waveform —
  all four sine BRAMs load it through the BD configuration. Keep the same
  depth/width, or update the `blk_mem_gen_*` configs in `bd/ltc2500_bd.tcl`
  to match.

### Expected warnings (safe to ignore)

Seen on every clean recreate/build of this design — don't chase them:

- `CRITICAL WARNING: [BD 41-1347] Reset pin /UDP_0/reset ... connected to
  asynchronous reset source /btnc` — pre-existing design trait (the center
  push-button is the UDP reset); present in V0 as well.
- `INFO`/recommendation messages about `xlconstant` → inline-HDL and "utility
  IPs have equivalent inline hdl" — Xilinx deprecation notices, harmless.

Any **other** critical warning after a recreate is news — investigate before
committing.

## Making changes

> **Golden rule:** everything under `work/` is disposable output. Never edit HDL
> there (Vivado shows *copies* under `work/**/ltc2500_top.gen/.../ipshared/`) —
> regeneration silently discards those edits. The only sources of truth are
> `ip_repo/`, `bd/ltc2500_bd.tcl`, `coe/`, `constraints/`, `sim/`, `vitis/`.
> GUI actions that write back to those repo files are safe — see the table below.

### Do I need the GUI? (recommended workflow)

Mostly no. What's disposable is the generated *project* in `work/`, not GUI
editing as such — what matters is which **file** an edit ultimately lands in:

| Edit | File that persists (commit this) | GUI needed? |
|---|---|---|
| IP logic (behavior only) | `ip_repo/<ip>/hdl/` or `src/` `.v`/`.sv` | No — any text editor |
| Constraints / pinout | `constraints/Genesys-2-Master.xdc` | No (GUI also fine — the project references this file in place) |
| Testbenches | `sim/*.sv` | No |
| MicroBlaze C code | `vitis/ltc2500_read_v1/src/` | No |
| BD: config tweaks, rewiring, another instance of an existing IP | `bd/ltc2500_bd.tcl` — edit it directly | No |
| BD: large topology rework | `bd/ltc2500_bd.tcl` via GUI + re-export (step 5) | Recommended |
| IP interface change / brand-new IP | `ip_repo/<ip>/` via IP Packager (writes back to the repo) | Strongly recommended — raw `ipx::*` Tcl exists but is error-prone |

**Recommended loop:** edit the repo sources in your normal editor, then use the
recreate script as your "compile check":

```powershell
& "E:\Xilinx\2025.2\Vivado\bin\vivado.bat" -mode batch -source scripts\recreate_project.tcl
```

It rebuilds the BD from your edited sources, fails loudly on bad
cells/nets/CONFIG values, and finishes with `validate_bd_design`. No license or
VPN needed. Reserve the GUI for the two rows marked above. (This
edit-and-batch-verify loop is also fully drivable by an AI assistant.)

**Editing `bd/ltc2500_bd.tcl` directly** — the file is declarative Tcl and
quite readable: `create_bd_cell` blocks with `CONFIG.*` properties,
`create_bd_port`, `connect_bd_net` / `connect_bd_intf_net`, and
`assign_bd_address` at the end. Typical no-GUI edits: change a `CONFIG` value,
re-route a net, or copy an existing instance block to add another IP of a type
already in the design. This path has a real advantage over the GUI: there is no
`write_bd_tcl` round-trip, so the hand-patches below are never dropped and your
git diff is exactly your intent. Caveats: if you add a *new* IP type, also add
its VLNV to the `list_check_ips` string near the top; the `# Create instance:`
comments are cosmetic; always finish with the batch recreate to validate.

**Headless simulation** too: `scripts/sim.tcl` runs any testbench in batch and
prints the transcript (see *Run simulations* below) — XSim is license-free.

### 1. Edit an existing IP's logic (no interface change)

Edit the `.v`/`.sv` directly in `ip_repo/<ip>/hdl/` (or `src/`). To propagate
into an already-generated project: open `work/ltc2500_top/ltc2500_top.xpr`, in
the Sources window right-click the IP under the BD → **Reset Output Products…**,
then **Generate Output Products…** — or just delete `work/` and re-run
`scripts/recreate_project.tcl`. AXI register maps live in the
`*_S00_AXI.v` wrapper of each IP.

**Export:** nothing to export — the repo file *is* the source. `git diff` shows
your change; commit it.

### 2. Change an IP's interface (ports, parameters, registers)

Interface changes require re-packaging:

1. In the generated project: **Window → IP Catalog** → right-click the IP →
   **Edit in IP Packager** (creates a disposable `edit_*` project; the default
   location is fine, keep it outside this repo).
2. Make your changes, then in the *Package IP* tab step through every group
   flagged for update (File Groups, Ports and Interfaces, Customization
   Parameters). Bump the **Revision** for compatible fixes; bump the **Version**
   if the interface changed (the BD pins exact VLNVs like
   `xilinx.com:user:FSM:1.0`, so a version bump requires upgrading the BD
   instance). Finish with **Re-Package IP** — this writes back into
   `ip_repo/<ip>/`.
3. Back in the design project: **Reports → Report IP Status** → check the IP →
   **Upgrade Selected**, then re-validate the BD (F6).

**Export:** commit the changed `ip_repo/` files **and** re-export the BD
(step 5) — the upgraded instance changes the BD.

### 3. Create a new IP

1. **Tools → Create and Package New IP** → for a MicroBlaze-controlled block
   pick **Create a new AXI4 peripheral** (that's what the existing 8 IPs are).
2. Set the *IP location* to `TIS_EIT_V1/ip_repo/<YourIP_1_0>` so it is committed
   with the rest, choose **Edit IP** on the finish page, add your logic to the
   generated skeleton, then **Re-Package IP**.
3. Keep **all** sources inside that folder — no `../` file references. (The
   nested layout of `ltc_driver_fsm_1_1`/`UDP_v5_3` is inherited legacy; don't
   imitate it — see the "Do not flatten" note below.)
4. Add it to the BD: open the BD, **+** (Add IP) → your IP → connect clock/reset
   and AXI via **Run Connection Automation**; the Address Editor assigns a
   window automatically. Validate (F6), save.

**Export:** commit the new `ip_repo/<YourIP_1_0>/` folder + re-export the BD
(step 5).

### 4. Edit the block design

Regenerate the project if you don't have one (`scripts/recreate_project.tcl`),
open `work/ltc2500_top/ltc2500_top.xpr`, edit `ltc2500_bd` in the GUI,
**Validate Design** (F6), save.

Constraints are simpler: the project references
`constraints/Genesys-2-Master.xdc` *in place* (added without copying), so
editing it in the Vivado GUI edits the repo file directly — just commit.

### 5. Export the block design (after GUI BD edits or IP upgrades)

Only needed when the BD was changed *in the generated project* (GUI edits,
Report IP Status upgrades). If you edited `bd/ltc2500_bd.tcl` directly, there
is nothing to export. To capture GUI changes, run in the project's Tcl console:

```tcl
write_bd_tcl -force -include_layout E:/Vivado_Genesys2_main/TIS_EIT_V1/bd/ltc2500_bd.tcl
```

Then **before committing**, run `git diff TIS_EIT_V1/bd/ltc2500_bd.tcl` and
**re-apply the three hand-patches** listed under *Hand-patches applied* below —
`write_bd_tcl` rewrites the file from scratch and drops them every time
(clk_wiz output names/frequencies, the 200 MHz input `FREQ_HZ`/`PRIM_IN_FREQ`,
and the `${script_folder}`-relative `Coe_File` paths). The diff makes it obvious
which ones vanished.

Also remember: a BD change that touches the address map or any IP interface
makes the previously exported **XSA stale** — re-run `build.tcl` and rebuild
the Vitis platform from the new XSA (see step 9).

### 6. Add testbenches

Committed home: `sim/`. Any `.v`/`.sv`/`.vhd` file there is added to the
`sim_1` simulation fileset automatically by `recreate_project.tcl`, so it
survives `work/` deletion.

- Create `sim/tb_<name>.sv`, then either re-run the recreate script, or just
  run `scripts/sim.tcl` (it syncs new `sim/` files into the project
  automatically), or in an open project:
  `add_files -fileset sim_1 <repo>/TIS_EIT_V1/sim/tb_<name>.sv`
  (added in place — edits flow back to the repo file).
- Set it as simulation top (right-click → **Set as Top**, or
  `set_property top tb_<name> [get_filesets sim_1]`) and run
  **Run Simulation → Run Behavioral Simulation**. XSim is free: simulation
  works without the synthesis license / VPN.
- Unit-test a single IP by instantiating its module directly — the IP HDL in
  `ip_repo/` is plain source. For system-level simulation instantiate
  `ltc2500_bd_wrapper`; Vivado generates the BD simulation products on the
  first launch.
- Existing examples: `ip_repo/ltc_driver_fsm_1_1/ip_repo/src/tb_ltc_driver.sv`
  and each AXI IP's generated `example_designs/bfm_design/*_tb.sv`.
- Don't use **Add Sources → simulation source → Create File** with the default
  location — it lands in `work/.../sim_1/new/` and dies with `work/`. Create
  the file in `sim/` first, then add it.

### 7. Run simulations

All five Vivado simulation flavors work here. `scripts/sim.tcl` runs any of
them headlessly and prints the simulation transcript at the end:

```powershell
# behavioral (the default)
& "E:\Xilinx\2025.2\Vivado\bin\vivado.bat" -mode batch -source scripts\sim.tcl -tclargs tb_myname
# netlist sims: mode = post-synthesis | post-implementation, type = functional | timing
& "E:\Xilinx\2025.2\Vivado\bin\vivado.bat" -mode batch -source scripts\sim.tcl -tclargs tb_myname post-synthesis functional
```

| Flavor | Simulates | Needs | When to use |
|---|---|---|---|
| Behavioral | RTL sources as written | nothing — license-free | everyday logic debugging; your default |
| Post-synthesis functional | synthesized netlist | completed `synth_1` (`build.tcl` → CMC license/VPN) | suspected synthesis mismatch: unintended latches, sensitivity-list bugs, X-propagation |
| Post-synthesis timing | synthesized netlist + estimated delays | completed `synth_1` | rarely worth it — the delays are only estimates |
| Post-implementation functional | placed-and-routed netlist | completed `impl_1` | final netlist sanity check |
| Post-implementation timing | routed netlist + real SDF delays | completed `impl_1` | the only true timing sim; very slow — unit-level scopes or async corner cases only |

In the GUI the same five options live under **Run Simulation →** (flow
navigator submenu). The underlying Tcl is `launch_simulation` (behavioral) or
`launch_simulation -mode post-synthesis|post-implementation -type
functional|timing`.

> **Timing is signed off by STA, not by simulation.** After implementation,
> check the Timing Summary (`report_timing_summary`, or open the implemented
> run in the GUI): WNS/WHS ≥ 0 with complete constraints is the normal FPGA
> timing sign-off. A post-implementation *timing simulation* of the whole
> MicroBlaze BD is impractically slow — use behavioral simulation for
> functionality plus STA for timing, and reach for netlist simulations only
> with a concrete suspicion.

Practicalities: testbenches must be **self-checking and call `$finish`**
(`sim.tcl` sets the XSim run time to `all`, so a free-running clock with no
`$finish` never terminates); batch outputs land under
`work/ltc2500_top/ltc2500_top.sim/sim_1/<flavor>/`; for waveform viewing run
the same flavor from the GUI instead of batch.

### 8. Verify before committing

Run the clean-clone test: delete `work/`, re-run
`scripts/recreate_project.tcl` in batch mode, and confirm it finishes with
`validate_bd_design` passing. Then check `git status` — only intended source
files should appear. A full `scripts/build.tcl` run is the strongest check but
needs the CMC license (VPN).

### 9. Vitis software

App sources live in `vitis/ltc2500_read_v1/src/`. If you develop inside a Vitis
workspace, copy the edited files back there — workspaces are disposable and
gitignored.

**Staleness rule:** after any BD change that moves the address map or changes
an IP interface, the old XSA — and every platform built from it — is stale.
Re-run `build.tcl`, recreate the platform component from the fresh XSA, and
rebuild the app: the `XPAR_*` base-address macros in `xparameters.h` follow the
address map, so code built against the old platform reads the wrong registers.

## Maintainer / AI-assistant reference

### Provenance

Migrated on 2026-07-18 from the untracked `TIS_EIT_V0/` folder (kept on disk as a
local backup; ~1.1 GB of duplicated Vivado projects). Canonical sources used:

| V1 path | Came from (under `TIS_EIT_V0/`) |
|---|---|
| `bd/ltc2500_bd.tcl` | `write_bd_tcl` export of `LTC2500_new/LTC2500_new/LTC2500/ltc2500_top` (project `ltc2500_top.xpr`) |
| `ip_repo/{addr_gen,FSM,IP_1,IP_Two,IP_Three}*` | `Combined_IP/Combine/IP_compiled2/...` — **not** `IP_Compiled/`, whose HDL differs; `IP_compiled2` is what the working V0 project referenced |
| `ip_repo/ethernet_debug_1_0` | `Combined_IP/Ethernet_Debug_V5/Ethernet_Debug_Test_5/ip_repo/ethernet_debug_1_0` |
| `ip_repo/{ltc_driver_fsm_1_1, UDP_v5_3}` | `LTC2500_new/LTC2500_new/LTC2500/ip_repo/` (the project-local repo) |
| `coe/sine_64k_16bit.coe` | `Combined_IP/Combine/sine_64k_16bit.coe` (was referenced as `c:/Combine/...` in V0) |
| `constraints/`, `vitis/` | `LTC2500_new/LTC2500_new/LTC2500/` project root and `vitis_workspace/ltc2500_read_v1/` |

> **Do not flatten `ltc_driver_fsm_1_1/` or `UDP_v5_3/`**: their `component.xml`
> references sources *outside* the packaged folder (`../cdc_sync_edge.sv`,
> `../../addr_sel.v`, …), so V1 keeps V0's nesting — `component.xml` sits in an
> inner `ip_repo/` subfolder with the extra `.v/.vhd/.sv` files at the level the
> relative paths expect. Flattening breaks IP output generation at synthesis
> ("Failed to deliver one or more file(s)"), not at project creation.

### Hand-patches applied to `bd/ltc2500_bd.tcl` (re-apply after any re-export!)

1. **clk_wiz_1**: added `CLK_OUT2_PORT {clk_125MHz}`, `CLK_OUT3_PORT {clk_10MHz}`
   and the three `CLKOUT*_REQUESTED_OUT_FREQ` values. `write_bd_tcl` drops
   parameters whose `value_src` isn't `"user"`, which breaks the clock pin names
   and leaves five user-IP clocks unconnected (validate_bd_design fails).
2. **200 MHz input clock**: added `CONFIG.FREQ_HZ {200000000}` on both
   `sys_diff_clock_clk_p/n` ports and `CONFIG.PRIM_IN_FREQ {200.000}` on
   `clk_wiz_1`. Same export quirk — without these the recreated MMCM assumes a
   100 MHz input and every clock on real hardware would run at 2×.
3. **blk_mem_gen_0..3**: `CONFIG.Coe_File` re-pointed from the dead absolute path
   `c:/Combine/sine_64k_16bit.coe` to `${script_folder}/../coe/sine_64k_16bit.coe`.

### Rules (the definitive checklist)

1. `work/` is disposable output: never commit it, never edit files under it
   (enforced by `TIS_EIT_V1/.gitignore`; the repo-root `.gitignore` filters
   Vivado/Vitis junk repo-wide).
2. `TIS_EIT_V0/` stays untracked — it is the pre-migration backup; don't add it
   to git and don't source files from it anymore.
3. After every `write_bd_tcl` re-export: `git diff` and re-apply the three
   hand-patches above. No exceptions — the export drops them every time.
4. Never flatten `ip_repo/ltc_driver_fsm_1_1/` or `ip_repo/UDP_v5_3/` (their
   `component.xml` uses `../` source paths); new IPs must keep *all* sources
   inside their own folder.
5. Testbenches live only in `sim/` — anything created under `work/` dies with it.
6. BD changed (address map / IP interface)? The exported XSA and every Vitis
   platform built from it are stale — rebuild both (Making changes, step 9).
7. `bd/ltc2500_bd.tcl` merges poorly (generated-format file): keep BD edits in
   small dedicated commits and let one person at a time rework the BD.
8. Vivado version bump: the BD script hard-checks `2025.2` — after upgrading,
   re-export the BD from the upgraded design, re-apply the hand-patches, and
   update the version check.
9. Before pushing: run the clean-clone test (delete `work/`, batch-run
   `scripts/recreate_project.tcl`, confirm `validate_bd_design` passes) and
   check `git status` shows only intended sources.
