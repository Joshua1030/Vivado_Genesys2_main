`timescale 1ns / 1ps
// ============================================================================
// tb_dac_fsm.v — self-checking testbench for the AD5686R DAC driver FSM
//
// Exercises the programmable-SCLK + update-rate features added to
// ip_repo/FSM_1_0/hdl/myip_slave_lite_v1_0_S00_AXI.v:
//   slv_reg0[7:0] = N  -> SCLK = 100 MHz / (2*N)   (0 => default N=2 = 25 MHz)
//   slv_reg1[31:0]     = DAC update period in clk cycles (0 = free-run)
//
// clk and s00_axi_aclk share one 100 MHz clock here, mirroring the block
// design where FSM_0/clk was moved onto the 100 MHz net. Pure-Verilog DUT,
// so this runs in XSim behavioral mode with no license.
//
// Run (standalone XSim, from TIS_EIT_V2/):
//   xvlog ip_repo/FSM_1_0/hdl/myip.v \
//         ip_repo/FSM_1_0/hdl/myip_slave_lite_v1_0_S00_AXI.v \
//         sim/tb_dac_fsm.v
//   xelab -debug typical tb_dac_fsm -s tb_dac_fsm_sim
//   xsim tb_dac_fsm_sim -runall
// Or via the project flow:
//   vivado -mode batch -source scripts/sim.tcl -tclargs tb_dac_fsm
// ============================================================================

module tb_dac_fsm;

    // ---- clock / reset ----
    reg clk_100;
    reg aresetn;

    // ---- FSM user-domain inputs ----
    reg        update_tick;
    reg [15:0] sine_A, sine_B, sine_C, sine_D;

    // ---- DAC outputs ----
    wire dac_sclk, dac_sync, dac_sdo, dac_ldac;
    wire clk_A, clk_B, clk_C, clk_D;

    // ---- AXI4-Lite (write path only) ----
    reg  [5:0]  awaddr;
    reg         awvalid;
    reg  [31:0] wdata;
    reg  [3:0]  wstrb;
    reg         wvalid;
    reg         bready;
    wire        awready, wready, bvalid;
    wire [1:0]  bresp;

    integer errors = 0;
    real meas_period;   // last measured SCLK period (ns)
    real meas_ldac;     // last measured LDAC low width (ns)
    real meas_update;   // last measured loop (update) period (ns)

    // 100 MHz clock -> 10 ns period
    initial clk_100 = 1'b0;
    always #5 clk_100 = ~clk_100;

    // ------------------------------------------------------------------
    // DUT: FSM top. clk and s00_axi_aclk both driven by the 100 MHz clock,
    // as in the block design after moving FSM_0/clk to the 100 MHz net.
    // ------------------------------------------------------------------
    myip #(
        .C_S00_AXI_DATA_WIDTH (32),
        .C_S00_AXI_ADDR_WIDTH (6)
    ) dut (
        .clk         (clk_100),
        .rst_n       (aresetn),
        .update_tick (update_tick),
        .sine_data_A (sine_A),
        .sine_data_B (sine_B),
        .sine_data_C (sine_C),
        .sine_data_D (sine_D),
        .dac_sclk    (dac_sclk),
        .dac_sync    (dac_sync),
        .dac_sdo     (dac_sdo),
        .dac_ldac    (dac_ldac),
        .clk_A       (clk_A),
        .clk_B       (clk_B),
        .clk_C       (clk_C),
        .clk_D       (clk_D),
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
        .s00_axi_araddr  (6'b0),
        .s00_axi_arprot  (3'b000),
        .s00_axi_arvalid (1'b0),
        .s00_axi_arready (),
        .s00_axi_rdata   (),
        .s00_axi_rresp   (),
        .s00_axi_rvalid  (),
        .s00_axi_rready  (1'b0)
    );

    // ------------------------------------------------------------------
    // AXI-Lite single write. This slave latches the register whenever
    // WVALID is high (address taken from AWADDR when AWVALID is high), so
    // driving AW+W together for one cycle performs exactly one write.
    // ------------------------------------------------------------------
    task axi_write;
        input [5:0]  addr;
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

    // Wait for the new divider to be latched (div_n updates in STATE_IDLE):
    // let two full loops elapse (two LDAC pulses) before measuring.
    task settle_two_loops;
    begin
        @(negedge dac_ldac);
        @(negedge dac_ldac);
    end
    endtask

    // Average SCLK period over a mid-frame window (avoids frame boundaries).
    task measure_sclk;
        real t1, t2;
    begin
        @(negedge dac_sync);            // start of an SPI frame
        repeat (3) @(negedge dac_sclk); // skip the first few edges
        t1 = $realtime;
        repeat (10) @(negedge dac_sclk);
        t2 = $realtime;
        meas_period = (t2 - t1) / 10.0;
    end
    endtask

    // LDAC low-pulse width.
    task measure_ldac_low;
        real t1, t2;
    begin
        @(negedge dac_ldac);
        t1 = $realtime;
        @(posedge dac_ldac);
        t2 = $realtime;
        meas_ldac = t2 - t1;
    end
    endtask

    // Loop (DAC update) period = spacing between successive LDAC pulses.
    task measure_loop_period;
        real t1, t2;
    begin
        @(negedge dac_ldac);
        t1 = $realtime;
        @(negedge dac_ldac);
        t2 = $realtime;
        meas_update = t2 - t1;
    end
    endtask

    task check_real;
        input [255:0] name;
        input real    got;
        input real    exp;
        input real    tol;
    begin
        if (got > (exp - tol) && got < (exp + tol))
            $display("[PASS] %0s = %0.2f ns (expected %0.2f)", name, got, exp);
        else begin
            $display("[FAIL] %0s = %0.2f ns (expected %0.2f +/- %0.2f)",
                     name, got, exp, tol);
            errors = errors + 1;
        end
    end
    endtask

    // ------------------------------------------------------------------
    // Stimulus
    // ------------------------------------------------------------------
    initial begin
        update_tick = 1'b0;
        sine_A = 16'hA000; sine_B = 16'hB000; sine_C = 16'hC000; sine_D = 16'hD000;
        awaddr = 6'b0; awvalid = 1'b0; wdata = 32'b0; wstrb = 4'b0;
        wvalid = 1'b0; bready = 1'b0;

        aresetn = 1'b0;
        repeat (8) @(posedge clk_100);
        aresetn = 1'b1;
        update_tick = 1'b1;              // mirror BD: update_tick tied high
        repeat (4) @(posedge clk_100);

        // ---- default divider: no write, div_n = DEFAULT_N = 2 -> 25 MHz ----
        settle_two_loops;
        measure_sclk;
        check_real("default SCLK period (N=2)", meas_period, 40.0, 2.0); // 25 MHz
        measure_ldac_low;
        check_real("default LDAC low (N=2)",    meas_ldac,   80.0, 2.0); // 4*N*10

        // ---- N=1 -> 50 MHz ----
        axi_write(6'h00, 32'd1);
        settle_two_loops;
        measure_sclk;
        check_real("SCLK period (N=1)", meas_period, 20.0, 2.0);         // 50 MHz
        measure_ldac_low;
        check_real("LDAC low (N=1)",    meas_ldac,   40.0, 2.0);         // 4*1*10

        // ---- N=4 -> 12.5 MHz ----
        axi_write(6'h00, 32'd4);
        settle_two_loops;
        measure_sclk;
        check_real("SCLK period (N=4)", meas_period, 80.0, 4.0);         // 12.5 MHz
        measure_ldac_low;
        check_real("LDAC low (N=4)",    meas_ldac,  160.0, 4.0);         // 4*4*10

        // ---- update-rate decoupling: fixed 50 us loop period (still N=4) ----
        axi_write(6'h04, 32'd5000);      // 5000 clk * 10 ns = 50 us
        measure_loop_period;             // first spacing may be partial
        measure_loop_period;             // this one is a full programmed period
        check_real("update period (reg1=5000)", meas_update, 50000.0, 200.0);

        // ---- back to free-run (reg1=0) ----
        axi_write(6'h04, 32'd0);
        settle_two_loops;
        measure_loop_period;
        // free-run loop at N=4 ~ (204*4+9)*10 ns = 8250 ns; must be << 50 us
        if (meas_update < 20000.0)
            $display("[PASS] free-run resumed: loop period = %0.2f ns (<< 50 us)",
                     meas_update);
        else begin
            $display("[FAIL] free-run not resumed: loop period = %0.2f ns",
                     meas_update);
            errors = errors + 1;
        end

        $display("-----------------------------------------------------------");
        if (errors == 0) $display("TB RESULT: ALL CHECKS PASSED");
        else             $display("TB RESULT: %0d CHECK(S) FAILED", errors);
        $display("-----------------------------------------------------------");
        $finish;
    end

    // safety timeout
    initial begin
        #2000000;   // 2 ms
        $display("[FAIL] TIMEOUT - simulation did not finish");
        $finish;
    end

endmodule
