module bnn_layer_tb;

    localparam int INPUTS = 784;
    localparam int NEURONS = 256;
    localparam int PW = 16;
    localparam int PN = 8;
    localparam int BEATS = 49;
    localparam int COUNT_W = 10;

    logic clk, rst, load, start, done, busy, valid;
    logic [INPUTS-1:0] inp;
    logic [NEURONS-1:0] act;
    logic [NEURONS*COUNT_W-1:0] pop;
    logic cfg_we, cfg_tw, cfg_rdy;
    logic [7:0] cfg_nidx;
    logic [5:0] cfg_addr;
    logic [PW-1:0] cfg_wdata;
    logic [COUNT_W-1:0] cfg_tdata;

    logic last_cfg_mode;
    always_ff @(posedge clk) begin
        if (rst) last_cfg_mode <= 0;
        else if (cfg_we) last_cfg_mode <= cfg_tw;
    end

    bnn_layer #(.INPUTS(INPUTS), .NEURONS(NEURONS), .PW(PW), .PN(PN), .OUTPUT_LAYER(0))
    dut (.clk(clk), .rst(rst), .input_load(load), .input_vector(inp),
         .start(start), .done(done), .busy(busy), .activations_out(act),
         .popcounts_out(pop), .output_valid(valid),
         .cfg_write_en(cfg_we), .cfg_neuron_idx(cfg_nidx),
         .cfg_weight_addr(cfg_addr), .cfg_weight_data(cfg_wdata),
         .cfg_threshold_data(cfg_tdata), .cfg_threshold_write(cfg_tw),
         .cfg_ready(cfg_rdy));

    always #5 clk = ~clk;

    int pass = 0, fail = 0;
    logic [PW-1:0] saved_weights[NEURONS][BEATS];
    logic [COUNT_W-1:0] saved_thresh[NEURONS];

    covergroup cg_interface @(posedge clk);
    option.per_instance = 1;
    
    cp_config_mode: coverpoint cfg_tw iff(cfg_we) {
        bins weights = {0};
        bins thresholds = {1};
    }
    
    cp_config_continuous: coverpoint cfg_we {
        bins idle = {0};
        bins active = {1};
        bins short_burst = (1 [*2:5]);
        bins medium_burst = (1 [*6:10]);
        bins long_burst = (1 [*11:20]);
        bins gaps = (1 => 0 => 1);
        bins multi_gaps = (1 => 0 [*2:5] => 1);
    }
    
    cp_inference_timing: coverpoint {start, done} {
        bins start_idle = {2'b10};
        bins done_assert = {2'b01};
        bins back_to_back_immediate = (2'b01 => 2'b10);
        bins short_gap = (2'b01 => 2'b00 [*1:3] => 2'b10);
        bins medium_gap = (2'b01 => 2'b00 [*4:10] => 2'b10);
        bins long_gap = (2'b01 => 2'b00 [*11:50] => 2'b10);
    }
    
    cp_busy_ready: coverpoint {busy, cfg_rdy} {
        bins idle_ready = {2'b01};
        bins busy_not_ready = {2'b10};
    }
    
    cp_output: coverpoint {done, valid} {
        bins done_with_valid = {2'b11};
    }
    
    cross_config: cross cp_config_mode, cp_config_continuous {
        ignore_bins weights_with_idle = binsof(cp_config_mode.weights) && binsof(cp_config_continuous.idle);
        ignore_bins thresholds_with_idle = binsof(cp_config_mode.thresholds) && binsof(cp_config_continuous.idle);
    }
endgroup

    covergroup cg_reset @(posedge clk);
        option.per_instance = 1;
        
        cp_cold_reset: coverpoint rst iff(!busy) {
            bins reset_idle = {1};
        }
        
        cp_warm_reset: coverpoint rst iff(busy) {
            bins reset_active = {1};
        }
        
        cp_reset_timing: coverpoint rst {
            bins early_reset = (0 => 1 [*3:5] => 0);
            bins long_reset = (0 => 1 [*10:15] => 0);
        }
    endgroup

    covergroup cg_corner_cases @(posedge clk iff done);
        option.per_instance = 1;
        
        cp_thresh_extremes: coverpoint saved_thresh[0] {
            bins zero = {0};
            bins low = {[1:INPUTS/4]};
            bins mid = {[INPUTS/4+1:3*INPUTS/4]};
            bins high = {[3*INPUTS/4+1:INPUTS-1]};
            bins max = {INPUTS};
        }
        
        cp_input_patterns: coverpoint inp[INPUTS-1:0] {
            bins all_zero = {'0};
            bins all_one = {'1};
            bins sparse = {[1:100]};
            bins dense = {[INPUTS-100:INPUTS-1]};
        }
    endgroup

    cg_interface cov_intf;
    cg_reset cov_rst;
    cg_corner_cases cov_corner;

    property p_done_valid;
        @(posedge clk) disable iff(rst) done |-> valid;
    endproperty
    assert property(p_done_valid) else $error("done without valid");

    property p_busy_cfg;
        @(posedge clk) disable iff(rst) busy |-> !cfg_rdy;
    endproperty
    assert property(p_busy_cfg) else $error("cfg_rdy during busy");

    property p_no_cfg_when_busy;
        @(posedge clk) disable iff(rst) busy |-> !cfg_we;
    endproperty
    assert property(p_no_cfg_when_busy) else $error("cfg_we during busy");

    task automatic reset_dut(int reset_cycles = 10);
        rst = 1;
        load = 0; start = 0; cfg_we = 0;
        repeat(reset_cycles) @(posedge clk);
        rst = 0;
        repeat(5) @(posedge clk);
    endtask

    task automatic config_weights(bit with_gaps, int gap_prob = 10, int burst_len = 0);
        int consecutive = 0;
        for (int n = 0; n < NEURONS; n++) begin
            for (int b = 0; b < BEATS; b++) begin
                @(posedge clk);
                cfg_we = 1; cfg_tw = 0;
                cfg_nidx = n; cfg_addr = b;
                cfg_wdata = $urandom;
                saved_weights[n][b] = cfg_wdata;
                consecutive++;
                
                if (with_gaps) begin
                    if (burst_len > 0 && consecutive >= burst_len) begin
                        @(posedge clk); cfg_we = 0;
                        repeat($urandom_range(1, 5)) @(posedge clk);
                        consecutive = 0;
                    end else if ($urandom_range(0, 99) < gap_prob) begin
                        @(posedge clk); cfg_we = 0;
                        repeat($urandom_range(1, 3)) @(posedge clk);
                        consecutive = 0;
                    end
                end
            end
        end
        @(posedge clk); cfg_we = 0;
    endtask

    task automatic config_thresholds(int thresh_value = -1, bit randomize = 1, bit with_bursts = 0);
        int consecutive = 0;
        for (int n = 0; n < NEURONS; n++) begin
            @(posedge clk);
            cfg_we = 1; cfg_tw = 1;
            cfg_nidx = n;
            if (thresh_value >= 0) cfg_tdata = thresh_value;
            else if (randomize) cfg_tdata = $urandom_range(INPUTS/4, 3*INPUTS/4);
            else cfg_tdata = INPUTS/2;
            saved_thresh[n] = cfg_tdata;
            consecutive++;
            
            if (with_bursts && consecutive >= 15) begin
                @(posedge clk); cfg_we = 0;
                repeat(2) @(posedge clk);
                consecutive = 0;
            end
        end
        @(posedge clk); cfg_we = 0; cfg_tw = 0;
    endtask

    task automatic load_input(logic [INPUTS-1:0] data);
        inp = data;
        @(posedge clk); load = 1;
        @(posedge clk); load = 0;
    endtask

    task automatic run_inference(int timeout = 200000);
        fork
            begin
                @(posedge clk); start = 1;
                @(posedge clk); start = 0;
                wait(done); @(posedge clk);
                if (valid) pass++; else fail++;
            end
            begin
                repeat(timeout) @(posedge clk);
                $error("TIMEOUT"); fail++;
            end
        join_any
        disable fork;
    endtask

    task automatic test_cross_weights_gaps_explicit();
        for (int rep = 0; rep < 50; rep++) begin
            @(posedge clk);
            cfg_we = 1; cfg_tw = 0;
            cfg_nidx = 0; cfg_addr = 0; cfg_wdata = $urandom;
            
            @(posedge clk);
            cfg_we = 0; cfg_tw = 0;
            
            @(posedge clk);
            cfg_we = 1; cfg_tw = 0;
            cfg_nidx = 0; cfg_addr = 1; cfg_wdata = $urandom;
        end
        @(posedge clk); cfg_we = 0;
        
        config_thresholds(-1, 1, 0);
        for (int i = 0; i < INPUTS; i++) inp[i] = $urandom_range(0,1);
        load_input(inp);
        run_inference(200000);
    endtask

    task automatic test_cross_weights_idle_explicit();
        for (int n = 0; n < 64; n++) begin
            for (int b = 0; b < BEATS; b++) begin
                @(posedge clk);
                cfg_we = 1; cfg_tw = 0;
                cfg_nidx = n; cfg_addr = b; cfg_wdata = $urandom;
            end
        end
        
        @(posedge clk); cfg_we = 0; cfg_tw = 0;
        repeat(20) @(posedge clk);
        
        for (int n = 64; n < 128; n++) begin
            for (int b = 0; b < BEATS; b++) begin
                @(posedge clk);
                cfg_we = 1; cfg_tw = 0;
                cfg_nidx = n; cfg_addr = b; cfg_wdata = $urandom;
            end
        end
        
        @(posedge clk); cfg_we = 0; cfg_tw = 0;
        repeat(20) @(posedge clk);
        
        for (int n = 128; n < NEURONS; n++) begin
            for (int b = 0; b < BEATS; b++) begin
                @(posedge clk);
                cfg_we = 1; cfg_tw = 0;
                cfg_nidx = n; cfg_addr = b; cfg_wdata = $urandom;
            end
        end
        @(posedge clk); cfg_we = 0;
        
        config_thresholds(-1, 1, 0);
        for (int i = 0; i < INPUTS; i++) inp[i] = $urandom_range(0,1);
        load_input(inp);
        run_inference(200000);
    endtask

    task automatic test_cross_thresholds_idle_explicit();
        config_weights(0, 0, 0);
        
        for (int n = 0; n < 64; n++) begin
            @(posedge clk);
            cfg_we = 1; cfg_tw = 1;
            cfg_nidx = n; cfg_tdata = $urandom_range(INPUTS/4, 3*INPUTS/4);
        end
        
        @(posedge clk); cfg_we = 0; cfg_tw = 0;
        repeat(20) @(posedge clk);
        
        for (int n = 64; n < 128; n++) begin
            @(posedge clk);
            cfg_we = 1; cfg_tw = 1;
            cfg_nidx = n; cfg_tdata = $urandom_range(INPUTS/4, 3*INPUTS/4);
        end
        
        @(posedge clk); cfg_we = 0; cfg_tw = 0;
        repeat(20) @(posedge clk);
        
        for (int n = 128; n < NEURONS; n++) begin
            @(posedge clk);
            cfg_we = 1; cfg_tw = 1;
            cfg_nidx = n; cfg_tdata = $urandom_range(INPUTS/4, 3*INPUTS/4);
        end
        @(posedge clk); cfg_we = 0; cfg_tw = 0;
        
        for (int i = 0; i < INPUTS; i++) inp[i] = $urandom_range(0,1);
        load_input(inp);
        run_inference(200000);
    endtask

    task automatic test_early_reset();
        config_weights(0, 0, 0);
        config_thresholds(-1, 1, 0);
        for (int i = 0; i < INPUTS; i++) inp[i] = $urandom_range(0,1);
        load_input(inp);
        
        fork
            begin
                @(posedge clk); start = 1;
                @(posedge clk); start = 0;
                wait(done);
            end
            begin
                repeat(200) @(posedge clk);
                reset_dut(4);
                config_weights(0, 0, 0);
                config_thresholds(-1, 1, 0);
                for (int j = 0; j < INPUTS; j++) inp[j] = $urandom_range(0,1);
                load_input(inp);
                run_inference(200000);
            end
        join_any
        disable fork;
    endtask

    task automatic test_dense_input_numeric();
        config_weights(0, 0, 0);
        config_thresholds(-1, 1, 0);
        
        for (int val = 684; val <= 783; val++) begin
            inp = '0;
            inp[9:0] = val[9:0];
            load_input(inp);
            run_inference(200000);
        end
    endtask

    task automatic test_basic();
        config_weights(0, 0, 0);
        config_thresholds(-1, 1, 0);
        for (int i = 0; i < INPUTS; i++) inp[i] = $urandom_range(0,1);
        load_input(inp);
        run_inference(200000);
    endtask

    task automatic test_config_burst_patterns();
        config_weights(1, 50, 3);
        config_thresholds(-1, 1, 1);
        for (int i = 0; i < INPUTS; i++) inp[i] = $urandom_range(0,1);
        load_input(inp);
        run_inference(200000);
        
        config_weights(1, 30, 8);
        config_thresholds(-1, 1, 1);
        for (int i = 0; i < INPUTS; i++) inp[i] = $urandom_range(0,1);
        load_input(inp);
        run_inference(200000);
        
        config_weights(1, 10, 15);
        config_thresholds(-1, 1, 1);
        for (int i = 0; i < INPUTS; i++) inp[i] = $urandom_range(0,1);
        load_input(inp);
        run_inference(200000);
    endtask

    task automatic test_back_to_back_aggressive();
        config_weights(0, 0, 0);
        config_thresholds(-1, 1, 0);
        
        for (int seq = 0; seq < 10; seq++) begin
            for (int i = 0; i < INPUTS; i++) inp[i] = $urandom_range(0,1);
            load_input(inp);
            
            @(posedge clk); start = 1;
            @(posedge clk); start = 0;
            
            wait(done);
            
            for (int i = 0; i < INPUTS; i++) inp[i] = $urandom_range(0,1);
            @(posedge clk);
            load = 1;
            start = 1;
            @(posedge clk);
            load = 0;
            start = 0;
            
            wait(done);
            @(posedge clk);
            if (valid) pass++; else fail++;
        end
    endtask

    task automatic test_inference_timing_variations();
        config_weights(0, 0, 0);
        config_thresholds(-1, 1, 0);
        
        for (int i = 0; i < 3; i++) begin
            repeat($urandom_range(1,3)) @(posedge clk);
            for (int j = 0; j < INPUTS; j++) inp[j] = $urandom_range(0,1);
            load_input(inp);
            run_inference(200000);
        end
        
        for (int i = 0; i < 3; i++) begin
            repeat($urandom_range(4,10)) @(posedge clk);
            for (int j = 0; j < INPUTS; j++) inp[j] = $urandom_range(0,1);
            load_input(inp);
            run_inference(200000);
        end
        
        for (int i = 0; i < 3; i++) begin
            repeat($urandom_range(11,50)) @(posedge clk);
            for (int j = 0; j < INPUTS; j++) inp[j] = $urandom_range(0,1);
            load_input(inp);
            run_inference(200000);
        end
    endtask

    task automatic test_threshold_extremes();
        config_weights(0, 0, 0);
        config_thresholds(0, 0, 0);
        for (int i = 0; i < INPUTS; i++) inp[i] = $urandom_range(0,1);
        load_input(inp);
        run_inference(200000);
        
        config_thresholds(INPUTS, 0, 0);
        for (int i = 0; i < INPUTS; i++) inp[i] = $urandom_range(0,1);
        load_input(inp);
        run_inference(200000);
        
        config_thresholds(INPUTS/8, 0, 0);
        for (int i = 0; i < INPUTS; i++) inp[i] = $urandom_range(0,1);
        load_input(inp);
        run_inference(200000);
        
        config_thresholds(7*INPUTS/8, 0, 0);
        for (int i = 0; i < INPUTS; i++) inp[i] = $urandom_range(0,1);
        load_input(inp);
        run_inference(200000);
    endtask

    task automatic test_input_patterns();
        config_weights(0, 0, 0);
        config_thresholds(-1, 1, 0);
        
        inp = '0;
        load_input(inp);
        run_inference(200000);
        
        inp = '1;
        load_input(inp);
        run_inference(200000);
        
        for (int val = 1; val <= 100; val += 10) begin
            inp = '0;
            inp[9:0] = val[9:0];
            load_input(inp);
            run_inference(200000);
        end
    endtask

    task automatic test_warm_resets();
        for (int scenario = 0; scenario < 3; scenario++) begin
            config_weights(0, 0, 0);
            config_thresholds(-1, 1, 0);
            for (int i = 0; i < INPUTS; i++) inp[i] = $urandom_range(0,1);
            load_input(inp);
            
            fork
                begin
                    @(posedge clk); start = 1;
                    @(posedge clk); start = 0;
                    wait(done);
                end
                begin
                    repeat($urandom_range(100, 500)) @(posedge clk);
                    reset_dut($urandom_range(3, 6));
                    config_weights(0, 0, 0);
                    config_thresholds(-1, 1, 0);
                    for (int j = 0; j < INPUTS; j++) inp[j] = $urandom_range(0,1);
                    load_input(inp);
                    run_inference(200000);
                end
            join_any
            disable fork;
        end
    endtask

    task automatic test_long_reset();
        config_weights(0, 0, 0);
        config_thresholds(-1, 1, 0);
        for (int i = 0; i < INPUTS; i++) inp[i] = $urandom_range(0,1);
        load_input(inp);
        
        fork
            begin
                @(posedge clk); start = 1;
                @(posedge clk); start = 0;
                wait(done);
            end
            begin
                repeat(200) @(posedge clk);
                reset_dut(12);
                config_weights(0, 0, 0);
                config_thresholds(-1, 1, 0);
                for (int j = 0; j < INPUTS; j++) inp[j] = $urandom_range(0,1);
                load_input(inp);
                run_inference(200000);
            end
        join_any
        disable fork;
    endtask

    initial begin
        clk = 0; rst = 1;
        load = 0; start = 0; cfg_we = 0;
        inp = '0; cfg_nidx = 0; cfg_addr = 0;
        cfg_wdata = 0; cfg_tdata = 0; cfg_tw = 0;
        
        cov_intf = new();
        cov_rst = new();
        cov_corner = new();
        
        reset_dut(10);
        
        test_basic();
        test_cross_weights_gaps_explicit();
        test_cross_weights_idle_explicit();
        test_cross_thresholds_idle_explicit();
        test_config_burst_patterns();
        test_back_to_back_aggressive();
        test_inference_timing_variations();
        test_threshold_extremes();
        test_input_patterns();
        test_dense_input_numeric();
        test_warm_resets();
        test_early_reset();
        test_long_reset();
        
        repeat(50) @(posedge clk);
        
        $display("PASSED: %0d, FAILED: %0d", pass, fail);
        
        $finish;
    end

endmodule

