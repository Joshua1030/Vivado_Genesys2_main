// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2025 Advanced Micro Devices, Inc. All Rights Reserved.
// -------------------------------------------------------------------------------
// This file contains confidential and proprietary information
// of AMD and is protected under U.S. and international copyright
// and other intellectual property laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// AMD, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND AMD HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) AMD shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or AMD had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// AMD products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of AMD products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
//
// DO NOT MODIFY THIS FILE.

// MODULE VLNV: xilinx.com:user:DEM_NetronV2:1.0

`timescale 1ps / 1ps

`include "vivado_interfaces.svh"

module DEM_NetronV2_0_sv (
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S00_AXI" *)
  (* X_INTERFACE_MODE = "slave S00_AXI" *)
  (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME S00_AXI, WIZ_DATA_WIDTH 32, WIZ_NUM_REG 4, SUPPORTS_NARROW_BURST 0, DATA_WIDTH 32, PROTOCOL AXI4LITE, FREQ_HZ 100000000, ID_WIDTH 0, ADDR_WIDTH 4, AWUSER_WIDTH 0, ARUSER_WIDTH 0, WUSER_WIDTH 0, RUSER_WIDTH 0, BUSER_WIDTH 0, READ_WRITE_MODE READ_WRITE, HAS_BURST 0, HAS_LOCK 0, HAS_PROT 1, HAS_CACHE 0, HAS_QOS 0, HAS_REGION 0, HAS_WSTRB 1, HAS_BRESP 1, HAS_RRESP 1, NUM_READ_OUTSTANDING 1, NUM_WRITE_OUTSTANDING 1, MAX_BURST_LENGTH 1, PHASE 0.0, NUM_READ_THREADS 1, NUM_WRITE_THREADS 1, RUSER_BITS_PER_BYTE 0, WUSER_BITS_PER_BYTE 0, INSERT_VIP 0" *)
  vivado_axi4_lite_v1_0.slave S00_AXI,
  (* X_INTERFACE_IGNORE = "true" *)
  input wire [2:0] D,
  (* X_INTERFACE_IGNORE = "true" *)
  input wire CLK_IN,
  (* X_INTERFACE_IGNORE = "true" *)
  input wire RSTB,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire [6:0] NS_SAR_ADC_FEEDBACK,
  (* X_INTERFACE_IGNORE = "true" *)
  input wire s00_axi_aclk,
  (* X_INTERFACE_IGNORE = "true" *)
  input wire s00_axi_aresetn
);

  DEM_NetronV2_0 inst (
    .D(D),
    .CLK_IN(CLK_IN),
    .RSTB(RSTB),
    .NS_SAR_ADC_FEEDBACK(NS_SAR_ADC_FEEDBACK),
    .s00_axi_aclk(s00_axi_aclk),
    .s00_axi_aresetn(s00_axi_aresetn),
    .s00_axi_awaddr(S00_AXI.AWADDR),
    .s00_axi_awprot(S00_AXI.AWPROT),
    .s00_axi_awvalid(S00_AXI.AWVALID),
    .s00_axi_awready(S00_AXI.AWREADY),
    .s00_axi_wdata(S00_AXI.WDATA),
    .s00_axi_wstrb(S00_AXI.WSTRB),
    .s00_axi_wvalid(S00_AXI.WVALID),
    .s00_axi_wready(S00_AXI.WREADY),
    .s00_axi_bresp(S00_AXI.BRESP),
    .s00_axi_bvalid(S00_AXI.BVALID),
    .s00_axi_bready(S00_AXI.BREADY),
    .s00_axi_araddr(S00_AXI.ARADDR),
    .s00_axi_arprot(S00_AXI.ARPROT),
    .s00_axi_arvalid(S00_AXI.ARVALID),
    .s00_axi_arready(S00_AXI.ARREADY),
    .s00_axi_rdata(S00_AXI.RDATA),
    .s00_axi_rresp(S00_AXI.RRESP),
    .s00_axi_rvalid(S00_AXI.RVALID),
    .s00_axi_rready(S00_AXI.RREADY)
  );

endmodule
