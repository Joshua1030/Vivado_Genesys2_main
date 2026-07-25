
`timescale 1 ns / 1 ps

	module ethernet_debug #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line


		// Parameters of Axi Slave Bus Interface S00_AXI
		parameter integer C_S00_AXI_DATA_WIDTH	= 32,
		parameter integer C_S00_AXI_ADDR_WIDTH	= 4
	)
	(
		// Users to add ports here
input  wire        global_clk,     // 100MHz 系统主时钟
    input  wire        rst_n,          // 异步复位（低电平有效）
    input  wire        o_eth_valid,    // 外部每传过来一个有效字节，该信号拉高一个周期
    input  wire [7:0]  o_eth_data,     // 输入的 8 位（1字节）数据
    input  wire [2:0]  dac_ch,         // 当前 DAC 注入通道 (0..7)，写入表头
    input  wire [2:0]  adc_ch,         // 当前 ADC 感测通道 (0..7)，写入表头

    output          clk_trg,        // 输出的延长时钟信号
    output   [7:0]  data_out,
    output   [1:0]  dbg_rx_byte_cnt,   // 观察点1：接收字节计数有没有在动
    output          dbg_tx_start_en,   // 观察点2：有没有出现单周期启动脉冲
    output          dbg_current_state,
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
	ethernet_debug_slave_lite_v1_0_S00_AXI # ( 
		.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
	) ethernet_debug_slave_lite_v1_0_S00_AXI_inst (
	.global_clk(global_clk),
	.rst_n(rst_n),
	.o_eth_valid(o_eth_valid),
	.o_eth_data(o_eth_data),
	.dac_ch(dac_ch),
	.adc_ch(adc_ch),
	.clk_trg(clk_trg),
	.data_out(data_out),
	.dbg_rx_byte_cnt(dbg_rx_byte_cnt),
	.dbg_tx_start_en(dbg_tx_start_en),
	.dbg_current_state(dbg_current_state),
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
