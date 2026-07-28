`timescale 1ns / 1ps
// ============================================================================
// tb_scan_chain.v — self-checking testbench for the EIT scan-IP chain
//
// Verifies the sine-cycle sequencer + mux controllers WITHOUT the MicroBlaze:
//   IP_1     (module IP_1)   — rollover cycle_done -> done_tick / chanel_cnt /
//                              total_tick / dac_cnt / dac_ch_sel / sync
//   IP_Two   (module IP_Two) — DAC source mux, latches on done_tick
//   IP_Three (module myip)   — ADC sense mux, cycle-paced advance on done_tick
//
// addr_gen and the FSM are MODELLED here (addr_gen shares module names with
// IP_Three, and modelling gives exact control of the ramp IP_1 must detect):
//   * clk_A..D  : active-low per-channel strobes like the FSM (clk_C low when
//                 the DAC frame is on channel C); accumulators advance on negedge.
//   * DDS ch C  : acc_C += PHASE_STEP_C on negedge clk_C; lut_addr_C = acc_C[15:0],
//                 forced to 0 while IP_1.sync is high (mirrors addr_gen dds_sync).
//   * o_mclk    : a free ADC-conversion strobe for IP_Three's edge detector.
//
// Config registers are applied by hierarchical `force` (the sim equivalent of
// the MCU having written them) — no AXI master needed. Pure-Verilog DUTs, so it
// runs in behavioral XSim with no license.
//
// Run (standalone XSim, from TIS_EIT_V2/):
//   xvlog ip_repo/IP_1_1_0/hdl/IP_1.v ip_repo/IP_1_1_0/hdl/IP_1_slave_lite_v1_0_S00_AXI.v \
//         ip_repo/IP_Two_1_0/hdl/IP_Two.v ip_repo/IP_Two_1_0/hdl/IP_Two_slave_lite_v1_0_S00_AXI.v \
//         ip_repo/IP_Three_1_0/hdl/myip.v ip_repo/IP_Three_1_0/hdl/myip_slave_lite_v1_0_S00_AXI.v \
//         sim/tb_scan_chain.v
//   xelab -debug typical tb_scan_chain -s tb_scan_sim
//   xsim tb_scan_sim -runall
// ============================================================================

module tb_scan_chain;

    // ---------------- config knobs ----------------
    localparam integer FRAME_STEP   = 100;      // ns between DAC channel slots
    localparam [31:0]  PHASE_STEP_C = 32'd8192; // 65536/8192 = 8 acc steps per sine period
    localparam integer N_CYC        = 1;        // IP_1 cycles-per-channel (slv_reg1)
    localparam integer RUN_NS       = 300000;   // total sim time

    // ---------------- clock / reset ----------------
    reg clk_100 = 1'b0;
    reg aresetn = 1'b0;
    always #5 clk_100 = ~clk_100;               // 100 MHz

    // ---------------- modelled FSM strobes clk_A..D ----------------
    reg [1:0] dac_slot = 2'd0;                  // which channel the DAC frame is on
    reg clk_A = 1'b1, clk_B = 1'b1, clk_C = 1'b1, clk_D = 1'b1;
    always begin
        #FRAME_STEP;
        dac_slot = dac_slot + 2'd1;             // 0->1->2->3->0...
        clk_A = (dac_slot != 2'd0);
        clk_B = (dac_slot != 2'd1);
        clk_C = (dac_slot != 2'd2);             // clk_C falls when slot==2 (one negedge per DAC frame)
        clk_D = (dac_slot != 2'd3);
    end

    // ---------------- modelled DDS channel C (mirrors addr_gen) ----------------
    reg  [31:0] acc_C      = 32'd0;
    reg  [15:0] lut_addr_C = 16'd0;
    wire        ip1_sync;                        // IP_1 sync output = addr_gen dds_sync

    always @(negedge clk_C or negedge aresetn) begin
        if (!aresetn) acc_C <= 32'd0;
        else          acc_C <= acc_C + PHASE_STEP_C;
    end
    always @(posedge clk_100 or negedge aresetn) begin
        if (!aresetn)      lut_addr_C <= 16'd0;
        else if (ip1_sync) lut_addr_C <= 16'd0;  // sync re-zeros the phase each cycle
        else               lut_addr_C <= acc_C[15:0];
    end

    // ---------------- modelled ADC conversion strobe ----------------
    reg o_mclk = 1'b0;
    always #500 o_mclk = ~o_mclk;               // 1 MHz-ish; unused for cha_cnt in cycle-paced mode

    // ---------------- DUT interconnect ----------------
    wire        done_tick, total_tick, ip1_enable;
    wire [2:0]  chanel_cnt, dac_ch_sel;
    wire [2:0]  mux1, mux2;
    wire [2:0]  adc_ch;

    // ---------------- IP_1 (module IP_1) ----------------
    IP_1 #(.C_S00_AXI_DATA_WIDTH(32), .C_S00_AXI_ADDR_WIDTH(7)) u_ip1 (
        .clk(clk_100), .rst_n(aresetn),
        .address(lut_addr_C), .CLK_A(clk_C),
        .done_tick(done_tick), .total_tick(total_tick),
        .chanel_cnt(chanel_cnt), .sync(ip1_sync), .enable(ip1_enable),
        .dac_ch_sel(dac_ch_sel),
        .s00_axi_aclk(clk_100), .s00_axi_aresetn(aresetn),
        .s00_axi_awaddr(7'd0), .s00_axi_awprot(3'd0), .s00_axi_awvalid(1'b0), .s00_axi_awready(),
        .s00_axi_wdata(32'd0), .s00_axi_wstrb(4'd0), .s00_axi_wvalid(1'b0), .s00_axi_wready(),
        .s00_axi_bresp(), .s00_axi_bvalid(), .s00_axi_bready(1'b0),
        .s00_axi_araddr(7'd0), .s00_axi_arprot(3'd0), .s00_axi_arvalid(1'b0), .s00_axi_arready(),
        .s00_axi_rdata(), .s00_axi_rresp(), .s00_axi_rvalid(), .s00_axi_rready(1'b0)
    );

    // ---------------- IP_Two (module IP_Two) — DAC source mux ----------------
    IP_Two #(.C_S00_AXI_DATA_WIDTH(32), .C_S00_AXI_ADDR_WIDTH(7)) u_ip2 (
        .clk(clk_100), .rst_n(aresetn),
        .done_tick(done_tick), .total_tick(total_tick), .cha_cnt(dac_ch_sel),
        .mux1(mux1), .mux2(mux2), .EIT_IN_EN(), .gain(), .reset(),
        .s00_axi_aclk(clk_100), .s00_axi_aresetn(aresetn),
        .s00_axi_awaddr(7'd0), .s00_axi_awprot(3'd0), .s00_axi_awvalid(1'b0), .s00_axi_awready(),
        .s00_axi_wdata(32'd0), .s00_axi_wstrb(4'd0), .s00_axi_wvalid(1'b0), .s00_axi_wready(),
        .s00_axi_bresp(), .s00_axi_bvalid(), .s00_axi_bready(1'b0),
        .s00_axi_araddr(7'd0), .s00_axi_arprot(3'd0), .s00_axi_arvalid(1'b0), .s00_axi_arready(),
        .s00_axi_rdata(), .s00_axi_rresp(), .s00_axi_rvalid(), .s00_axi_rready(1'b0)
    );

    // ---------------- IP_Three (module myip) — ADC sense mux ----------------
    myip #(.C_S00_AXI_DATA_WIDTH(32), .C_S00_AXI_ADDR_WIDTH(4)) u_ip3 (
        .clk(clk_100), .rst_n(aresetn),
        .master_clk(o_mclk), .sw_ch0(1'b0), .sw_ch1(1'b0), .sw_ch2(1'b0),
        .done_tick(done_tick), .run(1'b1),
        .mux(), .prev_master_clk(), .current_master_clk(), .enable(),
        .o_ja1(), .o_ja2(), .o_ja3(), .o_ja4(), .o_ja5(), .o_ja6(),
        .adc_ch(adc_ch), .adc_start(),
        .s00_axi_aclk(clk_100), .s00_axi_aresetn(aresetn),
        .s00_axi_awaddr(4'd0), .s00_axi_awprot(3'd0), .s00_axi_awvalid(1'b0), .s00_axi_awready(),
        .s00_axi_wdata(32'd0), .s00_axi_wstrb(4'd0), .s00_axi_wvalid(1'b0), .s00_axi_wready(),
        .s00_axi_bresp(), .s00_axi_bvalid(), .s00_axi_bready(1'b0),
        .s00_axi_araddr(4'd0), .s00_axi_arprot(3'd0), .s00_axi_arvalid(1'b0), .s00_axi_arready(),
        .s00_axi_rdata(), .s00_axi_rresp(), .s00_axi_rvalid(), .s00_axi_rready(1'b0)
    );

    // ---------------- config via hierarchical force (MCU-equivalent) ----------------
    initial begin
        // IP_1: N cycles-per-channel, nested DAC pacing
        force u_ip1.IP_1_slave_lite_v1_0_S00_AXI_inst.slv_reg1 = N_CYC;
        force u_ip1.IP_1_slave_lite_v1_0_S00_AXI_inst.slv_reg2 = 32'd1;   // nested_mode
        // IP_Three: auto mode (reg1=0), cycle-paced scheme (reg2=2)
        force u_ip3.myip_slave_lite_v1_0_S00_AXI_inst.slv_reg1 = 32'd0;
        force u_ip3.myip_slave_lite_v1_0_S00_AXI_inst.slv_reg2 = 32'd2;
        // IP_Two: auto mux mode (reg3=0)
        force u_ip2.IP_Two_slave_lite_v1_0_S00_AXI_inst.slv_reg3 = 32'd0;
    end

    // ---------------- observers ----------------
    // internal IP_1 signals (visible via hierarchy in sim)
    wire ip1_cycle_done = u_ip1.IP_1_slave_lite_v1_0_S00_AXI_inst.cycle_done;
    wire ip1_addr_msb_d = u_ip1.IP_1_slave_lite_v1_0_S00_AXI_inst.addr_msb_d;
    wire [2:0] ip1_dac_cnt = u_ip1.IP_1_slave_lite_v1_0_S00_AXI_inst.dac_cnt;

    integer done_cnt = 0, cyc_cnt = 0, total_cnt = 0;
    integer chan_seen = 0;      // bitmask of chanel_cnt values observed
    integer adc_seen  = 0;      // bitmask of adc_ch values observed
    reg done_d = 1'b0, cyc_d = 1'b0, tot_d = 1'b0;

    always @(posedge clk_100) begin
        done_d <= done_tick;  cyc_d <= ip1_cycle_done;  tot_d <= total_tick;
        if (done_tick & ~done_d) done_cnt  <= done_cnt  + 1;
        if (ip1_cycle_done & ~cyc_d) cyc_cnt <= cyc_cnt + 1;
        if (total_tick & ~tot_d) total_cnt <= total_cnt + 1;
        chan_seen <= chan_seen | (1 << chanel_cnt);
        adc_seen  <= adc_seen  | (1 << adc_ch);
    end

    // progress trace on each done_tick
    always @(posedge done_tick)
        $display("[%7t ns] done_tick #%0d : chanel_cnt=%0d dac_ch_sel=%0d dac_cnt=%0d adc_ch=%0d mux1=%0d",
                 $time, done_cnt+1, chanel_cnt, dac_ch_sel, ip1_dac_cnt, adc_ch, mux1);

    // ---------------- stimulus + checks ----------------
    integer errors = 0;
    initial begin
        aresetn = 1'b0;
        repeat (10) @(posedge clk_100);
        aresetn = 1'b1;

        #(RUN_NS);

        $display("-----------------------------------------------------------");
        $display("cycle_done pulses : %0d", cyc_cnt);
        $display("done_tick pulses  : %0d", done_cnt);
        $display("total_tick pulses : %0d", total_cnt);
        $display("chanel_cnt seen   : 0x%0h (want 0xFF = all 0..7)", chan_seen[7:0]);
        $display("adc_ch seen       : 0x%0h (want 0xFF = all 0..7)", adc_seen[7:0]);

        if (cyc_cnt  < 8)   begin errors=errors+1; $display("[FAIL] cycle_done never/rarely fired -> rollover detector broken"); end
        else                $display("[PASS] cycle_done fires once per sine period");
        if (done_cnt < 8)   begin errors=errors+1; $display("[FAIL] done_tick never/rarely fired"); end
        else                $display("[PASS] done_tick fires (>=8)");
        if (chan_seen[7:0] !== 8'hFF) begin errors=errors+1; $display("[FAIL] chanel_cnt did not sweep 0..7"); end
        else                          $display("[PASS] chanel_cnt swept 0..7");
        if (adc_seen[7:0]  !== 8'hFF) begin errors=errors+1; $display("[FAIL] IP_Three adc_ch did not sweep 0..7 (cycle-paced advance)"); end
        else                          $display("[PASS] IP_Three adc_ch swept 0..7 on done_tick");
        if (total_cnt < 1)  begin errors=errors+1; $display("[FAIL] total_tick never fired (no 8-channel frame completed)"); end
        else                $display("[PASS] total_tick fired (>=1 full 8-channel frame)");

        $display("-----------------------------------------------------------");
        if (errors == 0) $display("TB RESULT: ALL CHECKS PASSED");
        else             $display("TB RESULT: %0d CHECK(S) FAILED", errors);
        $display("-----------------------------------------------------------");
        $finish;
    end

    initial begin
        #(RUN_NS + 100000);
        $display("[FAIL] TIMEOUT - simulation did not finish");
        $finish;
    end

endmodule
