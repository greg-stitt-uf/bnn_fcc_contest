`timescale 1ns / 1ps

module config_parser_tb;

    import bnn_config_pkg::*;

    localparam int TARGET_LAYER_ID       = 0;
    localparam int INPUTS                = 784;
    localparam int NEURONS               = 256;
    localparam int PW                    = 8;
    localparam int COUNT_WIDTH           = $clog2(INPUTS + 1);
    localparam int INPUT_BEATS           = (INPUTS + PW - 1) / PW;
    localparam int CFG_NEURON_WIDTH      = (NEURONS > 1) ? $clog2(NEURONS) : 1;
    localparam int CFG_WEIGHT_ADDR_WIDTH = (INPUT_BEATS > 1) ? $clog2(INPUT_BEATS) : 1;

    logic                             clk, rst;
    logic                             cfg_valid, cfg_ready, cfg_last;
    logic [63:0]                      cfg_data;
    logic [7:0]                       cfg_keep;

    logic                             layer_cfg_we, layer_cfg_tw, layer_cfg_rdy;
    logic [CFG_NEURON_WIDTH-1:0]      layer_cfg_nidx;
    logic [CFG_WEIGHT_ADDR_WIDTH-1:0] layer_cfg_addr;
    logic [PW-1:0]                    layer_cfg_wdata;
    logic [COUNT_WIDTH-1:0]           layer_cfg_tdata;

    bit weights[NEURONS][INPUTS];
    int unsigned thresholds[NEURONS];

    byte_q_t       stream_bytes;
    axi64_beat_t   axi_beats[$];
    cfg_header_t   meta;
    bit            meta_valid;
    weight_write_t exp_w[$];
    thresh_write_t exp_t[$];

    int unsigned w_seen, t_seen;
    bit gaps_enable;
    bit stalls_enable;

    config_parser #(
        .TARGET_LAYER_ID(TARGET_LAYER_ID),
        .INPUTS(INPUTS),
        .NEURONS(NEURONS),
        .PW(PW)
    ) dut (
        .clk(clk),
        .rst(rst),
        .cfg_valid(cfg_valid),
        .cfg_ready(cfg_ready),
        .cfg_data(cfg_data),
        .cfg_keep(cfg_keep),
        .cfg_last(cfg_last),

        .cfg_we(layer_cfg_we),
        .cfg_tw(layer_cfg_tw),
        .cfg_nidx(layer_cfg_nidx),
        .cfg_addr(layer_cfg_addr),
        .cfg_wdata(layer_cfg_wdata),
        .cfg_tdata(layer_cfg_tdata),
        .cfg_rdy(layer_cfg_rdy)
    );

    always #5 clk = ~clk;

    task automatic do_reset();
        begin
            rst       = 1'b1;
            cfg_valid = 1'b0;
            cfg_data  = '0;
            cfg_keep  = '0;
            cfg_last  = 1'b0;
            layer_cfg_rdy = 1'b1;
            repeat (5) @(posedge clk);
            rst = 1'b0;
            repeat (2) @(posedge clk);
        end
    endtask

    task automatic fill_random_model(input int unsigned seed);
        void'($urandom(seed));
        for (int n = 0; n < NEURONS; n++) begin
            for (int i = 0; i < INPUTS; i++) begin
                weights[n][i] = $urandom_range(0, 1);
            end
            thresholds[n] = $urandom_range(0, INPUTS);
        end
    endtask

    task automatic build_case();
        begin
            stream_bytes.delete();
            axi_beats.delete();
            exp_w.delete();
            exp_t.delete();

            build_layer_stream(stream_bytes, TARGET_LAYER_ID, INPUTS, weights, thresholds);
            pack_bytes_to_axi64(stream_bytes, axi_beats);
            process_stream_for_layer(stream_bytes, TARGET_LAYER_ID, PW, meta, meta_valid, exp_w, exp_t);

            if (!meta_valid) $fatal(1, "No weight header found for target layer");
            if (exp_w.size() != (NEURONS * INPUT_BEATS))
                $fatal(1, "Expected %0d weight writes, got %0d", NEURONS*INPUT_BEATS, exp_w.size());
            if (exp_t.size() != NEURONS)
                $fatal(1, "Expected %0d threshold writes, got %0d", NEURONS, exp_t.size());
        end
    endtask

    task automatic drive_stream();
        begin
            for (int i = 0; i < axi_beats.size(); i++) begin
                do begin
                    @(posedge clk);
                    cfg_valid <= 1'b1;
                    cfg_data  <= axi_beats[i].data;
                    cfg_keep  <= axi_beats[i].keep;
                    cfg_last  <= axi_beats[i].last;
                end while (!cfg_ready);

                @(posedge clk);
                cfg_valid <= 1'b0;
                cfg_data  <= '0;
                cfg_keep  <= '0;
                cfg_last  <= 1'b0;

                if (gaps_enable) begin
                    repeat ($urandom_range(0, 3)) @(posedge clk);
                end
            end
        end
    endtask

    always @(posedge clk) begin
        if (rst) begin
            w_seen <= 0;
            t_seen <= 0;
        end else begin
            if (layer_cfg_we && layer_cfg_rdy) begin
                if (w_seen >= exp_w.size())
                    $fatal(1, "Extra weight write seen: n=%0d addr=%0d data=0x%0h",
                           layer_cfg_nidx, layer_cfg_addr, layer_cfg_wdata);

                if (layer_cfg_nidx !== exp_w[w_seen].neuron[CFG_NEURON_WIDTH-1:0])
                    $fatal(1, "Weight write neuron mismatch exp=%0d got=%0d at idx=%0d",
                           exp_w[w_seen].neuron, layer_cfg_nidx, w_seen);

                if (layer_cfg_addr !== exp_w[w_seen].beat[CFG_WEIGHT_ADDR_WIDTH-1:0])
                    $fatal(1, "Weight write addr mismatch exp=%0d got=%0d at idx=%0d",
                           exp_w[w_seen].beat, layer_cfg_addr, w_seen);

                if (layer_cfg_wdata !== exp_w[w_seen].word[PW-1:0])
                    $fatal(1, "Weight write data mismatch exp=0x%0h got=0x%0h at idx=%0d",
                           exp_w[w_seen].word[PW-1:0], layer_cfg_wdata, w_seen);

                w_seen <= w_seen + 1;
            end

            if (layer_cfg_tw && layer_cfg_rdy) begin
                if (t_seen >= exp_t.size())
                    $fatal(1, "Extra threshold write seen: n=%0d t=0x%0h",
                           layer_cfg_nidx, layer_cfg_tdata);

                if (layer_cfg_nidx !== exp_t[t_seen].neuron[CFG_NEURON_WIDTH-1:0])
                    $fatal(1, "Threshold neuron mismatch exp=%0d got=%0d at idx=%0d",
                           exp_t[t_seen].neuron, layer_cfg_nidx, t_seen);

                if (layer_cfg_tdata !== exp_t[t_seen].thresh[COUNT_WIDTH-1:0])
                    $fatal(1, "Threshold data mismatch exp=0x%0h got=0x%0h at idx=%0d",
                           exp_t[t_seen].thresh[COUNT_WIDTH-1:0], layer_cfg_tdata, t_seen);

                t_seen <= t_seen + 1;
            end
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            layer_cfg_rdy <= 1'b1;
        end else if (stalls_enable) begin
            layer_cfg_rdy <= ($urandom_range(0, 3) != 0); // 75% ready
        end else begin
            layer_cfg_rdy <= 1'b1;
        end
    end

    task automatic run_test(
        input string name,
        input int unsigned seed,
        input bit use_gaps,
        input bit use_stalls
    );
        begin
            $display("---- %s ----", name);
            gaps_enable   = use_gaps;
            stalls_enable = use_stalls;
            w_seen        = 0;
            t_seen        = 0;

            do_reset();
            fill_random_model(seed);
            build_case();
            fork
                drive_stream();
            join

            wait (w_seen == exp_w.size() && t_seen == exp_t.size());
            repeat (10) @(posedge clk);

            if (w_seen != exp_w.size())
                $fatal(1, "%s: missing weight writes exp=%0d got=%0d", name, exp_w.size(), w_seen);
            if (t_seen != exp_t.size())
                $fatal(1, "%s: missing threshold writes exp=%0d got=%0d", name, exp_t.size(), t_seen);

            $display("%s PASS", name);
        end
    endtask

    initial begin
        clk = 1'b0;

        run_test("basic",          32'd42,   1'b0, 1'b0);
        run_test("with_gaps",      32'd99,   1'b1, 1'b0);
        run_test("with_backpress", 32'd2026, 1'b0, 1'b1);
        run_test("gaps_backpress", 32'd7,    1'b1, 1'b1);

        $display("ALL TESTS PASSED");
        $finish;
    end

    initial begin
        #5ms;
        $fatal(1, "TB timeout: w_seen=%0d/%0d t_seen=%0d/%0d",
            w_seen, exp_w.size(), t_seen, exp_t.size());
    end


endmodule