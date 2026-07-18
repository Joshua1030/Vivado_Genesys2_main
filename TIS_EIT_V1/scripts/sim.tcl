# ------------------------------------------------------------------------------
# sim.tcl — run a testbench in XSim (behavioral or netlist simulation)
#
# Usage:
#   vivado -mode batch -source scripts/sim.tcl -tclargs <tb_top> [mode] [type]
#     mode: behavioral (default) | post-synthesis | post-implementation
#     type: functional (default) | timing          (ignored for behavioral)
#
# Examples:
#   vivado -mode batch -source scripts/sim.tcl -tclargs tb_ltc_driver
#   vivado -mode batch -source scripts/sim.tcl -tclargs tb_ltc_driver post-synthesis functional
#   vivado -mode batch -source scripts/sim.tcl -tclargs tb_ltc_driver post-implementation timing
#
# Testbenches live in sim/ (see README "Add testbenches") and must end with
# $finish — the run time is set to "all". Behavioral simulation needs no
# license; the post-* modes need completed build products from scripts/build.tcl
# (CMC license / VPN).
# ------------------------------------------------------------------------------

set script_dir [file dirname [file normalize [info script]]]
set proj_root  [file dirname $script_dir]
set proj_name  ltc2500_top

if { $argc < 1 } {
    error "Usage: vivado -mode batch -source scripts/sim.tcl -tclargs <tb_top> \[behavioral|post-synthesis|post-implementation\] \[functional|timing\]"
}
set tb_top   [lindex $argv 0]
set sim_mode [expr { $argc > 1 ? [lindex $argv 1] : "behavioral" }]
set sim_type [expr { $argc > 2 ? [lindex $argv 2] : "functional" }]

if { $sim_mode ni [list behavioral post-synthesis post-implementation] } {
    error "Invalid mode '$sim_mode' (expected: behavioral | post-synthesis | post-implementation)"
}
if { $sim_type ni [list functional timing] } {
    error "Invalid type '$sim_type' (expected: functional | timing)"
}

set xpr $proj_root/work/$proj_name/$proj_name.xpr
if { [file exists $xpr] } {
    open_project $xpr
} else {
    source $script_dir/recreate_project.tcl
}

# Netlist simulations need the corresponding run to have completed
if { $sim_mode eq "post-synthesis" && [get_property PROGRESS [get_runs synth_1]] ne "100%" } {
    error "post-synthesis simulation needs a completed synth_1 — run scripts/build.tcl first (requires the CMC license / VPN)"
}
if { $sim_mode eq "post-implementation" && [get_property PROGRESS [get_runs impl_1]] ne "100%" } {
    error "post-implementation simulation needs a completed impl_1 — run scripts/build.tcl first (requires the CMC license / VPN)"
}

# Pick up any sim/ files added since the project was generated
set sim_files [glob -nocomplain $proj_root/sim/*.v $proj_root/sim/*.sv $proj_root/sim/*.vhd]
foreach f $sim_files {
    if { [get_files -quiet -of_objects [get_filesets sim_1] $f] eq "" } {
        add_files -fileset sim_1 -norecurse $f
        puts "Added new testbench file to sim_1: [file tail $f]"
    }
}

set_property top $tb_top [get_filesets sim_1]
set_property -name {xsim.simulate.runtime} -value {all} -objects [get_filesets sim_1]

# Hardened shells may set this; it stops cmd.exe finding XSim's generated
# compile.bat/elaborate.bat in the sim dir ("'compile.bat' is not recognized").
unset -nocomplain ::env(NoDefaultCurrentDirectoryInExePath)

if { $sim_mode eq "behavioral" } {
    launch_simulation
} else {
    launch_simulation -mode $sim_mode -type $sim_type
}
close_sim -quiet

# Surface the simulation transcript ($display output) on the console
set logs [glob -nocomplain \
    $proj_root/work/$proj_name/$proj_name.sim/sim_1/*/xsim/simulate.log \
    $proj_root/work/$proj_name/$proj_name.sim/sim_1/*/*/xsim/simulate.log]
set log ""
set newest 0
foreach f $logs {
    if { [file mtime $f] > $newest } { set newest [file mtime $f]; set log $f }
}
if { $log ne "" } {
    puts "------------------------------------------------------------------"
    puts " Simulation transcript: $log"
    puts "------------------------------------------------------------------"
    set fh [open $log r]
    puts [read $fh]
    close $fh
} else {
    puts "WARNING: no simulate.log found under work/$proj_name/$proj_name.sim/sim_1"
}
