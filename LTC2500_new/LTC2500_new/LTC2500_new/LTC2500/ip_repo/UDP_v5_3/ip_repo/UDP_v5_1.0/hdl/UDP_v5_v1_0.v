
`timescale 1 ns / 1 ps

	module UDP_v5_v1_0 #
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
        input wire clk100MHz,                    
        //input [3:0] switches,                                                     
        input wire eth_int_b,        //interrupt                         
        input wire eth_pme_b,         //power management event            
        output wire eth_rst_b,        //reset                      
      // Management interface                                           
        output wire eth_mdc,                            
        inout wire eth_mdio,                              
        // Receive interface                                              
        input wire eth_rxck,                    
        input wire eth_rxctl,                   
        input wire [3:0]eth_rxd,                     
        // Transmit interface                                             
        output wire eth_txck,                            
        output wire eth_txctl,                           
        output wire [3:0]eth_txd,
        output wire [12:0] addr,    
        input wire reset,
        output wire [12:0] read_addr, 
        input wire clk_125MHz,
        output wire write_en,  
        input wire [7:0] mem_out,   
        input wire clk_trg,
        input wire clk_lock, //only lock the input signals
        output wire start_sending,
        
        output wire [1:0] outer_read_addr,
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
	UDP_v5_v1_0_S00_AXI # ( 
		.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
	) UDP_v5_v1_0_S00_AXI_inst (
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
		.clk100MHz(clk100MHz),                                                                 
        .eth_int_b(eth_int_b),             
        .eth_pme_b(eth_pme_b),              
        .eth_rst_b(eth_rst_b),                                             
        .eth_mdc(eth_mdc),                            
        .eth_mdio(eth_mdio),                                                                          
        .eth_rxck(eth_rxck),                    
        .eth_rxctl(eth_rxctl),                   
        .eth_rxd(eth_rxd),                                                                
        .eth_txck(eth_txck),                            
        .eth_txctl(eth_txctl),                           
        .eth_txd(eth_txd),
        .addr(addr),     
        .read_addr(read_addr), 
        .clk_125MHz(clk_125MHz),
        .write_en(write_en),  
        .mem_out(mem_out),
        .clk_trg(clk_trg),
        .clk_lock (clk_lock),
        .start_sending (start_sending),
        .reset(reset));
	endmodule
