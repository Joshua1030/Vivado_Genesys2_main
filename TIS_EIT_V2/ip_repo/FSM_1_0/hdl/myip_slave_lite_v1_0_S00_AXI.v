
`timescale 1 ns / 1 ps

	module myip_slave_lite_v1_0_S00_AXI #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line

		// Width of S_AXI data bus
		parameter integer C_S_AXI_DATA_WIDTH	= 32,
		// Width of S_AXI address bus
		parameter integer C_S_AXI_ADDR_WIDTH	= 6
	)
	(
		// Users to add ports here
input  wire        clk,            // AXI 主时钟 (例如 100MHz)
    input  wire        rst_n,          // 全局复位 (低电平有效)
    
    // 来自 addr_gen 和内嵌 ROM 的 4 通道 16位正弦波数据
    input  wire        update_tick,    // 采样率定时器脉冲 (DDS 触发更新点)
    input  wire [15:0] sine_data_A,    // 通道 A 的当前正弦波无符号数字量
    input  wire [15:0] sine_data_B,    // 通道 B 的当前正弦波无符号数字量
    input  wire [15:0] sine_data_C,    // 通道 C 的当前正弦波无符号数字量
    input  wire [15:0] sine_data_D,    // 通道 D 的当前正弦波无符号数字量
    
    // 物理输出管脚：直接连接到芯片外围的 AD5686R 硬件引脚
    output reg         dac_sclk,       // SPI 串行时钟管脚
    output reg         dac_sync,       // SPI 片选/同步信号 (低电平有效)
    output reg         dac_sdo,        // SPI 串行数据输出
    output reg         dac_ldac,
    output reg         clk_A,
    output reg         clk_B,
    output reg         clk_C,
    output reg         clk_D,
		// User ports ends
		// Do not modify the ports beyond this line

		// Global Clock Signal
		input wire  S_AXI_ACLK,
		// Global Reset Signal. This Signal is Active LOW
		input wire  S_AXI_ARESETN,
		// Write address (issued by master, acceped by Slave)
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
		// Write channel Protection type. This signal indicates the
    		// privilege and security level of the transaction, and whether
    		// the transaction is a data access or an instruction access.
		input wire [2 : 0] S_AXI_AWPROT,
		// Write address valid. This signal indicates that the master signaling
    		// valid write address and control information.
		input wire  S_AXI_AWVALID,
		// Write address ready. This signal indicates that the slave is ready
    		// to accept an address and associated control signals.
		output wire  S_AXI_AWREADY,
		// Write data (issued by master, acceped by Slave) 
		input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
		// Write strobes. This signal indicates which byte lanes hold
    		// valid data. There is one write strobe bit for each eight
    		// bits of the write data bus.    
		input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
		// Write valid. This signal indicates that valid write
    		// data and strobes are available.
		input wire  S_AXI_WVALID,
		// Write ready. This signal indicates that the slave
    		// can accept the write data.
		output wire  S_AXI_WREADY,
		// Write response. This signal indicates the status
    		// of the write transaction.
		output wire [1 : 0] S_AXI_BRESP,
		// Write response valid. This signal indicates that the channel
    		// is signaling a valid write response.
		output wire  S_AXI_BVALID,
		// Response ready. This signal indicates that the master
    		// can accept a write response.
		input wire  S_AXI_BREADY,
		// Read address (issued by master, acceped by Slave)
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
		// Protection type. This signal indicates the privilege
    		// and security level of the transaction, and whether the
    		// transaction is a data access or an instruction access.
		input wire [2 : 0] S_AXI_ARPROT,
		// Read address valid. This signal indicates that the channel
    		// is signaling valid read address and control information.
		input wire  S_AXI_ARVALID,
		// Read address ready. This signal indicates that the slave is
    		// ready to accept an address and associated control signals.
		output wire  S_AXI_ARREADY,
		// Read data (issued by slave)
		output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
		// Read response. This signal indicates the status of the
    		// read transfer.
		output wire [1 : 0] S_AXI_RRESP,
		// Read valid. This signal indicates that the channel is
    		// signaling the required read data.
		output wire  S_AXI_RVALID,
		// Read ready. This signal indicates that the master can
    		// accept the read data and response information.
		input wire  S_AXI_RREADY
	);

	// AXI4LITE signals
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_awaddr;
	reg  	axi_awready;
	reg  	axi_wready;
	reg [1 : 0] 	axi_bresp;
	reg  	axi_bvalid;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_araddr;
	reg  	axi_arready;
	reg [1 : 0] 	axi_rresp;
	reg  	axi_rvalid;

	// Example-specific design signals
	// local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
	// ADDR_LSB is used for addressing 32/64 bit registers/memories
	// ADDR_LSB = 2 for 32 bits (n downto 2)
	// ADDR_LSB = 3 for 64 bits (n downto 3)
	localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;
	localparam integer OPT_MEM_ADDR_BITS = 3;
	//----------------------------------------------
	//-- Signals for user logic register space example
	//------------------------------------------------
	//-- Number of Slave Registers 16
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg0;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg1;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg2;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg3;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg4;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg5;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg6;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg7;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg8;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg9;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg10;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg11;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg12;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg13;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg14;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg15;
	integer	 byte_index;

	// I/O Connections assignments

	assign S_AXI_AWREADY	= axi_awready;
	assign S_AXI_WREADY	= axi_wready;
	assign S_AXI_BRESP	= axi_bresp;
	assign S_AXI_BVALID	= axi_bvalid;
	assign S_AXI_ARREADY	= axi_arready;
	assign S_AXI_RRESP	= axi_rresp;
	assign S_AXI_RVALID	= axi_rvalid;
	 //state machine varibles 
	 reg [1:0] state_write;
	 reg [1:0] state_read;
	 //State machine local parameters
	 localparam Idle = 2'b00,Raddr = 2'b10,Rdata = 2'b11 ,Waddr = 2'b10,Wdata = 2'b11;
	// Implement Write state machine
	// Outstanding write transactions are not supported by the slave i.e., master should assert bready to receive response on or before it starts sending the new transaction
	always @(posedge S_AXI_ACLK)                                 
	  begin                                 
	     if (S_AXI_ARESETN == 1'b0)                                 
	       begin                                 
	         axi_awready <= 0;                                 
	         axi_wready <= 0;                                 
	         axi_bvalid <= 0;                                 
	         axi_bresp <= 0;                                 
	         axi_awaddr <= 0;                                 
	         state_write <= Idle;                                 
	       end                                 
	     else                                  
	       begin                                 
	         case(state_write)                                 
	           Idle:                                      
	             begin                                 
	               if(S_AXI_ARESETN == 1'b1)                                  
	                 begin                                 
	                   axi_awready <= 1'b1;                                 
	                   axi_wready <= 1'b1;                                 
	                   state_write <= Waddr;                                 
	                 end                                 
	               else state_write <= state_write;                                 
	             end                                 
	           Waddr:        //At this state, slave is ready to receive address along with corresponding control signals and first data packet. Response valid is also handled at this state                                 
	             begin                                 
	               if (S_AXI_AWVALID && S_AXI_AWREADY)                                 
	                  begin                                 
	                    axi_awaddr <= S_AXI_AWADDR;                                 
	                    if(S_AXI_WVALID)                                  
	                      begin                                   
	                        axi_awready <= 1'b1;                                 
	                        state_write <= Waddr;                                 
	                        axi_bvalid <= 1'b1;                                 
	                      end                                 
	                    else                                  
	                      begin                                 
	                        axi_awready <= 1'b0;                                 
	                        state_write <= Wdata;                                 
	                        if (S_AXI_BREADY && axi_bvalid) axi_bvalid <= 1'b0;                                 
	                      end                                 
	                  end                                 
	               else                                  
	                  begin                                 
	                    state_write <= state_write;                                 
	                    if (S_AXI_BREADY && axi_bvalid) axi_bvalid <= 1'b0;                                 
	                   end                                 
	             end                                 
	          Wdata:        //At this state, slave is ready to receive the data packets until the number of transfers is equal to burst length                                 
	             begin                                 
	               if (S_AXI_WVALID)                                 
	                 begin                                 
	                   state_write <= Waddr;                                 
	                   axi_bvalid <= 1'b1;                                 
	                   axi_awready <= 1'b1;                                 
	                 end                                 
	                else                                  
	                 begin                                 
	                   state_write <= state_write;                                 
	                   if (S_AXI_BREADY && axi_bvalid) axi_bvalid <= 1'b0;                                 
	                 end                                              
	             end                                 
	          endcase                                 
	        end                                 
	      end                                 

	// Implement memory mapped register select and write logic generation
	// The write data is accepted and written to memory mapped registers when
	// axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
	// select byte enables of slave registers while writing.
	// These registers are cleared when reset (active low) is applied.
	// Slave register write enable is asserted when valid address and data are available
	// and the slave is ready to accept the write address and write data.
	 

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      slv_reg0 <= 0;
	      slv_reg1 <= 0;
	      slv_reg2 <= 0;
	      slv_reg3 <= 0;
	      slv_reg4 <= 0;
	      slv_reg5 <= 0;
	      slv_reg6 <= 0;
	      slv_reg7 <= 0;
	      slv_reg8 <= 0;
	      slv_reg9 <= 0;
	      slv_reg10 <= 0;
	      slv_reg11 <= 0;
	      slv_reg12 <= 0;
	      slv_reg13 <= 0;
	      slv_reg14 <= 0;
	      slv_reg15 <= 0;
	    end 
	  else begin
	    if (S_AXI_WVALID)
	      begin
	        case ( (S_AXI_AWVALID) ? S_AXI_AWADDR[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] : axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
	          4'h0:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 0
	                slv_reg0[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          4'h1:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 1
	                slv_reg1[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          4'h2:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 2
	                slv_reg2[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          4'h3:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 3
	                slv_reg3[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          4'h4:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 4
	                slv_reg4[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          4'h5:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 5
	                slv_reg5[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          4'h6:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 6
	                slv_reg6[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          4'h7:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 7
	                slv_reg7[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          4'h8:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 8
	                slv_reg8[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          4'h9:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 9
	                slv_reg9[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          4'hA:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 10
	                slv_reg10[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          4'hB:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 11
	                slv_reg11[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          4'hC:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 12
	                slv_reg12[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          4'hD:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 13
	                slv_reg13[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          4'hE:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 14
	                slv_reg14[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          4'hF:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 15
	                slv_reg15[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          default : begin
	                      slv_reg0 <= slv_reg0;
	                      slv_reg1 <= slv_reg1;
	                      slv_reg2 <= slv_reg2;
	                      slv_reg3 <= slv_reg3;
	                      slv_reg4 <= slv_reg4;
	                      slv_reg5 <= slv_reg5;
	                      slv_reg6 <= slv_reg6;
	                      slv_reg7 <= slv_reg7;
	                      slv_reg8 <= slv_reg8;
	                      slv_reg9 <= slv_reg9;
	                      slv_reg10 <= slv_reg10;
	                      slv_reg11 <= slv_reg11;
	                      slv_reg12 <= slv_reg12;
	                      slv_reg13 <= slv_reg13;
	                      slv_reg14 <= slv_reg14;
	                      slv_reg15 <= slv_reg15;
	                    end
	        endcase
	      end
	  end
	end    

	// Implement read state machine
	  always @(posedge S_AXI_ACLK)                                       
	    begin                                       
	      if (S_AXI_ARESETN == 1'b0)                                       
	        begin                                       
	         //asserting initial values to all 0's during reset                                       
	         axi_arready <= 1'b0;                                       
	         axi_rvalid <= 1'b0;                                       
	         axi_rresp <= 1'b0;                                       
	         state_read <= Idle;                                       
	        end                                       
	      else                                       
	        begin                                       
	          case(state_read)                                       
	            Idle:     //Initial state inidicating reset is done and ready to receive read/write transactions                                       
	              begin                                                
	                if (S_AXI_ARESETN == 1'b1)                                        
	                  begin                                       
	                    state_read <= Raddr;                                       
	                    axi_arready <= 1'b1;                                       
	                  end                                       
	                else state_read <= state_read;                                       
	              end                                       
	            Raddr:        //At this state, slave is ready to receive address along with corresponding control signals                                       
	              begin                                       
	                if (S_AXI_ARVALID && S_AXI_ARREADY)                                       
	                  begin                                       
	                    state_read <= Rdata;                                       
	                    axi_araddr <= S_AXI_ARADDR;                                       
	                    axi_rvalid <= 1'b1;                                       
	                    axi_arready <= 1'b0;                                       
	                  end                                       
	                else state_read <= state_read;                                       
	              end                                       
	            Rdata:        //At this state, slave is ready to send the data packets until the number of transfers is equal to burst length                                       
	              begin                                           
	                if (S_AXI_RVALID && S_AXI_RREADY)                                       
	                  begin                                       
	                    axi_rvalid <= 1'b0;                                       
	                    axi_arready <= 1'b1;                                       
	                    state_read <= Raddr;                                       
	                  end                                       
	                else state_read <= state_read;                                       
	              end                                       
	           endcase                                       
	          end                                       
	        end                                         
	// Implement memory mapped register select and read logic generation
	  assign S_AXI_RDATA = (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 4'h0) ? slv_reg0 : (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 4'h1) ? slv_reg1 : (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 4'h2) ? slv_reg2 : (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 4'h3) ? slv_reg3 : (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 4'h4) ? slv_reg4 : (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 4'h5) ? slv_reg5 : (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 4'h6) ? slv_reg6 : (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 4'h7) ? slv_reg7 : (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 4'h8) ? slv_reg8 : (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 4'h9) ? slv_reg9 : (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 4'hA) ? slv_reg10 : (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 4'hB) ? slv_reg11 : (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 4'hC) ? slv_reg12 : (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 4'hD) ? slv_reg13 : (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 4'hE) ? slv_reg14 : (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 4'hF) ? slv_reg15 : 0; 
	// Add user logic here
// =====================================================================
    // 1. 状态独热码独占声明 (增加了一个新状态 STATE_SYNC_HIGH)
    // =====================================================================
    parameter STATE_IDLE      = 6'b000001,
              STATE_SYNC_HIGH = 6'b000010, // 新增：专门用来延长 SYNC 高电平的时间
              STATE_LOAD_DATA = 6'b000100,
              STATE_SPI_TX    = 6'b001000,
              STATE_CHECK_CH  = 6'b010000,
              STATE_PULSE_LDAC = 6'b100000; 
    
    // 状态寄存器位宽相应地从 [4:0] 扩展到 [5:0]
    reg [5:0] current_state;
    reg [5:0] next_state;

    // =====================================================================
    // 2. 内部硬件计数器与控制寄存器声明
    // =====================================================================
    // SCLK = clk / (2*div_n).  div_n 为 slv_reg0[7:0] 的工作副本，只在
    // STATE_IDLE 处锁存，帧内保持不变，避免中途改频产生毛刺。
    // slv_reg0==0 选用上电默认值 DEFAULT_N (clk=100MHz 时对应 25MHz SCLK)。
    localparam [7:0] DEFAULT_N = 8'd2;   // 100MHz / (2*2) = 25MHz
    reg  [7:0] div_n;                    // 当前有效的 SCLK 分频系数 N

    reg [8:0]  spi_clk_div;   // SPI 时钟分频计数器 (0 .. 2*div_n-1)
    reg        spi_tick;      // SPI 分频使能信号脉冲 (每个 SCLK 周期一次)
    reg [5:0]  bit_cnt;       // 比特发送计数器 (0 至 24)
    reg [1:0]  ch_cnt;        // 4 通道轮询计数器 (0=A, 1=B, 2=C, 3=D)
    reg [31:0] tx_shift_reg;  // 32位串行发送移位寄存器
    
    // SYNC 高电平保持计数器 (保持 1 个 SCLK 周期 = 2*div_n 个 clk)
    reg [10:0] sync_high_cnt;
    // LDAC 低脉冲保持计数器 (保持 2 个 SCLK 周期 = 4*div_n 个 clk)
    reg [10:0] ldac_cnt;

    // 采样率(DAC 更新率)控制：slv_reg1 = 更新周期(clk 周期数)，0 = 自由运行
    reg [31:0] upd_cnt;       // 自由运行的更新周期计数器
    reg        upd_pending;   // 到达周期后置位，进入一次刷新循环时清零
    wire       start_pulse = (current_state == STATE_IDLE) &&
                             (next_state    == STATE_SYNC_HIGH);

    // AD5686R 协议固定指令码：4'b0001 代表 "Write to and Update DAC Channel"
    localparam [3:0] DAC_CMD_WRITE_UPDATE = 4'b0001;

    // =====================================================================
    // 2b. 幅度增益级 (Q12 定点乘法，保持共模电压不变)
    //     out = CM + (sine - CM) * gain，其中 CM = 0x8000 中间码 (COE 直流中点)。
    //     只缩放围绕中点的交流摆幅，直流共模码保持 0x8000 不变。
    //     slv_reg2..5[15:0] = 各通道增益，Q12 格式 (4096 = x1.0)；0 映射为单位增益，
    //     以保留未配置时的满幅默认行为 (与 slv_reg0/1 "0=默认" 约定一致)。
    // =====================================================================
    localparam signed [17:0] CM_LEVEL   = 18'sd32768;  // 0x8000 中间码 (共模)
    localparam integer       GAIN_SHIFT = 12;          // Q12 定点
    localparam [15:0]        GAIN_UNITY = 16'd4096;     // Q12 下的 1.0

    // 按当前正在装载的通道 (ch_cnt) 选择原始采样值与增益字
    reg [15:0] gain_sample;
    reg [15:0] gain_word;
    always @(*) begin
        case (ch_cnt)
            2'd0: begin gain_sample = sine_data_A; gain_word = slv_reg2[15:0]; end
            2'd1: begin gain_sample = sine_data_B; gain_word = slv_reg3[15:0]; end
            2'd2: begin gain_sample = sine_data_C; gain_word = slv_reg4[15:0]; end
            2'd3: begin gain_sample = sine_data_D; gain_word = slv_reg5[15:0]; end
        endcase
    end

    // 0 => 单位增益 (保留未配置板卡的满幅行为)
    wire [15:0] gain_eff = (gain_word == 16'd0) ? GAIN_UNITY : gain_word;

    // 围绕共模做偏移、Q12 缩放、四舍五入、恢复共模，最后饱和到 [0,65535]
    wire signed [17:0] gain_offset  = $signed({2'b00, gain_sample}) - CM_LEVEL;   // -32768..+32767
    wire signed [34:0] gain_product = gain_offset * $signed({1'b0, gain_eff});    // Q12 结果
    wire signed [34:0] gain_rounded = gain_product + 35'sd2048;                   // +0.5 LSB (2^11)
    wire signed [22:0] gain_scaled  = gain_rounded >>> GAIN_SHIFT;                // 移回整数 LSB
    wire signed [23:0] gain_sum     = gain_scaled + CM_LEVEL;                     // 恢复共模
    wire [15:0]        dac_word     = (gain_sum < 24'sd0)     ? 16'h0000 :
                                      (gain_sum > 24'sd65535) ? 16'hFFFF :
                                                                gain_sum[15:0];

    // =====================================================================
    // 3. 任务 A：SPI 时钟分频逻辑
    // =====================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            spi_clk_div <= 9'b0;
            spi_tick    <= 1'b0;
        end else if (current_state == STATE_SPI_TX) begin
            if (spi_clk_div == (2*div_n - 1)) begin
                spi_clk_div <= 9'b0;
                spi_tick    <= 1'b1;
            end else begin
                spi_clk_div <= spi_clk_div + 1'b1;
                spi_tick    <= 1'b0;
            end
        end else begin
            spi_clk_div <= 9'b0;
            spi_tick    <= 1'b0;
        end
    end

    // =====================================================================
    // 3b. 采样率(DAC 更新率)分频：与 SCLK 频率解耦
    //     slv_reg1 = 更新周期 (clk 周期数)。0 = 自由运行(与旧行为一致)。
    //     计数到 slv_reg1-1 即置位 upd_pending，STATE_IDLE 消费一次并清零。
    // =====================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            upd_cnt     <= 32'd0;
            upd_pending <= 1'b0;
        end else if (slv_reg1 == 32'd0) begin
            upd_cnt     <= 32'd0;
            upd_pending <= 1'b0;
        end else begin
            if (upd_cnt >= (slv_reg1 - 1'b1)) begin
                upd_cnt     <= 32'd0;
                upd_pending <= 1'b1;
            end else begin
                upd_cnt <= upd_cnt + 1'b1;
            end
            if (start_pulse)          // 本周期离开 IDLE，消费掉挂起标志
                upd_pending <= 1'b0;
        end
    end

    // =====================================================================
    // 4. FSM 三段式状态机之第一段：状态同步转移
    // =====================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= STATE_IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    // =====================================================================
    // 5. FSM 三段式状态机之第二段：组合逻辑判断状态转移条件
    // =====================================================================
    always @(*) begin
        next_state = current_state;
        case (current_state)
            STATE_IDLE: begin
                // 自由运行(slv_reg1==0) 或到达采样周期(upd_pending) 时触发一次刷新
                if (update_tick && (slv_reg1 == 32'd0 || upd_pending))
                    next_state = STATE_SYNC_HIGH;
                else
                    next_state = STATE_IDLE;
            end

            // 维持 SYNC 高电平 1 个 SCLK 周期 (2*div_n 个 clk)
            STATE_SYNC_HIGH: begin
                if (sync_high_cnt == (2*div_n - 1))
                    next_state = STATE_LOAD_DATA;
                else
                    next_state = STATE_SYNC_HIGH;
            end
            
            STATE_LOAD_DATA: begin
                next_state = STATE_SPI_TX; 
            end
            
            STATE_SPI_TX: begin
                if (bit_cnt == 6'd24 && spi_tick) 
                    next_state = STATE_CHECK_CH;
                else 
                    next_state = STATE_SPI_TX;
            end
            
            STATE_CHECK_CH: begin
                if (ch_cnt == 2'd3) 
                    next_state = STATE_PULSE_LDAC; 
                else 
                    next_state = STATE_SYNC_HIGH; // 通道未完时，调头先去维持 SYNC 高电平
            end
            
            // 保持 LDAC 低电平 2 个 SCLK 周期 (4*div_n 个 clk) 再回到 IDLE
            STATE_PULSE_LDAC: begin
                if (ldac_cnt == (4*div_n - 1))
                    next_state = STATE_IDLE;
                else
                    next_state = STATE_PULSE_LDAC;
            end

            default: next_state = STATE_IDLE;
        endcase
    end

    // =====================================================================
    // 6. FSM 三段式状态机之第三段：时序逻辑执行动作与计数器维护
    // =====================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_cnt       <= 6'b0;
            ch_cnt        <= 2'b0;
            sync_high_cnt <= 11'b0;
            ldac_cnt      <= 11'b0;
            div_n         <= DEFAULT_N;
            tx_shift_reg  <= 32'b0;
            dac_sclk      <= 1'b1;
            dac_sync      <= 1'b1;
            dac_sdo       <= 1'b0;
            dac_ldac      <= 1'b1;
            clk_A         <= 1'b1;
            clk_B         <= 1'b1;
            clk_C         <= 1'b1;
            clk_D         <= 1'b1;
        end else begin
            case (current_state)
                STATE_IDLE: begin
                    bit_cnt       <= 6'b0;
                    ch_cnt        <= 2'b0;
                    sync_high_cnt <= 11'b0;
                    ldac_cnt      <= 11'b0;
                    // 每次循环起点锁存分频系数，帧内保持不变；0 映射为默认值
                    div_n         <= (slv_reg0[7:0] == 8'd0) ? DEFAULT_N : slv_reg0[7:0];
                    dac_sclk      <= 1'b1;
                    dac_sync      <= 1'b1;
                    dac_sdo       <= 1'b0;
                    dac_ldac      <= 1'b1;
                end
                
                // 新增状态的行为：确保 dac_sync 为高，并累加计数器
                STATE_SYNC_HIGH: begin
                    dac_sync <= 1'b1; // 明确地持续拉高 SYNC
                    dac_sclk <= 1'b1; // 保持时钟空闲高电平
                    if (sync_high_cnt < (2*div_n - 1)) begin
                        sync_high_cnt <= sync_high_cnt + 1'b1;
                    end
                end
                
                STATE_LOAD_DATA: begin
                    bit_cnt       <= 6'b0;
                    sync_high_cnt <= 3'b0; // 顺手把等待计数器清零，为下一次做准备
                    dac_sync      <= 1'b1; 
                    // dac_word 已按 ch_cnt 选出对应通道并施加增益，只有通道选择位不同
                    case (ch_cnt)
                        2'd0: tx_shift_reg <= {DAC_CMD_WRITE_UPDATE, 4'b0001, dac_word, 8'h00};
                        2'd1: tx_shift_reg <= {DAC_CMD_WRITE_UPDATE, 4'b0010, dac_word, 8'h00};
                        2'd2: tx_shift_reg <= {DAC_CMD_WRITE_UPDATE, 4'b0100, dac_word, 8'h00};
                        2'd3: tx_shift_reg <= {DAC_CMD_WRITE_UPDATE, 4'b1000, dac_word, 8'h00};
                    endcase
                end
                
                STATE_SPI_TX: begin
                    dac_sync <= 1'b0; 
                    
                    if (spi_tick) begin
                        if (bit_cnt < 6'd24) begin
                            dac_sclk     <= 1'b0; 
                            bit_cnt      <= bit_cnt + 1'b1;
                        end
                    end else if (spi_clk_div == div_n) begin
                        if (dac_sync == 1'b0) begin
                            dac_sclk <= 1'b1;
                            dac_sdo      <= tx_shift_reg[31];
                            tx_shift_reg <= {tx_shift_reg[30:0], 1'b0};
                        end
                    end
                end
                
                STATE_CHECK_CH: begin
                    dac_sync <= 1'b1; 
                    dac_sclk <= 1'b1;
                    if (ch_cnt < 2'd3) begin
                        ch_cnt <= ch_cnt + 1'b1; 
                    end
                    case (ch_cnt)
                        2'd0: begin clk_A <= 0; clk_B <= 1; clk_C <= 1; clk_D <= 1; end
                        2'd1: begin clk_A <= 1; clk_B <= 0; clk_C <= 1; clk_D <= 1; end
                        2'd2: begin clk_A <= 1; clk_B <= 1; clk_C <= 0; clk_D <= 1; end
                        2'd3: begin clk_A <= 1; clk_B <= 1; clk_C <= 1; clk_D <= 0; end
                    endcase 
                end
                
                STATE_PULSE_LDAC: begin
                    dac_ldac <= 1'b0;
                    ch_cnt   <= 2'b0;
                    if (ldac_cnt < (4*div_n - 1))
                        ldac_cnt <= ldac_cnt + 1'b1;
                end
                
                default: ;
            endcase
        end
    end
	// User logic ends

	endmodule
