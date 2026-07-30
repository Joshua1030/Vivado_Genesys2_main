
`timescale 1 ns / 1 ps

	module ethernet_debug_slave_lite_v1_0_S00_AXI #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line

		// Width of S_AXI data bus
		parameter integer C_S_AXI_DATA_WIDTH	= 32,
		// Width of S_AXI address bus
		parameter integer C_S_AXI_ADDR_WIDTH	= 4
	)
	(
		// Users to add ports here
       input  wire        global_clk,     // 100MHz 系统主时钟
    input  wire        rst_n,          // 异步复位（低电平有效）
    input  wire        o_eth_valid,    // 外部每传过来一个有效字节，该信号拉高一个周期
    input  wire [7:0]  o_eth_data,     // 输入的 8 位（1字节）数据
    input  wire [2:0]  dac_ch,         // 当前 DAC 注入通道 (0..7)，写入表头
    input  wire [2:0]  adc_ch,         // 当前 ADC 感测通道 (0..7)，写入表头
    input  wire        mclk,           // LTC2500 MCLK 选通（ltc_driver_fsm/o_mclk）：采样瞬间

    output reg         clk_trg,        // 输出的延长时钟信号
    output reg  [7:0]  data_out,       // 伴随输出的 8 位（2位十六进制）数据

    // ============ DEBUG 输出（排查用，定位后可删除） ============
    output reg  [1:0]  dbg_rx_byte_cnt,   // 观察点1：接收字节计数有没有在动
    output reg         dbg_tx_start_en,   // 观察点2：有没有出现单周期启动脉冲
    output reg         dbg_current_state,
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
	localparam integer OPT_MEM_ADDR_BITS = 1;
	//----------------------------------------------
	//-- Signals for user logic register space example
	//------------------------------------------------
	//-- Number of Slave Registers 4
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg0;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg1;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg2;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg3;
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
	    end 
	  else begin
	    if (S_AXI_WVALID)
	      begin
	        case ( (S_AXI_AWVALID) ? S_AXI_AWADDR[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] : axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
	          2'h0:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 0
	                slv_reg0[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          2'h1:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 1
	                slv_reg1[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          2'h2:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 2
	                slv_reg2[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          2'h3:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 3
	                slv_reg3[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          default : begin
	                      slv_reg0 <= slv_reg0;
	                      slv_reg1 <= slv_reg1;
	                      slv_reg2 <= slv_reg2;
	                      slv_reg3 <= slv_reg3;
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
	  assign S_AXI_RDATA = (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 2'h0) ? slv_reg0 : (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 2'h1) ? slv_reg1 : (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 2'h2) ? slv_reg2 : (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 2'h3) ? slv_reg3 : 0; 
	// Add user logic here
parameter STATE_IDLE = 1'b0, STATE_TX =1'b1;
reg next_state;
    // 说明：原内部寄存器 current_state / rx_byte_cnt / tx_start_en
    // 已直接改名为上面的 dbg_* 输出端口，逻辑本身一行未改。

    // 内部计数器与寄存器
    reg [6:0]  clk_cnt;         // 用于计算单周期内 0 到 24 (共25个时钟周期)
    reg [2:0]  byte_tx_cnt;     // 当前发送到第几个字节 (0..5：标记+通道+4数据)

    // 接收控制寄存器
    reg [31:0] rx_shift_reg;    // 32位接收移位拼接寄存器
    reg [31:0] data_latch;      // 用于发送期间稳定锁存的 32 位数据
    reg [7:0]  ch_latch;        // 锁存的表头通道字节 {0,DAC[2:0],0,ADC[2:0]}
    reg [7:0]  ch_sampled;      // 采样瞬间(MCLK 拉高)的通道字节 —— 与本次样本对应
    reg        mclk_d;          // MCLK 打拍，用于上升沿检测
    localparam [7:0] HDR_MARKER = 8'hA5;  // 每个样本表头的同步标记字节

    // =================================================================
    // 0. 采样瞬间锁存通道号
    // MCLK 拉高的那一刻 LTC2500 才对模拟输入采样，此刻 mux 上的通道才是这一次
    // 样本真正的通道。但 IP_Three 的 cha_cnt 在 MCLK 下降沿就 +1 了
    // (myip_slave_lite_v1_0_S00_AXI.v)，而这一次的 32 位结果要 100 多个周期后
    // 才通过 o_eth_data 送到这里 —— 那时 adc_ch 早已指向下一个通道。
    // 所以必须在 MCLK 拉高时先把通道号存下来，等数据发送时再用。
    // 取上升沿而不是整个高电平期间：高电平有 3 个周期，若 dac_ch 恰在这期间翻转，
    // 按电平锁存会存到采样之后才生效的通道号。
    // =================================================================
    always @(posedge global_clk or negedge rst_n) begin
        if (!rst_n) begin
            mclk_d     <= 1'b0;
            ch_sampled <= 8'd0;
        end else begin
            mclk_d <= mclk;
            if (mclk && !mclk_d)
                ch_sampled <= {1'b0, dac_ch, 1'b0, adc_ch};
        end
    end

    // =================================================================
    // 1. 输入 8 位数据流拼接与组包块
    // =================================================================
    always @(posedge global_clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_shift_reg    <= 32'd0;
            dbg_rx_byte_cnt <= 2'd0;
            dbg_tx_start_en <= 1'b0;
        end else begin
            if (o_eth_valid) begin
                // 按照大端序（先收到的作为高字节）进行移位拼接
                rx_shift_reg <= {rx_shift_reg[23:0], o_eth_data};

                // 当收满第 4 个字节 (即 rx_byte_cnt == 3) 时，触发发送使能
                if (dbg_rx_byte_cnt == 2'd3) begin
                    dbg_rx_byte_cnt <= 2'd0;
                    dbg_tx_start_en <= 1'b1; // 激发发送标志
                end else begin
                    dbg_rx_byte_cnt <= dbg_rx_byte_cnt + 1'b1;
                    dbg_tx_start_en <= 1'b0;
                end
            end else begin
                dbg_tx_start_en <= 1'b0; // 保持单周期脉冲特性
            end
        end
    end

    // =================================================================
    // 2. 状态机次态逻辑 (由拼包完成信号 tx_start_en 触发)
    // =================================================================
    always @(*) begin
        case (dbg_current_state)
            STATE_IDLE: begin
                if (dbg_tx_start_en)
                    next_state = STATE_TX;
                else
                    next_state = STATE_IDLE;
            end
            STATE_TX: begin
                // 当 6 个字节（标记+通道+4数据）全部输出完毕时回到 IDLE
                if (byte_tx_cnt == 3'd5 && clk_cnt == 7'd24)
                    next_state = STATE_IDLE;
                else
                    next_state = STATE_TX;
            end
            default: next_state = STATE_IDLE;
        endcase
    end

    // =================================================================
    // 3. 状态机主时序逻辑与核心计数器
    // =================================================================
    always @(posedge global_clk or negedge rst_n) begin
        if (!rst_n) begin
            dbg_current_state <= STATE_IDLE;
            clk_cnt           <= 7'd0;
            byte_tx_cnt       <= 3'd0;
            data_latch        <= 32'd0;
            ch_latch          <= 8'd0;
        end else begin
            dbg_current_state <= next_state; // 状态正常跳转

            case (dbg_current_state)
                STATE_IDLE: begin
                    clk_cnt     <= 7'd0;
                    byte_tx_cnt <= 3'd0;
                    // 当检测到使能要往 TX 跳转时，在这一拍同时锁存数据与通道。
                    // 通道取 ch_sampled（本次转换 MCLK 时刻的值），不是当前的
                    // dac_ch/adc_ch —— 后者此时已是下一个通道，见上面第 0 节。
                    if (dbg_tx_start_en) begin
                        data_latch <= rx_shift_reg;
                        ch_latch   <= ch_sampled;
                    end
                end

                STATE_TX: begin
                    // 25分频主计数器自增
                    if (clk_cnt == 7'd24) begin
                        clk_cnt     <= 7'd0;
                        byte_tx_cnt <= byte_tx_cnt + 1'b1; // 切到下一个待发送字节
                    end else begin
                        clk_cnt     <= clk_cnt + 1'b1;
                    end
                end
            endcase
        end
    end

    // =================================================================
    // 4. 输出逻辑：clk_trg 的波形生成 (前20%为高，即 0-4 为高，5-24 为低)
    // =================================================================
    always @(posedge global_clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_trg <= 1'b0;
        end else begin
            if (dbg_current_state == STATE_TX && clk_cnt < 7'd5) begin
                clk_trg <= 1'b1;
            end else begin
                clk_trg <= 1'b0;
            end
        end
    end

    // =================================================================
    // 5. 输出逻辑：data_out 数据多路选择
    // =================================================================
    always @(posedge global_clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 8'd0;
        end else begin
            if (dbg_current_state == STATE_TX) begin
                case (byte_tx_cnt)
                    3'd0: data_out <= HDR_MARKER;          // 表头同步标记 0xA5
                    3'd1: data_out <= ch_latch;            // {0,DAC,0,ADC} 通道字节
                    3'd2: data_out <= data_latch[31:24];
                    3'd3: data_out <= data_latch[23:16];
                    3'd4: data_out <= data_latch[15:8];
                    3'd5: data_out <= data_latch[7:0];
                    default: data_out <= 8'd0;
                endcase
            end else begin
                data_out <= 8'd0; // 空闲状态输出清零
            end
        end
    end
	// User logic ends

	endmodule
