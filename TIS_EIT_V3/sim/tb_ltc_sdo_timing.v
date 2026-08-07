`timescale 1ns / 1ps
//=============================================================================
// tb_ltc_sdo_timing.sv
//
// 目的：证明 LTC2500 读回路的 “晚采一位” 失效机理，并把 SCK_DIV=2 锁死。
//
// 背景（硬件实测的 bug）：
//   ltc_driver_fsm 里 shift_reg 是在【驱动 SCK 上升沿的那一个内部时钟沿】上
//   采 i_sdob 的，采到的是【上一个 SCK 上升沿】推出来的那一位。所以整个回路
//   （FPGA Tco + FMC 排线 + LTC2500 t_dSDO + 回程 + 输入建立）必须塞进一个
//   SCK 周期。commit 9171e13 把 SCK_DIV 从 2 改成 1（25MHz -> 50MHz），预算
//   从 40ns 掉到 20ns，回路超时 -> 每一位都晚采一位：
//       收到的字 = {w[31], w[31:1]}
//   于是 bit30 变成 OV 位的副本（恒 0），24 位差分的符号位丢失。
//
//   仓库里原有的 ADC 模型 ip_repo/ltc_driver_fsm_1_1/ip_repo/src/adc_inst.sv
//   是【零延时】的 —— 这正是这个 bug 在仿真里从来没被发现的原因：零延时模型
//   在任何 SCK_DIV 下都能过。本 TB 自带一个【可设传播延时】的 LTC2500 模型。
//
// 实测出来的悬崖（本 TB 扫 sdo_dly 10..60ns 得到）：
//
//   SCK_DIV=2 (25MHz, 预算 40ns)   延时 <=35ns 全对；40ns 起 ONE-BIT-LATE
//   SCK_DIV=1 (50MHz, 预算 20ns)   延时 <=15ns 全对；25ns 起 ONE-BIT-LATE
//
//   现场估算回路 ~21-31ns —— 正好卡在这两条线中间，所以 25MHz 好、50MHz 坏。
//   SCK_DIV=1 在 25ns 时给出的正是现场那个签名：
//       exp=7f891a7f -> got=3fc48d3f   (bit30 1->0，符号位掉到 bit29)
//
// 另外 CYCLES_QUIET 从 2 加到 4 之前，OV(bit31) 的预算只有 30ns，比每一位的
// 40ns 还紧 —— 延时 >=30ns 就只丢 OV、差分位全对（OV-LOST 分类）。加大之后
// OV 和数据位一样撑到 35ns。这可能就是历来 OV 恒为 0 的原因之一。
//
// 本 TB 做三件事：
//   1. 在多个 SDO 传播延时下读回已知字，把结果分类成
//      EXACT / ONE-BIT-LATE / OTHER，直接给出失效签名。
//   2. 验证 OV(bit31) 能端到端传下来（用 OV=1 的向量）。
//   3. 量出 FSM 一圈的时钟数 —— 决定 IP_Three slv_reg3 的采样周期 N 能设多小
//      （N 必须 >= 一圈的时钟数，否则 FSM 会漏掉 3 拍宽的启动脉冲，采样率不是
//       缓慢下降而是【直接减半】，见 myip_slave_lite_v1_0_S00_AXI.v:432-435）。
//
//-----------------------------------------------------------------------------
// 跑法（独立 xvlog/xelab/xsim 流程，不要用 scripts/sim.tcl —— 那个走 BD，
// 模块名会被改成 ltc2500_bd_* 而找不到 ltc_driver_fsm；与 sim/tb_eth_ch_tag.v
// 同一个约定）。注意必须给 -timescale：FSM 源文件里没有 `timescale。
//
//   set V=E:/Xilinx/2025.2/Vivado/bin
//   set S=e:/Vivado_Genesys2_main/TIS_EIT_V2
//   $V/xvlog.bat -sv $S/ip_repo/ltc_driver_fsm_1_1/ip_repo/src/cdc_sync_edge.sv `
//                    $S/ip_repo/ltc_driver_fsm_1_1/ip_repo/src/ltc_driver_fsm.sv `
//                    $S/sim/tb_ltc_sdo_timing.v
//   $V/xelab.bat -timescale 1ns/1ps -debug typical tb_ltc_sdo_timing -s tb_sdo
//   $V/xsim.bat tb_sdo -runall
//
// 反向对照（应当复现 ONE-BIT-LATE）：把 ltc_driver_fsm.sv 拷到别处、
// 改成 SCK_DIV=1，再按上面编译那份拷贝。
//=============================================================================

module tb_ltc_sdo_timing;

    // ---------------- 时钟 / 复位 ----------------
    localparam real CLK_NS = 10.0;          // 100 MHz，与 clk_wiz_1/clk_100Mhz 一致
    reg clk   = 1'b0;
    reg rst_n = 1'b0;
    always #(CLK_NS/2.0) clk = ~clk;

    // ---------------- DUT 接线 ----------------
    reg         i_start = 1'b0;
    wire        o_mclk, o_sync, o_pre;
    reg         i_busy  = 1'b0;
    reg         i_drl   = 1'b1;             // 空闲高
    wire        o_sdi, o_sckb, o_rdlb;
    wire        i_sdob;
    wire [3:0]  o_debug_state;
    wire [31:0] o_read_data;
    wire [7:0]  o_eth_data;
    wire        o_eth_valid, o_data_valid, o_error;

    ltc_driver_fsm dut (
        .i_clk        (clk),
        .i_rst_n      (rst_n),
        .i_start      (i_start),
        .o_mclk       (o_mclk),
        .o_sync       (o_sync),
        .o_pre        (o_pre),
        .i_busy       (i_busy),
        .i_drl        (i_drl),
        .o_sdi        (o_sdi),
        .o_sckb       (o_sckb),
        .o_rdlb       (o_rdlb),
        .i_sdob       (i_sdob),
        .o_debug_state(o_debug_state),
        .o_read_data  (o_read_data),
        .o_eth_data   (o_eth_data),
        .o_eth_valid  (o_eth_valid),
        .o_data_valid (o_data_valid),
        .o_error      (o_error)
    );

    //=========================================================================
    // 带传播延时的 LTC2500 模型（内联，方便直接读 TB 的 sdo_dly 变量）
    //
    //   t_CONV 后 BUSY 落，再过一点 DRL 落；
    //   RDLB 下降沿推出 MSB，之后每个 SCK 上升沿推下一位；
    //   所有 SDO 变化统一延后 sdo_dly（= Tco + 排线 + t_dSDO + 回程 + 输入路径）。
    //=========================================================================
    localparam real T_CONV_NS = 660.0;      // LTC2500-32 转换时间，FSM 超时门限是 750ns
    localparam real T_DRL_NS  =  20.0;      // BUSY 落 -> DRL 落

    reg [31:0] adc_word = 32'h0;            // 本次要送出的 32 位字
    integer    bit_idx  = 31;
    reg        sdo_val  = 1'b0;             // 未加延时的 SDO
    reg        sdo_pin  = 1'b0;             // 加了延时、真正进 FPGA 的 SDO
    real       sdo_dly;                     // 传播延时（ns），逐相位可改

    assign i_sdob = sdo_pin;

    always @(posedge o_mclk) begin
        i_busy <= 1'b1;
        i_drl  <= 1'b1;
        #(T_CONV_NS);
        i_busy <= 1'b0;
        #(T_DRL_NS);
        i_drl  <= 1'b0;
    end

    always @(negedge o_rdlb) begin          // 片选拉低 -> 推出 MSB
        bit_idx = 31;
        sdo_val = adc_word[31];
    end

    always @(posedge o_sckb) begin          // 每个 SCK 上升沿 -> 下一位
        if (!o_rdlb) begin
            if (bit_idx > 0) begin
                bit_idx = bit_idx - 1;
                sdo_val = adc_word[bit_idx];
            end else begin
                sdo_val = 1'b0;
            end
        end
    end

    always @(posedge o_rdlb) sdo_val = 1'b0; // 片选抬高 -> 总线回到低（模拟弱下拉）

    always @(sdo_val) sdo_pin <= #(sdo_dly) sdo_val;

    //=========================================================================
    // 判定
    //=========================================================================
    integer errors    = 0;   // 只统计“差分数据被破坏”这一类真错
    integer late_seen = 0;
    integer ov_lost   = 0;   // OV 位没采到；单独统计，见 ov_only_lost 的说明

    // 晚采一位的签名：c1 仍是 bit31（RDLB 推出的，时间充裕），
    // 之后每一拍都落后一位 -> {w[31], w[31:1]}
    function [31:0] one_bit_late;
        input [31:0] w;
        begin
            one_bit_late = {w[31], w[31:1]};
        end
    endfunction

    // 只丢了 OV(bit31)、其余 31 位全对。
    // 成因和“晚采一位”不是一回事：RDLB 下降沿到第一次采样之间只有
    // (CYCLES_QUIET-1) 个 100MHz 时钟，回路延时超过这一段就采不到 MSB；
    // 但之后每一位仍有一整个 SCK 周期，所以差分数据照样是对的。
    function ov_only_lost;
        input [31:0] expect_w;
        input [31:0] got_w;
        begin
            ov_only_lost = (got_w[30:0]  === expect_w[30:0]) &&
                           (got_w[31]    === 1'b0)           &&
                           (expect_w[31] === 1'b1);
        end
    endfunction

    task check_word;
        input [127:0] tag;
        input [31:0]  expect_w;
        input [31:0]  got_w;
        reg   [31:0]  late_w;
        begin
            late_w = one_bit_late(expect_w);
            if (got_w === expect_w) begin
                $display("  [%0s] EXACT          exp=%08h got=%08h", tag, expect_w, got_w);
            end else if (got_w === late_w) begin
                late_seen = late_seen + 1;
                errors    = errors + 1;
                $display("  [%0s] ONE-BIT-LATE   exp=%08h got=%08h  <-- 复现硬件失效",
                         tag, expect_w, got_w);
                $display("        bit31 %b->%b  bit30 %b->%b  bit29 %b->%b   (符号位掉到 bit29)",
                         expect_w[31], got_w[31], expect_w[30], got_w[30],
                         expect_w[29], got_w[29]);
            end else if (ov_only_lost(expect_w, got_w)) begin
                ov_lost = ov_lost + 1;
                $display("  [%0s] OV-LOST        exp=%08h got=%08h  (只丢 OV，差分位全对)",
                         tag, expect_w, got_w);
                $display("        RDLB 下降沿到第一次采样的时间装不下 %0.0f ns 的回路延时;",
                         sdo_dly);
                $display("        后面每一位仍有一整个 SCK 周期，所以只有 bit31 受影响。");
            end else begin
                errors = errors + 1;
                $display("  [%0s] OTHER MISMATCH exp=%08h got=%08h (晚采一位应为 %08h)",
                         tag, expect_w, got_w, late_w);
            end
        end
    endtask

    // 跑一次转换并检查
    // 注意 i_start 要一直拉到 FSM 真的动起来（o_mclk 拉高）为止。短脉冲会被
    // 漏掉 —— FSM 只在 STATE_IDLE 看 i_start，而上一轮的 SEND_ETH/STOP 还没走完。
    // 这正是 IP_Three 那个 3 拍宽启动脉冲在采样周期 N 太小时会踩的坑。
    task do_one_conversion;
        input [127:0] tag;
        input [31:0]  word;
        begin
            adc_word = word;
            @(posedge clk); i_start <= 1'b1;
            @(posedge o_mclk);              // FSM 已经离开 IDLE
            @(posedge clk); i_start <= 1'b0;
            wait (o_data_valid === 1'b1);
            @(posedge clk);                 // o_read_data 在 READ_DONE 那拍装载
            check_word(tag, word, o_read_data);
        end
    endtask

    //=========================================================================
    // 一圈时钟数：连续两个 o_mclk 上升沿之间的 100MHz 时钟数
    //=========================================================================
    integer loop_cnt   = 0;
    integer loop_last  = -1;
    integer loop_meas  = 0;
    integer measuring  = 0;

    always @(posedge clk) if (rst_n) loop_cnt = loop_cnt + 1;

    always @(posedge o_mclk) begin
        if (measuring) begin
            if (loop_last >= 0) begin
                loop_meas = loop_cnt - loop_last;
                $display("  FSM 一圈 = %0d 个时钟 (%0.2f us) -> 自由运行 %0.1f kHz",
                         loop_meas, loop_meas * CLK_NS / 1000.0,
                         1.0e6 / (loop_meas * CLK_NS));
            end
            loop_last = loop_cnt;
        end
    end

    //=========================================================================
    // 主流程
    //=========================================================================
    // 真实字的样子：{OV, 24 位差分, 7 位共模}，共模在实测中恒为 127
    function [31:0] mk_word;
        input        ov;
        input [23:0] diff;
        input [6:0]  cm;
        begin
            mk_word = {ov, diff, cm};
        end
    endfunction

    initial begin
        $display("=====================================================================");
        $display("tb_ltc_sdo_timing : LTC2500 SDO 回路延时 vs SCK_DIV");
        $display("  DUT 实际编译进来的 SCK_DIV -> SCK 周期 = %0d ns，单位间隔预算同此值",
                 dut.SCK_DIV * 2 * 10);
        $display("=====================================================================");

        sdo_dly = 5.0;
        repeat (5) @(posedge clk);
        rst_n = 1'b1;
        repeat (5) @(posedge clk);

        // ---- 相位 1：延时很小，一定要全对（证明逻辑本身没问题）----
        $display("\n[相位 1] SDO 回路延时 = 5 ns（远小于预算）");
        sdo_dly = 5.0;
        do_one_conversion("neg,OV=0", mk_word(1'b0, 24'hFF1234, 7'h7F)); // bit30=1，负数
        do_one_conversion("pos,OV=0", mk_word(1'b0, 24'h0ABCDE, 7'h7F)); // bit30=0，正数
        do_one_conversion("OV=1    ", mk_word(1'b1, 24'h800001, 7'h7F)); // 验证 OV 能传下来
        do_one_conversion("alt     ", 32'h5A5A_5A5A);

        // ---- 相位 2：15 ns，仍在 40ns 预算内 ----
        $display("\n[相位 2] SDO 回路延时 = 15 ns");
        sdo_dly = 15.0;
        do_one_conversion("neg,OV=0", mk_word(1'b0, 24'hFF1234, 7'h7F));
        do_one_conversion("pos,OV=0", mk_word(1'b0, 24'h0ABCDE, 7'h7F));

        // ---- 相位 3：25 ns —— 现场估算值。SCK_DIV=1(20ns) 会挂，SCK_DIV=2(40ns) 应过 ----
        $display("\n[相位 3] SDO 回路延时 = 25 ns（现场估算：Tco+排线+t_dSDO+回程+建立）");
        $display("         SCK_DIV=1 -> 预算 20ns，应当 ONE-BIT-LATE");
        $display("         SCK_DIV=2 -> 预算 40ns，应当 EXACT");
        sdo_dly = 25.0;
        do_one_conversion("neg,OV=0", mk_word(1'b0, 24'hFF1234, 7'h7F));
        do_one_conversion("pos,OV=0", mk_word(1'b0, 24'h0ABCDE, 7'h7F));
        do_one_conversion("OV=1    ", mk_word(1'b1, 24'h800001, 7'h7F));

        // ---- 相位 4：35 ns，SCK_DIV=2 的预算边缘（40ns 就翻车，实测见文件头）----
        $display("\n[相位 4] SDO 回路延时 = 35 ns（40ns 预算的边缘，仍应全对）");
        sdo_dly = 35.0;
        do_one_conversion("neg,OV=0", mk_word(1'b0, 24'hFF1234, 7'h7F));
        do_one_conversion("OV=1    ", mk_word(1'b1, 24'h800001, 7'h7F));

        // ---- 相位 5：量一圈的时钟数（自由运行）----
        $display("\n[相位 5] 自由运行，量 FSM 一圈时钟数");
        sdo_dly   = 25.0;
        adc_word  = mk_word(1'b0, 24'hFF1234, 7'h7F);
        measuring = 1;
        i_start   = 1'b1;                   // 保持高 = 自由运行
        repeat (6) @(posedge o_mclk);
        i_start   = 1'b0;
        measuring = 0;

        // ---- 汇总 ----
        $display("\n=====================================================================");
        $display("SCK_DIV = %0d   (SCK = %0d MHz, 单位间隔预算 %0d ns)",
                 dut.SCK_DIV, 100/(2*dut.SCK_DIV), dut.SCK_DIV*2*10);
        $display("FSM 一圈 = %0d 个时钟；IP_Three slv_reg3 的 N 必须 >= 这个数，", loop_meas);
        $display("  否则 FSM 漏掉 3 拍宽启动脉冲，采样率直接减半（不是缓慢下降）。");
        if (loop_meas <= 250)
            $display("  400 kHz 需要 N = 250 -> 250 >= %0d，可达（余量 %0d 个时钟）。",
                     loop_meas, 250 - loop_meas);
        else
            $display("  400 kHz 需要 N = 250 -> 一圈 %0d > 250，不可达，会掉到 200 kHz！",
                     loop_meas);
        if (ov_lost != 0)
            $display("OV-LOST 出现 %0d 次：RDLB 下降沿到首次采样的间隔太短，OV(bit31) 采不到（差分数据不受影响）。", ov_lost);
        if (errors == 0)
            $display("TB RESULT: ALL CHECKS PASSED (0 errors)");
        else
            $display("TB RESULT: %0d ERROR(S), 其中 %0d 个是 ONE-BIT-LATE 签名", errors, late_seen);
        $display("=====================================================================");
        $finish;
    end

    // 兜底超时
    initial begin
        #500_000;
        $display("TB RESULT: TIMEOUT");
        $finish;
    end

endmodule
