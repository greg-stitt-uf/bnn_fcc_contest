`default_nettype none
// ============================================================================
// Module: bnn_core_tb
// Purpose: Comprehensive testbench for bnn_core
// Tests: 3-layer sequencing, inter-layer handoff, warm reset, config routing,
//        done/result_valid timing, back-to-back inference, capture registers
// ============================================================================
module bnn_core_tb #(
    parameter int INPUTS         = 784,
    parameter int HIDDEN1        = 256,
    parameter int HIDDEN2        = 256,
    parameter int OUTPUTS        = 10,
    parameter int PW             = 8,
    parameter int PN             = 8,
    parameter int NUM_RAND_TESTS = 10,
    parameter bit LOG_CFG        = 1'b0,
    parameter bit LOG_INFERENCE  = 1'b1,
    parameter bit LOG_RESULT     = 1'b1
);
    // =========================================================================
    // Derived localparams — mirrors bnn_core exactly
    // =========================================================================
    localparam int L1_COUNT_W = $clog2(INPUTS + 1);
    localparam int L2_COUNT_W = $clog2(HIDDEN1 + 1);
    localparam int L3_COUNT_W = $clog2(HIDDEN2 + 1);
    localparam int THRESHOLD_W = L1_COUNT_W;
    localparam int POPCOUNT_OUT_W = OUTPUTS * L3_COUNT_W;
    localparam int L1_ACT_W = HIDDEN1;
    localparam int L2_ACT_W = HIDDEN2;
    localparam int MAX_NEURONS = (HIDDEN1 > HIDDEN2) ? HIDDEN1 : HIDDEN2;
    localparam int CFG_NEURON_W = $clog2(MAX_NEURONS);
    localparam int MAX_BEATS_L1 = (INPUTS + PW - 1) / PW;
    localparam int MAX_BEATS_L2 = (HIDDEN1 + PW - 1) / PW;
    localparam int MAX_BEATS_L3 = (HIDDEN2 + PW - 1) / PW;
    localparam int MAX_WEIGHT_BEATS =
        (MAX_BEATS_L1 > MAX_BEATS_L2) ?
            (MAX_BEATS_L1 > MAX_BEATS_L3 ? MAX_BEATS_L1 : MAX_BEATS_L3) :
            (MAX_BEATS_L2 > MAX_BEATS_L3 ? MAX_BEATS_L2 : MAX_BEATS_L3);
    localparam int CFG_WEIGHT_ADDR_W = $clog2(MAX_WEIGHT_BEATS);

    // =========================================================================
    // DUT signals
    // =========================================================================
    logic                         clk = 0;
    logic                         rst;

    logic                         start;
    logic [           INPUTS-1:0] input_vector;
    logic                         done;
    logic                         busy;
    logic                         result_valid;

    logic [   POPCOUNT_OUT_W-1:0] popcounts_out;
    logic [         L1_ACT_W-1:0] activations_l1;
    logic [         L2_ACT_W-1:0] activations_l2;

    logic                         cfg_write_en;
    logic [                  1:0] cfg_layer_sel;
    logic [     CFG_NEURON_W-1:0] cfg_neuron_idx;
    logic [CFG_WEIGHT_ADDR_W-1:0] cfg_weight_addr;
    logic [               PW-1:0] cfg_weight_data;
    logic [      THRESHOLD_W-1:0] cfg_threshold_data;
    logic                         cfg_threshold_write;
    logic                         cfg_ready;

    int passed, failed;

    // =========================================================================
    // Events
    // =========================================================================
    event                                 inference_done_event;
    event                                 cfg_done_event;
    event                                 reset_event;

    // =========================================================================
    // Mailboxes
    // =========================================================================
    mailbox #(logic [        INPUTS-1:0]) input_mailbox = new;
    mailbox #(logic [POPCOUNT_OUT_W-1:0]) result_mailbox = new;
    mailbox #(logic [POPCOUNT_OUT_W-1:0]) expected_mailbox = new;

    // =========================================================================
    // DUT instantiation
    // =========================================================================
    bnn_core #(
        .INPUTS (INPUTS),
        .HIDDEN1(HIDDEN1),
        .HIDDEN2(HIDDEN2),
        .OUTPUTS(OUTPUTS),
        .PW     (PW),
        .PN     (PN)
    ) DUT (
        .clk                (clk),
        .rst                (rst),
        .start              (start),
        .input_vector       (input_vector),
        .done               (done),
        .busy               (busy),
        .result_valid       (result_valid),
        .popcounts_out      (popcounts_out),
        .activations_l1     (activations_l1),
        .activations_l2     (activations_l2),
        .cfg_write_en       (cfg_write_en),
        .cfg_layer_sel      (cfg_layer_sel),
        .cfg_neuron_idx     (cfg_neuron_idx),
        .cfg_weight_addr    (cfg_weight_addr),
        .cfg_weight_data    (cfg_weight_data),
        .cfg_threshold_data (cfg_threshold_data),
        .cfg_threshold_write(cfg_threshold_write),
        .cfg_ready          (cfg_ready)
    );

    // =========================================================================
    // Transaction classes
    // =========================================================================
    class weight_row_item;
        logic [PW-1:0] beats     [];
        int            num_beats;

        function new(int nb);
            num_beats = nb;
            beats     = new[nb];
        endfunction

        function void randomize_beats();
            for (int i = 0; i < num_beats; i++) beats[i] = $urandom();
        endfunction

        function void set_all(logic [PW-1:0] val);
            for (int i = 0; i < num_beats; i++) beats[i] = val;
        endfunction
    endclass

    class model_item;
        logic [         PW-1:0] weights      [3] [] [];
        logic [THRESHOLD_W-1:0] thresholds   [3] [];
        int                     layer_neurons[3];
        int                     layer_beats  [3];

        function new();
            layer_neurons[0] = HIDDEN1;
            layer_neurons[1] = HIDDEN2;
            layer_neurons[2] = OUTPUTS;
            layer_beats[0]   = MAX_BEATS_L1;
            layer_beats[1]   = MAX_BEATS_L2;
            layer_beats[2]   = MAX_BEATS_L3;
            for (int l = 0; l < 3; l++) begin
                weights[l]    = new[layer_neurons[l]];
                thresholds[l] = new[layer_neurons[l]];
                for (int n = 0; n < layer_neurons[l]; n++) weights[l][n] = new[layer_beats[l]];
            end
        endfunction

        function void randomize_model();
            for (int l = 0; l < 3; l++) begin
                for (int n = 0; n < layer_neurons[l]; n++) begin
                    for (int b = 0; b < layer_beats[l]; b++) weights[l][n][b] = $urandom();
                    thresholds[l][n] = $urandom_range(0, layer_beats[l] * PW);
                end
            end
        endfunction

        function void set_all_weights(logic [PW-1:0] val);
            for (int l = 0; l < 3; l++)
            for (int n = 0; n < layer_neurons[l]; n++)
            for (int b = 0; b < layer_beats[l]; b++) weights[l][n][b] = val;
        endfunction

        function void set_all_thresholds(int val);
            for (int l = 0; l < 3; l++) for (int n = 0; n < layer_neurons[l]; n++) thresholds[l][n] = val;
        endfunction
    endclass

    class inference_item;
        logic [        INPUTS-1:0] input_vec;
        logic [POPCOUNT_OUT_W-1:0] expected_popcounts;

        function new();
            for (int i = 0; i < INPUTS; i++) input_vec[i] = $urandom_range(0, 1);
        endfunction
    endclass

    // =========================================================================
    // Reference model
    // =========================================================================
    function automatic logic [POPCOUNT_OUT_W-1:0] run_reference_model(input logic [INPUTS-1:0] in_vec,
                                                                      input model_item mdl);
        automatic logic [       HIDDEN1-1:0] l1_act;
        automatic logic [       HIDDEN2-1:0] l2_act;
        automatic logic [POPCOUNT_OUT_W-1:0] out_pops;

        // Layer 1: INPUTS -> HIDDEN1
        for (int n = 0; n < HIDDEN1; n++) begin
            automatic int popcount = 0;
            for (int b = 0; b < MAX_BEATS_L1; b++) begin
                automatic logic [PW-1:0] x_chunk, w_chunk, xnor_result;
                for (int bit_i = 0; bit_i < PW; bit_i++) begin
                    automatic int gbit = b * PW + bit_i;
                    x_chunk[bit_i] = (gbit < INPUTS) ? in_vec[gbit] : 1'b0;
                    w_chunk[bit_i] = (gbit < INPUTS) ? mdl.weights[0][n][b][bit_i] : 1'b1;
                end
                xnor_result = x_chunk ~^ w_chunk;
                popcount += $countones(xnor_result);
            end
            l1_act[n] = (popcount >= mdl.thresholds[0][n]);
        end

        // Layer 2: HIDDEN1 -> HIDDEN2
        for (int n = 0; n < HIDDEN2; n++) begin
            automatic int popcount = 0;
            for (int b = 0; b < MAX_BEATS_L2; b++) begin
                automatic logic [PW-1:0] x_chunk, w_chunk, xnor_result;
                for (int bit_i = 0; bit_i < PW; bit_i++) begin
                    automatic int gbit = b * PW + bit_i;
                    x_chunk[bit_i] = (gbit < HIDDEN1) ? l1_act[gbit] : 1'b0;
                    w_chunk[bit_i] = (gbit < HIDDEN1) ? mdl.weights[1][n][b][bit_i] : 1'b1;
                end
                xnor_result = x_chunk ~^ w_chunk;
                popcount += $countones(xnor_result);
            end
            l2_act[n] = (popcount >= mdl.thresholds[1][n]);
        end

        // Layer 3: HIDDEN2 -> OUTPUTS (no threshold, raw popcount)
        for (int n = 0; n < OUTPUTS; n++) begin
            automatic int popcount = 0;
            for (int b = 0; b < MAX_BEATS_L3; b++) begin
                automatic logic [PW-1:0] x_chunk, w_chunk, xnor_result;
                for (int bit_i = 0; bit_i < PW; bit_i++) begin
                    automatic int gbit = b * PW + bit_i;
                    x_chunk[bit_i] = (gbit < HIDDEN2) ? l2_act[gbit] : 1'b0;
                    w_chunk[bit_i] = (gbit < HIDDEN2) ? mdl.weights[2][n][b][bit_i] : 1'b1;
                end
                xnor_result = x_chunk ~^ w_chunk;
                popcount += $countones(xnor_result);
            end
            out_pops[n*L3_COUNT_W+:L3_COUNT_W] = L3_COUNT_W'(popcount);
        end

        return out_pops;
    endfunction

    // =========================================================================
    // Clock
    // =========================================================================
    initial forever #5 clk = ~clk;

    // =========================================================================
    // Initialization
    // =========================================================================
    initial begin
        $timeformat(-9, 0, " ns");
        passed              = 0;
        failed              = 0;
        rst                 = 1;
        start               = 0;
        input_vector        = '0;
        cfg_write_en        = 0;
        cfg_layer_sel       = '0;
        cfg_neuron_idx      = '0;
        cfg_weight_addr     = '0;
        cfg_weight_data     = '0;
        cfg_threshold_data  = '0;
        cfg_threshold_write = 0;
        repeat (5) @(posedge clk);
        rst = 0;
        @(posedge clk);
    end

    // =========================================================================
    // Task: write_model
    // Loads all weights and thresholds for a model into the DUT via cfg interface
    // =========================================================================
    task automatic write_model(input model_item mdl);
        @(posedge clk iff cfg_ready);
        for (int l = 0; l < 3; l++) begin
            for (int n = 0; n < mdl.layer_neurons[l]; n++) begin
                // Write all weight beats for this neuron
                for (int b = 0; b < mdl.layer_beats[l]; b++) begin
                    @(posedge clk);
                    cfg_write_en        <= 1;
                    cfg_threshold_write <= 0;
                    cfg_layer_sel       <= 2'(l);
                    cfg_neuron_idx      <= CFG_NEURON_W'(n);
                    cfg_weight_addr     <= CFG_WEIGHT_ADDR_W'(b);
                    cfg_weight_data     <= mdl.weights[l][n][b];
                end
                // Write threshold for this neuron
                @(posedge clk);
                cfg_write_en        <= 1;
                cfg_threshold_write <= 1;
                cfg_layer_sel       <= 2'(l);
                cfg_neuron_idx      <= CFG_NEURON_W'(n);
                cfg_weight_addr     <= '0;
                cfg_threshold_data  <= mdl.thresholds[l][n];
            end
        end
        @(posedge clk);
        cfg_write_en        <= 0;
        cfg_threshold_write <= 0;
        if (LOG_CFG) $display("[%0t] Model write complete", $realtime);
        ->cfg_done_event;
    endtask

    // =========================================================================
    // Task: run_inference
    // Drives start + input_vector, waits for done
    // =========================================================================
    task automatic run_inference(input logic [INPUTS-1:0] in_vec);
        @(posedge clk iff !busy);
        input_vector <= in_vec;
        @(posedge clk);
        start <= 1;
        @(posedge clk);
        start <= 0;
        if (LOG_INFERENCE) $display("[%0t] Inference started", $realtime);
        @(posedge clk iff done);
        if (LOG_INFERENCE) $display("[%0t] Inference done. result_valid=%0b", $realtime, result_valid);
        ->inference_done_event;
    endtask

    // =========================================================================
    // Task: check_result
    // =========================================================================
    task automatic check_result(input string test_name, input logic [POPCOUNT_OUT_W-1:0] expected);
        if (popcounts_out === expected) begin
            $display("[PASS] %s: popcounts_out = %0h", test_name, popcounts_out);
            passed++;
        end else begin
            $display("[FAIL] %s: got %0h, expected %0h", test_name, popcounts_out, expected);
            failed++;
        end
    endtask

    // =========================================================================
    // Task: do_reset
    // Applies synchronous reset aligned to clock edges using nonblocking
    // assignment. Waits one full cycle after alignment before asserting rst
    // so the cover property (busy ##1 rst) sees busy=1 on edge N and
    // rst=1 on edge N+1 cleanly.
    // =========================================================================
    task automatic do_reset(input int cycles = 3);
        @(posedge clk);  // edge N:   busy sampled here by cover property
        @(posedge clk);  // edge N+1: rst asserted here via nonblocking
        rst <= 1;
        repeat (cycles) @(posedge clk);
        rst <= 0;
        @(posedge clk);
        ->reset_event;
    endtask

    // =========================================================================
    // Main test sequence
    // =========================================================================
    initial begin : test_sequence
        model_item                      mdl;
        logic      [        INPUTS-1:0] test_input;
        logic      [POPCOUNT_OUT_W-1:0] expected;
        int                             done_cycle;
        int                             start_cycle;

        @(posedge clk iff !rst);
        repeat (2) @(posedge clk);

        // ==================================================================
        // TEST 1: All zeros input, all zeros weights, threshold=0
        // XNOR(0,0)=1 so all bits match — all hidden neurons activate
        // ==================================================================
        $display("\n=== TEST 1: All zeros input, all zeros weights, threshold=0 ===");
        mdl = new();
        mdl.set_all_weights(8'h00);
        mdl.set_all_thresholds(0);
        write_model(mdl);
        test_input = '0;
        expected   = run_reference_model(test_input, mdl);
        run_inference(test_input);
        check_result("Test1_allzeros", expected);

        // ==================================================================
        // TEST 2: All ones input, all ones weights, threshold=0
        // ==================================================================
        $display("\n=== TEST 2: All ones input, all ones weights, threshold=0 ===");
        mdl = new();
        mdl.set_all_weights(8'hFF);
        mdl.set_all_thresholds(0);
        write_model(mdl);
        test_input = '1;
        expected   = run_reference_model(test_input, mdl);
        run_inference(test_input);
        check_result("Test2_allones", expected);

        // ==================================================================
        // TEST 3: Max threshold — hidden layers should not activate
        // ==================================================================
        $display("\n=== TEST 3: Max threshold — hidden layers should not activate ===");
        mdl = new();
        mdl.set_all_weights(8'hFF);
        mdl.set_all_thresholds(MAX_BEATS_L1 * PW + 1);
        write_model(mdl);
        test_input = '1;
        expected   = run_reference_model(test_input, mdl);
        run_inference(test_input);
        check_result("Test3_maxthresh", expected);

        // ==================================================================
        // TEST 4: Alternating AA/55 — no bits match per beat
        // XNOR(0xAA, 0x55) = 0x00 so popcount = 0 per beat
        // ==================================================================
        $display("\n=== TEST 4: Alternating AA/55 — no matches ===");
        mdl = new();
        mdl.set_all_weights(8'h55);
        mdl.set_all_thresholds(0);
        write_model(mdl);
        test_input = '0;
        for (int i = 0; i < INPUTS; i += 2) begin
            test_input[i] = 1'b1;
            if (i + 1 < INPUTS) test_input[i+1] = 1'b0;
        end
        expected = run_reference_model(test_input, mdl);
        run_inference(test_input);
        check_result("Test4_alternating", expected);

        // ==================================================================
        // TEST 5: Random model + random input x NUM_RAND_TESTS
        // ==================================================================
        $display("\n=== TEST 5: Random model + random input x%0d ===", NUM_RAND_TESTS);
        for (int t = 0; t < NUM_RAND_TESTS; t++) begin
            mdl = new();
            mdl.randomize_model();
            write_model(mdl);
            for (int i = 0; i < INPUTS; i++) test_input[i] = $urandom_range(0, 1);
            expected = run_reference_model(test_input, mdl);
            run_inference(test_input);
            check_result($sformatf("Test5_rand_%0d", t), expected);
        end

        // ==================================================================
        // TEST 6: Back-to-back inferences, same model, different inputs
        // No reconfiguration between runs
        // ==================================================================
        $display("\n=== TEST 6: Back-to-back inferences, same model ===");
        mdl = new();
        mdl.randomize_model();
        write_model(mdl);
        for (int t = 0; t < 3; t++) begin
            for (int i = 0; i < INPUTS; i++) test_input[i] = $urandom_range(0, 1);
            expected = run_reference_model(test_input, mdl);
            run_inference(test_input);
            check_result($sformatf("Test6_back2back_%0d", t), expected);
        end

        // ==================================================================
        // TEST 7: result_valid stability
        // After inference, result_valid should stay high until next start
        // and popcounts_out should remain stable
        // ==================================================================
        $display("\n=== TEST 7: result_valid stability between inferences ===");
        mdl = new();
        mdl.randomize_model();
        write_model(mdl);
        for (int i = 0; i < INPUTS; i++) test_input[i] = $urandom_range(0, 1);
        expected = run_reference_model(test_input, mdl);
        run_inference(test_input);
        repeat (10) @(posedge clk);
        if (!result_valid) begin
            $display("[FAIL] Test7: result_valid dropped before next start");
            failed++;
        end else begin
            $display("[PASS] Test7: result_valid stable after done");
            passed++;
        end
        if (popcounts_out === expected) begin
            $display("[PASS] Test7: popcounts_out stable during result_valid");
            passed++;
        end else begin
            $display("[FAIL] Test7: popcounts_out changed while result_valid high");
            failed++;
        end

        // ==================================================================
        // TEST 8: done is exactly one cycle
        // ==================================================================
        $display("\n=== TEST 8: done pulse width ===");
        mdl = new();
        mdl.randomize_model();
        write_model(mdl);
        for (int i = 0; i < INPUTS; i++) test_input[i] = $urandom_range(0, 1);
        @(posedge clk iff !busy);
        input_vector <= test_input;
        @(posedge clk);
        start <= 1;
        @(posedge clk);
        start <= 0;
        @(posedge clk iff done);
        @(posedge clk);
        if (done) begin
            $display("[FAIL] Test8: done held high for more than one cycle");
            failed++;
        end else begin
            $display("[PASS] Test8: done was exactly one cycle");
            passed++;
        end

        // ==================================================================
        // TEST 9: start ignored while busy
        // Assert start twice — once to begin inference, once while busy.
        // DUT should complete normally without launching a spurious inference.
        // ==================================================================
        $display("\n=== TEST 9: start ignored while busy ===");
        mdl = new();
        mdl.randomize_model();
        write_model(mdl);
        for (int i = 0; i < INPUTS; i++) test_input[i] = $urandom_range(0, 1);
        @(posedge clk iff !busy);
        input_vector <= test_input;
        @(posedge clk);
        start <= 1;
        @(posedge clk);
        start <= 1;  // assert again while busy — should be ignored
        @(posedge clk);
        start <= 0;
        @(posedge clk iff done);
        $display("[PASS] Test9: DUT completed normally despite extra start pulse");
        passed++;

        // ==================================================================
        // TEST 10: result_valid clears on new start
        // result_valid clears the cycle AFTER start is accepted in always_ff
        // so we wait one extra clock after start goes low before sampling
        // ==================================================================
        $display("\n=== TEST 10: result_valid clears on new start ===");
        mdl = new();
        mdl.randomize_model();
        write_model(mdl);
        for (int i = 0; i < INPUTS; i++) test_input[i] = $urandom_range(0, 1);
        run_inference(test_input);
        // result_valid is 1 here
        @(posedge clk iff !busy);
        input_vector <= test_input;
        @(posedge clk);
        start <= 1;
        @(posedge clk);
        start <= 0;
        // Wait one extra cycle for result_valid to clear in always_ff
        @(posedge clk);
        if (result_valid) begin
            $display("[FAIL] Test10: result_valid did not clear after new start");
            failed++;
        end else begin
            $display("[PASS] Test10: result_valid cleared on new start");
            passed++;
        end
        @(posedge clk iff done);

        // ==================================================================
        // TEST 11: Warm reset after config, before inference
        // Model should be preserved — inference should give correct result
        // without reconfiguring after reset
        // ==================================================================
        $display("\n=== TEST 11: Warm reset after config, before inference ===");
        mdl = new();
        mdl.randomize_model();
        write_model(mdl);
        do_reset(3);
        for (int i = 0; i < INPUTS; i++) test_input[i] = $urandom_range(0, 1);
        expected = run_reference_model(test_input, mdl);
        run_inference(test_input);
        check_result("Test11_reset_before_inference", expected);

        // ==================================================================
        // TEST 12: Warm reset during inference
        // Wait 100 cycles deep into inference so busy is guaranteed high.
        // Layer 1 alone takes ~6272 cycles so 100 is safely mid-inference.
        // do_reset waits one extra cycle between sampling and asserting rst
        // so the cover property (busy ##1 rst) and was_busy bin both fire.
        // ==================================================================
        $display("\n=== TEST 12: Warm reset during inference ===");
        mdl = new();
        mdl.randomize_model();
        write_model(mdl);
        for (int i = 0; i < INPUTS; i++) test_input[i] = $urandom_range(0, 1);
        @(posedge clk iff !busy);
        input_vector <= test_input;
        @(posedge clk);
        start <= 1;
        @(posedge clk);
        start <= 0;
        // Wait deep enough into inference that busy is guaranteed high
        repeat (100) @(posedge clk);
        // do_reset internally waits one cycle before asserting rst so
        // the cover property (busy ##1 rst) is guaranteed to fire
        do_reset(3);
        if (!cfg_ready) begin
            $display("[FAIL] Test12: DUT not idle after reset");
            failed++;
        end else begin
            $display("[PASS] Test12: DUT returned to IDLE after warm reset");
            passed++;
        end
        // Model preserved — run inference without reconfiguring
        expected = run_reference_model(test_input, mdl);
        run_inference(test_input);
        check_result("Test12_after_warm_reset", expected);

        // ==================================================================
        // TEST 13: Config overwrite — model B must win
        // Write model A then immediately overwrite with model B.
        // Result must match model B not model A.
        // ==================================================================
        $display("\n=== TEST 13: Config overwrite — model B must win ===");
        begin
            model_item mdl_a, mdl_b;
            logic [POPCOUNT_OUT_W-1:0] expected_a, expected_b;
            mdl_a = new();
            mdl_b = new();
            mdl_a.randomize_model();
            mdl_b.randomize_model();
            for (int i = 0; i < INPUTS; i++) test_input[i] = $urandom_range(0, 1);
            expected_a = run_reference_model(test_input, mdl_a);
            expected_b = run_reference_model(test_input, mdl_b);
            write_model(mdl_a);
            write_model(mdl_b);
            run_inference(test_input);
            if (popcounts_out === expected_b) begin
                $display("[PASS] Test13: Config overwrite correct — model B result");
                passed++;
            end else if (popcounts_out === expected_a) begin
                $display("[FAIL] Test13: Got model A result — overwrite failed");
                failed++;
            end else begin
                $display("[FAIL] Test13: Got unexpected result");
                failed++;
            end
        end

        // ==================================================================
        // TEST 14: cfg write blocked while busy
        // Attempt to write a bogus weight while inference is running.
        // DUT must complete correctly — the write must have been ignored.
        // ==================================================================
        $display("\n=== TEST 14: cfg blocked while busy ===");
        mdl = new();
        mdl.randomize_model();
        write_model(mdl);
        for (int i = 0; i < INPUTS; i++) test_input[i] = $urandom_range(0, 1);
        @(posedge clk iff !busy);
        input_vector <= test_input;
        @(posedge clk);
        start <= 1;
        @(posedge clk);
        start <= 0;
        @(posedge clk);
        cfg_write_en        <= 1;
        cfg_layer_sel       <= 2'd0;
        cfg_neuron_idx      <= '0;
        cfg_weight_addr     <= '0;
        cfg_weight_data     <= 8'hBE;
        cfg_threshold_write <= 0;
        @(posedge clk);
        cfg_write_en <= 0;
        @(posedge clk iff done);
        $display("[PASS] Test14: DUT completed inference despite write-while-busy attempt");
        passed++;

        // ==================================================================
        // TEST 15: Latency measurement
        // Counts cycles from start assertion to done pulse
        // ==================================================================
        $display("\n=== TEST 15: Latency measurement ===");
        mdl = new();
        mdl.randomize_model();
        write_model(mdl);
        for (int i = 0; i < INPUTS; i++) test_input[i] = $urandom_range(0, 1);
        @(posedge clk iff !busy);
        input_vector <= test_input;
        @(posedge clk);
        start_cycle = $time / 10;
        start <= 1;
        @(posedge clk);
        start <= 0;
        @(posedge clk iff done);
        done_cycle = $time / 10;
        $display("[INFO] Test15: Inference latency = %0d cycles", done_cycle - start_cycle);
        passed++;

        // ==================================================================
        // TEST 16: Back-to-back throughput
        // Measures cycle gap between end of first and end of second inference
        // ==================================================================
        $display("\n=== TEST 16: Back-to-back throughput measurement ===");
        mdl = new();
        mdl.randomize_model();
        write_model(mdl);
        for (int i = 0; i < INPUTS; i++) test_input[i] = $urandom_range(0, 1);
        expected = run_reference_model(test_input, mdl);
        run_inference(test_input);
        start_cycle = $time / 10;
        run_inference(test_input);
        done_cycle = $time / 10;
        check_result("Test16_throughput_second", expected);
        $display("[INFO] Test16: Back-to-back cycle gap = %0d cycles", done_cycle - start_cycle);

        // ==================================================================
        // SUMMARY
        // ==================================================================
        @(posedge clk);
        $display("\n========================================");
        $display("BNN Core TB Complete");
        $display("Tests passed: %0d", passed);
        $display("Tests failed: %0d", failed);
        $display("========================================");
        $finish;
    end

    // =========================================================================
    // Done monitor
    // =========================================================================
    initial begin : done_monitor
        forever begin
            @(posedge clk iff !rst && done);
            if (LOG_RESULT)
                $display(
                    "[%0t] Done monitor: popcounts_out = %0h, result_valid = %0b",
                    $realtime,
                    popcounts_out,
                    result_valid
                );
            ->inference_done_event;
        end
    end

    // =========================================================================
    // Assertions
    // =========================================================================

    p_done_one_cycle :
    assert property (@(posedge clk) disable iff (rst) done |=> !done)
    else $error("done held high for more than one cycle");

    p_result_valid_stable :
    assert property (@(posedge clk) disable iff (rst) (result_valid && !start) |=> result_valid)
    else $error("result_valid dropped without start");

    p_result_valid_clears :
    assert property (@(posedge clk) disable iff (rst) (result_valid && start && !busy) |=> !result_valid)
    else $error("result_valid did not clear after start");

    p_done_sets_result_valid :
    assert property (@(posedge clk) disable iff (rst) done |=> result_valid)
    else $error("result_valid not set after done");

    p_busy_clears_after_done :
    assert property (@(posedge clk) disable iff (rst) done |=> !busy)
    else $error("busy still high after done");

    p_cfg_ready_only_in_idle :
    assert property (@(posedge clk) disable iff (rst) cfg_ready |-> (DUT.state_r == DUT.IDLE))
    else $error("cfg_ready asserted outside IDLE");

    p_start_ignored_while_busy :
    assert property (@(posedge clk) disable iff (rst) (start && busy) |=> (DUT.state_r != DUT.LOAD_L1))
    else $error("spurious LOAD_L1 after start-while-busy");

    p_popcounts_stable :
    assert property (@(posedge clk) disable iff (rst) (result_valid && !start) |=> $stable(popcounts_out))
    else $error("popcounts_out changed while result_valid and no new start");

    p_cfg_blocked_when_busy :
    assert property (
        @(posedge clk) disable iff (rst)
        busy |-> !(DUT.l1_cfg_write_en ||
                   DUT.l2_cfg_write_en ||
                   DUT.l3_cfg_write_en))
    else $error("internal cfg write enable fired while busy");

    // =========================================================================
    // Covergroups
    // =========================================================================

    covergroup cg_inference @(inference_done_event);
        option.per_instance = 1;

        coverpoint popcounts_out[L3_COUNT_W-1:0] {
            bins low = {[0 : HIDDEN2 / 4]};
            bins mid = {[HIDDEN2 / 4 + 1 : 3 * HIDDEN2 / 4]};
            bins high = {[3 * HIDDEN2 / 4 + 1 : HIDDEN2]};
        }

        coverpoint result_valid {bins valid = {1};}
    endgroup

    // Sample busy while rst is asserted so both bins are reachable:
    //   was_busy: hit when reset fires mid-inference (Test 12)
    //   was_idle: hit when reset fires while idle   (Test 11)
    covergroup cg_reset @(posedge clk);
        option.per_instance = 1;
        coverpoint busy iff (rst) {bins was_busy = {1}; bins was_idle = {0};}
    endgroup

    cg_inference cov_inference = new();
    cg_reset     cov_reset = new();

    // =========================================================================
    // Cover properties
    // =========================================================================

    cp_idle_start :
    cover property (@(posedge clk) disable iff (rst) DUT.state_r == DUT.IDLE && start);

    cp_load_l1 :
    cover property (@(posedge clk) disable iff (rst) DUT.state_r == DUT.LOAD_L1);

    cp_run_l1 :
    cover property (@(posedge clk) disable iff (rst) DUT.state_r == DUT.RUN_L1);

    cp_load_l2 :
    cover property (@(posedge clk) disable iff (rst) DUT.state_r == DUT.LOAD_L2);

    cp_run_l2 :
    cover property (@(posedge clk) disable iff (rst) DUT.state_r == DUT.RUN_L2);

    cp_load_l3 :
    cover property (@(posedge clk) disable iff (rst) DUT.state_r == DUT.LOAD_L3);

    cp_run_l3 :
    cover property (@(posedge clk) disable iff (rst) DUT.state_r == DUT.RUN_L3);

    cp_done_state :
    cover property (@(posedge clk) disable iff (rst) DUT.state_r == DUT.DONE);

    cp_l1_done :
    cover property (@(posedge clk) disable iff (rst) DUT.l1_done);

    cp_l2_done :
    cover property (@(posedge clk) disable iff (rst) DUT.l2_done);

    cp_l3_done :
    cover property (@(posedge clk) disable iff (rst) DUT.l3_done);

    cp_back_to_back :
    cover property (@(posedge clk) disable iff (rst) done ##[1:3] start);

    cp_reset_while_busy :
    cover property (@(posedge clk) busy ##1 rst);

    cp_cfg_write_while_ready :
    cover property (@(posedge clk) disable iff (rst) cfg_write_en && cfg_ready);

    cp_cfg_layer0 :
    cover property (@(posedge clk) disable iff (rst) cfg_write_en && (cfg_layer_sel == 2'd0));

    cp_cfg_layer1 :
    cover property (@(posedge clk) disable iff (rst) cfg_write_en && (cfg_layer_sel == 2'd1));

    cp_cfg_layer2 :
    cover property (@(posedge clk) disable iff (rst) cfg_write_en && (cfg_layer_sel == 2'd2));

    cp_result_valid_sustained :
    cover property (@(posedge clk) disable iff (rst) result_valid [* 5]);

    cp_done_then_valid :
    cover property (@(posedge clk) disable iff (rst) done ##1 result_valid);

endmodule
`default_nettype wire
