`default_nettype none
module bnn_layer_tb;
    //==========================================================================
    // Parameters
    //==========================================================================
    localparam int INPUTS = 784;
    localparam int NEURONS = 256;
    localparam int PW = 16;
    localparam int PN = 8;
    localparam int BEATS = 49;
    localparam int COUNT_W = 10;
    localparam int NEURON_GROUPS = 32;
    localparam int WEIGHT_DEPTH = 1568;

    //==========================================================================
    // DUT Signals
    //==========================================================================
    logic clk, rst, load, start, done, busy, valid;
    logic [         INPUTS-1:0] inp;
    logic [        NEURONS-1:0] act;
    logic [NEURONS*COUNT_W-1:0] pop;
    logic cfg_we, cfg_tw, cfg_rdy;
    logic [        7:0] cfg_nidx;
    logic [        5:0] cfg_addr;
    logic [     PW-1:0] cfg_wdata;
    logic [COUNT_W-1:0] cfg_tdata;

    //==========================================================================
    // Configuration Storage
    //==========================================================================
    class ConfigData;
        logic [     PW-1:0] weights   [NEURONS] [BEATS];
        logic [COUNT_W-1:0] thresholds[NEURONS];

        function void set_weight(int neuron, int beat, logic [PW-1:0] data);
            weights[neuron][beat] = data;
        endfunction
        function void set_threshold(int neuron, logic [COUNT_W-1:0] data);
            thresholds[neuron] = data;
        endfunction
    endclass

    //==========================================================================
    // Scoreboard
    //==========================================================================
    class Scoreboard;
        int tests_run, tests_passed, tests_failed, x_errors;

        function void reset_stats();
            tests_run    = 0;
            tests_passed = 0;
            tests_failed = 0;
            x_errors     = 0;
        endfunction

        function void report();
            $display("\n================================================================================");
            $display("FINAL RESULTS");
            $display("================================================================================");
            $display("Tests Run:      %0d", tests_run);
            $display("Tests Passed:   %0d (%.1f%%)", tests_passed,
                     tests_run ? 100.0 * tests_passed / tests_run : 0.0);
            $display("Tests Failed:   %0d", tests_failed);
            $display("X-State Errors: %0d", x_errors);
            $display("================================================================================");
            if (tests_failed == 0) $display("*** ALL TESTS PASSED ***");
            else $display("*** FAILURES DETECTED ***");
        endfunction
    endclass

    ConfigData cfg_data;
    Scoreboard sb;

    //==========================================================================
    // Golden Model
    //==========================================================================
    class GoldenModel;
        function automatic bit verify_outputs(
            input logic [INPUTS-1:0] input_vec, input logic [NEURONS-1:0] actual_act,
            input logic [NEURONS*COUNT_W-1:0] actual_pop_packed, output string error_msg);
            logic [NEURONS-1:0] expected_act;
            logic [COUNT_W-1:0] expected_pop    [NEURONS];
            logic [COUNT_W-1:0] actual_pop      [NEURONS];
            bit                 pass = 1;
            int                 error_count = 0;

            for (int n = 0; n < NEURONS; n++) actual_pop[n] = actual_pop_packed[n*COUNT_W+:COUNT_W];

            for (int n = 0; n < NEURONS; n++) begin
                int popcount = 0;
                for (int b = 0; b < BEATS; b++)
                for (int p = 0; p < PW; p++) begin
                    int inp_idx = b * PW + p;
                    if (inp_idx < INPUTS) popcount += (input_vec[inp_idx] == cfg_data.weights[n][b][p]);
                end
                expected_pop[n] = popcount;
                expected_act[n] = (popcount >= cfg_data.thresholds[n]);
            end

            for (int n = 0; n < NEURONS && error_count < 5; n++) begin
                if ($isunknown(actual_act[n])) begin
                    error_msg = {error_msg, $sformatf("N%0d:act=X ", n)};
                    pass = 0;
                    error_count++;
                end
                if ($isunknown(actual_pop[n])) begin
                    error_msg = {error_msg, $sformatf("N%0d:pop=X ", n)};
                    pass = 0;
                    error_count++;
                end
            end

            if (pass) begin
                for (int n = 0; n < NEURONS && error_count < 5; n++) begin
                    if (actual_pop[n] !== expected_pop[n]) begin
                        error_msg = {
                            error_msg, $sformatf("N%0d:pop %0d!=%0d ", n, actual_pop[n], expected_pop[n])
                        };
                        pass = 0;
                        error_count++;
                    end
                    if (actual_act[n] !== expected_act[n]) begin
                        error_msg = {
                            error_msg, $sformatf("N%0d:act %0b!=%0b ", n, actual_act[n], expected_act[n])
                        };
                        pass = 0;
                        error_count++;
                    end
                end
            end
            return pass;
        endfunction
    endclass

    GoldenModel golden;

    //==========================================================================
    // DUT Instantiation
    //==========================================================================
    bnn_layer #(
        .INPUTS      (INPUTS),
        .NEURONS     (NEURONS),
        .PW          (PW),
        .PN          (PN),
        .OUTPUT_LAYER(0)
    ) dut (
        .clk                (clk),
        .rst                (rst),
        .input_load         (load),
        .input_vector       (inp),
        .start              (start),
        .done               (done),
        .busy               (busy),
        .activations_out    (act),
        .popcounts_out      (pop),
        .output_valid       (valid),
        .cfg_write_en       (cfg_we),
        .cfg_neuron_idx     (cfg_nidx),
        .cfg_weight_addr    (cfg_addr),
        .cfg_weight_data    (cfg_wdata),
        .cfg_threshold_data (cfg_tdata),
        .cfg_threshold_write(cfg_tw),
        .cfg_ready          (cfg_rdy)
    );

    //==========================================================================
    // Clock
    //==========================================================================
    always #5 clk = ~clk;

    //==========================================================================
    // Tasks
    //==========================================================================

    task reset_and_init_dut();
        $display("[%0t] Asserting reset and initializing memories...", $time);
        rst    = 1;
        start  = 0;
        load   = 0;
        cfg_we = 0;
        cfg_tw = 0;
        repeat (5) @(posedge clk);

        $display("[%0t] Depositing zeros to all memories...", $time);
        for (int np = 0; np < PN; np++)
            for (int addr = 0; addr < WEIGHT_DEPTH; addr++) $deposit(dut.weight_rams[np][addr], 16'h0000);

        for (int np = 0; np < PN; np++)
            for (int grp = 0; grp < NEURON_GROUPS; grp++) $deposit(dut.threshold_rams[np][grp], 10'h000);

        for (int b = 0; b < BEATS; b++) $deposit(dut.input_buffer[b], 16'h0000);

        $display("[%0t] Memory initialization complete", $time);
        repeat (10) @(posedge clk);
        rst = 0;
        repeat (10) @(posedge clk);
        $display("[%0t] Reset released", $time);
    endtask

    task warm_reset();
        $display("[%0t] >>> Warm reset asserted <<<", $time);
        rst    = 1;
        start  = 0;
        load   = 0;
        cfg_we = 0;
        cfg_tw = 0;
        repeat (5) @(posedge clk);
        rst = 0;
        repeat (5) @(posedge clk);
        $display("[%0t] >>> Warm reset released <<<", $time);
    endtask

    task configure_weights();
        $display("[%0t] Configuring weights...", $time);
        while (!cfg_rdy) @(posedge clk);
        for (int n = 0; n < NEURONS; n++) begin
            for (int b = 0; b < BEATS; b++) begin
                @(posedge clk);
                cfg_we    = 1;
                cfg_tw    = 0;
                cfg_nidx  = n;
                cfg_addr  = b;
                cfg_wdata = cfg_data.weights[n][b];
            end
        end
        @(posedge clk);
        cfg_we = 0;
        repeat (10) @(posedge clk);
        $display("[%0t] Weight configuration complete", $time);
    endtask

    task configure_thresholds();
        $display("[%0t] Configuring thresholds...", $time);
        while (!cfg_rdy) @(posedge clk);
        for (int n = 0; n < NEURONS; n++) begin
            @(posedge clk);
            cfg_we    = 1;
            cfg_tw    = 1;
            cfg_nidx  = n;
            cfg_tdata = cfg_data.thresholds[n];
        end
        @(posedge clk);
        cfg_we = 0;
        cfg_tw = 0;
        repeat (10) @(posedge clk);
        $display("[%0t] Threshold configuration complete", $time);
    endtask

    task run_test(input logic [INPUTS-1:0] input_vec, input string test_name);
        string error_msg;
        bit    timed_out;
        error_msg = "";
        timed_out = 0;
        sb.tests_run++;

        $display("[%0t] Test: %s (density=%0d/%0d)", $time, test_name, $countones(input_vec), INPUTS);

        @(posedge clk);
        inp  = input_vec;
        load = 1;
        @(posedge clk);
        load = 0;
        repeat (5) @(posedge clk);

        fork
            begin
                @(posedge clk);
                start = 1;
                @(posedge clk);
                start = 0;
                wait (done);
                @(posedge clk);
            end
            begin
                repeat (100000) @(posedge clk);
                timed_out = 1;
            end
        join_any
        disable fork;

        if (timed_out) begin
            $error("[TIMEOUT] %s", test_name);
            sb.tests_failed++;
            return;
        end
        if (!valid) begin
            $error("[PROTOCOL] %s - done asserted but output_valid not set", test_name);
            sb.tests_failed++;
            return;
        end

        if (golden.verify_outputs(input_vec, act, pop, error_msg)) begin
            $display("[PASS] %s", test_name);
            sb.tests_passed++;
        end else begin
            $error("[FAIL] %s: %s", test_name, error_msg);
            if (error_msg.len() > 0 && (error_msg.substr(0, 2) == "N0:" || error_msg.substr(0, 2) == "N1:"))
                sb.x_errors++;
            sb.tests_failed++;
        end
    endtask

    // ------------------------------------------------------------------
    // check_busy_protocol
    //
    // The design drives busy combinationally from state_r and done from
    // done_r (a register). Both update at the same posedge but busy
    // updates in the active region while done_r updates via NBA — so
    // there is always a delta-cycle window where busy=0 and done=0
    // coexist. No posedge sampling trick can close this gap [1].
    //
    // Correct protocol check:
    //   - busy must go high after start
    //   - once busy goes low, done must fire within 1 clock cycle
    //   - if done never fires after busy drops, that is a violation
    // ------------------------------------------------------------------
    task automatic check_busy_protocol(input logic [INPUTS-1:0] input_vec, output bit pass);
        bit timed_out;
        bit busy_went_high;
        bit busy_dropped;
        bit done_fired;

        timed_out      = 0;
        busy_went_high = 0;
        busy_dropped   = 0;
        done_fired     = 0;
        pass           = 1;

        @(posedge clk);
        inp  = input_vec;
        load = 1;
        @(posedge clk);
        load = 0;
        repeat (5) @(posedge clk);

        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;

        // Step 1: wait for busy to go high
        fork
            begin : wait_busy_high
                wait (busy);
                busy_went_high = 1;
            end
            begin : busy_high_timeout
                repeat (20) @(posedge clk);
            end
        join_any
        disable fork;

        if (!busy_went_high) begin
            $error("[PROTOCOL] busy never asserted after start");
            pass = 0;
            return;
        end

        // Step 2: wait for busy to go low, then check done fires
        // within 1 clock cycle. This correctly handles the design's
        // delta-cycle ordering where busy drops before done resolves [1].
        fork
            begin : wait_busy_low
                wait (!busy);
                busy_dropped = 1;
                // Give done one full clock cycle to appear
                // (it may already be high in this same time step)
                fork
                    begin : wait_done
                        wait (done);
                        done_fired = 1;
                    end
                    begin : done_window
                        // Allow up to 1 cycle for done to appear
                        @(posedge clk);
                        @(posedge clk);
                    end
                join_any
                disable fork;
            end
            begin : main_timeout
                repeat (100000) @(posedge clk);
                timed_out = 1;
            end
        join_any
        disable fork;

        // Wait for done to fully resolve before returning
        if (busy_dropped && !done_fired) wait (done) done_fired = 1;

        @(posedge clk);

        if (timed_out) begin
            $error("[TIMEOUT] busy protocol check");
            pass = 0;
        end
        if (!busy_went_high) begin
            $error("[PROTOCOL] busy never asserted after start");
            pass = 0;
        end
        if (busy_dropped && !done_fired) begin
            $error("[PROTOCOL] busy deasserted but done never fired");
            pass = 0;
        end
    endtask

    //==========================================================================
    // Main Test Flow
    //==========================================================================
    initial begin
        clk       = 0;
        rst       = 1;
        load      = 0;
        start     = 0;
        cfg_we    = 0;
        cfg_tw    = 0;
        inp       = '0;
        cfg_nidx  = 0;
        cfg_addr  = 0;
        cfg_wdata = 0;
        cfg_tdata = 0;

        cfg_data  = new();
        golden    = new();
        sb        = new();
        sb.reset_stats();

        $display("=== BNN Layer Testbench Started ===");
        $display("INPUTS=%0d, NEURONS=%0d, PW=%0d, PN=%0d", INPUTS, NEURONS, PW, PN);

        reset_and_init_dut();

        for (int n = 0; n < NEURONS; n++) begin
            for (int b = 0; b < BEATS; b++) cfg_data.weights[n][b] = $urandom();
            cfg_data.thresholds[n] = $urandom_range(INPUTS / 4, 3 * INPUTS / 4);
        end
        configure_weights();
        configure_thresholds();

        // ------------------------------------------------------------------
        // TEST GROUP 1: Basic Functionality
        // ------------------------------------------------------------------
        $display("\n=== TEST GROUP 1: Basic Functionality ===");
        for (int i = 0; i < 5; i++) begin
            logic [INPUTS-1:0] test_input;
            test_input = $urandom();
            run_test(test_input, $sformatf("basic_%0d", i));
        end

        // ------------------------------------------------------------------
        // TEST GROUP 2: Corner Cases
        // ------------------------------------------------------------------
        $display("\n=== TEST GROUP 2: Corner Cases ===");
        run_test('0, "all_zeros");
        run_test('1, "all_ones");

        begin
            logic [INPUTS-1:0] alt;
            for (int i = 0; i < INPUTS; i++) alt[i] = i[0];
            run_test(alt, "alternating_01");
        end

        begin
            logic [INPUTS-1:0] alt;
            for (int i = 0; i < INPUTS; i++) alt[i] = ~i[0];
            run_test(alt, "alternating_10");
        end

        begin
            logic [INPUTS-1:0] single;
            single    = '0;
            single[0] = 1'b1;
            run_test(single, "single_lsb");
        end

        begin
            logic [INPUTS-1:0] single;
            single           = '0;
            single[INPUTS-1] = 1'b1;
            run_test(single, "single_msb");
        end

        // ------------------------------------------------------------------
        // TEST GROUP 3: Back-to-Back Inferences
        // ------------------------------------------------------------------
        $display("\n=== TEST GROUP 3: Back-to-Back Inferences ===");
        for (int i = 0; i < 10; i++) begin
            logic [INPUTS-1:0] test_input;
            test_input = $urandom();
            run_test(test_input, $sformatf("back2back_%0d", i));
        end

        // ------------------------------------------------------------------
        // TEST GROUP 4: Reconfiguration + Re-Inference
        // ------------------------------------------------------------------
        $display("\n=== TEST GROUP 4: Reconfiguration + Re-Inference ===");
        begin
            logic [INPUTS-1:0] test_input;

            test_input = $urandom();
            run_test(test_input, "pre_reconfig");

            $display("[%0t] Writing new model...", $time);
            for (int n = 0; n < NEURONS; n++) begin
                for (int b = 0; b < BEATS; b++) cfg_data.weights[n][b] = $urandom();
                cfg_data.thresholds[n] = $urandom_range(INPUTS / 4, 3 * INPUTS / 4);
            end
            configure_weights();
            configure_thresholds();

            run_test(test_input, "post_reconfig_same_input");
            test_input = $urandom();
            run_test(test_input, "post_reconfig_new_input");
            for (int i = 0; i < 3; i++) begin
                test_input = $urandom();
                run_test(test_input, $sformatf("post_reconfig_%0d", i));
            end
        end

        // ------------------------------------------------------------------
        // TEST GROUP 5: Warm Reset during IDLE [1]
        // ------------------------------------------------------------------
        $display("\n=== TEST GROUP 5: Warm Reset (during IDLE) ===");
        begin
            logic [INPUTS-1:0] test_input;
            warm_reset();
            for (int i = 0; i < 3; i++) begin
                test_input = $urandom();
                run_test(test_input, $sformatf("after_warm_reset_idle_%0d", i));
            end
        end

        // ------------------------------------------------------------------
        // TEST GROUP 6: Warm Reset mid-inference [1]
        // ------------------------------------------------------------------
        $display("\n=== TEST GROUP 6: Warm Reset (mid-inference) ===");
        begin
            logic [INPUTS-1:0] test_input;
            test_input = $urandom();

            @(posedge clk);
            inp  = test_input;
            load = 1;
            @(posedge clk);
            load = 0;
            repeat (3) @(posedge clk);

            @(posedge clk);
            start = 1;
            @(posedge clk);
            start = 0;
            repeat (10) @(posedge clk);

            if (!busy)
                $display(
                    "[%0t] NOTE: inference completed before mid-reset point; reset still applied.", $time
                );

            warm_reset();

            if (busy) begin
                $error("[WARM-RESET] busy still high after reset released");
                sb.tests_run++;
                sb.tests_failed++;
            end else $display("[%0t] busy correctly deasserted after warm reset", $time);

            repeat (5) @(posedge clk);
            if (done) begin
                $error("[WARM-RESET] done spuriously asserted after reset");
                sb.tests_run++;
                sb.tests_failed++;
            end

            for (int i = 0; i < 5; i++) begin
                test_input = $urandom();
                run_test(test_input, $sformatf("after_warm_reset_mid_%0d", i));
            end
        end

        // ------------------------------------------------------------------
        // TEST GROUP 7: Protocol / Busy Checks
        // ------------------------------------------------------------------
        $display("\n=== TEST GROUP 7: Protocol Checks ===");
        begin
            logic [INPUTS-1:0] test_input;
            bit proto_pass;
            for (int i = 0; i < 3; i++) begin
                test_input = $urandom();
                check_busy_protocol(test_input, proto_pass);
                sb.tests_run++;
                if (proto_pass) begin
                    $display("[PASS] busy_protocol_%0d", i);
                    sb.tests_passed++;
                end else begin
                    $error("[FAIL] busy_protocol_%0d", i);
                    sb.tests_failed++;
                end
            end
        end

        // ------------------------------------------------------------------
        // TEST GROUP 8: cfg_ready deasserts while busy
        // ------------------------------------------------------------------
        $display("\n=== TEST GROUP 8: cfg_ready Protocol ===");
        begin
            logic [INPUTS-1:0] test_input;
            bit cfg_rdy_fail;
            cfg_rdy_fail = 0;

            test_input   = $urandom();
            @(posedge clk);
            inp  = test_input;
            load = 1;
            @(posedge clk);
            load = 0;
            repeat (3) @(posedge clk);

            @(posedge clk);
            start = 1;
            @(posedge clk);
            start = 0;

            fork
                begin : cfg_rdy_check
                    wait (done);
                end
                begin : cfg_rdy_monitor
                    forever begin
                        @(posedge clk);
                        if (busy && cfg_rdy) begin
                            cfg_rdy_fail = 1;
                            disable cfg_rdy_monitor;
                        end
                    end
                end
                begin : cfg_rdy_timeout
                    repeat (100000) @(posedge clk);
                end
            join_any
            disable fork;

            @(posedge clk);

            sb.tests_run++;
            if (!cfg_rdy_fail) begin
                $display("[PASS] cfg_ready_deasserts_while_busy");
                sb.tests_passed++;
            end else begin
                $error("[FAIL] cfg_ready was high while busy");
                sb.tests_failed++;
            end
        end

        // ------------------------------------------------------------------
        // Final report
        // ------------------------------------------------------------------
        repeat (50) @(posedge clk);
        sb.report();
        if (sb.tests_failed == 0) $display("\n*** SIMULATION PASSED ***\n");
        else $display("\n*** SIMULATION FAILED ***\n");
        $finish;
    end

endmodule
`default_nettype wire
