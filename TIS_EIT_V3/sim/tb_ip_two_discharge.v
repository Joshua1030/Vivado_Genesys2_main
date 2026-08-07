`timescale 1ns / 1ps
// ============================================================================
// tb_ip_two_discharge.v — self-checking testbench for IP_Two's electrode
// discharge output (ip_repo/IP_Two_1_0/hdl/IP_Two_slave_lite_v1_0_S00_AXI.v).
//
// Electrode_Discharge is ACTIVE LOW on the pin (0 = discharging); the registers
// use the software-friendly sense (1 = discharge ON):
//   slv_reg5[0]    (0x14) = mode        0 = manual (reset default), 1 = automatic
//   slv_reg6[0]    (0x18) = manual discharge, 1 = ON     (manual mode only)
//   slv_reg7[15:0] (0x1C) = N injection cycles between discharges (0 => 1)
//
// Automatic mode counts total_tick pulses from IP_1: after N completed injection
// cycles the pin is held low for exactly one further total_tick interval, then
// the count restarts. Counting the intervals from a fresh mode enable, the
// interval that follows tick k is a discharge interval iff k % (N+1) == N —
// i.e. N idle intervals then 1 discharge interval, repeating with period N+1.
// That closed form is the reference model used below.
//
// clk and s00_axi_aclk share one 100 MHz clock here, mirroring the block design
// where IP_Two_0/clk sits on the same 100 MHz net as IP_1. Pure-Verilog DUT, so
// this runs in XSim behavioral mode with no license.
//
// Run (standalone XSim, from TIS_EIT_V2/) — this is the working route:
//   xvlog ip_repo/IP_Two_1_0/hdl/IP_Two.v \
//         ip_repo/IP_Two_1_0/hdl/IP_Two_slave_lite_v1_0_S00_AXI.v \
//         sim/tb_ip_two_discharge.v
//   xelab -debug typical tb_ip_two_discharge -s tb_ip_two_discharge_sim
//   xsim tb_ip_two_discharge_sim -runall
//
// NOTE: scripts/sim.tcl does NOT work for IP unit testbenches on a fresh work/
// ("Module <IP_Two> not found"). The packaged IP HDL only enters the project's
// sources_1 fileset once the BD's per-IP output products have been generated,
// and recreate_project.tcl stops at the wrapper. This affects every IP unit TB
// here equally (tb_dac_fsm.v fails the same way) — use the standalone flow
// above, or generate the BD output products first.
// ============================================================================

module tb_ip_two_discharge;

    // ---- register offsets (byte addresses) ----
    localparam [6:0] REG_DIS_MODE   = 7'h14;   // slv_reg5
    localparam [6:0] REG_DIS_MANUAL = 7'h18;   // slv_reg6
    localparam [6:0] REG_DIS_N      = 7'h1C;   // slv_reg7

    // ---- pin polarity ----
    localparam PIN_DISCHARGING = 1'b0;
    localparam PIN_OFF         = 1'b1;

    // ---- clock / reset ----
    reg clk_100;
    reg aresetn;

    // ---- IP_Two user-domain inputs (from IP_1) ----
    reg        done_tick;
    reg        total_tick;
    reg [2:0]  cha_cnt;

    // ---- outputs ----
    wire [2:0] mux1, mux2;
    wire       EIT_IN_EN, gain, reset_o;
    wire       Electrode_Discharge;

    // ---- AXI4-Lite (write path only) ----
    reg  [6:0]  awaddr;
    reg         awvalid;
    reg  [31:0] wdata;
    reg  [3:0]  wstrb;
    reg         wvalid;
    reg         bready;
    wire        awready, wready, bvalid;
    wire [1:0]  bresp;

    integer errors = 0;
    integer k;
    integer n_eff;
    reg     exp_pin;

    // snapshots used to prove the discharge window touches nothing else
    reg [2:0] mux1_before, mux2_before;
    reg       eit_before;

    // 100 MHz clock -> 10 ns period
    initial clk_100 = 1'b0;
    always #5 clk_100 = ~clk_100;

    // ------------------------------------------------------------------
    // DUT: IP_Two top wrapper. clk and s00_axi_aclk both on the 100 MHz
    // clock, and rst_n tied to aresetn, as in the block design.
    // ------------------------------------------------------------------
    IP_Two #(
        .C_S00_AXI_DATA_WIDTH(32),
        .C_S00_AXI_ADDR_WIDTH(7)
    ) dut (
        .clk                 (clk_100),
        .rst_n               (aresetn),
        .done_tick           (done_tick),
        .total_tick          (total_tick),
        .cha_cnt             (cha_cnt),
        .mux1                (mux1),
        .mux2                (mux2),
        .EIT_IN_EN           (EIT_IN_EN),
        .gain                (gain),
        .reset               (reset_o),
        .Electrode_Discharge (Electrode_Discharge),

        .s00_axi_aclk    (clk_100),
        .s00_axi_aresetn (aresetn),
        .s00_axi_awaddr  (awaddr),
        .s00_axi_awprot  (3'b000),
        .s00_axi_awvalid (awvalid),
        .s00_axi_awready (awready),
        .s00_axi_wdata   (wdata),
        .s00_axi_wstrb   (wstrb),
        .s00_axi_wvalid  (wvalid),
        .s00_axi_wready  (wready),
        .s00_axi_bresp   (bresp),
        .s00_axi_bvalid  (bvalid),
        .s00_axi_bready  (bready),
        .s00_axi_araddr  (7'h00),
        .s00_axi_arprot  (3'b000),
        .s00_axi_arvalid (1'b0),
        .s00_axi_arready (),
        .s00_axi_rdata   (),
        .s00_axi_rresp   (),
        .s00_axi_rvalid  (),
        .s00_axi_rready  (1'b0)
    );

    // ------------------------------------------------------------------
    // Helpers
    // ------------------------------------------------------------------
    task axi_write;
        input [6:0]  addr;
        input [31:0] data;
    begin
        @(posedge clk_100);
        awaddr  <= addr;
        wdata   <= data;
        wstrb   <= 4'hF;
        awvalid <= 1'b1;
        wvalid  <= 1'b1;
        bready  <= 1'b1;
        @(posedge clk_100);   // register captured on this edge
        awvalid <= 1'b0;
        wvalid  <= 1'b0;
        @(posedge clk_100);
        bready  <= 1'b0;
        @(posedge clk_100);
    end
    endtask

    // One total_tick pulse, exactly one clock wide (as IP_1 emits it).
    task inject_total_tick;
    begin
        @(posedge clk_100);
        total_tick <= 1'b1;
        @(posedge clk_100);   // DUT samples total_tick=1 on this edge
        total_tick <= 1'b0;
        @(posedge clk_100);
    end
    endtask

    task check_pin;
        input            exp;
        input [60*8-1:0] label;
    begin
        if (Electrode_Discharge !== exp) begin
            $display("FAIL: %0s -> Electrode_Discharge=%b, expected %b (t=%0t)",
                     label, Electrode_Discharge, exp, $time);
            errors = errors + 1;
        end
        else begin
            $display("  ok: %0s -> Electrode_Discharge=%b", label, exp);
        end
    end
    endtask

    // Nothing outside the discharge pin may move.
    task check_untouched;
        input [60*8-1:0] label;
    begin
        if (mux1 !== mux1_before || mux2 !== mux2_before || EIT_IN_EN !== eit_before) begin
            $display("FAIL: %0s -> discharge disturbed mux/EIT_IN_EN: mux1=%b(was %b) mux2=%b(was %b) EIT_IN_EN=%b(was %b) (t=%0t)",
                     label, mux1, mux1_before, mux2, mux2_before,
                     EIT_IN_EN, eit_before, $time);
            errors = errors + 1;
        end
    end
    endtask

    // Drive `count` ticks in automatic mode and check the pin after each one
    // against the reference model. Assumes the counter was just restarted
    // (i.e. automatic mode was entered immediately before the first tick).
    task run_auto_ticks;
        input integer n;        // programmed N (already mapped: 0 -> 1)
        input integer count;    // number of ticks to drive
    begin
        for (k = 1; k <= count; k = k + 1) begin
            mux1_before = mux1;
            mux2_before = mux2;
            eit_before  = EIT_IN_EN;

            inject_total_tick;

            exp_pin = ((k % (n + 1)) == n) ? PIN_DISCHARGING : PIN_OFF;
            if (Electrode_Discharge !== exp_pin) begin
                $display("FAIL: auto N=%0d tick %0d -> Electrode_Discharge=%b, expected %b (t=%0t)",
                         n, k, Electrode_Discharge, exp_pin, $time);
                errors = errors + 1;
            end
            else begin
                $display("  ok: auto N=%0d tick %0d -> %b", n, k, exp_pin);
            end

            check_untouched("auto tick");

            // the level must hold for the whole interval, not just one clock
            repeat (25) @(posedge clk_100);
            if (Electrode_Discharge !== exp_pin) begin
                $display("FAIL: auto N=%0d tick %0d -> level not held (%b, expected %b) (t=%0t)",
                         n, k, Electrode_Discharge, exp_pin, $time);
                errors = errors + 1;
            end
        end
    end
    endtask

    // ------------------------------------------------------------------
    // Stimulus
    // ------------------------------------------------------------------
    initial begin
        $display("=== tb_ip_two_discharge ===");

        aresetn    = 1'b0;
        done_tick  = 1'b0;
        total_tick = 1'b0;
        cha_cnt    = 3'd0;
        awaddr     = 7'h00;
        awvalid    = 1'b0;
        wdata      = 32'h0;
        wstrb      = 4'h0;
        wvalid     = 1'b0;
        bready     = 1'b0;

        repeat (10) @(posedge clk_100);

        // ---------------------------------------------------------------
        // 1. Reset default: manual mode + off -> pin high (not discharging)
        // ---------------------------------------------------------------
        check_pin(PIN_OFF, "reset default (manual, off)");

        aresetn = 1'b1;
        repeat (5) @(posedge clk_100);
        check_pin(PIN_OFF, "after reset release");

        // Ticks must do nothing while in manual mode.
        repeat (6) inject_total_tick;
        check_pin(PIN_OFF, "manual mode ignores total_tick");

        // ---------------------------------------------------------------
        // 2. Manual mode: slv_reg6[0] drives the pin directly
        // ---------------------------------------------------------------
        mux1_before = mux1;
        mux2_before = mux2;
        eit_before  = EIT_IN_EN;

        axi_write(REG_DIS_MANUAL, 32'h1);          // discharge ON
        check_pin(PIN_DISCHARGING, "manual reg6=1");
        check_untouched("manual discharge");

        axi_write(REG_DIS_MANUAL, 32'h0);          // discharge OFF
        check_pin(PIN_OFF, "manual reg6=0");

        axi_write(REG_DIS_MANUAL, 32'h1);          // leave it set on purpose
        check_pin(PIN_DISCHARGING, "manual reg6=1 again");

        // ---------------------------------------------------------------
        // 3. Automatic mode, N = 3: 3 idle intervals then 1 discharge
        //    interval, repeating. Entering automatic mode must also override
        //    the manual bit, which is still 1 from the step above.
        // ---------------------------------------------------------------
        axi_write(REG_DIS_N,    32'd3);
        axi_write(REG_DIS_MODE, 32'h1);            // automatic
        check_pin(PIN_OFF, "auto entry overrides manual bit");

        run_auto_ticks(3, 13);                     // >3 full periods

        // ---------------------------------------------------------------
        // 4. Switching back to manual resets the automatic counter, so
        //    re-entering automatic mode starts a fresh count of N.
        // ---------------------------------------------------------------
        inject_total_tick;                          // leave a partial count
        axi_write(REG_DIS_MODE,   32'h0);           // manual (reg6 still 1)
        check_pin(PIN_DISCHARGING, "manual bit takes over again");

        axi_write(REG_DIS_MANUAL, 32'h0);
        axi_write(REG_DIS_MODE,   32'h1);           // back to automatic
        check_pin(PIN_OFF, "re-entered automatic mode");
        run_auto_ticks(3, 8);                       // must count from 1 again

        // ---------------------------------------------------------------
        // 5. N = 0 maps to 1 (house "0 = default" convention):
        //    discharge every other injection cycle.
        // ---------------------------------------------------------------
        axi_write(REG_DIS_MODE, 32'h0);             // park + reset the counter
        axi_write(REG_DIS_N,    32'd0);
        axi_write(REG_DIS_MODE, 32'h1);
        run_auto_ticks(1, 6);                       // n_eff = 1

        // ---------------------------------------------------------------
        // 6. N = 1 explicitly behaves the same as N = 0.
        // ---------------------------------------------------------------
        axi_write(REG_DIS_MODE, 32'h0);
        axi_write(REG_DIS_N,    32'd1);
        axi_write(REG_DIS_MODE, 32'h1);
        run_auto_ticks(1, 6);

        // ---------------------------------------------------------------
        // 7. Asynchronous reset while discharging returns the pin to off.
        // ---------------------------------------------------------------
        axi_write(REG_DIS_MODE, 32'h0);
        axi_write(REG_DIS_N,    32'd1);
        axi_write(REG_DIS_MODE, 32'h1);
        inject_total_tick;
        check_pin(PIN_DISCHARGING, "discharging before reset");

        aresetn = 1'b0;
        repeat (3) @(posedge clk_100);
        check_pin(PIN_OFF, "reset during discharge -> pin off");
        aresetn = 1'b1;
        repeat (3) @(posedge clk_100);
        check_pin(PIN_OFF, "still off after reset release");

        // ---------------------------------------------------------------
        $display("=== tb_ip_two_discharge: %0d error(s) ===", errors);
        if (errors == 0)
            $display("TEST PASSED");
        else
            $display("TEST FAILED");
        $finish;
    end

    // Watchdog so a stuck run never hangs the batch flow (sim.tcl runs "all").
    initial begin
        #500000;
        $display("FAIL: watchdog timeout");
        $display("TEST FAILED");
        $finish;
    end

endmodule
