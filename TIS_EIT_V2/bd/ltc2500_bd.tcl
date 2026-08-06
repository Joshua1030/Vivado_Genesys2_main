
################################################################
# This is a generated script based on design: ltc2500_bd
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2025.2
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   if { [string compare $scripts_vivado_version $current_vivado_version] > 0 } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2042 -severity "ERROR" " This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Sourcing the script failed since it was created with a future version of Vivado."}

   } else {
     catch {common::send_gid_msg -ssname BD::TCL -id 2041 -severity "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}

   }

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source ltc2500_bd_script.tcl

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xc7k325tffg900-2
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name ltc2500_bd

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      common::send_gid_msg -ssname BD::TCL -id 2001 -severity "INFO" "Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   common::send_gid_msg -ssname BD::TCL -id 2002 -severity "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   common::send_gid_msg -ssname BD::TCL -id 2003 -severity "INFO" "Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   common::send_gid_msg -ssname BD::TCL -id 2004 -severity "INFO" "Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

common::send_gid_msg -ssname BD::TCL -id 2005 -severity "INFO" "Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   catch {common::send_gid_msg -ssname BD::TCL -id 2006 -severity "ERROR" $errMsg}
   return $nRet
}

set bCheckIPsPassed 1
##################################################################
# CHECK IPs
##################################################################
set bCheckIPs 1
if { $bCheckIPs == 1 } {
   set list_check_ips "\ 
xilinx.com:ip:microblaze:11.0\
xilinx.com:user:UDP:5.3\
xilinx.com:ip:mdm:3.2\
xilinx.com:ip:clk_wiz:6.0\
xilinx.com:ip:proc_sys_reset:5.0\
xilinx.com:ip:smartconnect:1.0\
xilinx.com:ip:dist_mem_gen:8.0\
xilinx.com:ip:ila:6.2\
xilinx.com:ip:axi_gpio:2.0\
xilinx.com:user:ltc_driver_fsm:1.1\
xilinx.com:ip:xlconstant:1.1\
xilinx.com:ip:blk_mem_gen:8.4\
xilinx.com:user:IP_1:1.0\
xilinx.com:user:IP_Three:1.0\
xilinx.com:user:IP_Two:1.0\
xilinx.com:user:FSM:1.0\
xilinx.com:user:addr_gen:1.0\
xilinx.com:user:ethernet_debug:1.0\
xilinx.com:ip:lmb_v10:3.0\
xilinx.com:ip:lmb_bram_if_cntlr:4.0\
"

   set list_ips_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2011 -severity "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

   foreach ip_vlnv $list_check_ips {
      set ip_obj [get_ipdefs -all $ip_vlnv]
      if { $ip_obj eq "" } {
         lappend list_ips_missing $ip_vlnv
      }
   }

   if { $list_ips_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2012 -severity "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
      set bCheckIPsPassed 0
   }

}

if { $bCheckIPsPassed != 1 } {
  common::send_gid_msg -ssname BD::TCL -id 2023 -severity "WARNING" "Will not continue with creation of design due to the error(s) above."
  return 3
}

##################################################################
# DESIGN PROCs
##################################################################


# Hierarchical cell: microblaze_0_local_memory
proc create_hier_cell_microblaze_0_local_memory { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_microblaze_0_local_memory() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode MirroredMaster -vlnv xilinx.com:interface:lmb_rtl:1.0 DLMB

  create_bd_intf_pin -mode MirroredMaster -vlnv xilinx.com:interface:lmb_rtl:1.0 ILMB


  # Create pins
  create_bd_pin -dir I -type clk LMB_Clk
  create_bd_pin -dir I -type rst SYS_Rst

  # Create instance: dlmb_v10, and set properties
  set dlmb_v10 [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_v10:3.0 dlmb_v10 ]

  # Create instance: ilmb_v10, and set properties
  set ilmb_v10 [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_v10:3.0 ilmb_v10 ]

  # Create instance: dlmb_bram_if_cntlr, and set properties
  set dlmb_bram_if_cntlr [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_bram_if_cntlr:4.0 dlmb_bram_if_cntlr ]
  set_property CONFIG.C_ECC {0} $dlmb_bram_if_cntlr


  # Create instance: ilmb_bram_if_cntlr, and set properties
  set ilmb_bram_if_cntlr [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_bram_if_cntlr:4.0 ilmb_bram_if_cntlr ]
  set_property CONFIG.C_ECC {0} $ilmb_bram_if_cntlr


  # Create instance: lmb_bram, and set properties
  set lmb_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 lmb_bram ]
  set_property -dict [list \
    CONFIG.Memory_Type {True_Dual_Port_RAM} \
    CONFIG.use_bram_block {BRAM_Controller} \
  ] $lmb_bram


  # Create interface connections
  connect_bd_intf_net -intf_net microblaze_0_dlmb [get_bd_intf_pins dlmb_v10/LMB_M] [get_bd_intf_pins DLMB]
  connect_bd_intf_net -intf_net microblaze_0_dlmb_bus [get_bd_intf_pins dlmb_v10/LMB_Sl_0] [get_bd_intf_pins dlmb_bram_if_cntlr/SLMB]
  connect_bd_intf_net -intf_net microblaze_0_dlmb_cntlr [get_bd_intf_pins dlmb_bram_if_cntlr/BRAM_PORT] [get_bd_intf_pins lmb_bram/BRAM_PORTA]
  connect_bd_intf_net -intf_net microblaze_0_ilmb [get_bd_intf_pins ilmb_v10/LMB_M] [get_bd_intf_pins ILMB]
  connect_bd_intf_net -intf_net microblaze_0_ilmb_bus [get_bd_intf_pins ilmb_v10/LMB_Sl_0] [get_bd_intf_pins ilmb_bram_if_cntlr/SLMB]
  connect_bd_intf_net -intf_net microblaze_0_ilmb_cntlr [get_bd_intf_pins ilmb_bram_if_cntlr/BRAM_PORT] [get_bd_intf_pins lmb_bram/BRAM_PORTB]

  # Create port connections
  connect_bd_net -net SYS_Rst_1  [get_bd_pins SYS_Rst] \
  [get_bd_pins dlmb_v10/SYS_Rst] \
  [get_bd_pins dlmb_bram_if_cntlr/LMB_Rst] \
  [get_bd_pins ilmb_v10/SYS_Rst] \
  [get_bd_pins ilmb_bram_if_cntlr/LMB_Rst]
  connect_bd_net -net microblaze_0_Clk  [get_bd_pins LMB_Clk] \
  [get_bd_pins dlmb_v10/LMB_Clk] \
  [get_bd_pins dlmb_bram_if_cntlr/LMB_Clk] \
  [get_bd_pins ilmb_v10/LMB_Clk] \
  [get_bd_pins ilmb_bram_if_cntlr/LMB_Clk]

  # Restore current instance
  current_bd_instance $oldCurInst
}


# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder
  variable design_name

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports

  # Create ports
  set reset [ create_bd_port -dir I -type rst reset ]
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_LOW} \
 ] $reset
  set eth_rst_b [ create_bd_port -dir O eth_rst_b ]
  set eth_mdc [ create_bd_port -dir O eth_mdc ]
  set eth_mdio [ create_bd_port -dir IO eth_mdio ]
  set eth_txck [ create_bd_port -dir O eth_txck ]
  set eth_txctl [ create_bd_port -dir O eth_txctl ]
  set eth_txd [ create_bd_port -dir O -from 3 -to 0 eth_txd ]
  set o_mclk [ create_bd_port -dir O o_mclk ]
  set o_sync [ create_bd_port -dir O o_sync ]
  set o_sdi [ create_bd_port -dir O o_sdi ]
  set i_drl [ create_bd_port -dir I i_drl ]
  set i_busy [ create_bd_port -dir I i_busy ]
  set eth_int_b [ create_bd_port -dir I eth_int_b ]
  set eth_pme_b [ create_bd_port -dir I eth_pme_b ]
  set eth_rxck [ create_bd_port -dir I eth_rxck ]
  set eth_rxctl [ create_bd_port -dir I eth_rxctl ]
  set eth_rxd [ create_bd_port -dir I -from 3 -to 0 eth_rxd ]
  set btnc [ create_bd_port -dir I -type rst btnc ]
  set i_sdob [ create_bd_port -dir I i_sdob ]
  set o_rdlb [ create_bd_port -dir O o_rdlb ]
  set o_sckb [ create_bd_port -dir O o_sckb ]
  # NOTE (hand-patch): the Genesys2 differential SYSCLK is 200 MHz. Keep the
  # -freq_hz 200000000 on BOTH sys_diff_clock_clk_p/n below and
  # CONFIG.PRIM_IN_FREQ {200.000} on clk_wiz_1 — write_bd_tcl has dropped these
  # before (value_src != "user"). Without them the recreated MMCM is configured
  # for a 100 MHz input, validation still PASSES, and every clock on real
  # hardware runs at 2x.
  set sys_diff_clock_clk_n [ create_bd_port -dir I -type clk -freq_hz 200000000 sys_diff_clock_clk_n ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_RESET {rst_n_0} \
 ] $sys_diff_clock_clk_n
  set sys_diff_clock_clk_p [ create_bd_port -dir I -type clk -freq_hz 200000000 sys_diff_clock_clk_p ]
  set mux_0 [ create_bd_port -dir O -from 2 -to 0 mux_0 ]
  set mux_dac1 [ create_bd_port -dir O -from 2 -to 0 mux_dac1 ]
  set mux_dac2 [ create_bd_port -dir O -from 2 -to 0 mux_dac2 ]
  set EIT_IN_EN_0 [ create_bd_port -dir O EIT_IN_EN_0 ]
  set Electrode_Discharge [ create_bd_port -dir O Electrode_Discharge ]
  set dac_sclk_0 [ create_bd_port -dir O dac_sclk_0 ]
  set dac_sync_0 [ create_bd_port -dir O dac_sync_0 ]
  set dac_sdo_0 [ create_bd_port -dir O dac_sdo_0 ]
  set dac_ldac_0 [ create_bd_port -dir O dac_ldac_0 ]
  set gain_0 [ create_bd_port -dir O gain_0 ]
  set reset_0 [ create_bd_port -dir O -type rst reset_0 ]
  set sw0 [ create_bd_port -dir I sw0 ]
  set sw1 [ create_bd_port -dir I sw1 ]
  set sw2 [ create_bd_port -dir I sw2 ]
  set sw3 [ create_bd_port -dir I sw3 ]
  set sw4 [ create_bd_port -dir I sw4 ]
  set sw5 [ create_bd_port -dir I sw5 ]
  set sw6 [ create_bd_port -dir I sw6 ]
  set ja1 [ create_bd_port -dir O ja1 ]
  set ja2 [ create_bd_port -dir O ja2 ]
  set ja3 [ create_bd_port -dir O ja3 ]
  set ja4 [ create_bd_port -dir O ja4 ]
  set ja5 [ create_bd_port -dir O ja5 ]
  set ja6 [ create_bd_port -dir O ja6 ]
  set ja0 [ create_bd_port -dir O ja0 ]

  # Create instance: microblaze_0, and set properties
  set microblaze_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:microblaze:11.0 microblaze_0 ]
  set_property -dict [list \
    CONFIG.C_DEBUG_ENABLED {1} \
    CONFIG.C_D_AXI {1} \
    CONFIG.C_D_LMB {1} \
    CONFIG.C_ENABLE_CONVERSION {0} \
    CONFIG.C_I_LMB {1} \
  ] $microblaze_0


  # Create instance: UDP_0, and set properties
  set UDP_0 [ create_bd_cell -type ip -vlnv xilinx.com:user:UDP:5.3 UDP_0 ]

  # Create instance: microblaze_0_local_memory
  create_hier_cell_microblaze_0_local_memory [current_bd_instance .] microblaze_0_local_memory

  # Create instance: mdm_1, and set properties
  set mdm_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:mdm:3.2 mdm_1 ]

  # Create instance: clk_wiz_1, and set properties
  set clk_wiz_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 clk_wiz_1 ]
  # NOTE (hand-patch): CLK_OUT2/3_PORT, the CLKOUT*_REQUESTED_OUT_FREQ values and
  # PRIM_IN_FREQ must all survive every write_bd_tcl re-export — the export drops
  # parameters whose value_src isn't "user". Without them the clock pin names are
  # wrong (the BD nets connect to clk_100Mhz / clk_125MHz / clk_10MHz) and five
  # user-IP clocks are left unconnected, so validate_bd_design fails.
  set_property -dict [list \
    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {100.000} \
    CONFIG.CLKOUT2_JITTER {107.523} \
    CONFIG.CLKOUT2_PHASE_ERROR {89.971} \
    CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {125} \
    CONFIG.CLKOUT2_USED {true} \
    CONFIG.CLKOUT3_JITTER {178.053} \
    CONFIG.CLKOUT3_PHASE_ERROR {89.971} \
    CONFIG.CLKOUT3_REQUESTED_OUT_FREQ {10} \
    CONFIG.CLKOUT3_USED {true} \
    CONFIG.CLK_OUT1_PORT {clk_100Mhz} \
    CONFIG.CLK_OUT2_PORT {clk_125MHz} \
    CONFIG.CLK_OUT3_PORT {clk_10MHz} \
    CONFIG.MMCM_CLKOUT1_DIVIDE {8} \
    CONFIG.MMCM_CLKOUT2_DIVIDE {100} \
    CONFIG.NUM_OUT_CLKS {3} \
    CONFIG.PRIM_IN_FREQ {200.000} \
    CONFIG.PRIM_SOURCE {Differential_clock_capable_pin} \
    CONFIG.RESET_PORT {resetn} \
    CONFIG.RESET_TYPE {ACTIVE_LOW} \
  ] $clk_wiz_1


  # Create instance: rst_clk_wiz_1_100M, and set properties
  set rst_clk_wiz_1_100M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_clk_wiz_1_100M ]

  # Create instance: axi_smc, and set properties
  set axi_smc [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 axi_smc ]
  set_property -dict [list \
    CONFIG.NUM_MI {8} \
    CONFIG.NUM_SI {1} \
  ] $axi_smc


  # Create instance: dist_mem_gen_0, and set properties
  set dist_mem_gen_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:dist_mem_gen:8.0 dist_mem_gen_0 ]
  set_property -dict [list \
    CONFIG.data_width {8} \
    CONFIG.depth {8192} \
    CONFIG.memory_type {simple_dual_port_ram} \
  ] $dist_mem_gen_0


  # Create instance: ila_0, and set properties
  set ila_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:ila:6.2 ila_0 ]
  set_property -dict [list \
    CONFIG.C_DATA_DEPTH {16384} \
    CONFIG.C_MONITOR_TYPE {Native} \
    CONFIG.C_NUM_OF_PROBES {36} \
    CONFIG.C_PROBE11_WIDTH {4} \
    CONFIG.C_PROBE12_WIDTH {16} \
    CONFIG.C_PROBE13_WIDTH {16} \
    CONFIG.C_PROBE14_WIDTH {3} \
    CONFIG.C_PROBE15_WIDTH {3} \
    CONFIG.C_PROBE17_WIDTH {8} \
    CONFIG.C_PROBE18_WIDTH {2} \
    CONFIG.C_PROBE21_WIDTH {13} \
    CONFIG.C_PROBE31_WIDTH {3} \
    CONFIG.C_PROBE34_WIDTH {3} \
    CONFIG.C_PROBE3_WIDTH {8} \
    CONFIG.C_PROBE4_WIDTH {32} \
  ] $ila_0


  # Create instance: axi_gpio_0, and set properties
  set axi_gpio_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 axi_gpio_0 ]
  set_property -dict [list \
    CONFIG.C_ALL_INPUTS {1} \
    CONFIG.C_ALL_INPUTS_2 {0} \
    CONFIG.C_ALL_OUTPUTS_2 {1} \
    CONFIG.C_GPIO2_WIDTH {1} \
    CONFIG.C_GPIO_WIDTH {8} \
    CONFIG.C_IS_DUAL {1} \
    CONFIG.GPIO2_BOARD_INTERFACE {Custom} \
    CONFIG.GPIO_BOARD_INTERFACE {Custom} \
    CONFIG.USE_BOARD_FLOW {true} \
  ] $axi_gpio_0


  # Create instance: ltc_driver_fsm_0, and set properties
  set ltc_driver_fsm_0 [ create_bd_cell -type ip -vlnv xilinx.com:user:ltc_driver_fsm:1.1 ltc_driver_fsm_0 ]

  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0 ]

  # Create instance: blk_mem_gen_0, and set properties
  set blk_mem_gen_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 blk_mem_gen_0 ]
  set_property -dict [list \
    CONFIG.Coe_File [file normalize ${script_folder}/../coe/sine_64k_16bit.coe] \
    CONFIG.Load_Init_File {true} \
    CONFIG.Write_Depth_A {65536} \
    CONFIG.Write_Width_A {16} \
    CONFIG.use_bram_block {Stand_Alone} \
  ] $blk_mem_gen_0


  # Create instance: blk_mem_gen_1, and set properties
  set blk_mem_gen_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 blk_mem_gen_1 ]
  set_property -dict [list \
    CONFIG.Coe_File [file normalize ${script_folder}/../coe/sine_64k_16bit.coe] \
    CONFIG.Load_Init_File {true} \
    CONFIG.Write_Depth_A {65536} \
    CONFIG.Write_Width_A {16} \
    CONFIG.use_bram_block {Stand_Alone} \
  ] $blk_mem_gen_1


  # Create instance: blk_mem_gen_2, and set properties
  set blk_mem_gen_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 blk_mem_gen_2 ]
  set_property -dict [list \
    CONFIG.Coe_File [file normalize ${script_folder}/../coe/sine_64k_16bit.coe] \
    CONFIG.Load_Init_File {true} \
    CONFIG.Write_Depth_A {65536} \
    CONFIG.Write_Width_A {16} \
    CONFIG.use_bram_block {Stand_Alone} \
  ] $blk_mem_gen_2


  # Create instance: blk_mem_gen_3, and set properties
  set blk_mem_gen_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 blk_mem_gen_3 ]
  set_property -dict [list \
    CONFIG.Coe_File [file normalize ${script_folder}/../coe/sine_64k_16bit.coe] \
    CONFIG.Load_Init_File {true} \
    CONFIG.Write_Depth_A {65536} \
    CONFIG.Write_Width_A {16} \
    CONFIG.use_bram_block {Stand_Alone} \
  ] $blk_mem_gen_3


  # Create instance: IP_1_0, and set properties
  set IP_1_0 [ create_bd_cell -type ip -vlnv xilinx.com:user:IP_1:1.0 IP_1_0 ]

  # Create instance: IP_Three_0, and set properties
  set IP_Three_0 [ create_bd_cell -type ip -vlnv xilinx.com:user:IP_Three:1.0 IP_Three_0 ]

  # Create instance: IP_Two_0, and set properties
  set IP_Two_0 [ create_bd_cell -type ip -vlnv xilinx.com:user:IP_Two:1.0 IP_Two_0 ]

  # Create instance: FSM_0, and set properties
  set FSM_0 [ create_bd_cell -type ip -vlnv xilinx.com:user:FSM:1.0 FSM_0 ]

  # Create instance: addr_gen_0, and set properties
  set addr_gen_0 [ create_bd_cell -type ip -vlnv xilinx.com:user:addr_gen:1.0 addr_gen_0 ]

  # Create instance: ethernet_debug_0, and set properties
  set ethernet_debug_0 [ create_bd_cell -type ip -vlnv xilinx.com:user:ethernet_debug:1.0 ethernet_debug_0 ]

  # Create instance: xlconstant_1, and set properties
  set xlconstant_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_1 ]

  # Create instance: xlconstant_2, and set properties
  # Constant 0 (NOT the default 1) — ties off addr_gen_0/dds_sync, see IP_1_0_sync below.
  set xlconstant_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_2 ]
  set_property CONFIG.CONST_VAL {0} $xlconstant_2

  # Create interface connections
  connect_bd_intf_net -intf_net axi_smc_M00_AXI [get_bd_intf_pins axi_smc/M00_AXI] [get_bd_intf_pins UDP_0/S00_AXI]
  connect_bd_intf_net -intf_net axi_smc_M01_AXI [get_bd_intf_pins axi_smc/M01_AXI] [get_bd_intf_pins axi_gpio_0/S_AXI]
  connect_bd_intf_net -intf_net axi_smc_M02_AXI [get_bd_intf_pins axi_smc/M02_AXI] [get_bd_intf_pins addr_gen_0/S00_AXI]
  connect_bd_intf_net -intf_net axi_smc_M03_AXI [get_bd_intf_pins axi_smc/M03_AXI] [get_bd_intf_pins FSM_0/S00_AXI]
  connect_bd_intf_net -intf_net axi_smc_M04_AXI [get_bd_intf_pins axi_smc/M04_AXI] [get_bd_intf_pins IP_1_0/S00_AXI]
  connect_bd_intf_net -intf_net axi_smc_M05_AXI [get_bd_intf_pins axi_smc/M05_AXI] [get_bd_intf_pins IP_Three_0/S00_AXI]
  connect_bd_intf_net -intf_net axi_smc_M06_AXI [get_bd_intf_pins axi_smc/M06_AXI] [get_bd_intf_pins IP_Two_0/S00_AXI]
  connect_bd_intf_net -intf_net axi_smc_M07_AXI [get_bd_intf_pins axi_smc/M07_AXI] [get_bd_intf_pins ethernet_debug_0/S00_AXI]
  connect_bd_intf_net -intf_net microblaze_0_M_AXI_DP [get_bd_intf_pins microblaze_0/M_AXI_DP] [get_bd_intf_pins axi_smc/S00_AXI]
  connect_bd_intf_net -intf_net microblaze_0_debug [get_bd_intf_pins mdm_1/MBDEBUG_0] [get_bd_intf_pins microblaze_0/DEBUG]
  connect_bd_intf_net -intf_net microblaze_0_dlmb_1 [get_bd_intf_pins microblaze_0/DLMB] [get_bd_intf_pins microblaze_0_local_memory/DLMB]
  connect_bd_intf_net -intf_net microblaze_0_ilmb_1 [get_bd_intf_pins microblaze_0/ILMB] [get_bd_intf_pins microblaze_0_local_memory/ILMB]

  # Create port connections
  connect_bd_net -net FSM_0_clk_B  [get_bd_pins FSM_0/clk_B] \
  [get_bd_pins addr_gen_0/clk_B]
  connect_bd_net -net FSM_0_clk_C  [get_bd_pins FSM_0/clk_C] \
  [get_bd_pins addr_gen_0/clk_C] \
  [get_bd_pins IP_1_0/CLK_A] \
  [get_bd_pins ila_0/probe33]
  connect_bd_net -net FSM_0_clk_D  [get_bd_pins FSM_0/clk_D] \
  [get_bd_pins addr_gen_0/clk_D]
  connect_bd_net -net FSM_0_dac_ldac  [get_bd_pins FSM_0/dac_ldac] \
  [get_bd_ports dac_ldac_0] \
  [get_bd_pins ila_0/probe26]
  connect_bd_net -net FSM_0_dac_sclk  [get_bd_pins FSM_0/dac_sclk] \
  [get_bd_ports dac_sclk_0] \
  [get_bd_pins ila_0/probe23]
  connect_bd_net -net FSM_0_dac_sdo  [get_bd_pins FSM_0/dac_sdo] \
  [get_bd_ports dac_sdo_0] \
  [get_bd_pins ila_0/probe25]
  connect_bd_net -net FSM_0_dac_sync  [get_bd_pins FSM_0/dac_sync] \
  [get_bd_ports dac_sync_0] \
  [get_bd_pins ila_0/probe24]
  connect_bd_net -net IP_1_0_dac_ch_sel  [get_bd_pins IP_1_0/dac_ch_sel] \
  [get_bd_pins IP_Two_0/cha_cnt] \
  [get_bd_pins ethernet_debug_0/dac_ch] \
  [get_bd_pins ila_0/probe31]
  connect_bd_net -net IP_1_0_done_tick  [get_bd_pins IP_1_0/done_tick] \
  [get_bd_pins IP_Two_0/done_tick] \
  [get_bd_pins IP_Three_0/done_tick] \
  [get_bd_pins ila_0/probe27]
  connect_bd_net -net IP_1_0_enable  [get_bd_pins IP_1_0/enable] \
  [get_bd_ports EIT_IN_EN_0]
  connect_bd_net -net IP_1_0_o_addr_msb  [get_bd_pins IP_1_0/o_addr_msb] \
  [get_bd_pins ila_0/probe29]
  connect_bd_net -net IP_1_0_o_cycle_done  [get_bd_pins IP_1_0/o_cycle_done] \
  [get_bd_pins ila_0/probe28]
  # IP_1/sync marks channel-C sine wraps (50 kHz); kept as an ILA marker ONLY.
  # It must not drive addr_gen/dds_sync: dds_sync zeroes lut_addr_A..D for one
  # 100 MHz cycle, which glitched the A/B/D DAC waveforms (2000/2010/2000 Hz)
  # once per channel-C period while aligning no phase at all — the accumulator
  # resets it was meant to drive are commented out in addr_gen. dds_sync is now
  # tied low by xlconstant_2 below.
  connect_bd_net -net IP_1_0_sync  [get_bd_pins IP_1_0/sync] \
  [get_bd_pins ila_0/probe30]
  connect_bd_net -net IP_1_0_total_tick  [get_bd_pins IP_1_0/total_tick] \
  [get_bd_pins IP_Two_0/total_tick] \
  [get_bd_pins ila_0/probe32]
  connect_bd_net -net IP_Three_0_adc_ch  [get_bd_pins IP_Three_0/adc_ch] \
  [get_bd_pins ethernet_debug_0/adc_ch] \
  [get_bd_pins ila_0/probe34]
  connect_bd_net -net IP_Three_0_adc_start  [get_bd_pins IP_Three_0/adc_start] \
  [get_bd_pins ltc_driver_fsm_0/i_start]
  connect_bd_net -net IP_Three_0_enable  [get_bd_pins IP_Three_0/enable] \
  [get_bd_ports ja0]
  connect_bd_net -net IP_Three_0_mux  [get_bd_pins IP_Three_0/mux] \
  [get_bd_ports mux_0]
  connect_bd_net -net IP_Three_0_o_ja1  [get_bd_pins IP_Three_0/o_ja1] \
  [get_bd_ports ja1]
  connect_bd_net -net IP_Three_0_o_ja2  [get_bd_pins IP_Three_0/o_ja2] \
  [get_bd_ports ja2]
  connect_bd_net -net IP_Three_0_o_ja3  [get_bd_pins IP_Three_0/o_ja3] \
  [get_bd_ports ja3]
  connect_bd_net -net IP_Three_0_o_ja4  [get_bd_pins IP_Three_0/o_ja4] \
  [get_bd_ports ja4]
  connect_bd_net -net IP_Three_0_o_ja5  [get_bd_pins IP_Three_0/o_ja5] \
  [get_bd_ports ja5]
  connect_bd_net -net IP_Three_0_o_ja6  [get_bd_pins IP_Three_0/o_ja6] \
  [get_bd_ports ja6]
  connect_bd_net -net IP_Two_0_Electrode_Discharge  [get_bd_pins IP_Two_0/Electrode_Discharge] \
  [get_bd_ports Electrode_Discharge]
  connect_bd_net -net IP_Two_0_gain  [get_bd_pins IP_Two_0/gain] \
  [get_bd_ports gain_0]
  connect_bd_net -net IP_Two_0_mux1  [get_bd_pins IP_Two_0/mux1] \
  [get_bd_ports mux_dac1] \
  [get_bd_pins ila_0/probe14]
  connect_bd_net -net IP_Two_0_mux2  [get_bd_pins IP_Two_0/mux2] \
  [get_bd_ports mux_dac2] \
  [get_bd_pins ila_0/probe15]
  connect_bd_net -net IP_Two_0_reset  [get_bd_pins IP_Two_0/reset] \
  [get_bd_ports reset_0]
  connect_bd_net -net Net  [get_bd_ports eth_mdio] \
  [get_bd_pins UDP_0/eth_mdio]
  connect_bd_net -net Net1  [get_bd_pins FSM_0/clk_A] \
  [get_bd_pins addr_gen_0/clk_A]
  connect_bd_net -net UDP_0_addr  [get_bd_pins UDP_0/addr] \
  [get_bd_pins dist_mem_gen_0/a] \
  [get_bd_pins ila_0/probe21]
  connect_bd_net -net UDP_0_eth_mdc  [get_bd_pins UDP_0/eth_mdc] \
  [get_bd_ports eth_mdc]
  connect_bd_net -net UDP_0_eth_rst_b  [get_bd_pins UDP_0/eth_rst_b] \
  [get_bd_ports eth_rst_b]
  connect_bd_net -net UDP_0_eth_txck  [get_bd_pins UDP_0/eth_txck] \
  [get_bd_ports eth_txck]
  connect_bd_net -net UDP_0_eth_txd  [get_bd_pins UDP_0/eth_txd] \
  [get_bd_ports eth_txd]
  connect_bd_net -net UDP_0_read_addr  [get_bd_pins UDP_0/read_addr] \
  [get_bd_pins dist_mem_gen_0/dpra]
  connect_bd_net -net UDP_0_write_en  [get_bd_pins UDP_0/write_en] \
  [get_bd_pins dist_mem_gen_0/we] \
  [get_bd_pins ila_0/probe22]
  connect_bd_net -net addr_gen_0_lut_addr_A1  [get_bd_pins addr_gen_0/lut_addr_A] \
  [get_bd_pins blk_mem_gen_0/addra]
  connect_bd_net -net addr_gen_0_lut_addr_B  [get_bd_pins addr_gen_0/lut_addr_B] \
  [get_bd_pins blk_mem_gen_1/addra]
  connect_bd_net -net addr_gen_0_lut_addr_C  [get_bd_pins addr_gen_0/lut_addr_C] \
  [get_bd_pins blk_mem_gen_2/addra] \
  [get_bd_pins IP_1_0/address] \
  [get_bd_pins ila_0/probe12]
  connect_bd_net -net addr_gen_0_lut_addr_D  [get_bd_pins addr_gen_0/lut_addr_D] \
  [get_bd_pins blk_mem_gen_3/addra]
  connect_bd_net -net axi_gpio_0_gpio2_io_o  [get_bd_pins axi_gpio_0/gpio2_io_o] \
  [get_bd_pins IP_Three_0/run]
  connect_bd_net -net blk_mem_gen_0_douta  [get_bd_pins blk_mem_gen_0/douta] \
  [get_bd_pins ila_0/probe13] \
  [get_bd_pins FSM_0/sine_data_A]
  connect_bd_net -net blk_mem_gen_1_douta  [get_bd_pins blk_mem_gen_1/douta] \
  [get_bd_pins FSM_0/sine_data_B]
  connect_bd_net -net blk_mem_gen_2_douta  [get_bd_pins blk_mem_gen_2/douta] \
  [get_bd_pins FSM_0/sine_data_C]
  connect_bd_net -net blk_mem_gen_3_douta  [get_bd_pins blk_mem_gen_3/douta] \
  [get_bd_pins FSM_0/sine_data_D]
  connect_bd_net -net clk_in1_n_0_1  [get_bd_ports sys_diff_clock_clk_n] \
  [get_bd_pins clk_wiz_1/clk_in1_n]
  connect_bd_net -net clk_in1_p_0_1  [get_bd_ports sys_diff_clock_clk_p] \
  [get_bd_pins clk_wiz_1/clk_in1_p]
  # clk_10MHz output no longer used: IP_1/IP_Two/IP_Three/addr_gen clk moved to clk_100Mhz (below)
  connect_bd_net -net clk_wiz_1_clk_125MHz  [get_bd_pins clk_wiz_1/clk_125MHz] \
  [get_bd_pins UDP_0/clk_125MHz] \
  [get_bd_pins dist_mem_gen_0/clk]
  connect_bd_net -net clk_wiz_1_clk_400MHz  [get_bd_pins clk_wiz_1/clk_100Mhz] \
  [get_bd_pins microblaze_0/Clk] \
  [get_bd_pins axi_smc/aclk] \
  [get_bd_pins microblaze_0_local_memory/LMB_Clk] \
  [get_bd_pins UDP_0/s00_axi_aclk] \
  [get_bd_pins UDP_0/clk100MHz] \
  [get_bd_pins ila_0/clk] \
  [get_bd_pins axi_gpio_0/s_axi_aclk] \
  [get_bd_pins rst_clk_wiz_1_100M/slowest_sync_clk] \
  [get_bd_pins ltc_driver_fsm_0/i_clk] \
  [get_bd_pins blk_mem_gen_0/clka] \
  [get_bd_pins blk_mem_gen_1/clka] \
  [get_bd_pins blk_mem_gen_2/clka] \
  [get_bd_pins blk_mem_gen_3/clka] \
  [get_bd_pins addr_gen_0/s00_axi_aclk] \
  [get_bd_pins FSM_0/s00_axi_aclk] \
  [get_bd_pins FSM_0/clk] \
  [get_bd_pins IP_1_0/clk] \
  [get_bd_pins IP_Three_0/clk] \
  [get_bd_pins IP_Two_0/clk] \
  [get_bd_pins addr_gen_0/clk] \
  [get_bd_pins IP_1_0/s00_axi_aclk] \
  [get_bd_pins IP_Three_0/s00_axi_aclk] \
  [get_bd_pins IP_Two_0/s00_axi_aclk] \
  [get_bd_pins ethernet_debug_0/global_clk] \
  [get_bd_pins ethernet_debug_0/s00_axi_aclk] \
  [get_bd_pins UDP_0/clk_lock]
  connect_bd_net -net clk_wiz_1_locked  [get_bd_pins clk_wiz_1/locked] \
  [get_bd_pins rst_clk_wiz_1_100M/dcm_locked]
  connect_bd_net -net dist_mem_gen_0_dpo  [get_bd_pins dist_mem_gen_0/dpo] \
  [get_bd_pins UDP_0/mem_out]
  connect_bd_net -net eth_int_b_0_1  [get_bd_ports eth_int_b] \
  [get_bd_pins UDP_0/eth_int_b]
  connect_bd_net -net eth_pme_b  [get_bd_ports eth_pme_b] \
  [get_bd_pins UDP_0/eth_pme_b]
  connect_bd_net -net eth_rxck_0_1  [get_bd_ports eth_rxck] \
  [get_bd_pins UDP_0/eth_rxck]
  connect_bd_net -net eth_rxctl_0_1  [get_bd_ports eth_rxctl] \
  [get_bd_pins UDP_0/eth_rxctl]
  connect_bd_net -net eth_rxd_0_1  [get_bd_ports eth_rxd] \
  [get_bd_pins UDP_0/eth_rxd]
  connect_bd_net -net eth_txctl  [get_bd_pins UDP_0/eth_txctl] \
  [get_bd_ports eth_txctl]
  connect_bd_net -net ethernet_debug_0_clk_trg  [get_bd_pins ethernet_debug_0/clk_trg] \
  [get_bd_pins ila_0/probe16] \
  [get_bd_pins UDP_0/clk_trg]
  connect_bd_net -net ethernet_debug_0_data_out  [get_bd_pins ethernet_debug_0/data_out] \
  [get_bd_pins ila_0/probe17] \
  [get_bd_pins dist_mem_gen_0/d]
  connect_bd_net -net ethernet_debug_0_dbg_current_state  [get_bd_pins ethernet_debug_0/dbg_current_state] \
  [get_bd_pins ila_0/probe20]
  connect_bd_net -net ethernet_debug_0_dbg_rx_byte_cnt  [get_bd_pins ethernet_debug_0/dbg_rx_byte_cnt] \
  [get_bd_pins ila_0/probe18]
  connect_bd_net -net ethernet_debug_0_dbg_tx_start_en  [get_bd_pins ethernet_debug_0/dbg_tx_start_en] \
  [get_bd_pins ila_0/probe19]
  connect_bd_net -net i_busy_1  [get_bd_ports i_busy] \
  [get_bd_pins ila_0/probe8] \
  [get_bd_pins ltc_driver_fsm_0/i_busy]
  connect_bd_net -net i_drl_1  [get_bd_ports i_drl] \
  [get_bd_pins ila_0/probe9] \
  [get_bd_pins ltc_driver_fsm_0/i_drl]
  connect_bd_net -net i_sdoa_1  [get_bd_ports i_sdob] \
  [get_bd_pins ila_0/probe10] \
  [get_bd_pins ltc_driver_fsm_0/i_sdob]
  connect_bd_net -net ltc_driver_eth_0_o_eth_data  [get_bd_pins ltc_driver_fsm_0/o_eth_data] \
  [get_bd_pins ila_0/probe3] \
  [get_bd_pins ethernet_debug_0/o_eth_data]
  connect_bd_net -net ltc_driver_eth_0_o_eth_valid  [get_bd_pins ltc_driver_fsm_0/o_eth_valid] \
  [get_bd_pins ila_0/probe2] \
  [get_bd_pins ethernet_debug_0/o_eth_valid]
  connect_bd_net -net ltc_driver_fsm_0_o_data_valid  [get_bd_pins ltc_driver_fsm_0/o_data_valid] \
  [get_bd_pins ila_0/probe1]
  connect_bd_net -net ltc_driver_fsm_0_o_debug_state  [get_bd_pins ltc_driver_fsm_0/o_debug_state] \
  [get_bd_pins ila_0/probe11]
  connect_bd_net -net ltc_driver_fsm_0_o_error  [get_bd_pins ltc_driver_fsm_0/o_error] \
  [get_bd_pins ila_0/probe0]
  # NOTE (hand-patch): ethernet_debug_0/mclk marks the sample instant.
  # IP_Three's cha_cnt increments on this strobe's falling edge, so by the time
  # a 32-bit result reaches ethernet_debug, adc_ch already points at the next
  # channel. ethernet_debug latches the header channel byte on this strobe's
  # RISING edge instead, and emits it with the matching data word.
  # Regression test: sim/tb_eth_ch_tag.v
  connect_bd_net -net ltc_driver_fsm_0_o_mclk  [get_bd_pins ltc_driver_fsm_0/o_mclk] \
  [get_bd_ports o_mclk] \
  [get_bd_pins ila_0/probe5] \
  [get_bd_pins IP_Three_0/master_clk] \
  [get_bd_pins ethernet_debug_0/mclk]
  connect_bd_net -net ltc_driver_fsm_0_o_read_data  [get_bd_pins ltc_driver_fsm_0/o_read_data] \
  [get_bd_pins ila_0/probe4]
  connect_bd_net -net ltc_driver_fsm_0_o_scka  [get_bd_pins ltc_driver_fsm_0/o_sckb] \
  [get_bd_pins ila_0/probe6] \
  [get_bd_ports o_sckb]
  connect_bd_net -net ltc_driver_fsm_0_o_sdi  [get_bd_pins ltc_driver_fsm_0/o_sdi] \
  [get_bd_ports o_sdi]
  connect_bd_net -net ltc_driver_fsm_0_o_sync  [get_bd_pins ltc_driver_fsm_0/o_sync] \
  [get_bd_ports o_sync]
  connect_bd_net -net ltc_driver_fsm_1_o_rdlb  [get_bd_pins ltc_driver_fsm_0/o_rdlb] \
  [get_bd_pins ila_0/probe7] \
  [get_bd_ports o_rdlb]
  connect_bd_net -net mdm_1_debug_sys_rst  [get_bd_pins mdm_1/Debug_SYS_Rst] \
  [get_bd_pins rst_clk_wiz_1_100M/mb_debug_sys_rst]
  connect_bd_net -net reset_0_1  [get_bd_ports btnc] \
  [get_bd_pins UDP_0/reset] \
  [get_bd_pins ila_0/probe35]
  connect_bd_net -net reset_1  [get_bd_ports reset] \
  [get_bd_pins rst_clk_wiz_1_100M/ext_reset_in] \
  [get_bd_pins clk_wiz_1/resetn]
  connect_bd_net -net rst_clk_wiz_1_100M_bus_struct_reset  [get_bd_pins rst_clk_wiz_1_100M/bus_struct_reset] \
  [get_bd_pins microblaze_0_local_memory/SYS_Rst]
  connect_bd_net -net rst_clk_wiz_1_100M_mb_reset  [get_bd_pins rst_clk_wiz_1_100M/mb_reset] \
  [get_bd_pins microblaze_0/Reset]
  connect_bd_net -net rst_clk_wiz_1_100M_peripheral_aresetn  [get_bd_pins rst_clk_wiz_1_100M/peripheral_aresetn] \
  [get_bd_pins axi_smc/aresetn] \
  [get_bd_pins UDP_0/s00_axi_aresetn] \
  [get_bd_pins axi_gpio_0/s_axi_aresetn] \
  [get_bd_pins ltc_driver_fsm_0/i_rst_n] \
  [get_bd_pins addr_gen_0/s00_axi_aresetn] \
  [get_bd_pins FSM_0/s00_axi_aresetn] \
  [get_bd_pins IP_1_0/s00_axi_aresetn] \
  [get_bd_pins IP_Three_0/s00_axi_aresetn] \
  [get_bd_pins IP_Two_0/s00_axi_aresetn] \
  [get_bd_pins ethernet_debug_0/s00_axi_aresetn]
  connect_bd_net -net sw0_1  [get_bd_ports sw0] \
  [get_bd_pins IP_Three_0/sw_ch0]
  connect_bd_net -net sw1_1  [get_bd_ports sw1] \
  [get_bd_pins IP_Three_0/sw_ch1]
  connect_bd_net -net sw2_1  [get_bd_ports sw2] \
  [get_bd_pins IP_Three_0/sw_ch2]
  # Master reset for all user IPs, on slide switch SW3 (K19). ACTIVE LOW:
  # SW3 = 1 -> run, SW3 = 0 -> hold every user IP in reset. The board does
  # nothing with SW3 down. This replaced btnc, which is ACTIVE HIGH (idle 0) and
  # therefore held IP_1/IP_Two/IP_Three in reset unless the button was pressed.
  # btnc now only drives UDP_0/reset (active high) and ila_0/probe35.
  connect_bd_net -net sw3_rst_n  [get_bd_ports sw3] \
  [get_bd_pins IP_1_0/rst_n] \
  [get_bd_pins IP_Two_0/rst_n] \
  [get_bd_pins IP_Three_0/rst_n] \
  [get_bd_pins addr_gen_0/rst_n] \
  [get_bd_pins FSM_0/rst_n] \
  [get_bd_pins ethernet_debug_0/rst_n]
  connect_bd_net -net xlconstant_0_dout  [get_bd_pins xlconstant_0/dout] \
  [get_bd_pins blk_mem_gen_0/ena] \
  [get_bd_pins blk_mem_gen_1/ena] \
  [get_bd_pins blk_mem_gen_2/ena] \
  [get_bd_pins blk_mem_gen_3/ena]
  connect_bd_net -net xlconstant_1_dout  [get_bd_pins xlconstant_1/dout] \
  [get_bd_pins addr_gen_0/Update_Tick] \
  [get_bd_pins FSM_0/update_tick]
  connect_bd_net -net xlconstant_2_dout  [get_bd_pins xlconstant_2/dout] \
  [get_bd_pins addr_gen_0/dds_sync]

  # Create address segments
  assign_bd_address -offset 0x44A20000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs FSM_0/S00_AXI/S00_AXI_reg] -force
  assign_bd_address -offset 0x44A30000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs IP_1_0/S00_AXI/S00_AXI_reg] -force
  assign_bd_address -offset 0x44A40000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs IP_Three_0/S00_AXI/S00_AXI_reg] -force
  assign_bd_address -offset 0x44A50000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs IP_Two_0/S00_AXI/S00_AXI_reg] -force
  assign_bd_address -offset 0x44A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs UDP_0/S00_AXI/S00_AXI_reg] -force
  assign_bd_address -offset 0x44A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs addr_gen_0/S00_AXI/S00_AXI_reg] -force
  assign_bd_address -offset 0x40000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x00004000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs microblaze_0_local_memory/dlmb_bram_if_cntlr/SLMB/Mem] -force
  assign_bd_address -offset 0x44A60000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs ethernet_debug_0/S00_AXI/S00_AXI_reg] -force
  assign_bd_address -offset 0x00000000 -range 0x00004000 -target_address_space [get_bd_addr_spaces microblaze_0/Instruction] [get_bd_addr_segs microblaze_0_local_memory/ilmb_bram_if_cntlr/SLMB/Mem] -force

  # Perform GUI Layout
  regenerate_bd_layout -layout_string {
   "ActiveEmotionalView":"Default View",
   "Default View_ScaleFactor":"0.717935",
   "Default View_TopLeft":"1102,4",
   "ExpandedHierarchyInLayout":"",
   "guistr":"# # String gsaved with Nlview 7.8.0 2024-04-26 e1825d835c VDI=44 GEI=38 GUI=JA:21.0
#  -string -flagsOSRD
preplace port port-id_reset -pg 1 -lvl 0 -x -10 -y 2180 -defaultsOSRD
preplace port port-id_eth_rst_b -pg 1 -lvl 7 -x 2720 -y 80 -defaultsOSRD
preplace port port-id_eth_mdc -pg 1 -lvl 7 -x 2720 -y 100 -defaultsOSRD
preplace port port-id_eth_mdio -pg 1 -lvl 7 -x 2720 -y 120 -defaultsOSRD
preplace port port-id_eth_txck -pg 1 -lvl 7 -x 2720 -y 140 -defaultsOSRD
preplace port port-id_eth_txctl -pg 1 -lvl 7 -x 2720 -y 160 -defaultsOSRD
preplace port port-id_o_mclk -pg 1 -lvl 7 -x 2720 -y 1870 -defaultsOSRD
preplace port port-id_o_sync -pg 1 -lvl 7 -x 2720 -y 2080 -defaultsOSRD
preplace port port-id_o_sdi -pg 1 -lvl 7 -x 2720 -y 2320 -defaultsOSRD
preplace port port-id_i_drl -pg 1 -lvl 0 -x -10 -y 2040 -defaultsOSRD
preplace port port-id_i_busy -pg 1 -lvl 0 -x -10 -y 2020 -defaultsOSRD
preplace port port-id_eth_int_b -pg 1 -lvl 0 -x -10 -y 90 -defaultsOSRD
preplace port port-id_eth_pme_b -pg 1 -lvl 0 -x -10 -y 110 -defaultsOSRD
preplace port port-id_eth_rxck -pg 1 -lvl 0 -x -10 -y 130 -defaultsOSRD
preplace port port-id_eth_rxctl -pg 1 -lvl 0 -x -10 -y 150 -defaultsOSRD
preplace port port-id_btnc -pg 1 -lvl 0 -x -10 -y 1620 -defaultsOSRD
preplace port port-id_i_sdob -pg 1 -lvl 0 -x -10 -y 2060 -defaultsOSRD
preplace port port-id_o_rdlb -pg 1 -lvl 7 -x 2720 -y 1830 -defaultsOSRD
preplace port port-id_o_sckb -pg 1 -lvl 7 -x 2720 -y 1850 -defaultsOSRD
preplace port port-id_sys_diff_clock_clk_n -pg 1 -lvl 0 -x -10 -y 2140 -defaultsOSRD
preplace port port-id_sys_diff_clock_clk_p -pg 1 -lvl 0 -x -10 -y 2160 -defaultsOSRD
preplace port port-id_EIT_IN_EN_0 -pg 1 -lvl 7 -x 2720 -y 1200 -defaultsOSRD
preplace port port-id_dac_sclk_0 -pg 1 -lvl 7 -x 2720 -y 850 -defaultsOSRD
preplace port port-id_dac_sync_0 -pg 1 -lvl 7 -x 2720 -y 870 -defaultsOSRD
preplace port port-id_dac_sdo_0 -pg 1 -lvl 7 -x 2720 -y 890 -defaultsOSRD
preplace port port-id_dac_ldac_0 -pg 1 -lvl 7 -x 2720 -y 910 -defaultsOSRD
preplace port port-id_gain_0 -pg 1 -lvl 7 -x 2720 -y 1950 -defaultsOSRD
preplace port port-id_reset_0 -pg 1 -lvl 7 -x 2720 -y 1970 -defaultsOSRD
preplace port port-id_sw0 -pg 1 -lvl 0 -x -10 -y 2480 -defaultsOSRD
preplace port port-id_sw1 -pg 1 -lvl 0 -x -10 -y 2500 -defaultsOSRD
preplace port port-id_sw2 -pg 1 -lvl 0 -x -10 -y 2520 -defaultsOSRD
preplace port port-id_sw3 -pg 1 -lvl 0 -x -10 -y 1350 -defaultsOSRD
preplace port port-id_sw4 -pg 1 -lvl 0 -x -10 -y 40 -defaultsOSRD
preplace port port-id_sw5 -pg 1 -lvl 0 -x -10 -y 60 -defaultsOSRD
preplace port port-id_sw6 -pg 1 -lvl 0 -x -10 -y 190 -defaultsOSRD
preplace port port-id_ja1 -pg 1 -lvl 7 -x 2720 -y 2470 -defaultsOSRD
preplace port port-id_ja2 -pg 1 -lvl 7 -x 2720 -y 2490 -defaultsOSRD
preplace port port-id_ja3 -pg 1 -lvl 7 -x 2720 -y 2510 -defaultsOSRD
preplace port port-id_ja4 -pg 1 -lvl 7 -x 2720 -y 2530 -defaultsOSRD
preplace port port-id_ja5 -pg 1 -lvl 7 -x 2720 -y 2550 -defaultsOSRD
preplace port port-id_ja6 -pg 1 -lvl 7 -x 2720 -y 2570 -defaultsOSRD
preplace port port-id_ja0 -pg 1 -lvl 7 -x 2720 -y 2420 -defaultsOSRD
preplace portBus eth_txd -pg 1 -lvl 7 -x 2720 -y 180 -defaultsOSRD
preplace portBus eth_rxd -pg 1 -lvl 0 -x -10 -y 170 -defaultsOSRD
preplace portBus mux_0 -pg 1 -lvl 7 -x 2720 -y 2390 -defaultsOSRD
preplace portBus mux_dac1 -pg 1 -lvl 7 -x 2720 -y 1890 -defaultsOSRD
preplace portBus mux_dac2 -pg 1 -lvl 7 -x 2720 -y 1910 -defaultsOSRD
preplace inst microblaze_0 -pg 1 -lvl 3 -x 910 -y 2350 -defaultsOSRD
preplace inst UDP_0 -pg 1 -lvl 5 -x 1960 -y 170 -defaultsOSRD
preplace inst microblaze_0_local_memory -pg 1 -lvl 4 -x 1400 -y 2360 -defaultsOSRD
preplace inst mdm_1 -pg 1 -lvl 2 -x 470 -y 2350 -defaultsOSRD
preplace inst clk_wiz_1 -pg 1 -lvl 1 -x 140 -y 2150 -defaultsOSRD
preplace inst rst_clk_wiz_1_100M -pg 1 -lvl 2 -x 470 -y 2180 -defaultsOSRD
preplace inst axi_smc -pg 1 -lvl 4 -x 1400 -y 1490 -defaultsOSRD
preplace inst dist_mem_gen_0 -pg 1 -lvl 4 -x 1400 -y 270 -defaultsOSRD
preplace inst ila_0 -pg 1 -lvl 6 -x 2540 -y 1540 -defaultsOSRD
preplace inst axi_gpio_0 -pg 1 -lvl 5 -x 1960 -y 2230 -defaultsOSRD
preplace inst ltc_driver_fsm_0 -pg 1 -lvl 4 -x 1400 -y 2100 -defaultsOSRD
preplace inst xlconstant_0 -pg 1 -lvl 5 -x 1960 -y 1140 -defaultsOSRD
preplace inst blk_mem_gen_0 -pg 1 -lvl 6 -x 2540 -y 1040 -defaultsOSRD
preplace inst blk_mem_gen_1 -pg 1 -lvl 6 -x 2540 -y 390 -defaultsOSRD
preplace inst blk_mem_gen_2 -pg 1 -lvl 6 -x 2540 -y 570 -defaultsOSRD
preplace inst blk_mem_gen_3 -pg 1 -lvl 6 -x 2540 -y 750 -defaultsOSRD
preplace inst IP_1_0 -pg 1 -lvl 5 -x 1960 -y 1340 -defaultsOSRD
preplace inst IP_Three_0 -pg 1 -lvl 5 -x 1960 -y 2500 -defaultsOSRD
preplace inst IP_Two_0 -pg 1 -lvl 5 -x 1960 -y 1910 -defaultsOSRD
preplace inst FSM_0 -pg 1 -lvl 5 -x 1960 -y 560 -defaultsOSRD
preplace inst addr_gen_0 -pg 1 -lvl 5 -x 1960 -y 920 -defaultsOSRD
preplace inst ethernet_debug_0 -pg 1 -lvl 5 -x 1960 -y 1640 -defaultsOSRD
preplace inst xlconstant_1 -pg 1 -lvl 4 -x 1400 -y 510 -defaultsOSRD
preplace inst xlconstant_2 -pg 1 -lvl 4 -x 1400 -y 610 -defaultsOSRD
preplace netloc FSM_0_clk_B 1 4 2 1740 380 2140
preplace netloc FSM_0_clk_C 1 4 2 1800 750 2110
preplace netloc FSM_0_clk_D 1 4 2 1810 710 2130
preplace netloc FSM_0_dac_ldac 1 5 2 2180 910 NJ
preplace netloc FSM_0_dac_sclk 1 5 2 2370 850 NJ
preplace netloc FSM_0_dac_sdo 1 5 2 2310 890 NJ
preplace netloc FSM_0_dac_sync 1 5 2 2340 870 NJ
preplace netloc IP_1_0_dac_ch_sel 1 4 2 1810 1780 2210
preplace netloc IP_1_0_done_tick 1 4 2 1770 2120 2190
preplace netloc IP_1_0_enable 1 5 2 2210J 940 2640J
preplace netloc IP_1_0_o_addr_msb 1 5 1 2220 1410n
preplace netloc IP_1_0_o_cycle_done 1 5 1 2230 1390n
preplace netloc IP_1_0_sync 1 4 2 1750 1470 2240
preplace netloc IP_1_0_total_tick 1 4 2 1800 2040 2160
preplace netloc IP_Three_0_adc_ch 1 4 2 1780 2130 2430
preplace netloc IP_Three_0_adc_start 1 3 3 1260 2670 NJ 2670 2110
preplace netloc IP_Three_0_enable 1 5 2 2440 2420 NJ
preplace netloc IP_Three_0_mux 1 5 2 NJ 2390 NJ
preplace netloc IP_Three_0_o_ja1 1 5 2 NJ 2470 NJ
preplace netloc IP_Three_0_o_ja2 1 5 2 NJ 2490 NJ
preplace netloc IP_Three_0_o_ja3 1 5 2 NJ 2510 NJ
preplace netloc IP_Three_0_o_ja4 1 5 2 NJ 2530 NJ
preplace netloc IP_Three_0_o_ja5 1 5 2 NJ 2550 NJ
preplace netloc IP_Three_0_o_ja6 1 5 2 NJ 2570 NJ
preplace netloc IP_Two_0_gain 1 5 2 2180J 1990 2690J
preplace netloc IP_Two_0_mux1 1 5 2 2410 1960 2640J
preplace netloc IP_Two_0_mux2 1 5 2 2420 1970 2650J
preplace netloc IP_Two_0_reset 1 5 2 2170J 1980 2700J
preplace netloc Net 1 5 2 NJ 110 2640J
preplace netloc Net1 1 4 2 1780 410 2110
preplace netloc UDP_0_addr 1 3 3 1250 -30 NJ -30 2400
preplace netloc UDP_0_eth_mdc 1 5 2 2440J 100 NJ
preplace netloc UDP_0_eth_rst_b 1 5 2 NJ 70 2640J
preplace netloc UDP_0_eth_txck 1 5 2 NJ 130 2640J
preplace netloc UDP_0_eth_txd 1 5 2 NJ 170 2640J
preplace netloc UDP_0_read_addr 1 3 3 1260 -20 NJ -20 2110
preplace netloc UDP_0_write_en 1 3 3 1260 370 NJ 370 2150
preplace netloc addr_gen_0_lut_addr_A1 1 5 1 2130 890n
preplace netloc addr_gen_0_lut_addr_B 1 5 1 2160 370n
preplace netloc addr_gen_0_lut_addr_C 1 4 2 1790 2050 2250
preplace netloc addr_gen_0_lut_addr_D 1 5 1 2190 730n
preplace netloc axi_gpio_0_gpio2_io_o 1 4 2 1750 2320 2110
preplace netloc blk_mem_gen_0_douta 1 4 2 1800 720 2330
preplace netloc blk_mem_gen_1_douta 1 4 2 1760 390 2430J
preplace netloc blk_mem_gen_2_douta 1 4 2 1770 400 2420J
preplace netloc blk_mem_gen_3_douta 1 4 2 1790 730 2130J
preplace netloc clk_in1_n_0_1 1 0 1 NJ 2140
preplace netloc clk_in1_p_0_1 1 0 1 NJ 2160
preplace netloc clk_wiz_1_clk_125MHz 1 1 4 270J 1350 NJ 1350 1240 170 1730J
preplace netloc clk_wiz_1_clk_400MHz 1 1 5 300 2080 670 2230 1250 1630 1640 740 2440
preplace netloc clk_wiz_1_locked 1 1 1 260 2180n
preplace netloc dist_mem_gen_0_dpo 1 4 1 1560 220n
preplace netloc eth_int_b_0_1 1 0 5 10J 80 NJ 80 NJ 80 NJ 80 NJ
preplace netloc eth_pme_b 1 0 5 10J 100 NJ 100 NJ 100 NJ 100 NJ
preplace netloc eth_rxck_0_1 1 0 5 10J 120 NJ 120 NJ 120 NJ 120 NJ
preplace netloc eth_rxctl_0_1 1 0 5 10J 140 NJ 140 NJ 140 NJ 140 NJ
preplace netloc eth_rxd_0_1 1 0 5 NJ 170 NJ 170 NJ 170 1190J 160 NJ
preplace netloc eth_txctl 1 5 2 NJ 150 2640J
preplace netloc ethernet_debug_0_clk_trg 1 4 2 1730 1480 2140
preplace netloc ethernet_debug_0_data_out 1 3 3 1250 1350 1700J 1490 2130
preplace netloc ethernet_debug_0_dbg_current_state 1 5 1 2330 1600n
preplace netloc ethernet_debug_0_dbg_rx_byte_cnt 1 5 1 2120 1560n
preplace netloc ethernet_debug_0_dbg_tx_start_en 1 5 1 2300 1580n
preplace netloc i_busy_1 1 0 6 NJ 2020 NJ 2020 NJ 2020 1210 2440 1710J 2150 2350
preplace netloc i_drl_1 1 0 6 NJ 2040 NJ 2040 NJ 2040 1200 2450 1740J 2330 2380
preplace netloc i_sdoa_1 1 0 6 NJ 2060 NJ 2060 NJ 2060 1220 2270 1540J 2310 2390
preplace netloc ltc_driver_eth_0_o_eth_data 1 4 2 1700 2100 2260
preplace netloc ltc_driver_eth_0_o_eth_valid 1 4 2 1650 760 2320
preplace netloc ltc_driver_fsm_0_o_data_valid 1 4 2 1690J 1080 2130
preplace netloc ltc_driver_fsm_0_o_debug_state 1 4 2 NJ 2110 2360
preplace netloc ltc_driver_fsm_0_o_error 1 4 2 1550J 1200 N
preplace netloc ltc_driver_fsm_0_o_mclk 1 4 3 1590 2140 2290 2000 2680J
preplace netloc ltc_driver_fsm_0_o_read_data 1 4 2 1680J 1210 2270
preplace netloc ltc_driver_fsm_0_o_scka 1 4 3 NJ 2070 2270 2010 2670J
preplace netloc ltc_driver_fsm_0_o_sdi 1 4 3 1600J 2060 NJ 2060 2640J
preplace netloc ltc_driver_fsm_0_o_sync 1 4 3 1610J 2080 NJ 2080 NJ
preplace netloc ltc_driver_fsm_1_o_rdlb 1 4 3 NJ 2090 2280 2020 2660J
preplace netloc mdm_1_debug_sys_rst 1 1 2 300 2280 640
preplace netloc reset_0_1 1 0 6 NJ 1620 NJ 1620 NJ 1620 NJ 1620 1600 1500 2200
preplace netloc reset_1 1 0 2 20 2240 270
preplace netloc rst_clk_wiz_1_100M_bus_struct_reset 1 2 2 660J 2240 1150J
preplace netloc rst_clk_wiz_1_100M_mb_reset 1 2 1 650 2140n
preplace netloc rst_clk_wiz_1_100M_peripheral_aresetn 1 2 3 NJ 2220 1240 1640 1670
preplace netloc sw0_1 1 0 5 NJ 2480 NJ 2480 NJ 2480 NJ 2480 NJ
preplace netloc sw1_1 1 0 5 NJ 2500 NJ 2500 NJ 2500 NJ 2500 NJ
preplace netloc sw2_1 1 0 5 NJ 2520 NJ 2520 NJ 2520 NJ 2520 NJ
preplace netloc xlconstant_0_dout 1 5 1 2170 430n
preplace netloc xlconstant_1_dout 1 4 1 1690 510n
preplace netloc xlconstant_2_dout 1 4 1 1700 610n
preplace netloc sw3_rst_n 1 0 5 N 1350 260 1360 N 1360 N 1360 1720
preplace netloc axi_smc_M00_AXI 1 4 1 1540 40n
preplace netloc axi_smc_M01_AXI 1 4 1 1630 1440n
preplace netloc axi_smc_M02_AXI 1 4 1 1620 820n
preplace netloc axi_smc_M03_AXI 1 4 1 1610 470n
preplace netloc axi_smc_M04_AXI 1 4 1 1560 1280n
preplace netloc axi_smc_M05_AXI 1 4 1 1620 1520n
preplace netloc axi_smc_M06_AXI 1 4 1 1660 1540n
preplace netloc axi_smc_M07_AXI 1 4 1 N 1560
preplace netloc microblaze_0_M_AXI_DP 1 3 1 1230 1470n
preplace netloc microblaze_0_debug 1 2 1 N 2340
preplace netloc microblaze_0_dlmb_1 1 3 1 N 2330
preplace netloc microblaze_0_ilmb_1 1 3 1 N 2350
levelinfo -pg 1 -10 140 470 910 1400 1960 2540 2720
pagesize -pg 1 -db -bbox -sgen -200 -60 2870 2680
"
}

  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################


# NOTE: Exported from TIS_EIT_V0 (ltc2500_top) with write_bd_tcl on 2026-07-18.
# The V0 project reported its user IPs as locked because its IP repo paths were
# stale; all user-IP VLNVs below are provided by ../ip_repo in this repository.
# Coe_File paths were re-pointed to ../coe/ (relative to this script).

create_root_design ""


