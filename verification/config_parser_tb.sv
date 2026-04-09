`timescale 1ns / 1ps

import bnn_config_pkg::*; 

module config_parser_tb;

    // ---------------------------------------------------------
    // Parameters & Signals
    // ---------------------------------------------------------
    parameter int PW = 8;
    parameter int MAX_NEURONS = 256;
    parameter int MAX_BEATS = 98;

    logic clk, rst;
    
    // AXI-Stream Signals
    logic [63:0] cfg_data;
    logic        cfg_valid;
    logic        cfg_ready;
    logic [7:0]  cfg_keep;
    logic        cfg_last;

    // Layer Interface Signals
    logic        cfg_we, cfg_tw, cfg_rdy;
    logic [7:0]  cfg_nidx;
    logic [$clog2(MAX_BEATS)-1:0] cfg_addr;
    logic [PW-1:0]                cfg_wdata;
    logic [9:0]                   cfg_tdata;

    // ---------------------------------------------------------
    // DUT & Golden Model
    // ---------------------------------------------------------
    bnn_config_manager #(PW, MAX_NEURONS, MAX_BEATS) dut (.*);
    
    // Split declaration and instantiation to make Modelsim happy
    ConfigParser gold;

    // ---------------------------------------------------------
    // Testbench Variables & Scoreboard
    // ---------------------------------------------------------
    byte stream_q[$];
    int errors = 0;
    int tests_passed = 0;

    // Clock Generation
    initial begin clk = 0; forever #5 clk = ~clk; end

    // ---------------------------------------------------------
    // Task: Drive AXI Stream (Made 'automatic')
    // ---------------------------------------------------------
    task automatic drive_stream(ref byte data[$]);
        int i = 0; // Now legal because the task is automatic
        while (i < data.size()) begin
            @(posedge clk);
            if (cfg_ready) begin
                cfg_valid = 1'b1;
                cfg_data  = 0;
                // Pack 8 bytes into the 64-bit AXI word (Little Endian)
                for (int b = 0; b < 8; b++) begin
                    if (i < data.size()) begin
                        cfg_data |= (64'(data[i]) << (b * 8));
                        i++;
                    end
                end
                cfg_last = (i >= data.size());
            end else begin
                @(posedge clk); // Wait for ready
            end
        end
        @(posedge clk);
        cfg_valid = 1'b0;
    endtask

    // ---------------------------------------------------------
    // Task: Scoreboard Checker (Made 'automatic')
    // ---------------------------------------------------------
    task automatic check_results(int layer_id);
        weight_write_t exp_w;
        threshold_write_t exp_t;
        
        // Check Weights
        while (gold.weight_writes[layer_id].size() > 0) begin
            @(posedge clk);
            if (cfg_we && cfg_rdy) begin
                exp_w = gold.weight_writes[layer_id].pop_front();
                if (cfg_nidx !== exp_w.neuron || cfg_addr !== exp_w.beat || cfg_wdata !== exp_w.word) begin
                    $error("[FAIL] Weight Mismatch! Neu:%0d Beat:%0d Data:%h | Exp: Neu:%0d Beat:%0d Data:%h",
                           cfg_nidx, cfg_addr, cfg_wdata, exp_w.neuron, exp_w.beat, exp_w.word);
                    errors++;
                end
            end
        end

        // Check Thresholds
        while (gold.threshold_writes[layer_id].size() > 0) begin
            @(posedge clk);
            if (cfg_tw && cfg_rdy) begin
                exp_t = gold.threshold_writes[layer_id].pop_front();
                if (cfg_nidx !== exp_t.neuron || cfg_tdata !== exp_t.thresh) begin
                    $error("[FAIL] Thresh Mismatch! Neu:%0d Data:%h | Exp: Neu:%0d Data:%h",
                           cfg_nidx, cfg_tdata, exp_t.neuron, exp_t.thresh);
                    errors++;
                end
            end
        end
        
        if (errors == 0) begin
            $display("[PASS] Layer %0d verification complete.", layer_id);
            tests_passed++;
        end
    endtask

    // Helper to push 16-byte header into the stream queue (Made 'automatic')
    task automatic push_header(byte mtype, byte id, shortint inputs, shortint neurons, shortint bpn, int total);
        stream_q.push_back(mtype);
        stream_q.push_back(id);
        stream_q.push_back(inputs[7:0]);  stream_q.push_back(inputs[15:8]);
        stream_q.push_back(neurons[7:0]); stream_q.push_back(neurons[15:8]);
        stream_q.push_back(bpn[7:0]);     stream_q.push_back(bpn[15:8]);
        stream_q.push_back(total[7:0]);   stream_q.push_back(total[15:8]);
        stream_q.push_back(total[23:16]); stream_q.push_back(total[31:24]);
        repeat(4) stream_q.push_back(8'h00); // Reserved
    endtask

    // ---------------------------------------------------------
    // Test Suites
    // ---------------------------------------------------------
    initial begin
        // Initialize the class object here
        gold = new(PW);

        // Init Signals
        rst = 1; cfg_valid = 0; cfg_rdy = 1;
        repeat(5) @(posedge clk);
        rst = 0;
        
        // --- T1 & T8: Full 784 -> 256 Layer Config ---
        $display("\n=== Running T8: Full SFC Layer (784 in -> 256 neu) ===");
        push_header(0, 0, 784, 256, 98, 25088);
        for (int i = 0; i < 25088; i++) stream_q.push_back(8'hAA);
        push_header(1, 0, 0, 256, 4, 1024);
        for (int i = 0; i < 256; i++) begin
            stream_q.push_back(i[7:0]);   
            stream_q.push_back(i[15:8]);
            stream_q.push_back(8'h00);
            stream_q.push_back(8'h00);
        end

        gold.process(stream_q);
        
        fork
            drive_stream(stream_q);
            check_results(0);
        join
        
        // --- T4: Threshold Truncation Test ---
        $display("\n=== Running T4: Threshold Truncation ===");
        stream_q.delete();
        push_header(0, 1, 784, 1, 98, 98);
        for (int i = 0; i < 98; i++) stream_q.push_back(8'h00);
        push_header(1, 1, 0, 1, 4, 4);
        stream_q.push_back(8'hEF); stream_q.push_back(8'hBE);
        stream_q.push_back(8'hAD); stream_q.push_back(8'hDE);
        
        gold.process(stream_q);
        fork
            drive_stream(stream_q);
            check_results(1);
        join

        $display("\n========================================");
        $display(" Final Results: %0d Tests Passed, %0d Errors", tests_passed, errors);
        $display("========================================\n");
        $finish;
    end

endmodule