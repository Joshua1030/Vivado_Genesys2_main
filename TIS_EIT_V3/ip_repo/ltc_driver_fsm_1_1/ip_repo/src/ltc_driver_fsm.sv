module ltc_driver_fsm #(
    parameter int DATA_WIDTH = 32,
    parameter int ETH_DATA_WIDTH = 8,
    parameter int CLK_FREQ   = 100_000_000, // 100 M
    parameter int DF         = 64           // Down-Sampling Factor
)(
    input  wire i_clk, 
    input  wire i_rst_n,
    input  wire i_start,
    
    // Control Signals
    output logic o_mclk,
    output logic o_sync, 
    output logic o_pre,
    input  wire  i_busy,
    input  wire  i_drl,
    
    // SPI signals
    output logic o_sdi,
    output logic o_sckb,
    output logic o_rdlb,
    input  wire  i_sdob,
    
    output logic [3:0] o_debug_state,

    output logic [DATA_WIDTH-1:0] o_read_data,
    output logic [ETH_DATA_WIDTH-1:0] o_eth_data,
    output logic o_eth_valid,
    output logic o_data_valid,
    output logic o_error
);

localparam int CYCLES_MCLKH = 3;
localparam int CYCLES_MCLKL = 2;
// STATE_QUIET 的长度：RDLB 拉低之后、第一次采 SDO 之前的等待。
// RDLB 下降沿到第一次采样的间隔 = (CYCLES_QUIET-1) + SCK_DIV 个时钟。
// MSB(OV 位) 是靠 RDLB 下降沿推出来的，不是靠 SCK，所以它单独吃这一段预算；
// 后面每一位吃的是一个完整 SCK 周期(SCK_DIV*2 个时钟)。
// 原来 CYCLES_QUIET 和 CYCLES_MCLKL 共用 =2 -> 间隔只有 3 个时钟(30ns)，
// 比每一位的 40ns 预算还紧：仿真里回路延时 >=30ns 就只丢 OV(bit31)、
// 差分位全对 —— 这很可能就是历来 OV 恒为 0 的原因之一。
// 取 4 -> 间隔 5 个时钟(50ns) > 40ns，OV 不再是最紧的那一环。代价 2 个时钟。
localparam int CYCLES_QUIET = 4;
localparam int CYCLES_CONV  = 75; 
localparam int CYCLES_ACQ   = 35; 
// SCLK = 100MHz/(2*SCK_DIV)。SCK_DIV=2 -> 25MHz，读出 32bit 约 128 clk。
// !!! 必须保持 >= 2，不要再改回 1 !!!
// shift_reg 是在“驱动 SCK 上升沿的那一个内部时钟沿”上采 i_sdob 的（见下方
// STATE_READ_DATA / sck_posedge），采到的是上一个 SCK 上升沿推出来的那一位。
// 于是整个回路——FPGA Tco + FMC 排线 + LTC2500 t_dSDO + 回程 + 输入建立——
// 必须塞进【一个 SCK 周期】：
//     SCK_DIV=2 (25MHz) -> 预算 40ns，实测回路约 21~31ns，正常；
//     SCK_DIV=1 (50MHz) -> 预算 20ns，回路超时，每一位都晚采一位：
//                          bit30 变成 OV 位的副本，24 位差分的符号位丢失，
//                          负数全部变成大正数。硬件实测，见 commit 9171e13。
// i_sdob/o_sckb 在 constraints/Genesys-2-Master.xdc 里只有引脚和电平约束，
// 没有 set_input_delay/set_output_delay —— 这条路径根本没被时序分析覆盖，
// 改快了 Vivado 一句警告都不会给。
localparam int SCK_DIV      = 2;

typedef enum logic [3:0] { 
    STATE_IDLE,
    STATE_START,
    STATE_WAIT_BUSY,
    STATE_ACQUIRE,     
    STATE_WAIT_DRL,
    STATE_QUIET,
    STATE_READ_DATA,
    STATE_READ_DONE,
    STATE_SEND_ETH,
    STATE_STOP,
    STATE_ERROR 
} state_t; 

state_t state, next_state;

assign o_debug_state = state;

logic [31:0] shift_reg;
logic bit_en, bit_clr;
logic delay_en, delay_clr;
logic eth_byte_en, eth_byte_clr;
logic [5:0] bit_cnt;
logic [7:0] delay_cnt;
logic [2:0] eth_byte_cnt;

logic [6:0] mclk_cnt;
logic mclk_cnt_en, mclk_cnt_clr;

logic next_mclk;
logic next_rdlb;
logic next_data_valid;
logic next_error;

assign o_sync = 1'b0;
assign o_pre  = 1'b1; 
assign o_sdi  = 1'b0;

logic sck_en;
logic [3:0] sck_cnt;

logic next_eth_valid;
logic [7:0] next_eth_data;

always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (~i_rst_n) begin
        o_sckb  <= 1'b0;
        sck_cnt <= '0;
    end else begin
        if (sck_en) begin
            if (sck_cnt == SCK_DIV - 1) begin
                sck_cnt <= '0;
                o_sckb  <= ~o_sckb;
            end else begin
                sck_cnt <= sck_cnt + 1'b1;
            end
        end
        else begin
            o_sckb  <= 1'b0;
            sck_cnt <= '0;
        end
    end
end 

wire sck_posedge = sck_en && (sck_cnt == SCK_DIV - 1) && (o_sckb == 1'b0);
wire sck_negedge = sck_en && (sck_cnt == SCK_DIV - 1) && (o_sckb == 1'b1);

logic busy_sync, drl_sync;

cdc_sync_edge #(.INIT_VAL(1'b0)) cdc_sync_edge_inst1 (
    .i_clk(i_clk), .i_rst_n(i_rst_n), .async_in(i_busy), .sync_out(busy_sync)
);

cdc_sync_edge #(.INIT_VAL(1'b1)) cdc_sync_edge_inst2 (
    .i_clk(i_clk), .i_rst_n(i_rst_n), .async_in(i_drl), .sync_out(drl_sync)
);

logic busy_sync_d, drl_sync_d;
always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (~i_rst_n) begin 
        busy_sync_d <= 1'b0;
        drl_sync_d  <= 1'b1;
    end else begin
        busy_sync_d <= busy_sync;
        drl_sync_d  <= drl_sync; 
    end
end

wire negedge_busy = busy_sync_d & ~busy_sync;
wire negedge_drl  = drl_sync_d  & ~drl_sync;

// ----------------------------------------------------
// Data Path Counters
// ----------------------------------------------------
always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (~i_rst_n)          delay_cnt <= '0;
    else if (delay_clr)    delay_cnt <= '0;
    else if (delay_en)     delay_cnt <= delay_cnt + 1'b1;
end

always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (~i_rst_n)          bit_cnt <= '0;
    else if (bit_clr)      bit_cnt <= '0;
    else if (bit_en)       bit_cnt <= bit_cnt + 1'b1;
end

always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (~i_rst_n)          eth_byte_cnt <= '0;
    else if (eth_byte_clr) eth_byte_cnt <= '0;
    else if (eth_byte_en)  eth_byte_cnt <= eth_byte_cnt + 1'b1;
end

always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (~i_rst_n)          mclk_cnt <= '0;
    else if (mclk_cnt_clr) mclk_cnt <= '0;
    else if (mclk_cnt_en)  mclk_cnt <= mclk_cnt + 1'b1;
end 

always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (~i_rst_n) begin
        shift_reg <= '0;
    end else if (state == STATE_READ_DATA && sck_posedge) begin
        shift_reg <= {shift_reg[30:0], i_sdob}; 
    end
end

always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (~i_rst_n) begin 
        o_eth_data  <= '0;
        o_eth_valid <= 1'b0;
    end else begin
        o_eth_data  <= next_eth_data;
        o_eth_valid <= next_eth_valid;
    end
end

always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (~i_rst_n) begin
        state        <= STATE_IDLE;
        o_mclk       <= 1'b0;
        o_rdlb       <= 1'b1;
        o_data_valid <= 1'b0;
        o_error      <= 1'b0;
    end else begin
        state        <= next_state;
        o_mclk       <= next_mclk;
        o_rdlb       <= next_rdlb;
        o_data_valid <= next_data_valid;
        o_error      <= next_error;
    end
end

always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (~i_rst_n) begin
        o_read_data <= '0;
    end else if (state == STATE_READ_DONE) begin
        o_read_data <= shift_reg;
    end
end

always_comb begin
    next_state      = state;
    next_mclk       = o_mclk;
    next_rdlb       = o_rdlb;
    next_data_valid = 1'b0;
    next_eth_valid  = 1'b0;
    next_eth_data   = o_eth_data;
    next_error      = o_error;

    sck_en       = 1'b0;
    delay_en     = 1'b0;
    delay_clr    = 1'b0;
    bit_en       = 1'b0;
    bit_clr      = 1'b0;
    eth_byte_en  = 1'b0;
    eth_byte_clr = 1'b0;
    mclk_cnt_en  = 1'b0;
    mclk_cnt_clr = 1'b0;

    case (state)
        STATE_IDLE: begin
            next_mclk = 1'b0;
            next_rdlb = 1'b1;
            delay_clr = 1'b1;
            bit_clr   = 1'b1;
            mclk_cnt_clr = 1'b1; 
            
            if (i_start) begin
                next_state = STATE_START;
                next_error = 1'b0;
            end
        end

        STATE_START: begin
            next_mclk = 1'b1;
            delay_en  = 1'b1;
            if (delay_cnt == CYCLES_MCLKH - 1) begin 
                next_state = STATE_WAIT_BUSY;
                next_mclk  = 1'b0;
                delay_clr  = 1'b1;
            end
        end
        
        STATE_WAIT_BUSY: begin
            delay_en = 1'b1;
            if (negedge_busy) begin
                mclk_cnt_en = 1'b1;
                delay_clr   = 1'b1;
                
              
//                if (mclk_cnt == DF - 1) begin 
                if (1) begin //skip Down sampling
                    next_state = STATE_WAIT_DRL; // Sent 64 MCLK
                end else begin
                    next_state = STATE_ACQUIRE; 
                end
            end
            else if (delay_cnt == CYCLES_CONV) begin 
                next_error = 1'b1;
                next_state = STATE_ERROR;
            end
        end

        STATE_ACQUIRE: begin
            delay_en = 1'b1;
            if (delay_cnt >= CYCLES_ACQ - 1) begin
                next_state = STATE_START;
                delay_clr  = 1'b1;
            end
        end

        STATE_WAIT_DRL: begin
            if (~drl_sync) begin
                next_state = STATE_QUIET;
                delay_clr  = 1'b1;
            end
        end

        STATE_QUIET: begin
            next_rdlb = 1'b0;
            delay_en  = 1'b1;
            if (delay_cnt >= CYCLES_QUIET - 1) begin
                next_state = STATE_READ_DATA;
                delay_clr  = 1'b1;
            end
        end

        STATE_READ_DATA: begin
            next_rdlb = 1'b0; 
            sck_en    = 1'b1;
            bit_en    = sck_posedge; 

            if (bit_cnt == 6'd32) begin
                next_state = STATE_READ_DONE;
                sck_en     = 1'b0;
                delay_clr  = 1'b1;
            end
        end

        STATE_READ_DONE: begin
            next_data_valid = 1'b1;
            eth_byte_clr    = 1'b1;
            next_state      = STATE_SEND_ETH;
        end
        
        STATE_SEND_ETH: begin
            eth_byte_en = 1'b1;
            
            next_eth_valid = ~eth_byte_cnt[0];

            case(eth_byte_cnt[2:1])
                2'b00: next_eth_data = shift_reg[31:24]; // count = 0, 1
                2'b01: next_eth_data = shift_reg[23:16]; // count = 2, 3
                2'b10: next_eth_data = shift_reg[15:8];  // count = 4, 5
                2'b11: next_eth_data = shift_reg[7:0];   // count = 6, 7
                default: next_eth_data = '0;
            endcase 

            if (eth_byte_cnt == 3'd7) begin
                eth_byte_en = 1'b0;
                next_state = STATE_STOP;
                eth_byte_clr = 1'b1;
            end
        end

        STATE_STOP: begin
            delay_en = 1'b1;       
            if (delay_cnt >= CYCLES_MCLKL - 1) begin
                next_state      = STATE_IDLE;
                delay_clr       = 1'b1;
            end    
        end

        STATE_ERROR: begin
            next_state = STATE_IDLE; 
        end

        default: next_state = STATE_IDLE;
    endcase
end

endmodule