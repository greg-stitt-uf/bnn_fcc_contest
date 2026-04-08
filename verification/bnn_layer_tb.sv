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
    logic [INPUTS-1:0] inp;
    logic [NEURONS-1:0] act;
    logic [NEURONS*COUNT_W-1:0] pop;
    logic cfg_we, cfg_tw, cfg_rdy;
    logic [7:0] cfg_nidx;
    logic [5:0] cfg_addr;
    logic [PW-1:0] cfg_wdata;
    logic [COUNT_W-1:0] cfg_tdata;
    //==========================================================================
    // Configuration Storage
    //==========================================================================
    class ConfigData;
        logic [PW-1:0] weights[NEURONS][BEATS];
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
            tests_run = 0;
            tests_passed = 0;
            tests_failed = 0;
            x_errors = 0;
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
            logic [COUNT_W-1:0] expected_pop[NEURONS];
            logic [COUNT_W-1:0] actual_pop[NEURONS];
            bit pass = 1;
            int error_count = 0;
            // Unpack actual popcounts
            for (int n = 0; n < NEURONS; n++) begin
                actual_pop[n] = actual_pop_packed[n*COUNT_W+:COUNT_W];
            end
            // Compute expected values
            for (int n = 0; n < NEURONS; n++) begin
                int popcount = 0;
                for (int b = 0; b < BEATS; b++) begin
                    for (int p = 0; p < PW; p++) begin
                        int inp_idx = b * PW + p;
                        if (inp_idx < INPUTS) begin
                            bit match = (input_vec[inp_idx] == cfg_data.weights[n][b][p]);
                            popcount += match;
                        end
                    end
                end
                expected_pop[n] = popcount;
                expected_act[n] = (popcount >= cfg_data.thresholds[n]);
            end
            // Check for X states first
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
            // Check values if no X states
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
        rst = 1;
        repeat (5) @(posedge clk);
        $display("[%0t] Depositing zeros to all memories...", $time);
        // Weight RAMs
        for (int np = 0; np < PN; np++) begin
            for (int addr = 0; addr < WEIGHT_DEPTH; addr++) begin
                $deposit(dut.weight_rams[np][addr], 16'h0000);
            end
        end
        // Threshold RAMs
        for (int np = 0; np < PN; np++) begin
            for (int grp = 0; grp < NEURON_GROUPS; grp++) begin
                $deposit(dut.threshold_rams[np][grp], 10'h000);
            end
        end
        // Input buffer
        for (int b = 0; b < BEATS; b++) begin
            $deposit(dut.input_buffer[b], 16'h0000);
        end
        // NOTE: stage2 registers removed from design — no longer deposited here
        $display("[%0t] Memory initialization complete", $time);
        repeat (10) @(posedge clk);
        rst = 0;
        repeat (10) @(posedge clk);
        $display("[%0t] Reset released", $time);
    endtask
    task configure_weights();
        $display("[%0t] Configuring weights...", $time);
        while (!cfg_rdy) @(posedge clk);
        for (int n = 0; n < NEURONS; n++) begin
            for (int b = 0; b < BEATS; b++) begin
                @(posedge clk);
                cfg_we = 1;
                cfg_tw = 0;
                cfg_nidx = n;
                cfg_addr = b;
                cfg_wdata = $urandom();
                cfg_data.set_weight(n, b, cfg_wdata);
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
            cfg_we = 1;
            cfg_tw = 1;
            cfg_nidx = n;
            cfg_tdata = $urandom_range(INPUTS / 4, 3 * INPUTS / 4);
            cfg_data.set_threshold(n, cfg_tdata);
        end
        @(posedge clk);
        cfg_we = 0;
        cfg_tw = 0;
        repeat (10) @(posedge clk);
        $display("[%0t] Threshold configuration complete", $time);
    endtask
    task run_test(input logic [INPUTS-1:0] input_vec, input string test_name);
        string error_msg;
        bit timed_out;
        error_msg = "";
        timed_out = 0;
        sb.tests_run++;
        $display("[%0t] Test: %s (density=%0d/%0d)", $time, test_name, $countones(input_vec), INPUTS);
        // Load input
        @(posedge clk);
        inp  = input_vec;
        load = 1;
        @(posedge clk);
        load = 0;
        repeat (5) @(posedge clk);
        // Start inference
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
            $error("[PROTOCOL] %s - done but !valid", test_name);
            sb.tests_failed++;
            return;
        end
        // Verify
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
    //==========================================================================
    // Main Test Flow
    //==========================================================================
    initial begin
        clk = 0;
        rst = 1;
        load = 0;
        start = 0;
        cfg_we = 0;
        cfg_tw = 0;
        inp = '0;
        cfg_nidx = 0;
        cfg_addr = 0;
        cfg_wdata = 0;
        cfg_tdata = 0;
        cfg_data = new();
        golden = new();
        sb = new();
        sb.reset_stats();
        $display("=== BNN Layer Testbench Started ===");
        $display("INPUTS=%0d, NEURONS=%0d, PW=%0d, PN=%0d", INPUTS, NEURONS, PW, PN);
        reset_and_init_dut();
        configure_weights();
        configure_thresholds();
        // Basic tests
        $display("\n=== TEST: Basic Functionality ===");
        for (int i = 0; i < 5; i++) begin
            logic [INPUTS-1:0] test_input;
            test_input = $urandom();
            run_test(test_input, $sformatf("basic_%0d", i));
        end
        // Corner cases
        $display("\n=== TEST: Corner Cases ===");
        run_test('0, "all_zeros");
        run_test('1, "all_ones");
        repeat (50) @(posedge clk);
        sb.report();
        if (sb.tests_failed == 0) $display("\n*** SIMULATION PASSED ***\n");
        else $display("\n*** SIMULATION FAILED ***\n");
        $finish;
    end
endmodule
`default_nettype wire
