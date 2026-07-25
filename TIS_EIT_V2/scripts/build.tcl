# ------------------------------------------------------------------------------
# build.tcl — synthesize, implement, write bitstream, export XSA
#
# Usage (after recreate_project.tcl has been run at least once):
#   vivado -mode batch -source <repo>/TIS_EIT_V1/scripts/build.tcl
# or source it in the Vivado GUI Tcl console (with the project open or not).
#
# Outputs (all inside the gitignored work/ directory):
#   work/ltc2500_top/ltc2500_top.runs/impl_1/ltc2500_bd_wrapper.bit
#   work/ltc2500_bd_wrapper.xsa   (hardware export for Vitis, bitstream included)
# ------------------------------------------------------------------------------

set script_dir [file dirname [file normalize [info script]]]
set proj_root  [file dirname $script_dir]   ;# TIS_EIT_V1
set proj_name  ltc2500_top

if { [catch {current_project}] } {
    open_project $proj_root/work/$proj_name/$proj_name.xpr
}

reset_run synth_1
launch_runs synth_1 -jobs 8
wait_on_run synth_1
if { [get_property PROGRESS [get_runs synth_1]] != "100%" } {
    error "Synthesis failed: [get_property STATUS [get_runs synth_1]]"
}

launch_runs impl_1 -to_step write_bitstream -jobs 8
wait_on_run impl_1
if { [get_property PROGRESS [get_runs impl_1]] != "100%" } {
    error "Implementation failed: [get_property STATUS [get_runs impl_1]]"
}

# Hardware export for Vitis (includes the bitstream)
write_hw_platform -fixed -include_bit -force $proj_root/work/ltc2500_bd_wrapper.xsa

# Refresh the committed clone-and-go artifacts at the repo root so they always
# match this build: XSA (Vitis) + the bitstream/ILA-probes pair (remote Hardware
# Manager ILA). These three basenames are whitelisted in .gitignore.
set impl $proj_root/work/$proj_name/$proj_name.runs/impl_1
file copy -force $proj_root/work/ltc2500_bd_wrapper.xsa $proj_root/ltc2500_bd_wrapper.xsa
file copy -force $impl/ltc2500_bd_wrapper.bit           $proj_root/ltc2500_bd_wrapper.bit
file copy -force $impl/ltc2500_bd_wrapper.ltx           $proj_root/ltc2500_bd_wrapper.ltx

puts "------------------------------------------------------------------"
puts " Bitstream: $proj_root/work/$proj_name/$proj_name.runs/impl_1/ltc2500_bd_wrapper.bit"
puts " XSA:       $proj_root/work/ltc2500_bd_wrapper.xsa"
puts " Tip: copy the XSA into TIS_EIT_V1/ and commit it if you want"
puts "      clone-and-go Vitis without rebuilding hardware."
puts "------------------------------------------------------------------"
