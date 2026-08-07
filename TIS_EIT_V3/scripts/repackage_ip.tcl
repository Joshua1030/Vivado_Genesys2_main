# ------------------------------------------------------------------------------
# repackage_ip.tcl — headless re-package of a user IP after its HDL ports changed
#
# Usage (from anywhere):
#   vivado -mode batch -source <repo>/TIS_EIT_V3/scripts/repackage_ip.tcl \
#          -tclargs <ip_folder_name> [<ip_folder_name> ...]
# e.g.
#   vivado -mode batch -source scripts/repackage_ip.tcl -tclargs IP_1_1_0 FSM_1_0
#
# Why this exists: adding a port to an already-packaged IP means component.xml has
# to be updated, otherwise the block design still sees the old interface and
# recreate_project.tcl fails to connect the new pin. The GUI path is
# "Edit in IP Packager -> Re-Package IP"; this is the scripted equivalent, per
# README.md "Making changes > 2. Change an IP's interface".
#
# The key detail: ipx::open_core on its own merges NOTHING. You need a real
# (in-memory) project that has actually elaborated the HDL, then ask IPX to merge
# that project's port list back into the component. Hence the create_project /
# ipx::merge_project_changes ports sequence below.
#
# VLNV/version is deliberately NOT bumped — the block design pins exact VLNVs
# (e.g. xilinx.com:user:IP_1:1.0) and every IP here stays at 1.0, so bd/ltc2500_bd.tcl
# and its list_check_ips need no edits. Only the port list changes.
# Requires Vivado 2025.2.
# ------------------------------------------------------------------------------

set script_dir [file dirname [file normalize [info script]]]
set proj_root  [file dirname $script_dir]   ;# TIS_EIT_V3
set part_name  xc7k325tffg900-2

set ip_list $argv
if { [llength $ip_list] == 0 } {
    # Default: the three IPs that gained ports for the TIS sequencer work.
    set ip_list [list IP_1_1_0 FSM_1_0 ethernet_debug_1_0]
}

foreach ip $ip_list {
    set ip_dir $proj_root/ip_repo/$ip
    if { ![file isdirectory $ip_dir] } {
        error "No such IP folder: $ip_dir"
    }
    puts "=============================================================="
    puts "Re-packaging $ip"
    puts "=============================================================="

    # The IP's top module, read straight out of component.xml. This MUST be set
    # explicitly below: left to auto-inference Vivado picks the inner
    # *_slave_lite_v1_0_S00_AXI module, whose AXI ports are named S_AXI_* rather
    # than the wrapper's s00_axi_*, and the merge then strips the entire S00_AXI
    # interface out of the component ("Multiple IP ports were removed").
    set fh [open $ip_dir/component.xml r]
    set xml [read $fh]
    close $fh
    if { ![regexp {<spirit:modelName>([^<]+)</spirit:modelName>} $xml -> top_mod] } {
        error "Could not find <spirit:modelName> in $ip_dir/component.xml"
    }

    # Throwaway in-memory project holding just this IP's sources, so the HDL is
    # elaborated and its (new) port list is known.
    create_project -in_memory -part $part_name

    set src [concat \
        [glob -nocomplain $ip_dir/hdl/*.v]  \
        [glob -nocomplain $ip_dir/hdl/*.sv] \
        [glob -nocomplain $ip_dir/hdl/*.vhd]]
    if { [llength $src] == 0 } {
        error "No HDL found under $ip_dir/hdl"
    }
    add_files -norecurse $src
    set_property top $top_mod [current_fileset]
    update_compile_order -fileset sources_1
    puts "  top module: $top_mod"

    # Merge the elaborated port list into the existing component.xml, in place.
    # Only 'ports' is merged: new HDL *parameters* (e.g. IP_1's DEBOUNCE_CYCLES)
    # are deliberately NOT promoted to component parameters, so the block design
    # keeps using the HDL default and bd/ltc2500_bd.tcl needs no CONFIG.* edits.
    # (xgui regeneration is skipped for the same reason.)
    ipx::open_core $ip_dir/component.xml
    ipx::merge_project_changes ports [ipx::current_core]

    ipx::update_checksums     [ipx::current_core]
    ipx::check_integrity      [ipx::current_core]
    ipx::save_core            [ipx::current_core]
    ipx::unload_core          [ipx::current_core]

    close_project -delete
    puts "  -> $ip_dir/component.xml updated"
}

puts ""
puts "Re-packaged [llength $ip_list] IP(s). Now re-run scripts/recreate_project.tcl."
