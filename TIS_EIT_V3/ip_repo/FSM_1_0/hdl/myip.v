
`timescale 1 ns / 1 ps

	module myip #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line


		// Parameters of Axi Slave Bus Interface S00_AXI
		parameter integer C_S00_AXI_DATA_WIDTH	= 32,
		parameter integer C_S00_AXI_ADDR_WIDTH	= 6
	)
	(
		// Users to add ports here
input  wire        clk,            // AXI 主时钟 (例如 100MHz)
    input  wire        rst_n,          // 全局复位 (低电平有效)
    
    // 来自 addr_gen 和内嵌 ROM 的 4 通道 16位正弦波数据
    input  wire        update_tick,    // 采样率定时器脉冲 (DDS 触发更新点)
    input  wire        tis_on,         // 1 = TIS 猝发中；0 时把 A/B 增益强制为 0 (静音)
    input  wire [15:0] sine_data_A,    // 通道 A 的当前正弦波无符号数字量
    input  wire [15:0] sine_data_B,    // 通道 B 的当前正弦波无符号数字量
    input  wire [15:0] sine_data_C,    // 通道 C 的当前正弦波无符号数字量
    input  wire [15:0] sine_data_D,    // 通道 D 的当前正弦波无符号数字量
    
    // 物理输出管脚：直接连接到芯片外围的 AD5686R 硬件引脚
    output         dac_sclk,       // SPI 串行时钟管脚
    output          dac_sync,       // SPI 片选/同步信号 (低电平有效)
    output          dac_sdo,        // SPI 串行数据输出
    output          dac_ldac,
    output        clk_A,
    output         clk_B,
    output       clk_C,
    output        clk_D,
		// User ports ends
		// Do not modify the ports beyond this line


		// Ports of Axi Slave Bus Interface S00_AXI
		input wire  s00_axi_aclk,
		input wire  s00_axi_aresetn,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
		input wire [2 : 0] s00_axi_awprot,
		input wire  s00_axi_awvalid,
		output wire  s00_axi_awready,
		input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
		input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
		input wire  s00_axi_wvalid,
		output wire  s00_axi_wready,
		output wire [1 : 0] s00_axi_bresp,
		output wire  s00_axi_bvalid,
		input wire  s00_axi_bready,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
		input wire [2 : 0] s00_axi_arprot,
		input wire  s00_axi_arvalid,
		output wire  s00_axi_arready,
		output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
		output wire [1 : 0] s00_axi_rresp,
		output wire  s00_axi_rvalid,
		input wire  s00_axi_rready
	);
// Instantiation of Axi Bus Interface S00_AXI
	myip_slave_lite_v1_0_S00_AXI # ( 
		.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
	) myip_slave_lite_v1_0_S00_AXI_inst (
	.clk(clk),
	.rst_n(rst_n),
	.update_tick(update_tick),
	.tis_on(tis_on),
	.sine_data_A(sine_data_A),
	.sine_data_B(sine_data_B),
	.sine_data_C(sine_data_C),
	.sine_data_D(sine_data_D),
	.dac_sclk(dac_sclk),
	.dac_sync(dac_sync),
	.dac_sdo(dac_sdo),
	.dac_ldac(dac_ldac),
	.clk_A(clk_A),
	.clk_B(clk_B),
	.clk_C(clk_C),
	.clk_D(clk_D),
		.S_AXI_ACLK(s00_axi_aclk),
		.S_AXI_ARESETN(s00_axi_aresetn),
		.S_AXI_AWADDR(s00_axi_awaddr),
		.S_AXI_AWPROT(s00_axi_awprot),
		.S_AXI_AWVALID(s00_axi_awvalid),
		.S_AXI_AWREADY(s00_axi_awready),
		.S_AXI_WDATA(s00_axi_wdata),
		.S_AXI_WSTRB(s00_axi_wstrb),
		.S_AXI_WVALID(s00_axi_wvalid),
		.S_AXI_WREADY(s00_axi_wready),
		.S_AXI_BRESP(s00_axi_bresp),
		.S_AXI_BVALID(s00_axi_bvalid),
		.S_AXI_BREADY(s00_axi_bready),
		.S_AXI_ARADDR(s00_axi_araddr),
		.S_AXI_ARPROT(s00_axi_arprot),
		.S_AXI_ARVALID(s00_axi_arvalid),
		.S_AXI_ARREADY(s00_axi_arready),
		.S_AXI_RDATA(s00_axi_rdata),
		.S_AXI_RRESP(s00_axi_rresp),
		.S_AXI_RVALID(s00_axi_rvalid),
		.S_AXI_RREADY(s00_axi_rready)
	);

	// Add user logic here

	// User logic ends

	endmodule
