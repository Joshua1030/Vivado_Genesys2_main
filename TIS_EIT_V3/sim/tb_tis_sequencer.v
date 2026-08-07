`timescale 1ns / 1ps
// ============================================================================
// tb_tis_sequencer.v — self-checking testbench for IP_1 as the TIS/EIT sequencer
//
// Covers the timed-stimulation rewrite of IP_1 (ip_repo/IP_1_1_0/hdl/):
//   * BTNU debounce + edge detect -> exactly ONE run per (bouncy) press
//   * the 200ms/90ms/100ms stimulation window, scaled down for simulation
//   * nerve_pulse at [tis_delay+nerve_delay, +nerve_width)
//   * dds_hold == ~tis_on at all times (A/B DDS phase park)
//   * done_tick / total_tick cascade and the run length in BOTH scan modes:
//       mode A (scan_mode=1): 64 stimulations per frame
//       mode B (scan_mode=0):  8 stimulations per frame
//   * run_active drops at the end and a second press starts a new run
//
// Timing registers are scaled by ~1e5 vs. hardware so the whole thing runs in
// milliseconds of sim time instead of minutes; the RATIOS are what matter, and
// they match main.c (90/100/200 -> 90/100/200 here).
// DEBOUNCE_CYCLES is overridden via the module parameter (hardware default is
// 2_000_000 = 20ms @100MHz, which would dominate the simulation).
//
// Config registers are applied by hierarchical `force` (the sim equivalent of
// the MCU having written them) — same approach as tb_scan_chain.v. Pure-Verilog
// DUT, so it runs in behavioral XSim with no license.
//
// Run:
//   vivado -mode batch -source scripts/sim.tcl -tclargs tb_tis_sequencer
// or standalone:
//   xvlog ip_repo/IP_1_1_0/hdl/IP_1.v ip_repo/IP_1_1_0/hdl/IP_1_slave_lite_v1_0_S00_AXI.v \
//         sim/tb_tis_sequencer.v
//   xelab -debug typical tb_tis_sequencer -s tb_tis_sim && xsim tb_tis_sim -runall
// ============================================================================

module tb_tis_sequencer;

    // ---------------- scaled timing (cycles) ----------------
    // hardware : 20_000_000 / 9_000_000 / 10_000_000 / 50_000 / 100_000
    // here     :        200 /        90 /        100 /      5 /      10
    localparam integer STIM_PERIOD  = 200;
    localparam integer TIS_DELAY    = 90;
    localparam integer TIS_DURATION = 100;
    localparam integer NERVE_DELAY  = 5;
    localparam integer NERVE_WIDTH  = 10;
    localparam integer FRAMES       = 2;
    localparam integer DEBOUNCE     = 20;   // scaled from 2_000_000

    // tis_on / nerve_pulse / dds_hold are REGISTERED outputs in IP_1 (the window
    // comparators are deliberately pipelined so the 32-bit compares stay off the
    // critical path). So by the time an edge is visible, stim_cnt has already
    // advanced one more count — every absolute offset below is therefore
    // (boundary + OUT_LAT). Widths and relative spacings are unaffected.
    // At 100 MHz this is a 10 ns skew on a 90 ms window: irrelevant in hardware,
    // but the testbench has to model it or it "fails" a perfectly good DUT.
    localparam integer OUT_LAT      = 1;

    // ---------------- clock / reset ----------------
    reg clk = 1'b0;
    reg rst_n = 1'b0;
    always #5 clk = ~clk;                   // 100 MHz

    // ---------------- DUT ----------------
    reg  btn = 1'b0;
    wire done_tick, total_tick, sync, enable;
    wire tis_on, dds_hold, nerve_pulse, run_active;
    wire [2:0] chanel_cnt, dac_ch_sel;

    IP_1 #(
        .DEBOUNCE_CYCLES(DEBOUNCE),
        .C_S00_AXI_DATA_WIDTH(32), .C_S00_AXI_ADDR_WIDTH(7)
    ) dut (
        .clk(clk), .rst_n(rst_n),
        .address(16'd0), .CLK_A(1'b0),      // vestigial ports
        .btn_start(btn),
        .done_tick(done_tick), .total_tick(total_tick),
        .chanel_cnt(chanel_cnt), .sync(sync), .enable(enable),
        .dac_ch_sel(dac_ch_sel),
        .tis_on(tis_on), .dds_hold(dds_hold),
        .nerve_pulse(nerve_pulse), .run_active(run_active),
        .o_cycle_done(), .o_addr_msb(),
        .s00_axi_aclk(clk), .s00_axi_aresetn(rst_n),
        .s00_axi_awaddr(7'd0), .s00_axi_awprot(3'd0), .s00_axi_awvalid(1'b0), .s00_axi_awready(),
        .s00_axi_wdata(32'd0), .s00_axi_wstrb(4'd0), .s00_axi_wvalid(1'b0), .s00_axi_wready(),
        .s00_axi_bresp(), .s00_axi_bvalid(), .s00_axi_bready(1'b0),
        .s00_axi_araddr(7'd0), .s00_axi_arprot(3'd0), .s00_axi_arvalid(1'b0), .s00_axi_arready(),
        .s00_axi_rdata(), .s00_axi_rresp(), .s00_axi_rvalid(), .s00_axi_rready(1'b0)
    );

    `define RF dut.IP_1_slave_lite_v1_0_S00_AXI_inst

    // ---------------- observers ----------------
    wire [31:0] stim_cnt = `RF.stim_cnt;
    integer done_cnt = 0, total_cnt = 0, nerve_cnt = 0;
    integer errors = 0;
    reg  done_d = 0, tot_d = 0, nerve_d = 0, tis_d = 0, run_d = 0;
    integer tis_rise_off = -1;   // stim_cnt when tis_on rose
    integer nerve_rise_off = -1;
    integer dac_changes = 0;
    reg [2:0] dac_prev;

    always @(posedge clk) begin
        done_d <= done_tick; tot_d <= total_tick;
        nerve_d <= nerve_pulse; tis_d <= tis_on; run_d <= run_active;

        if (done_tick & ~done_d)  done_cnt  = done_cnt + 1;
        if (total_tick & ~tot_d)  total_cnt = total_cnt + 1;

        // dds_hold must always be the exact complement of tis_on
        if (rst_n && (dds_hold !== ~tis_on)) begin
            errors = errors + 1;
            $display("[FAIL @%0t] dds_hold(%b) != ~tis_on(%b)", $time, dds_hold, tis_on);
        end

        // TIS window placement inside the stimulation period
        if (tis_on & ~tis_d)  tis_rise_off = stim_cnt;
        if (~tis_on & tis_d) begin
            if (tis_rise_off !== TIS_DELAY + OUT_LAT) begin
                errors = errors + 1;
                $display("[FAIL @%0t] tis_on rose at offset %0d, want %0d",
                         $time, tis_rise_off, TIS_DELAY + OUT_LAT);
            end
            if (stim_cnt !== (TIS_DELAY + TIS_DURATION + OUT_LAT)) begin
                errors = errors + 1;
                $display("[FAIL @%0t] tis_on fell at offset %0d, want %0d",
                         $time, stim_cnt, TIS_DELAY + TIS_DURATION + OUT_LAT);
            end
        end

        // nerve pulse placement + width
        if (nerve_pulse & ~nerve_d) begin
            nerve_rise_off = stim_cnt;
            nerve_cnt = nerve_cnt + 1;
            if (stim_cnt !== (TIS_DELAY + NERVE_DELAY + OUT_LAT)) begin
                errors = errors + 1;
                $display("[FAIL @%0t] nerve_pulse rose at offset %0d, want %0d",
                         $time, stim_cnt, TIS_DELAY + NERVE_DELAY + OUT_LAT);
            end
        end
        if (~nerve_pulse & nerve_d) begin
            if ((stim_cnt - nerve_rise_off) !== NERVE_WIDTH) begin
                errors = errors + 1;
                $display("[FAIL @%0t] nerve_pulse width %0d, want %0d",
                         $time, stim_cnt - nerve_rise_off, NERVE_WIDTH);
            end
        end
        // nerve pulse must never fire outside a run
        if (nerve_pulse && !run_active) begin
            errors = errors + 1;
            $display("[FAIL @%0t] nerve_pulse asserted with run_active low", $time);
        end

        // count DAC injection-pair changes (to tell mode A from mode B)
        if (done_tick & ~done_d) begin
            if (done_cnt > 1 && dac_ch_sel !== dac_prev) dac_changes = dac_changes + 1;
            dac_prev = dac_ch_sel;
        end
    end

    // ---------------- press the button, with bounce ----------------
    task press_button;
        integer i;
        begin
            for (i = 0; i < 6; i = i + 1) begin       // mechanical bounce
                btn = ~btn;
                repeat (2) @(posedge clk);
            end
            btn = 1'b1;
            repeat (DEBOUNCE * 3) @(posedge clk);     // settle -> accepted
        end
    endtask

    task release_button;
        begin
            btn = 1'b0;
            repeat (DEBOUNCE * 3) @(posedge clk);
        end
    endtask

    // ---------------- one full run in a given mode ----------------
    task run_mode;
        input        mode;               // 1 = A (64 stim/frame), 0 = B (8 stim/frame)
        input integer want_done;
        input integer want_total;
        integer guard;
        begin
            $display("");
            $display("=== scan_mode=%0d : expecting %0d done_tick, %0d total_tick ===",
                     mode, want_done, want_total);
            force `RF.slv_reg2 = {31'd0, mode};

            done_cnt = 0; total_cnt = 0; nerve_cnt = 0; dac_changes = 0;

            press_button;
            if (!run_active) begin
                errors = errors + 1;
                $display("[FAIL] run_active did not assert after button press");
            end
            release_button;

            // wait for the run to finish (with a generous guard)
            guard = 0;
            while (run_active && guard < (want_done + 4) * STIM_PERIOD * 2) begin
                @(posedge clk);
                guard = guard + 1;
            end
            if (run_active) begin
                errors = errors + 1;
                $display("[FAIL] run did not terminate (run_active still high)");
            end
            // The final boundary's done_tick/total_tick are registered on the SAME
            // edge that clears run_active, so they are still in flight when the
            // wait loop above exits. Let the counting block see them before
            // comparing, otherwise both counts read one short.
            repeat (5) @(posedge clk);

            $display("  done_tick=%0d total_tick=%0d nerve=%0d dac_changes=%0d",
                     done_cnt, total_cnt, nerve_cnt, dac_changes);

            // done_tick fires once at the start (latch combo 0) plus once per boundary
            if (done_cnt !== want_done) begin
                errors = errors + 1;
                $display("[FAIL] done_tick=%0d, want %0d", done_cnt, want_done);
            end else
                $display("[PASS] done_tick count correct");

            if (total_cnt !== want_total) begin
                errors = errors + 1;
                $display("[FAIL] total_tick=%0d, want %0d", total_cnt, want_total);
            end else
                $display("[PASS] total_tick count correct");

            // one nerve pulse per stimulation actually executed
            if (nerve_cnt !== want_done - 1) begin
                errors = errors + 1;
                $display("[FAIL] nerve pulses=%0d, want %0d", nerve_cnt, want_done - 1);
            end else
                $display("[PASS] one nerve pulse per stimulation");

            // mode A: DAC pair changes every 8th tick; mode B: every tick
            if (mode) begin
                if (dac_changes !== want_total) begin
                    errors = errors + 1;
                    $display("[FAIL] mode A: dac_ch_sel changed %0d times, want %0d (every 8th stim)",
                             dac_changes, want_total);
                end else
                    $display("[PASS] mode A: DAC pair held for 8 stimulations");
            end else begin
                if (dac_changes < want_done - 2) begin
                    errors = errors + 1;
                    $display("[FAIL] mode B: dac_ch_sel changed only %0d times, want ~%0d (every stim)",
                             dac_changes, want_done - 1);
                end else
                    $display("[PASS] mode B: DAC pair advances every stimulation");
            end
        end
    endtask

    // ---------------- stimulus ----------------
    initial begin
        // timing registers (same for both modes)
        force `RF.slv_reg3 = STIM_PERIOD;
        force `RF.slv_reg4 = TIS_DELAY;
        force `RF.slv_reg5 = TIS_DURATION;
        force `RF.slv_reg6 = NERVE_DELAY;
        force `RF.slv_reg7 = NERVE_WIDTH;
        force `RF.slv_reg8 = FRAMES;
        force `RF.slv_reg9 = 32'd0;         // no soft start/abort
        force `RF.slv_reg2 = 32'd1;

        rst_n = 1'b0;
        repeat (10) @(posedge clk);
        rst_n = 1'b1;
        repeat (5) @(posedge clk);

        // idle state: TIS off, phase parked, nothing running
        if (run_active || tis_on || nerve_pulse || !dds_hold) begin
            errors = errors + 1;
            $display("[FAIL] idle state wrong: run=%b tis=%b nerve=%b hold=%b",
                     run_active, tis_on, nerve_pulse, dds_hold);
        end else
            $display("[PASS] idle: TIS off, A/B phase held at 0");

        // Mode A: a frame is 8 DAC pairs x 8 ADC channels = 64 stimulations, so
        // total_tick (one per 8-stimulation sweep) fires 8 times per frame.
        // done_tick = 1 (start, latches combo 0) + one per stimulation boundary.
        run_mode(1'b1, 1 + FRAMES*64, FRAMES*8);

        // Mode B: a frame is 8 stimulations (ADC multiplexed inside each one), so
        // the frame boundary IS the 8-stimulation sweep — total_tick fires exactly
        // once per frame.
        run_mode(1'b0, 1 + FRAMES*8,  FRAMES);

        $display("");
        $display("-----------------------------------------------------------");
        if (errors == 0) $display("TB RESULT: ALL CHECKS PASSED");
        else             $display("TB RESULT: %0d CHECK(S) FAILED", errors);
        $display("-----------------------------------------------------------");
        $finish;
    end

    // watchdog — sim.tcl runs XSim with "run all", so never hang
    initial begin
        #50_000_000;
        $display("[FAIL] TIMEOUT - simulation did not finish");
        $finish;
    end

endmodule
