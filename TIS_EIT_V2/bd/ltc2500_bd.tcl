
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
  # NOTE: FREQ_HZ restored by hand — the Genesys2 differential SYSCLK is 200 MHz
  # (write_bd_tcl dropped it; without it the ports default to 100 MHz and the
  # recreated clk_wiz MMCM is configured for the wrong input frequency).
  set sys_diff_clock_clk_n [ create_bd_port -dir I -type clk sys_diff_clock_clk_n ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_RESET {rst_n_0} \
   CONFIG.FREQ_HZ {200000000} \
 ] $sys_diff_clock_clk_n
  set sys_diff_clock_clk_p [ create_bd_port -dir I -type clk sys_diff_clock_clk_p ]
  set_property CONFIG.FREQ_HZ {200000000} $sys_diff_clock_clk_p
  set mux_0 [ create_bd_port -dir O -from 2 -to 0 mux_0 ]
  set mux_dac1 [ create_bd_port -dir O -from 2 -to 0 mux_dac1 ]
  set mux_dac2 [ create_bd_port -dir O -from 2 -to 0 mux_dac2 ]
  set EIT_IN_EN_0 [ create_bd_port -dir O EIT_IN_EN_0 ]
  set dac_sclk_0 [ create_bd_port -dir O dac_sclk_0 ]
  set dac_sync_0 [ create_bd_port -dir O dac_sync_0 ]
  set dac_sdo_0 [ create_bd_port -dir O dac_sdo_0 ]
  set dac_ldac_0 [ create_bd_port -dir O dac_ldac_0 ]
  set gain_0 [ create_bd_port -dir O gain_0 ]
  set reset_0 [ create_bd_port -dir O -type rst reset_0 ]
  set enable_0 [ create_bd_port -dir O enable_0 ]
  set sw0 [ create_bd_port -dir I sw0 ]
  set sw1 [ create_bd_port -dir I sw1 ]
  set sw2 [ create_bd_port -dir I sw2 ]
  set sw3 [ create_bd_port -dir I sw3 ]
  set sw4 [ create_bd_port -dir I sw4 ]
  set sw5 [ create_bd_port -dir I sw5 ]
  set sw6 [ create_bd_port -dir I sw6 ]
  set ja0 [ create_bd_port -dir O ja0 ]
  set ja1 [ create_bd_port -dir O ja1 ]
  set ja2 [ create_bd_port -dir O ja2 ]
  set ja3 [ create_bd_port -dir O ja3 ]
  set ja4 [ create_bd_port -dir O ja4 ]
  set ja5 [ create_bd_port -dir O ja5 ]
  set ja6 [ create_bd_port -dir O ja6 ]

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
  # NOTE: CLK_OUT2/3_PORT and CLKOUT*_REQUESTED_OUT_FREQ were restored by hand
  # from the V0 XCI (ltc2500_bd_clk_wiz_1_0.xci) — write_bd_tcl omitted them
  # because their value_src was not "user". Do not remove them: the BD nets
  # connect to pins clk_100Mhz / clk_125MHz / clk_10MHz.
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
    CONFIG.C_NUM_OF_PROBES {27} \
    CONFIG.C_PROBE11_WIDTH {4} \
    CONFIG.C_PROBE12_WIDTH {16} \
    CONFIG.C_PROBE13_WIDTH {16} \
    CONFIG.C_PROBE14_WIDTH {3} \
    CONFIG.C_PROBE15_WIDTH {3} \
    CONFIG.C_PROBE17_WIDTH {8} \
    CONFIG.C_PROBE18_WIDTH {2} \
    CONFIG.C_PROBE21_WIDTH {13} \
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

  # Create instance: xlconstant_1, and set properties
  set xlconstant_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_1 ]

  # Create instance: xlconstant_2, and set properties
  set xlconstant_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_2 ]

  # Create instance: ethernet_debug_0, and set properties
  set ethernet_debug_0 [ create_bd_cell -type ip -vlnv xilinx.com:user:ethernet_debug:1.0 ethernet_debug_0 ]

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
  [get_bd_pins addr_gen_0/clk_C]
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
  connect_bd_net -net IP_1_0_chanel_cnt  [get_bd_pins IP_1_0/chanel_cnt] \
  [get_bd_pins IP_Two_0/cha_cnt] \
  [get_bd_pins ethernet_debug_0/dac_ch]
  connect_bd_net -net IP_1_0_done_tick  [get_bd_pins IP_1_0/done_tick] \
  [get_bd_pins IP_Two_0/done_tick] \
  [get_bd_pins IP_Three_0/done_tick]
  connect_bd_net -net IP_1_0_enable  [get_bd_pins IP_1_0/enable] \
  [get_bd_ports EIT_IN_EN_0]
  connect_bd_net -net IP_1_0_sync  [get_bd_pins IP_1_0/sync] \
  [get_bd_pins addr_gen_0/dds_sync]
  connect_bd_net -net IP_1_0_total_tick  [get_bd_pins IP_1_0/total_tick] \
  [get_bd_pins IP_Two_0/total_tick]
  connect_bd_net -net IP_Three_0_enable  [get_bd_pins IP_Three_0/enable] \
  [get_bd_ports enable_0]
  connect_bd_net -net IP_Three_0_mux  [get_bd_pins IP_Three_0/mux] \
  [get_bd_ports mux_0]
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
  [get_bd_pins addr_gen_0/clk_A] \
  [get_bd_pins IP_1_0/CLK_A]
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
  [get_bd_pins IP_1_0/address] \
  [get_bd_pins blk_mem_gen_0/addra] \
  [get_bd_pins ila_0/probe12]
  connect_bd_net -net addr_gen_0_lut_addr_B  [get_bd_pins addr_gen_0/lut_addr_B] \
  [get_bd_pins blk_mem_gen_1/addra]
  connect_bd_net -net addr_gen_0_lut_addr_C  [get_bd_pins addr_gen_0/lut_addr_C] \
  [get_bd_pins blk_mem_gen_2/addra]
  connect_bd_net -net addr_gen_0_lut_addr_D  [get_bd_pins addr_gen_0/lut_addr_D] \
  [get_bd_pins blk_mem_gen_3/addra]
  connect_bd_net -net axi_gpio_0_gpio2_io_o  [get_bd_pins axi_gpio_0/gpio2_io_o] \
  [get_bd_pins ltc_driver_fsm_0/i_start]
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
  connect_bd_net -net clk_wiz_1_clk_10MHz  [get_bd_pins clk_wiz_1/clk_10MHz] \
  [get_bd_pins IP_1_0/clk] \
  [get_bd_pins IP_Three_0/clk] \
  [get_bd_pins IP_Two_0/clk] \
  [get_bd_pins addr_gen_0/clk]
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
  connect_bd_net -net ltc_driver_fsm_0_o_mclk  [get_bd_pins ltc_driver_fsm_0/o_mclk] \
  [get_bd_ports o_mclk] \
  [get_bd_pins ila_0/probe5] \
  [get_bd_pins IP_Three_0/master_clk]
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
  [get_bd_pins IP_Three_0/rst_n] \
  [get_bd_pins IP_1_0/rst_n] \
  [get_bd_pins IP_Two_0/rst_n]
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
  connect_bd_net -net IP_Two_0_EIT_IN_EN  [get_bd_pins IP_Two_0/EIT_IN_EN] \
  [get_bd_ports ja0]
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
  connect_bd_net -net IP_Three_0_adc_ch  [get_bd_pins IP_Three_0/adc_ch] \
  [get_bd_pins ethernet_debug_0/adc_ch]
  connect_bd_net -net xlconstant_0_dout  [get_bd_pins xlconstant_0/dout] \
  [get_bd_pins blk_mem_gen_0/ena] \
  [get_bd_pins blk_mem_gen_1/ena] \
  [get_bd_pins blk_mem_gen_2/ena] \
  [get_bd_pins blk_mem_gen_3/ena]
  connect_bd_net -net xlconstant_1_dout  [get_bd_pins xlconstant_1/dout] \
  [get_bd_pins addr_gen_0/Update_Tick] \
  [get_bd_pins addr_gen_0/rst_n] \
  [get_bd_pins FSM_0/rst_n] \
  [get_bd_pins FSM_0/update_tick]
  connect_bd_net -net xlconstant_2_dout  [get_bd_pins xlconstant_2/dout] \
  [get_bd_pins ethernet_debug_0/rst_n]

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


