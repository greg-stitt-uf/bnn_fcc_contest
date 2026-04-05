// ============================================================================
// Module: neuron_processor_tb
// Purpose: Comprehensive testbench for neuron_processor with coverage
// ============================================================================

module neuron_processor_tb #(
    parameter int PW                = 8,     // Parallel width
    parameter int MAX_NEURON_INPUTS = 784,   // Largest neuron size
    parameter bit OUTPUT_LAYER      = 0,     // 0=hidden, 1=output
    parameter int NUM_TESTS         = 100,   // Number of neurons to test
    parameter int MIN_BEATS         = 1,     // Minimum beats per neuron
    parameter int MAX_BEATS         = 10,    // Maximum beats per neuron
    parameter bit TOGGLE_INPUTS_WHILE_ACTIVE = 1'b1,
    parameter int MIN_CYCLES_BETWEEN_NEURONS = 1,
    parameter int MAX_CYCLES_BETWEEN_NEURONS = 5,
    parameter bit LOG_START_MONITOR = 1'b0,
    parameter bit LOG_DONE_MONITOR  = 1'b0
);
    
    localparam int ACCUM_WIDTH = $clog2(MAX_NEURON_INPUTS + 1);
    
    // DUT signals
    logic clk = 0;
    logic rst;
    logic valid_in;
    logic last;
    logic [PW-1:0] x;
    logic [PW-1:0] w;
    logic [ACCUM_WIDTH-1:0] threshold;
    logic valid_out;
    logic activation;
    logic [ACCUM_WIDTH-1:0] popcount_out;
    
    // Testbench variables
    int passed, failed;
    
    // Events
    event start_event;
    event done_event;
    
    // Mailboxes
    mailbox driver_mailbox = new;
    mailbox scoreboard_input_mailbox = new;
    mailbox scoreboard_result_mailbox = new;
    
    // DUT instantiation
    neuron_processor #(
        .PW               (PW),
        .MAX_NEURON_INPUTS(MAX_NEURON_INPUTS),
        .OUTPUT_LAYER     (OUTPUT_LAYER)
    ) DUT (.*);
    
    // ========================================================================
    // Transaction class
    // ========================================================================
    class neuron_item;
        rand int num_beats;                        // How many beats for this neuron
        rand bit [PW-1:0] x_data[];               // Input activations (one per beat)
        rand bit [PW-1:0] w_data[];               // Weights (one per beat)
        rand bit [ACCUM_WIDTH-1:0] threshold;      // Activation threshold
        
        constraint valid_beats {
            num_beats inside {[MIN_BEATS:MAX_BEATS]};
        }
        
        constraint array_sizes {
            x_data.size() == num_beats;
            w_data.size() == num_beats;
        }
        
        // Calculate expected result
        function int calc_expected_popcount();
            int total = 0;
            for (int i = 0; i < num_beats; i++) begin
                bit [PW-1:0] xnor_result = x_data[i] ~^ w_data[i];
                total += $countones(xnor_result);
            end
            return total;
        endfunction
        
        function bit calc_expected_activation();
            return (calc_expected_popcount() >= threshold);
        endfunction
    endclass
    
    // ========================================================================
    // Reference model
    // ========================================================================
    function int model_popcount(neuron_item item);
        return item.calc_expected_popcount();
    endfunction
    
    function bit model_activation(neuron_item item);
        return item.calc_expected_activation();
    endfunction
    
    // ========================================================================
    // Clock generation
    // ========================================================================
    initial begin : generate_clock
        forever #5 clk <= ~clk;
    end
    
    // ========================================================================
    // Initialization
    // ========================================================================
    initial begin : initialization
        $timeformat(-9, 0, " ns");
        rst <= 1;
        valid_in <= 0;
        last <= 0;
        x <= '0;
        w <= '0;
        threshold <= '0;
        repeat (5) @(posedge clk);
        rst <= 0;
    end
    
    // ========================================================================
    // Generator: Create test cases
    // ========================================================================
    initial begin : generator
        neuron_item test;
        
        // Generate random neurons
        for (int i = 0; i < NUM_TESTS; i++) begin
            test = new();
            assert(test.randomize());
            driver_mailbox.put(test);
        end
        
        // Add specific corner cases
        
        // Corner case 1: Single beat, all match
        test = new();
        test.num_beats = 1;
        test.x_data = new[1];
        test.w_data = new[1];
        test.x_data[0] = 8'hFF;
        test.w_data[0] = 8'hFF;
        test.threshold = PW / 2;
        driver_mailbox.put(test);
        
        // Corner case 2: Single beat, none match
        test = new();
        test.num_beats = 1;
        test.x_data = new[1];
        test.w_data = new[1];
        test.x_data[0] = 8'hFF;
        test.w_data[0] = 8'h00;
        test.threshold = PW / 2;
        driver_mailbox.put(test);
        
        // Corner case 3: Max beats
        test = new();
        test.num_beats = MAX_BEATS;
        test.x_data = new[MAX_BEATS];
        test.w_data = new[MAX_BEATS];
        for (int i = 0; i < MAX_BEATS; i++) begin
            test.x_data[i] = $urandom();
            test.w_data[i] = $urandom();
        end
        test.threshold = (MAX_BEATS * PW) / 2;
        driver_mailbox.put(test);
    end
    
    // ========================================================================
    // Start Monitor: Detect when a neuron starts processing
    // ========================================================================
    initial begin : start_monitor
        forever begin
            @(posedge clk iff !rst && valid_in);
            if (LOG_START_MONITOR)
                $display("[%0t] Start monitor: neuron processing started", $realtime);
            ->start_event;
        end
    end
    
    // ========================================================================
    // Done Monitor: Detect when a neuron finishes
    // ========================================================================
    initial begin : done_monitor
        forever begin
            @(posedge clk iff !rst && valid_out);
            if (LOG_DONE_MONITOR)
                $display("[%0t] Done monitor: result = %0d, activation = %0b",
                         $realtime, popcount_out, activation);
            ->done_event;
        end
    end
    
    // ========================================================================
    // Driver: Send test stimuli
    // ========================================================================
    initial begin : driver
        neuron_item item;
        bit first_test = 1'b1;
        
        @(posedge clk iff !rst);
        
        forever begin
            driver_mailbox.get(item);
            
            // Wait between neurons
            if (!first_test) begin
                repeat($urandom_range(
                    MIN_CYCLES_BETWEEN_NEURONS, MAX_CYCLES_BETWEEN_NEURONS
                )) @(posedge clk);
            end
            first_test = 1'b0;
            
            // Send to scoreboard
            scoreboard_input_mailbox.put(item);
            
            // Drive the neuron beats
            for (int beat = 0; beat < item.num_beats; beat++) begin
                valid_in <= 1;
                last <= (beat == item.num_beats - 1);
                x <= item.x_data[beat];
                w <= item.w_data[beat];
                threshold <= item.threshold;
                @(posedge clk);
                
                // Optional: toggle inputs while processing (stress test)
                if (TOGGLE_INPUTS_WHILE_ACTIVE && beat < item.num_beats - 1) begin
                    valid_in <= 0;
                    x <= $urandom();
                    w <= $urandom();
                    @(posedge clk);
                end
            end
            
            // Deassert valid
            valid_in <= 0;
            last <= 0;
            
            // Wait for done
            @(posedge clk iff valid_out);
            scoreboard_result_mailbox.put({popcount_out, activation});
        end
    end
    
    // ========================================================================
    // Scoreboard: Check results
    // ========================================================================
    initial begin : scoreboard
        neuron_item item;
        logic [ACCUM_WIDTH:0] result_packet;  // {popcount, activation}
        int expected_popcount;
        bit expected_activation;
        logic [ACCUM_WIDTH-1:0] actual_popcount;
        logic actual_activation;
        
        passed = 0;
        failed = 0;
        
        for (int i = 0; i < NUM_TESTS + 3; i++) begin  // +3 for corner cases
            scoreboard_input_mailbox.get(item);
            scoreboard_result_mailbox.get(result_packet);
            
            actual_popcount = result_packet[ACCUM_WIDTH:1];
            actual_activation = result_packet[0];
            
            expected_popcount = model_popcount(item);
            expected_activation = model_activation(item);
            
            if (OUTPUT_LAYER) begin
                // Output layer: only check popcount
                if (actual_popcount == expected_popcount) begin
                    $display("Test %0d passed (time %0t): popcount = %0d",
                             i, $time, actual_popcount);
                    passed++;
                end else begin
                    $display("Test %0d FAILED (time %0t): popcount = %0d, expected = %0d",
                             i, $time, actual_popcount, expected_popcount);
                    failed++;
                end
            end else begin
                // Hidden layer: check both popcount and activation
                if (actual_popcount == expected_popcount && 
                    actual_activation == expected_activation) begin
                    $display("Test %0d passed (time %0t): popcount = %0d, activation = %0b",
                             i, $time, actual_popcount, actual_activation);
                    passed++;
                end else begin
                    $display("Test %0d FAILED (time %0t): popcount = %0d/%0d, activation = %0b/%0b",
                             i, $time, actual_popcount, expected_popcount,
                             actual_activation, expected_activation);
                    failed++;
                end
            end
        end
        
        $display("========================================");
        $display("Tests completed: %0d passed, %0d failed", passed, failed);
        $display("========================================");
        $finish;
    end
    
    // ========================================================================
    // Assertions
    // ========================================================================
    
    // Valid and last must be aligned
    assert property (@(posedge clk) disable iff (rst)
        valid_in && last |-> ##3 valid_out
    ) else $error("valid_out not asserted 3 cycles after last");
    
    // Accumulator should clear after last
    assert property (@(posedge clk) disable iff (rst)
        valid_in && last |-> ##4 DUT.accumulator_r == 0
    ) else $error("Accumulator not cleared after neuron completion");
    
    // valid_out should pulse for exactly one cycle
    assert property (@(posedge clk) disable iff (rst)
        valid_out |=> !valid_out
    ) else $error("valid_out held high for multiple cycles");
    
    // No overflow
    assert property (@(posedge clk) disable iff (rst)
        DUT.final_sum <= MAX_NEURON_INPUTS
    ) else $error("Popcount overflow detected");
    
    // ========================================================================
    // Coverage
    // ========================================================================
    
    covergroup cg_neuron @(done_event);
        cp_popcount: coverpoint popcount_out {
            bins zero = {0};
            bins low = {[1:PW-1]};
            bins medium = {[PW:2*PW-1]};
            bins high = {[2*PW:MAX_BEATS*PW]};
        }
        
        cp_activation: coverpoint activation {
            bins inactive = {0};
            bins active = {1};
        }
        
        cp_threshold: coverpoint threshold {
            bins low = {[0:PW/2]};
            bins medium = {[PW/2+1:PW]};
            bins high = {[PW+1:MAX_BEATS*PW]};
        }
        
        cross cp_popcount, cp_activation;
    endgroup
    
    covergroup cg_beats @(posedge clk iff valid_in);
        cp_last: coverpoint last {
            bins not_last = {0};
            bins is_last = {1};
        }
    endgroup
    
    cg_neuron cov_neuron = new();
    cg_beats cov_beats = new();
    
    // ========================================================================
    // Cover properties
    // ========================================================================
    
    // Back-to-back neurons
    back_to_back_neurons: cover property (
        @(posedge clk) disable iff (rst)
        valid_out ##1 valid_in
    );
    
    // Multi-beat neuron
    multi_beat_neuron: cover property (
        @(posedge clk) disable iff (rst)
        valid_in && !last ##1 valid_in
    );
    
    // Input toggle while active
    input_toggle_while_active: cover property (
        @(posedge clk) disable iff (rst)
        valid_in && !last ##1 !valid_in
    );
    
    // Max accumulation
    max_accumulation: cover property (
        @(posedge clk) disable iff (rst)
        DUT.accumulator_r == (MAX_BEATS - 1) * PW
    );

endmodule