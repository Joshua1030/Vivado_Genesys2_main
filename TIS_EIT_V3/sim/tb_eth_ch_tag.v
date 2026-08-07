`timescale 1ns / 1ps
// ============================================================================
// tb_eth_ch_tag.v — self-checking testbench for (1) the ethernet_debug sample
//                   header channel tag (DAC/ADC channel <-> data pairing) and
//                   (2) WHEN IP_Three is allowed to move the sense mux
//                       relative to the LTC2500 aperture
//
// BUG #1: THE CHANNEL TAG
//   ethernet_debug packs each ADC sample as
//       0xA5 | {0,DAC[2:0],0,ADC[2:0]} | data[31:24..7:0]
//   It used to sample dac_ch/adc_ch at the moment the 32-bit word had finished
//   arriving. By then the channel counters had already moved on: IP_Three's
//   cha_cnt increments on the FALLING edge of MCLK
//   (myip_slave_lite_v1_0_S00_AXI.v), i.e. ~3 cycles into a conversion that
//   takes 100+ cycles to reach ethernet_debug. Result: data N tagged with
//   channel N+1.
//   The fix latches the channel byte on the MCLK RISING edge (the instant the
//   LTC2500 samples) and emits that with the matching data word.
//
// HOW THE CHECK WORKS
//   The ADC stub returns a data word that carries its own ground truth:
//       {8'hC5, ch_at_sample_instant, 8'h3C, 8'h96}
//   where ch_at_sample_instant is reconstructed INDEPENDENTLY by this TB from
//   o_mclk + dac_ch/adc_ch. Each decoded frame must then satisfy
//       frame[1] (header channel) == frame[3] (channel carried in the data)
//   Pairing data with the wrong channel breaks this regardless of which
//   channel it is, so the test is not sensitive to counter start values.
//
// BUG #2: THE MUX SWITCH WINDOW
//   The LTC2500-32 samples on the MCLK RISING edge and holds for the whole
//   conversion (BUSY high); only while BUSY is LOW does the sampling capacitor
//   reconnect and track the input. So the sense mux must move only while BUSY
//   is high — see the SENSE-MUX SWITCH-TIMING MONITOR below for the full
//   argument and the two checks it makes.
//   The cycle-paced scheme used to advance straight off IP_1/done_tick, which
//   is asynchronous to the ADC, so the mux could move anywhere in the loop.
//
// FOUR PHASES (each exercises a different way the counters move):
//   A  paced conversions, free-run sense scan  (advances on MCLK fall)
//   B  back-to-back conversions               (worst-case ch_sampled->ch_latch
//                                              handoff margin, ~3 cycles, and
//                                              the tightest settling window)
//   C  cycle-paced sense scan                 (target advances on done_tick,
//                                              asynchronous to MCLK)
//   D  nested 8x8 legacy                      (per-conversion advance plus an
//                                              async reset on done_tick)
//   dac_ch is driven throughout on a period deliberately non-commensurate with
//   the conversion rate, so it also moves mid-conversion.
//
// Config registers are applied by hierarchical `force` (the sim equivalent of
// the MCU having written them) — no AXI master needed. See sim/tb_scan_chain.v
// for the same pattern.
//
// Run (standalone XSim, from TIS_EIT_V2/ — same flow as tb_scan_chain.v; NOT
// scripts/sim.tcl, which sees the BD-wrapped IP names rather than these raw
// module names):
//   xvlog -sv ip_repo/ltc_driver_fsm_1_1/ip_repo/src/ltc_driver_fsm.sv \
//             ip_repo/ltc_driver_fsm_1_1/ip_repo/src/cdc_sync_edge.sv
//   xvlog ip_repo/IP_Three_1_0/hdl/myip.v ip_repo/IP_Three_1_0/hdl/myip_slave_lite_v1_0_S00_AXI.v \
//         ip_repo/ethernet_debug_1_0/hdl/ethernet_debug.v \
//         ip_repo/ethernet_debug_1_0/hdl/ethernet_debug_slave_lite_v1_0_S00_AXI.v \
//         sim/tb_eth_ch_tag.v
//   xelab -debug typical -timescale 1ns/1ps tb_eth_ch_tag -s tb_chtag_sim
//   xsim tb_chtag_sim -runall
// (-timescale is required: ltc_driver_fsm.sv/cdc_sync_edge.sv carry no
//  `timescale of their own.)
//
// Expected: "TB RESULT: ALL CHECKS PASSED", mis-tagged frames = 0, mux moved in
// acq phase = 0, mux settled too late = 0.
// Negative controls:
//   * revert ch_latch to `{1'b0,dac_ch,1'b0,adc_ch}` in
//     ethernet_debug_slave_lite_v1_0_S00_AXI.v -> every frame mis-tags by one;
//   * make the cycle-paced scheme drive cha_cnt straight off done_rise in
//     myip_slave_lite_v1_0_S00_AXI.v -> phase C reports dozens of
//     "sense mux changed ... while BUSY low".
// ============================================================================

module tb_eth_ch_tag;

    // ---------------- clock / reset ----------------
    reg clk_100 = 1'b0;
    reg aresetn = 1'b0;
    always #5 clk_100 = ~clk_100;               // 100 MHz

    // ---------------- DUT interconnect ----------------
    wire        o_mclk, o_sync, o_pre, o_sdi, o_sckb, o_rdlb;
    wire        i_busy, i_drl, i_sdob;
    wire [31:0] o_read_data;
    wire [7:0]  eth_data;
    wire        eth_valid, o_data_valid, o_error;
    wire [3:0]  o_debug_state;

    wire [2:0]  adc_ch;
    wire        adc_start;
    reg  [2:0]  dac_ch    = 3'd0;
    reg         done_tick = 1'b0;

    wire        clk_trg;
    wire [7:0]  data_out;

    wire [31:0] payload_expected;

    // ================= ADC sense mux (IP_Three, module myip) =================
    myip #(.C_S00_AXI_DATA_WIDTH(32), .C_S00_AXI_ADDR_WIDTH(4)) u_ip3 (
        .clk(clk_100), .rst_n(aresetn),
        .master_clk(o_mclk), .sw_ch0(1'b0), .sw_ch1(1'b0), .sw_ch2(1'b0),
        .done_tick(done_tick), .run(1'b1),
        .mux(), .prev_master_clk(), .current_master_clk(), .enable(),
        .o_ja1(), .o_ja2(), .o_ja3(), .o_ja4(), .o_ja5(), .o_ja6(),
        .adc_ch(adc_ch), .adc_start(adc_start),
        .s00_axi_aclk(clk_100), .s00_axi_aresetn(aresetn),
        .s00_axi_awaddr(4'd0), .s00_axi_awprot(3'd0), .s00_axi_awvalid(1'b0), .s00_axi_awready(),
        .s00_axi_wdata(32'd0), .s00_axi_wstrb(4'd0), .s00_axi_wvalid(1'b0), .s00_axi_wready(),
        .s00_axi_bresp(), .s00_axi_bvalid(), .s00_axi_bready(1'b0),
        .s00_axi_araddr(4'd0), .s00_axi_arprot(3'd0), .s00_axi_arvalid(1'b0), .s00_axi_arready(),
        .s00_axi_rdata(), .s00_axi_rresp(), .s00_axi_rvalid(), .s00_axi_rready(1'b0)
    );

    // ================= LTC2500 driver FSM =================
    ltc_driver_fsm #(.DATA_WIDTH(32), .CLK_FREQ(100_000_000)) u_fsm (
        .i_clk(clk_100), .i_rst_n(aresetn), .i_start(adc_start),
        .o_mclk(o_mclk), .o_sync(o_sync), .o_pre(o_pre),
        .i_busy(i_busy), .i_drl(i_drl),
        .o_sdi(o_sdi), .o_sckb(o_sckb), .o_rdlb(o_rdlb), .i_sdob(i_sdob),
        .o_debug_state(o_debug_state),
        .o_read_data(o_read_data),
        .o_eth_data(eth_data), .o_eth_valid(eth_valid),
        .o_data_valid(o_data_valid), .o_error(o_error)
    );

    // ================= ADC model (payload carries the ground truth) =========
    ltc2500_stub u_adc (
        .mclk(o_mclk), .payload_in(payload_expected),
        .rdlb(o_rdlb), .sckb(o_sckb),
        .busy(i_busy), .drl(i_drl), .sdob(i_sdob)
    );

    // ---------------------------------------------------------------------
    // TIS tag stimulus. Free-running at periods that are deliberately coprime
    // with the conversion cadence, so the tags land in every phase relative to
    // the MCLK aperture over a run (including changing right at the edge).
    // ---------------------------------------------------------------------
    reg tis_on     = 1'b0;
    reg run_active = 1'b0;
    always #3330  tis_on     = ~tis_on;
    always #11110 run_active = ~run_active;

    // ================= Packetiser under test =================
    ethernet_debug #(.C_S00_AXI_DATA_WIDTH(32), .C_S00_AXI_ADDR_WIDTH(4)) u_eth (
        .global_clk(clk_100), .rst_n(aresetn),
        .o_eth_valid(eth_valid), .o_eth_data(eth_data),
        .dac_ch(dac_ch), .adc_ch(adc_ch), .mclk(o_mclk),
        .tis_on(tis_on), .run_active(run_active),
        .clk_trg(clk_trg), .data_out(data_out),
        .dbg_rx_byte_cnt(), .dbg_tx_start_en(), .dbg_current_state(),
        .s00_axi_aclk(clk_100), .s00_axi_aresetn(aresetn),
        .s00_axi_awaddr(4'd0), .s00_axi_awprot(3'd0), .s00_axi_awvalid(1'b0), .s00_axi_awready(),
        .s00_axi_wdata(32'd0), .s00_axi_wstrb(4'd0), .s00_axi_wvalid(1'b0), .s00_axi_wready(),
        .s00_axi_bresp(), .s00_axi_bvalid(), .s00_axi_bready(1'b0),
        .s00_axi_araddr(4'd0), .s00_axi_arprot(3'd0), .s00_axi_arvalid(1'b0), .s00_axi_arready(),
        .s00_axi_rdata(), .s00_axi_rresp(), .s00_axi_rvalid(), .s00_axi_rready(1'b0)
    );

    // ---------------------------------------------------------------------
    // Independent reconstruction of "the channel live at the sample instant".
    // Same rule as the DUT (one registered copy of MCLK, rising-edge detect)
    // but written here from the primary signals, not read out of the DUT.
    //
    // The detect depth must match the DUT's exactly. This used to use a 2-deep
    // pipeline (mclk_q/mclk_qq) while ethernet_debug uses a 1-deep one, so this
    // model latched the channel ONE CLOCK LATER than the DUT. Any dac_ch change
    // landing in that 10 ns gap produced a spurious MIS-TAGGED failure at a rate
    // of ~0.3% of frames — a flaky test, not a real defect.
    // ---------------------------------------------------------------------
    // The two spare bits of the header byte now carry the TIS tags from IP_1:
    //   bit7 = tis_on      bit3 = run_active
    // They are latched at the same MCLK rising edge as the channel numbers, so
    // folding them into this reconstruction means the existing "header byte ==
    // channel carried in the data" check below also regresses the tag bits.
    // Both DUT and model sample the same wires on the same clock edge with the
    // same 1-deep detect, so a tag changing near the aperture cannot race.
    reg        mclk_q = 1'b0;
    reg [7:0]  ch_at_sample = 8'd0;
    always @(posedge clk_100 or negedge aresetn) begin
        if (!aresetn) begin
            mclk_q <= 1'b0; ch_at_sample <= 8'd0;
        end else begin
            mclk_q <= o_mclk;
            if (o_mclk && !mclk_q)
                ch_at_sample <= {tis_on, dac_ch, run_active, adc_ch};
        end
    end

    // The stub latches this when BUSY falls, long after ch_at_sample settled.
    assign payload_expected = {8'hC5, ch_at_sample, 8'h3C, 8'h96};

    // ---------------------------------------------------------------------
    // Frame decoder — clk_trg is the host-side byte strobe; data_out is stable
    // while it is high. Sync on the 0xA5 marker, then free-run 6 bytes.
    //
    // NOTE: the header byte used to max out at 0x77, so 0xA5 was unambiguous.
    // Now that bits 7 and 3 carry the TIS tags it can be ANY value, 0xA5
    // included ({tis=1, dac=2, run=0, adc=5}). That is fine here because we sync
    // once on the first frame of a clean post-reset stream and then count bytes,
    // but a host-side parser must NOT assume 0xA5 identifies a frame start — in
    // real operation the four payload bytes are arbitrary ADC data and could
    // always contain 0xA5 anyway. Frame on the fixed 6-byte stride.
    // ---------------------------------------------------------------------
    localparam [7:0] HDR_MARKER = 8'hA5;

    integer fidx    = 0;
    integer frames  = 0;
    integer errors  = 0;
    integer bad_tag = 0;
    reg [7:0] fr0, fr1, fr2, fr3, fr4, fr5;

    always @(posedge clk_trg) begin
        case (fidx)
            0: if (data_out == HDR_MARKER) begin fr0 = data_out; fidx = 1; end
            1: begin fr1 = data_out; fidx = 2; end
            2: begin fr2 = data_out; fidx = 3; end
            3: begin fr3 = data_out; fidx = 4; end
            4: begin fr4 = data_out; fidx = 5; end
            5: begin fr5 = data_out; fidx = 0; check_frame; end
        endcase
    end

    task check_frame;
        begin
            frames = frames + 1;

            // structural sanity: the 32-bit word survived the byte pipeline
            if (fr2 !== 8'hC5 || fr4 !== 8'h3C || fr5 !== 8'h96) begin
                errors = errors + 1;
                $display("[%7t ns] [FAIL] frame %0d payload corrupt: %02h %02h %02h %02h",
                         $time, frames, fr2, fr3, fr4, fr5);
            end

            // THE CHECK: header channel must match the channel the sample was
            // actually taken on (carried inside the data word).
            if (fr1 !== fr3) begin
                errors  = errors + 1;
                bad_tag = bad_tag + 1;
                $display("[%7t ns] [FAIL] frame %0d MIS-TAGGED: header ch=0x%02h (DAC %0d/ADC %0d) but sample was taken on 0x%02h (DAC %0d/ADC %0d)",
                         $time, frames, fr1, fr1[6:4], fr1[2:0],
                                        fr3, fr3[6:4], fr3[2:0]);
            end else if (frames <= 6 || (frames % 10) == 0) begin
                $display("[%7t ns] [ok]   frame %0d  header ch=0x%02h (DAC %0d/ADC %0d)",
                         $time, frames, fr1, fr1[6:4], fr1[2:0]);
            end
        end
    endtask

    // =====================================================================
    // SENSE-MUX SWITCH-TIMING MONITOR
    //
    // LTC2500-32: a rising edge on MCLK starts a conversion and IS the aperture
    // — the 32-bit charge-redistribution CDAC disconnects from IN+/IN- and
    // holds. BUSY is high for the whole conversion (tCONV ~660 ns). Only while
    // BUSY is LOW is the CDAC reconnected to IN+/IN- and tracking the input
    // (the acquisition phase, tACQ = 327 ns @ 1 Msps).
    //
    //   => the sense mux may only change while BUSY is HIGH. The whole mux
    //      transient then falls inside the hold window, and the analog front
    //      end gets tCONV + tACQ to settle before the next aperture.
    //   => switching on the BUSY FALLING edge is the worst possible choice:
    //      the mux slew AND the CDAC's own charge kickback would have to settle
    //      within tACQ alone.
    //
    // Two checks, both built from primary signals (o_mclk / i_busy / adc_ch),
    // never from DUT internals:
    //   1. adc_ch must not change while i_busy is low.
    //   2. the gap from the last adc_ch change to the next MCLK rising edge
    //      must be >= MIN_SETTLE_NS.
    //
    // Negative control: with the sense counter advancing straight off done_tick
    // (the pre-fix cycle-paced path), phase C fails check 1 on ~7 of every 8
    // channel changes, because BUSY is high for only ~500 ns of the 4 us loop.
    // =====================================================================
    localparam integer MIN_SETTLE_NS = 900;  // < the ~2 us loop, > tCONV + tACQ

    integer mux_bad_window = 0;   // adc_ch moved during the acquisition phase
    integer mux_bad_settle = 0;   // adc_ch moved too close to the next aperture
    time    last_mux_change = 0;
    time    min_settle      = 64'hFFFF_FFFF;
    reg     mux_seen        = 1'b0;

    integer mux_changes = 0;
    always @(adc_ch) begin
        if (aresetn === 1'b1) begin
            last_mux_change = $time;
            mux_seen        = 1'b1;
            mux_changes     = mux_changes + 1;
            if (i_busy !== 1'b1) begin
                mux_bad_window = mux_bad_window + 1;
                errors         = errors + 1;
                $display("[%7t ns] [FAIL] sense mux changed to %0d while BUSY low (acquisition phase) - the sample cap is tracking the input",
                         $time, adc_ch);
            end
        end
    end

    always @(posedge o_mclk) begin
        if (aresetn === 1'b1 && mux_seen) begin
            if (($time - last_mux_change) < min_settle)
                min_settle = $time - last_mux_change;
            if (($time - last_mux_change) < MIN_SETTLE_NS) begin
                mux_bad_settle = mux_bad_settle + 1;
                errors         = errors + 1;
                $display("[%7t ns] [FAIL] sense mux settled only %0d ns before this aperture (need >= %0d ns)",
                         $time, $time - last_mux_change, MIN_SETTLE_NS);
            end
        end
    end

    // ---------------- DAC channel stimulus ----------------
    // 3.33 us period: deliberately non-commensurate with the conversion rate so
    // dac_ch also changes mid-conversion.
    //
    // Driven on the NEGEDGE, not the posedge. These are blocking assignments to
    // signals that both the DUT and this TB's own reference model sample with
    // `always @(posedge clk_100) ... <= ...`. Assigning them AT the posedge is a
    // race: whichever always block Verilog happens to run after the assignment
    // sees the new value in the same delta, the others see the old one. It bit
    // done_tick below for real (see there); dac_ch had the same latent hazard
    // between the DUT's ch_sampled latch and the TB's ch_at_sample model.
    always begin
        #3330;
        @(negedge clk_100) dac_ch = dac_ch + 3'd1;
    end

    // ---------------- done_tick stimulus (phase C / D) ----------------
    // WAS driven at `@(posedge clk_100)`, which made phase C silently inert:
    // IP_Three registers prev_done_tick <= done_tick on the posedge and derives
    // done_rise = done_tick & ~prev_done_tick combinationally. With done_tick
    // rising in the same delta as that posedge, prev_done_tick latched the 1
    // immediately, so done_rise was never high at ANY sampling edge — cha_cnt
    // never advanced and the cycle-paced scheme was never exercised at all.
    // Driving on the negedge gives done_rise a full clock of width.
    //
    // The period is per-phase. Nested-legacy resets the counter to 0 on every
    // done_tick, so it only sweeps if done_tick is SLOWER than the conversion
    // rate — which is that scheme's documented precondition ("the DAC dwell
    // spans >= 8 ADC conversions"). Phase D therefore uses a long period.
    integer cfg_done_period = 2170;
    always begin
        #(cfg_done_period);
        @(negedge clk_100) done_tick = 1'b1;
        repeat (4) @(negedge clk_100);
        done_tick = 1'b0;
    end

    // ---------------- IP_Three config (MCU-equivalent, via force) ----------------
    // Forced once to these module-level regs; changing a reg re-drives the force
    // (forcing directly to a task argument would not update on later calls).
    reg [31:0] cfg_mode   = 32'd0;   // slv_reg1: 0 = auto scan
    reg [31:0] cfg_scheme = 32'd0;   // slv_reg2: scan scheme
    reg [31:0] cfg_period = 32'd400; // slv_reg3: conversion period (0 = free-run)

    initial begin
        force u_ip3.myip_slave_lite_v1_0_S00_AXI_inst.slv_reg1 = cfg_mode;
        force u_ip3.myip_slave_lite_v1_0_S00_AXI_inst.slv_reg2 = cfg_scheme;
        force u_ip3.myip_slave_lite_v1_0_S00_AXI_inst.slv_reg3 = cfg_period;
    end

    // ---------------- phases ----------------
    integer phase_start_frames;
    integer phase_start_errors;
    integer phase_start_mux;

    task run_phase;
        input [255:0] name;
        input [31:0]  scheme;      // IP_Three slv_reg2
        input [31:0]  period;      // IP_Three slv_reg3 (0 = free-run)
        input integer done_period; // TB done_tick period (ns)
        input integer duration_ns;
        input integer min_frames;
        begin
            cfg_done_period = done_period;
            phase_start_frames = frames;
            phase_start_errors = errors;
            phase_start_mux    = mux_changes;
            min_settle         = 64'hFFFF_FFFF;
            mux_seen           = 1'b0;

            cfg_scheme = scheme;
            cfg_period = period;

            $display("-----------------------------------------------------------");
            $display("PHASE %0s : scheme=%0d period=%0d", name, scheme, period);
            $display("-----------------------------------------------------------");

            #(duration_ns);

            $display("PHASE %0s : %0d frames, %0d error(s)", name,
                     frames - phase_start_frames, errors - phase_start_errors);
            if (mux_seen)
                $display("PHASE %0s : %0d sense-mux changes, min settling before an aperture = %0d ns (need >= %0d)",
                         name, mux_changes - phase_start_mux, min_settle, MIN_SETTLE_NS);
            else begin
                errors = errors + 1;
                $display("[FAIL] PHASE %0s : sense mux never changed - the scan is not being exercised", name);
            end
            if ((frames - phase_start_frames) < min_frames) begin
                errors = errors + 1;
                $display("[FAIL] PHASE %0s produced only %0d frames (need >= %0d) - stimulus/DUT stalled",
                         name, frames - phase_start_frames, min_frames);
            end
        end
    endtask

    // ---------------- stimulus ----------------
    initial begin
        aresetn = 1'b0;
        repeat (20) @(posedge clk_100);
        aresetn = 1'b1;
        repeat (10) @(posedge clk_100);

        // A: paced conversions (4 us apart), sense scan advances on MCLK fall
        run_phase("A-paced-freerun-scan", 32'd0, 32'd400, 2170,  100000, 15);

        // B: back-to-back conversions - tightest ch_sampled -> ch_latch margin
        //    and the tightest mux settling window
        run_phase("B-back-to-back",       32'd0, 32'd0,   2170,  100000, 15);

        // C: cycle-paced sense scan - the target channel moves on done_tick,
        //    asynchronous to MCLK; the mux itself must still only move in the
        //    conversion window
        run_phase("C-cycle-paced-scan",   32'd2, 32'd400, 2170,  100000, 15);

        // D: nested 8x8 legacy - per-conversion advance plus an async reset to
        //    channel 0 on done_tick. done_tick must be slower than the 4 us
        //    conversion period or the counter is pinned at 0 and never sweeps.
        run_phase("D-nested-legacy",      32'd1, 32'd400, 17000, 100000, 15);

        $display("===========================================================");
        $display("total frames decoded : %0d", frames);
        $display("mis-tagged frames    : %0d", bad_tag);
        $display("mux moved in acq ph. : %0d", mux_bad_window);
        $display("mux settled too late : %0d", mux_bad_settle);
        if (o_error) begin
            errors = errors + 1;
            $display("[FAIL] ltc_driver_fsm raised o_error (conversion timeout)");
        end
        if (frames == 0) begin
            errors = errors + 1;
            $display("[FAIL] no frames decoded at all");
        end
        if (errors == 0) $display("TB RESULT: ALL CHECKS PASSED");
        else             $display("TB RESULT: %0d CHECK(S) FAILED", errors);
        $display("===========================================================");
        $finish;
    end

    initial begin
        #600000;
        $display("[FAIL] TIMEOUT - simulation did not finish");
        $finish;
    end

endmodule


// ============================================================================
// Minimal LTC2500 model.
//   * MCLK rising edge starts a conversion (the sample instant).
//   * BUSY high for the conversion time, then DRL low to flag data ready.
//   * Data shifts out MSB-first on SDOB: MSB presented when RDLB falls, then
//     advanced on each SCKB falling edge (the FSM samples on the rising edge).
// payload_in is latched when BUSY falls, so the TB has plenty of time to
// settle the value it wants handed back.
// ============================================================================
module ltc2500_stub (
    input  wire        mclk,
    input  wire [31:0] payload_in,
    input  wire        rdlb,
    input  wire        sckb,
    output reg         busy,
    output reg         drl,
    output reg         sdob
);
    // ltc_driver_fsm errors out if BUSY has not fallen within CYCLES_CONV
    // (75 cycles @100MHz = 750 ns), so stay comfortably under that.
    localparam integer CONV_NS = 500;

    reg [31:0] payload;
    reg [5:0]  bit_idx;

    initial begin
        busy    = 1'b0;
        drl     = 1'b1;
        sdob    = 1'b0;
        payload = 32'd0;
        bit_idx = 6'd31;
    end

    always @(posedge mclk) begin
        busy = 1'b1;
        drl  = 1'b1;
        #CONV_NS;
        busy    = 1'b0;
        payload = payload_in;   // ground truth for this conversion
        #10;
        drl = 1'b0;             // data ready
    end

    always @(negedge rdlb) begin
        bit_idx = 6'd31;
        sdob    = payload[31];
    end

    always @(negedge sckb) begin
        if (~rdlb && bit_idx > 0) begin
            bit_idx = bit_idx - 6'd1;
            sdob    = payload[bit_idx];
        end
    end
endmodule
