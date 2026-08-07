`timescale 1ns / 1ps
// ============================================================================
// tb_scan_chain.v — self-checking testbench for the EIT scan-IP chain
//
// Verifies the sequencer + both mux controllers WITHOUT the MicroBlaze:
//   IP_1     (module IP_1)   — TIS/EIT sequencer: 100 MHz time base -> done_tick /
//                              total_tick / chanel_cnt / dac_ch_sel / tis_on
//   IP_Two   (module IP_Two) — DAC source mux, latches on negedge done_tick
//   IP_Three (module myip)   — ADC sense mux, advances on mclk_negedge
//
// The point of this bench is the *chain*: that the two mux controllers, driven
// only by IP_1's done_tick and dac_ch_sel, together visit all 64
// {injection pair, sense channel} combinations exactly once per frame — in BOTH
// scan modes — and that the source and sense muxes are never shorted together.
//
//   mode A (IP_1 scan_mode=1 + IP_Three scheme=2'b10 "cycle-paced"):
//       sense channel fixed for a whole stimulation, DAC pair every 8
//       -> 64 stimulations per frame
//   mode B (IP_1 scan_mode=0 + IP_Three scheme=2'b01 "nested legacy"):
//       sense channel sweeps all 8 inside each stimulation, DAC pair every one
//       -> 8 stimulations per frame
//
// Both reach the same 64-combination coverage; that equivalence is the property
// worth regressing, since main.c derives both registers from one SCAN_MODE knob.
//
// Timing is scaled down hard (stimulation = 400 clk instead of 20_000_000) but
// keeps the hardware ratios 90:100:200. Config registers are applied by
// hierarchical `force` — the sim equivalent of the MCU having written them.
// Pure-Verilog DUTs, so it runs in behavioral XSim with no license.
//
// Run:
//   vivado -mode batch -source scripts/sim.tcl -tclargs tb_scan_chain
// ============================================================================

module tb_scan_chain;

    // ---------------- scaled config ----------------
    localparam integer STIM_PERIOD  = 400;      // clk per stimulation
    localparam integer TIS_DELAY    = 180;      // 90/200 of the period
    localparam integer TIS_DURATION = 200;      // 100/200
    localparam integer NERVE_DELAY  = 10;
    localparam integer NERVE_WIDTH  = 20;
    localparam integer FRAMES       = 1;
    localparam integer DEBOUNCE     = 20;
    localparam integer MCLK_PERIOD  = 40;       // clk per ADC conversion (10 per stim)

    // ---------------- clock / reset ----------------
    reg clk = 1'b0;
    reg aresetn = 1'b0;
    always #5 clk = ~clk;                       // 100 MHz

    // ---------------- modelled ADC conversion strobe (ltc_driver_fsm/o_mclk) ----
    // High for 4 clk like the real driver (CYCLES_MCLKH=3), then low. IP_Three
    // moves the sense mux on the *falling* edge (inside the LTC2500 hold window).
    reg o_mclk = 1'b0;
    integer mclk_cnt = 0;
    always @(posedge clk) begin
        mclk_cnt <= (mclk_cnt == MCLK_PERIOD-1) ? 0 : mclk_cnt + 1;
        o_mclk   <= (mclk_cnt < 4);
    end

    // ---------------- DUT interconnect ----------------
    reg         btn = 1'b0;
    wire        done_tick, total_tick, ip1_enable, ip1_sync;
    wire        tis_on, dds_hold, nerve_pulse, run_active;
    wire [2:0]  chanel_cnt, dac_ch_sel;
    wire [2:0]  mux1, mux2;
    wire [2:0]  adc_ch;

    // ---------------- IP_1 — TIS/EIT sequencer ----------------
    IP_1 #(
        .DEBOUNCE_CYCLES(DEBOUNCE),
        .C_S00_AXI_DATA_WIDTH(32), .C_S00_AXI_ADDR_WIDTH(7)
    ) u_ip1 (
        .clk(clk), .rst_n(aresetn),
        .address(16'd0), .CLK_A(1'b0),          // vestigial ports
        .btn_start(btn),
        .done_tick(done_tick), .total_tick(total_tick),
        .chanel_cnt(chanel_cnt), .sync(ip1_sync), .enable(ip1_enable),
        .dac_ch_sel(dac_ch_sel),
        .tis_on(tis_on), .dds_hold(dds_hold),
        .nerve_pulse(nerve_pulse), .run_active(run_active),
        .o_cycle_done(), .o_addr_msb(),
        .s00_axi_aclk(clk), .s00_axi_aresetn(aresetn),
        .s00_axi_awaddr(7'd0), .s00_axi_awprot(3'd0), .s00_axi_awvalid(1'b0), .s00_axi_awready(),
        .s00_axi_wdata(32'd0), .s00_axi_wstrb(4'd0), .s00_axi_wvalid(1'b0), .s00_axi_wready(),
        .s00_axi_bresp(), .s00_axi_bvalid(), .s00_axi_bready(1'b0),
        .s00_axi_araddr(7'd0), .s00_axi_arprot(3'd0), .s00_axi_arvalid(1'b0), .s00_axi_arready(),
        .s00_axi_rdata(), .s00_axi_rresp(), .s00_axi_rvalid(), .s00_axi_rready(1'b0)
    );

    // ---------------- IP_Two — DAC source mux ----------------
    IP_Two #(.C_S00_AXI_DATA_WIDTH(32), .C_S00_AXI_ADDR_WIDTH(7)) u_ip2 (
        .clk(clk), .rst_n(aresetn),
        .done_tick(done_tick), .total_tick(total_tick), .cha_cnt(dac_ch_sel),
        .mux1(mux1), .mux2(mux2), .EIT_IN_EN(), .gain(), .reset(),
        .Electrode_Discharge(),
        .s00_axi_aclk(clk), .s00_axi_aresetn(aresetn),
        .s00_axi_awaddr(7'd0), .s00_axi_awprot(3'd0), .s00_axi_awvalid(1'b0), .s00_axi_awready(),
        .s00_axi_wdata(32'd0), .s00_axi_wstrb(4'd0), .s00_axi_wvalid(1'b0), .s00_axi_wready(),
        .s00_axi_bresp(), .s00_axi_bvalid(), .s00_axi_bready(1'b0),
        .s00_axi_araddr(7'd0), .s00_axi_arprot(3'd0), .s00_axi_arvalid(1'b0), .s00_axi_arready(),
        .s00_axi_rdata(), .s00_axi_rresp(), .s00_axi_rvalid(), .s00_axi_rready(1'b0)
    );

    // ---------------- IP_Three — ADC sense mux ----------------
    myip #(.C_S00_AXI_DATA_WIDTH(32), .C_S00_AXI_ADDR_WIDTH(4)) u_ip3 (
        .clk(clk), .rst_n(aresetn),
        .master_clk(o_mclk), .sw_ch0(1'b0), .sw_ch1(1'b0), .sw_ch2(1'b0),
        .done_tick(done_tick), .run(1'b1),
        .mux(), .prev_master_clk(), .current_master_clk(), .enable(),
        .o_ja1(), .o_ja2(), .o_ja3(), .o_ja4(), .o_ja5(), .o_ja6(),
        .adc_ch(adc_ch), .adc_start(),
        .s00_axi_aclk(clk), .s00_axi_aresetn(aresetn),
        .s00_axi_awaddr(4'd0), .s00_axi_awprot(3'd0), .s00_axi_awvalid(1'b0), .s00_axi_awready(),
        .s00_axi_wdata(32'd0), .s00_axi_wstrb(4'd0), .s00_axi_wvalid(1'b0), .s00_axi_wready(),
        .s00_axi_bresp(), .s00_axi_bvalid(), .s00_axi_bready(1'b0),
        .s00_axi_araddr(4'd0), .s00_axi_arprot(3'd0), .s00_axi_arvalid(1'b0), .s00_axi_arready(),
        .s00_axi_rdata(), .s00_axi_rresp(), .s00_axi_rvalid(), .s00_axi_rready(1'b0)
    );

    `define IP1 u_ip1.IP_1_slave_lite_v1_0_S00_AXI_inst
    `define IP3 u_ip3.myip_slave_lite_v1_0_S00_AXI_inst

    // ---------------- observers ----------------
    // Sample the {injection pair, sense channel} combination at the MCLK RISING
    // edge — the LTC2500 aperture, i.e. exactly where ethernet_debug latches the
    // channel tag it ships to the host.
    reg [63:0] combo_seen;
    reg        mclk_d = 1'b0;
    integer    errors = 0;
    integer    short_errs = 0;

    always @(posedge clk) begin
        mclk_d <= o_mclk;
        if (aresetn && o_mclk && !mclk_d && run_active)
            combo_seen[{dac_ch_sel, adc_ch}] <= 1'b1;

        // Hard safety property: the source and sense mux must never select the
        // same electrode. IP_Two has a defensive override for this; if it ever
        // fires we want to know.
        if (aresetn && (mux1 === mux2)) begin
            short_errs = short_errs + 1;
            if (short_errs < 5)
                $display("[FAIL @%0t] mux1 == mux2 == %0d (source/sense shorted)",
                         $time, mux1);
        end
    end

    // ---------------- run one frame in a given mode ----------------
    task run_mode;
        input        mode;              // 1 = A (64 stim/frame), 0 = B (8 stim/frame)
        input [1:0]  ip3_scheme;        // 2'b10 cycle-paced (A) / 2'b01 nested (B)
        input integer want_stims;
        integer guard, i, n;
        begin
            $display("");
            $display("=== mode %s : scan_mode=%0d, IP_Three scheme=%0d, %0d stimulations ===",
                     mode ? "A (held)" : "B (multiplexed)", mode, ip3_scheme, want_stims);

            force `IP1.slv_reg2 = {31'd0, mode};
            force `IP3.slv_reg2 = {30'd0, ip3_scheme};
            combo_seen = 64'd0;

            // press BTNU (with bounce) to start the run
            for (i = 0; i < 6; i = i + 1) begin
                btn = ~btn;
                repeat (2) @(posedge clk);
            end
            btn = 1'b1;
            repeat (DEBOUNCE * 3) @(posedge clk);

            if (!run_active) begin
                errors = errors + 1;
                $display("[FAIL] run_active did not assert after button press");
            end
            btn = 1'b0;

            guard = 0;
            while (run_active && guard < (want_stims + 4) * STIM_PERIOD * 2) begin
                @(posedge clk);
                guard = guard + 1;
            end
            repeat (MCLK_PERIOD * 2) @(posedge clk);

            n = 0;
            for (i = 0; i < 64; i = i + 1)
                if (combo_seen[i]) n = n + 1;

            $display("  combinations visited: %0d / 64", n);
            if (n !== 64) begin
                errors = errors + 1;
                $display("[FAIL] only %0d of 64 {dac,adc} combinations were measured", n);
                for (i = 0; i < 64; i = i + 1)
                    if (!combo_seen[i])
                        $display("        missing dac=%0d adc=%0d", i[5:3], i[2:0]);
            end else
                $display("[PASS] all 64 {injection pair, sense channel} combinations visited");
        end
    endtask

    // ---------------- stimulus ----------------
    initial begin
        force `IP1.slv_reg3 = STIM_PERIOD;
        force `IP1.slv_reg4 = TIS_DELAY;
        force `IP1.slv_reg5 = TIS_DURATION;
        force `IP1.slv_reg6 = NERVE_DELAY;
        force `IP1.slv_reg7 = NERVE_WIDTH;
        force `IP1.slv_reg8 = FRAMES;
        force `IP1.slv_reg9 = 32'd0;
        force `IP3.slv_reg1 = 32'd0;        // IP_Three: automatic mode
        force `IP1.slv_reg2 = 32'd1;
        force `IP3.slv_reg2 = 32'd2;

        aresetn = 1'b0;
        repeat (10) @(posedge clk);
        aresetn = 1'b1;
        repeat (5) @(posedge clk);

        run_mode(1'b1, 2'b10, FRAMES*64);   // mode A
        run_mode(1'b0, 2'b01, FRAMES*8);    // mode B

        if (short_errs != 0) begin
            errors = errors + 1;
            $display("[FAIL] source/sense mux were shorted on %0d cycles", short_errs);
        end else
            $display("[PASS] source/sense mux never shorted");

        $display("");
        $display("-----------------------------------------------------------");
        if (errors == 0) $display("TB RESULT: ALL CHECKS PASSED");
        else             $display("TB RESULT: %0d CHECK(S) FAILED", errors);
        $display("-----------------------------------------------------------");
        $finish;
    end

    // watchdog — sim.tcl runs XSim with "run all", so never hang
    initial begin
        #20_000_000;
        $display("[FAIL] TIMEOUT - simulation did not finish");
        $finish;
    end

endmodule
