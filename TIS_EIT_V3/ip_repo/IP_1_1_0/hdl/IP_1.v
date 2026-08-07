
`timescale 1 ns / 1 ps

	module IP_1 #
	(
		// Users to add parameters here
		// 按键消抖窗口（clk 周期数）。100MHz 下 2_000_000 = 20ms。仿真里调小它。
		parameter integer DEBOUNCE_CYCLES = 2000000,
		// User parameters ends
		// Do not modify the parameters beyond this line


		// Parameters of Axi Slave Bus Interface S00_AXI
		parameter integer C_S00_AXI_DATA_WIDTH	= 32,
		parameter integer C_S00_AXI_ADDR_WIDTH	= 7
	)
	(
		// Users to add ports here
        input  wire        clk,          // 系统时钟 (100MHz)
    input  wire        rst_n,        // 异步复位（低电平有效）
    // address / CLK_A: 旧的 DDS 回绕检测输入，现已不参与逻辑（保留端口以免动 BD 连线）
    input  wire [15:0] address,
    input  wire CLK_A,
    input  wire        btn_start,    // BTNU 板载按键(高有效, 异步) —— 启动一次测量

    output         done_tick,    // 一次刺激(stimulation)结束标志
    output        total_tick,   // 8 次刺激(= 一轮感测扫描)结束标志
    output [2:0]  chanel_cnt,
    output sync,
    output enable,
    output [2:0]  dac_ch_sel,   // DAC 注入通道 (模式A:每8次刺激; 模式B:=chanel_cnt)
    output        tis_on,       // 1 = TIS 猝发中 (FSM 增益放行 / 数据打标签)
    output        dds_hold,     // = ~tis_on -> addr_gen/dds_sync, 保持 A/B 相位为 0
    output        nerve_pulse,  // 神经反应模拟脉冲 -> PMOD JD1
    output        run_active,   // 1 = 一次测量正在进行
    output        o_cycle_done, // 调试: 刺激边界脉冲
    output        o_addr_msb,   // 调试: TIS 窗口
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
	IP_1_slave_lite_v1_0_S00_AXI # (
		.DEBOUNCE_CYCLES(DEBOUNCE_CYCLES),
		.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
	) IP_1_slave_lite_v1_0_S00_AXI_inst (
	.clk(clk),
	.rst_n(rst_n),
	.address(address),
	.done_tick(done_tick),
	.total_tick(total_tick),
	.chanel_cnt(chanel_cnt),
	.CLK_A(CLK_A),
	.btn_start(btn_start),

	.sync(sync),
	.enable(enable),
	.dac_ch_sel(dac_ch_sel),
	.tis_on(tis_on),
	.dds_hold(dds_hold),
	.nerve_pulse(nerve_pulse),
	.run_active(run_active),
	.o_cycle_done(o_cycle_done),
	.o_addr_msb(o_addr_msb),
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
