
`timescale 1 ns / 1 ps

	module Multi_Mode_NS_SAR_Control #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line


		// Parameters of Axi Slave Bus Interface S00_AXI
		parameter integer C_S00_AXI_DATA_WIDTH	= 32,
		parameter integer C_S00_AXI_ADDR_WIDTH	= 8
	)
	(
		// Users to add ports here
        input  wire        main_clock,
        input  wire        sw,             // NEW: External switch input
        output wire        reset,          // NEW: Reset output driven by 'sw'
        input  wire [3:0]  DATA,
        output wire [3:0]  sampled_data,
    
        // Outputs
        output wire        A4,
        output wire        A3,
        output wire        A2,
        output wire        M0,
        output wire        M1,
        output wire [1:0]  OUT_SEL,
        output wire        DEM_EN,
        output wire        CLK_S,
        output wire        PINT1,
        output wire        PINT2,
        output wire        CLK,
        output wire        CLK_CHOP,
        output wire        DEM_CLK,
        
        // Output ports for AMP (NEW)
        output wire        AMP_CLK_Sample,
        output wire        AMP_CLK_Push,
        output wire        AMP_CLK_Chop,
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
	Multi_Mode_NS_SAR_Control_slave_lite_v1_0_S00_AXI # ( 
		.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
	) Multi_Mode_NS_SAR_Control_slave_lite_v1_0_S00_AXI_inst (
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
		.S_AXI_RREADY(s00_axi_rready),
		// User ports mapping
        .main_clock     (main_clock),
        .sw             (sw),
        .reset          (reset),
        .DATA           (DATA),
        .sampled_data   (sampled_data),
        .A4             (A4),
        .A3             (A3),
        .A2             (A2),
        .M0             (M0),
        .M1             (M1),
        .OUT_SEL        (OUT_SEL),
        .DEM_EN         (DEM_EN),
        .CLK_S          (CLK_S),
        .PINT1          (PINT1),
        .PINT2          (PINT2),
        .CLK            (CLK),
        .CLK_CHOP       (CLK_CHOP),
        .DEM_CLK        (DEM_CLK),
        .AMP_CLK_Sample (AMP_CLK_Sample),
        .AMP_CLK_Push   (AMP_CLK_Push),
        .AMP_CLK_Chop   (AMP_CLK_Chop)
	);

	// Add user logic here

	// User logic ends

	endmodule
