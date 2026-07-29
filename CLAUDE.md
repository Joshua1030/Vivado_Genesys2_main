# Vivado_Genesys2_main

Multi-project Vivado/Vitis workspace — one subfolder per hardware project. Each
project owns its own docs and Tcl build flow; there is no shared build system.

## Active project

**`TIS_EIT_V2/`** is the actively-maintained project. Its
[README.md](TIS_EIT_V2/README.md) is the canonical reference — build/sim
commands, IP inventory, the IP-editing workflow, `bd/ltc2500_bd.tcl` hand-patch
checklist, and system architecture all live there (including a dedicated
"Maintainer / AI-assistant reference" section). Read it before working in that
folder; don't duplicate its content here, it will drift.

## Other top-level folders

`TIS_EIT_V1/` (has its own `README.md`), `TIS_EIT_V0/` (untracked local backup —
don't add to git, don't source from it), `NetronV2/`, `NetronV3/`,
`ICSTRPNS_V1/`, `LTC2500_new/`. These have no root-level README and their status
hasn't been verified here — don't assume they're current or maintained; check
with whoever owns them before treating them as source of truth.

## Toolchain

Vivado/Vitis **2025.2** at `E:\Xilinx\2025.2\Vivado\bin` — not on PATH, invoke
with the full path (e.g. `& "E:\Xilinx\2025.2\Vivado\bin\vivado.bat" -mode batch
-source <script>.tcl`).

## `.claude/settings.json`

Sets `XILINX_LOCAL_USER_DATA=false`. Parallel `-jobs 8` synthesis can otherwise
fail at Vivado startup (`Could not open 'C'` / `tclapp::load_apps`) due to a
tclapp race; this env var avoids it.
