# ------------------------------------------------------------------------------
# recreate_project.tcl — regenerate the ltc2500_top Vivado project from sources
#
# Usage (from anywhere):
#   vivado -mode batch -source <repo>/TIS_EIT_V1/scripts/recreate_project.tcl
# or in the Vivado GUI Tcl console:
#   source <repo>/TIS_EIT_V1/scripts/recreate_project.tcl
#
# Creates the project in TIS_EIT_V1/work/ltc2500_top (gitignored, disposable).
# Requires Vivado 2025.2.
# ------------------------------------------------------------------------------

set script_dir [file dirname [file normalize [info script]]]
set proj_root  [file dirname $script_dir]   ;# TIS_EIT_V1
set proj_name  ltc2500_top
set part_name  xc7k325tffg900-2             ;# Kintex-7 on Digilent Genesys2

create_project $proj_name $proj_root/work/$proj_name -part $part_name -force
set_property target_language Verilog [current_project]

# User IP catalog (all 8 packaged IPs used by the block design)
set_property ip_repo_paths [list $proj_root/ip_repo] [current_project]
update_ip_catalog

# Build the block design (script validates and saves it at the end)
source $proj_root/bd/ltc2500_bd.tcl

# HDL wrapper as top
make_wrapper -files [get_files ltc2500_bd.bd] -top -import
set_property top ltc2500_bd_wrapper [current_fileset]

# Constraints
add_files -fileset constrs_1 -norecurse $proj_root/constraints/Genesys-2-Master.xdc

# Testbenches (simulation-only sources) from sim/
set sim_files [glob -nocomplain $proj_root/sim/*.v $proj_root/sim/*.sv $proj_root/sim/*.vhd]
if { [llength $sim_files] } {
    add_files -fileset sim_1 -norecurse $sim_files
    puts "Added [llength $sim_files] testbench file(s) from sim/ to sim_1"
}

update_compile_order -fileset sources_1

puts "------------------------------------------------------------------"
puts " Project recreated: $proj_root/work/$proj_name/$proj_name.xpr"
puts " Top module:        ltc2500_bd_wrapper"
puts " Next step:         source scripts/build.tcl  (synth + impl + XSA)"
puts "------------------------------------------------------------------"
