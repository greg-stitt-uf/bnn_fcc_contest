`default_nettype none

module config_manager_bnn_core_integration_patched_tb;

    parameter int CONFIG_BUS_WIDTH = 64;
    parameter int PW               = 8;
    parameter int PN               = 8;

    parameter int INPUTS  = 16;
    parameter int HIDDEN1 = 4;
    parameter int HIDDEN2 = 3;
    parameter int OUTPUTS = 2;

    localparam int L0_COUNT_WIDTH = $clog2(INPUTS + 1);
    localparam int L1_COUNT_WIDTH = $clog2(HIDDEN1 + 1);
    localparam int L2_COUNT_WIDTH = $clog2(HIDDEN2 + 1);

    localparam int L0_INPUT_BEATS = (INPUTS  + PW - 1) / PW;
    localparam int L1_INPUT_BEATS = (HIDDEN1 + PW - 1) / PW;
    localparam int L2_INPUT_BEATS = (HIDDEN2 + PW - 1) / PW;

    localparam int L0_NIDX_W = (HIDDEN1 > 1) ? $clog2(HIDDEN1) : 1;
    localparam int L1_NIDX_W = (HIDDEN2 > 1) ? $clog2(HIDDEN2) : 1;
    localparam int L2_NIDX_W = (OUTPUTS > 1) ? $clog2(OUTPUTS) : 1;

    localparam int L0_ADDR_W = (L0_INPUT_BEATS > 1) ? $clog2(L0_INPUT_BEATS) : 1;
    localparam int L1_ADDR_W = (L1_INPUT_BEATS > 1) ? $clog2(L1_INPUT_BEATS) : 1;
    localparam int L2_ADDR_W = (L2_INPUT_BEATS > 1) ? $clog2(L2_INPUT_BEATS) : 1;

    localparam int MAX_NEURONS =
        (HIDDEN1 >= HIDDEN2) ?
            ((HIDDEN1 >= OUTPUTS) ? HIDDEN1 : OUTPUTS) :
            ((HIDDEN2 >= OUTPUTS) ? HIDDEN2 : OUTPUTS);

    localparam int MAX_BEATS =
        (L0_INPUT_BEATS >= L1_INPUT_BEATS) ?
            ((L0_INPUT_BEATS >= L2_INPUT_BEATS) ? L0_INPUT_BEATS : L2_INPUT_BEATS) :
            ((L1_INPUT_BEATS >= L2_INPUT_BEATS) ? L1_INPUT_BEATS : L2_INPUT_BEATS);

    localparam int CFG_NEURON_W      = (MAX_NEURONS > 1) ? $clog2(MAX_NEURONS) : 1;
    localparam int CFG_WEIGHT_ADDR_W = (MAX_BEATS > 1) ? $clog2(MAX_BEATS) : 1;
    localparam int THRESHOLD_W =
        (L0_COUNT_WIDTH > L1_COUNT_WIDTH) ?
            ((L0_COUNT_WIDTH > L2_COUNT_WIDTH) ? L0_COUNT_WIDTH : L2_COUNT_WIDTH) :
            ((L1_COUNT_WIDTH > L2_COUNT_WIDTH) ? L1_COUNT_WIDTH : L2_COUNT_WIDTH);

    localparam int L3_POPCOUNT_W = OUTPUTS * L2_COUNT_WIDTH;

    logic clk = 1'b0;
    logic rst;

    logic                          cfg_valid;
    logic                          cfg_ready;
    logic [CONFIG_BUS_WIDTH-1:0]   cfg_data;
    logic [CONFIG_BUS_WIDTH/8-1:0] cfg_keep;
    logic                          cfg_last;

    logic                         m_cfg_write_en;
    logic [1:0]                   m_cfg_layer_sel;
    logic [CFG_NEURON_W-1:0]      m_cfg_neuron_idx;
    logic [CFG_WEIGHT_ADDR_W-1:0] m_cfg_weight_addr;
    logic [PW-1:0]                m_cfg_weight_data;
    logic [THRESHOLD_W-1:0]       m_cfg_threshold_data;
    logic                         m_cfg_threshold_write;
    logic                         m_cfg_ready_downstream;

    logic                     start;
    logic [INPUTS-1:0]        input_vector;
    logic                     done;
    logic                     busy;
    logic                     result_valid;
    logic [L3_POPCOUNT_W-1:0] popcounts_out;
    logic [HIDDEN1-1:0]       activations_l1;
    logic [HIDDEN2-1:0]       activations_l2;

    int passed;
    int failed;

    typedef struct packed {
        logic                         is_thresh;
        logic [1:0]                   layer_sel;
        logic [CFG_NEURON_W-1:0]      neuron_idx;
        logic [CFG_WEIGHT_ADDR_W-1:0] weight_addr;
        logic [PW-1:0]                weight_data;
        logic [THRESHOLD_W-1:0]       threshold_data;
    } cfg_txn_t;

    cfg_txn_t observed_q[$];

    config_manager_multi #(
        .CONFIG_BUS_WIDTH(CONFIG_BUS_WIDTH),
        .PW              (PW),
        .L0_INPUTS       (INPUTS),
        .L0_NEURONS      (HIDDEN1),
        .L0_COUNT_WIDTH  (L0_COUNT_WIDTH),
        .L0_INPUT_BEATS  (L0_INPUT_BEATS),
        .L0_NIDX_W       (L0_NIDX_W),
        .L0_ADDR_W       (L0_ADDR_W),
        .L1_INPUTS       (HIDDEN1),
        .L1_NEURONS      (HIDDEN2),
        .L1_COUNT_WIDTH  (L1_COUNT_WIDTH),
        .L1_INPUT_BEATS  (L1_INPUT_BEATS),
        .L1_NIDX_W       (L1_NIDX_W),
        .L1_ADDR_W       (L1_ADDR_W),
        .L2_INPUTS       (HIDDEN2),
        .L2_NEURONS      (OUTPUTS),
        .L2_COUNT_WIDTH  (L2_COUNT_WIDTH),
        .L2_INPUT_BEATS  (L2_INPUT_BEATS),
        .L2_NIDX_W       (L2_NIDX_W),
        .L2_ADDR_W       (L2_ADDR_W)
    ) mgr_dut (
        .clk                    (clk),
        .rst                    (rst),
        .cfg_valid              (cfg_valid),
        .cfg_ready              (cfg_ready),
        .cfg_data               (cfg_data),
        .cfg_keep               (cfg_keep),
        .cfg_last               (cfg_last),
        .out_cfg_write_en       (m_cfg_write_en),
        .out_cfg_layer_sel      (m_cfg_layer_sel),
        .out_cfg_neuron_idx     (m_cfg_neuron_idx),
        .out_cfg_weight_addr    (m_cfg_weight_addr),
        .out_cfg_weight_data    (m_cfg_weight_data),
        .out_cfg_threshold_data (m_cfg_threshold_data),
        .out_cfg_threshold_write(m_cfg_threshold_write),
        .out_cfg_ready          (m_cfg_ready_downstream)
    );

    bnn_core #(
        .INPUTS (INPUTS),
        .HIDDEN1(HIDDEN1),
        .HIDDEN2(HIDDEN2),
        .OUTPUTS(OUTPUTS),
        .PW     (PW),
        .PN     (PN)
    ) core_dut (
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
        .cfg_write_en       (m_cfg_write_en),
        .cfg_layer_sel      (m_cfg_layer_sel),
        .cfg_neuron_idx     (m_cfg_neuron_idx),
        .cfg_weight_addr    (m_cfg_weight_addr),
        .cfg_weight_data    (m_cfg_weight_data),
        .cfg_threshold_data (m_cfg_threshold_data),
        .cfg_threshold_write(m_cfg_threshold_write),
        .cfg_ready          (m_cfg_ready_downstream)
    );

    initial forever #5 clk = ~clk;

    initial begin
        $display("### PATCHED TB BUILD 2026-04-09 v2 ###");
    end

    function automatic logic [63:0] pack8(
        input logic [7:0] b0,
        input logic [7:0] b1,
        input logic [7:0] b2,
        input logic [7:0] b3,
        input logic [7:0] b4,
        input logic [7:0] b5,
        input logic [7:0] b6,
        input logic [7:0] b7
    );
        pack8 = {b7,b6,b5,b4,b3,b2,b1,b0};
    endfunction

    function automatic logic [5:0] layer_countw(input logic [1:0] lid);
        case (lid)
            2'd0: layer_countw = L0_COUNT_WIDTH[5:0];
            2'd1: layer_countw = L1_COUNT_WIDTH[5:0];
            2'd2: layer_countw = L2_COUNT_WIDTH[5:0];
            default: layer_countw = 6'd1;
        endcase
    endfunction

    function automatic logic [THRESHOLD_W-1:0] trunc_threshold(
        input logic [31:0] raw,
        input logic [1:0]  lid
    );
        logic [31:0] mask32;
        logic [31:0] tmp32;
        logic [5:0]  cw;
        begin
            cw = layer_countw(lid);
            if (cw >= 32)
                mask32 = 32'hFFFF_FFFF;
            else
                mask32 = (32'h0000_0001 << cw) - 1;
            tmp32 = raw & mask32;
            trunc_threshold = tmp32[THRESHOLD_W-1:0];
        end
    endfunction

    task automatic send_beat(
        input logic [63:0] data_i,
        input logic [7:0]  keep_i,
        input logic        last_i
    );
        @(posedge clk iff cfg_ready);
        cfg_valid <= 1'b1;
        cfg_data  <= data_i;
        cfg_keep  <= keep_i;
        cfg_last  <= last_i;
        @(posedge clk);
        cfg_valid <= 1'b0;
        cfg_data  <= '0;
        cfg_keep  <= '0;
        cfg_last  <= 1'b0;
    endtask

    task automatic send_message(
        input logic [7:0]  msgtype,
        input logic [7:0]  layerid,
        input logic [15:0] layerinputs_i,
        input logic [15:0] numneurons_i,
        input logic [15:0] bytesperneuron_i,
        input logic [7:0]  payload[]
    );
        logic [31:0] totalbytes;
        logic [63:0] beat_data;
        logic [7:0]  beat_keep;
        int idx;
        int j;

        totalbytes = payload.size();

        send_beat(
            pack8(
                msgtype,
                layerid,
                layerinputs_i[7:0],
                layerinputs_i[15:8],
                numneurons_i[7:0],
                numneurons_i[15:8],
                bytesperneuron_i[7:0],
                bytesperneuron_i[15:8]
            ),
            8'hFF,
            1'b0
        );

        send_beat(
            pack8(
                totalbytes[7:0],
                totalbytes[15:8],
                totalbytes[23:16],
                totalbytes[31:24],
                8'h00,
                8'h00,
                8'h00,
                8'h00
            ),
            8'hFF,
            (payload.size() == 0)
        );

        idx = 0;
        while (idx < payload.size()) begin
            beat_data = '0;
            beat_keep = '0;
            for (j = 0; j < 8; j++) begin
                if (idx < payload.size()) begin
                    beat_data[j*8 +: 8] = payload[idx];
                    beat_keep[j] = 1'b1;
                    idx++;
                end
            end
            send_beat(beat_data, beat_keep, (idx == payload.size()));
        end
    endtask

    task automatic wait_for_observed_count(
        input int base_idx,
        input int expected_added,
        input int timeout_cycles
    );
        int cycles;
        begin
            cycles = 0;
            while (((observed_q.size() - base_idx) < expected_added) && (cycles < timeout_cycles)) begin
                @(posedge clk);
                cycles++;
            end

            if ((observed_q.size() - base_idx) < expected_added) begin
                $display("[FAIL] Timed out waiting for %0d new observed txns, only saw %0d",
                         expected_added, observed_q.size() - base_idx);
                failed++;
            end
        end
    endtask

    task automatic wait_for_cfg_drain(
        input int idle_cycles_needed,
        input int timeout_cycles
    );
        int idle_cycles;
        int cycles;
        begin
            idle_cycles = 0;
            cycles = 0;
            while ((idle_cycles < idle_cycles_needed) && (cycles < timeout_cycles)) begin
                @(posedge clk);
                cycles++;
                if (cfg_ready &&
                    m_cfg_ready_downstream &&
                    !m_cfg_write_en &&
                    !m_cfg_threshold_write &&
                    (mgr_dut.state == mgr_dut.ST_IDLE))
                    idle_cycles++;
                else
                    idle_cycles = 0;
            end

            if (idle_cycles < idle_cycles_needed) begin
                $display("[FAIL] Timed out waiting for config path to drain");
                failed++;
            end
        end
    endtask

    task automatic check_segment(
        input string    name,
        input int       base_idx,
        input cfg_txn_t exp[]
    );
        bit local_fail;
        local_fail = 1'b0;

        if ((observed_q.size() - base_idx) != exp.size()) begin
            $display("[FAIL] %s: observed %0d txns, expected %0d",
                     name, observed_q.size() - base_idx, exp.size());
            failed++;
            return;
        end

        for (int i = 0; i < exp.size(); i++) begin
            if (observed_q[base_idx + i] !== exp[i]) begin
                $display("[FAIL] %s: mismatch at txn %0d", name, i);
                $display("       got is_thresh=%0b layer=%0d neuron=%0d addr=%0d w=%0h t=%0h",
                         observed_q[base_idx+i].is_thresh,
                         observed_q[base_idx+i].layer_sel,
                         observed_q[base_idx+i].neuron_idx,
                         observed_q[base_idx+i].weight_addr,
                         observed_q[base_idx+i].weight_data,
                         observed_q[base_idx+i].threshold_data);
                $display("       exp is_thresh=%0b layer=%0d neuron=%0d addr=%0d w=%0h t=%0h",
                         exp[i].is_thresh,
                         exp[i].layer_sel,
                         exp[i].neuron_idx,
                         exp[i].weight_addr,
                         exp[i].weight_data,
                         exp[i].threshold_data);
                local_fail = 1'b1;
            end
        end

        if (local_fail)
            failed++;
        else begin
            $display("[PASS] %s", name);
            passed++;
        end
    endtask

    always_ff @(posedge clk) begin
        cfg_txn_t txn;

        if (!rst && core_dut.l1_cfg_write_en) begin
            txn.is_thresh      = 1'b0;
            txn.layer_sel      = 2'd0;
            txn.neuron_idx     = '0;
            txn.weight_addr    = '0;
            txn.weight_data    = m_cfg_weight_data;
            txn.threshold_data = '0;
            txn.neuron_idx[L0_NIDX_W-1:0]  = m_cfg_neuron_idx[L0_NIDX_W-1:0];
            txn.weight_addr[L0_ADDR_W-1:0] = m_cfg_weight_addr[L0_ADDR_W-1:0];
            observed_q.push_back(txn);
        end

        if (!rst && core_dut.l2_cfg_write_en) begin
            txn.is_thresh      = 1'b0;
            txn.layer_sel      = 2'd1;
            txn.neuron_idx     = '0;
            txn.weight_addr    = '0;
            txn.weight_data    = m_cfg_weight_data;
            txn.threshold_data = '0;
            txn.neuron_idx[L1_NIDX_W-1:0]  = m_cfg_neuron_idx[L1_NIDX_W-1:0];
            txn.weight_addr[L1_ADDR_W-1:0] = m_cfg_weight_addr[L1_ADDR_W-1:0];
            observed_q.push_back(txn);
        end

        if (!rst && core_dut.l3_cfg_write_en) begin
            txn.is_thresh      = 1'b0;
            txn.layer_sel      = 2'd2;
            txn.neuron_idx     = '0;
            txn.weight_addr    = '0;
            txn.weight_data    = m_cfg_weight_data;
            txn.threshold_data = '0;
            txn.neuron_idx[L2_NIDX_W-1:0]  = m_cfg_neuron_idx[L2_NIDX_W-1:0];
            txn.weight_addr[L2_ADDR_W-1:0] = m_cfg_weight_addr[L2_ADDR_W-1:0];
            observed_q.push_back(txn);
        end

        if (!rst && core_dut.l1_cfg_thresh_write) begin
            txn.is_thresh      = 1'b1;
            txn.layer_sel      = 2'd0;
            txn.neuron_idx     = '0;
            txn.weight_addr    = '0;
            txn.weight_data    = '0;
            txn.threshold_data = '0;
            txn.neuron_idx[L0_NIDX_W-1:0]          = m_cfg_neuron_idx[L0_NIDX_W-1:0];
            txn.threshold_data[L0_COUNT_WIDTH-1:0] = m_cfg_threshold_data[L0_COUNT_WIDTH-1:0];
            observed_q.push_back(txn);
        end

        if (!rst && core_dut.l2_cfg_thresh_write) begin
            txn.is_thresh      = 1'b1;
            txn.layer_sel      = 2'd1;
            txn.neuron_idx     = '0;
            txn.weight_addr    = '0;
            txn.weight_data    = '0;
            txn.threshold_data = '0;
            txn.neuron_idx[L1_NIDX_W-1:0]          = m_cfg_neuron_idx[L1_NIDX_W-1:0];
            txn.threshold_data[L1_COUNT_WIDTH-1:0] = m_cfg_threshold_data[L1_COUNT_WIDTH-1:0];
            observed_q.push_back(txn);
        end

        if (!rst && core_dut.l3_cfg_thresh_write) begin
            txn.is_thresh      = 1'b1;
            txn.layer_sel      = 2'd2;
            txn.neuron_idx     = '0;
            txn.weight_addr    = '0;
            txn.weight_data    = '0;
            txn.threshold_data = '0;
            txn.neuron_idx[L2_NIDX_W-1:0]          = m_cfg_neuron_idx[L2_NIDX_W-1:0];
            txn.threshold_data[L2_COUNT_WIDTH-1:0] = m_cfg_threshold_data[L2_COUNT_WIDTH-1:0];
            observed_q.push_back(txn);
        end
    end

    initial begin
        passed       = 0;
        failed       = 0;
        rst          = 1'b1;
        cfg_valid    = 1'b0;
        cfg_data     = '0;
        cfg_keep     = '0;
        cfg_last     = 1'b0;
        start        = 1'b0;
        input_vector = '0;

        repeat (5) @(posedge clk);
        rst = 1'b0;
        repeat (2) @(posedge clk);

        begin
            logic [7:0] payload[];
            cfg_txn_t   exp[];
            int         base;
            int         idx;

            base    = observed_q.size();
            payload = new[L0_INPUT_BEATS * HIDDEN1];
            for (int i = 0; i < payload.size(); i++)
                payload[i] = 8'(8'h10 + i);

            exp = new[payload.size()];
            idx = 0;
            for (int n = 0; n < HIDDEN1; n++) begin
                for (int b = 0; b < L0_INPUT_BEATS; b++) begin
                    exp[idx].is_thresh      = 1'b0;
                    exp[idx].layer_sel      = 2'd0;
                    exp[idx].neuron_idx     = CFG_NEURON_W'(n);
                    exp[idx].weight_addr    = CFG_WEIGHT_ADDR_W'(b);
                    exp[idx].weight_data    = payload[idx];
                    exp[idx].threshold_data = '0;
                    idx++;
                end
            end

            send_message(8'd0, 8'd0, INPUTS[15:0], HIDDEN1[15:0], L0_INPUT_BEATS[15:0], payload);
            wait_for_observed_count(base, exp.size(), 200);
            wait_for_cfg_drain(3, 200);
            check_segment("Test1_layer0_weights_into_core", base, exp);
        end

        begin
            logic [7:0]  payload[];
            logic [31:0] raw_thresholds[0:HIDDEN2-1];
            cfg_txn_t    exp[];
            int          base;
            int          idx;

            base = observed_q.size();
            payload = new[4 * HIDDEN2];

            raw_thresholds[0] = 32'd1;
            raw_thresholds[1] = 32'd5;
            raw_thresholds[2] = 32'd255;

            for (int n = 0; n < HIDDEN2; n++) begin
                payload[n*4 + 0] = raw_thresholds[n][7:0];
                payload[n*4 + 1] = raw_thresholds[n][15:8];
                payload[n*4 + 2] = raw_thresholds[n][23:16];
                payload[n*4 + 3] = raw_thresholds[n][31:24];
            end

            exp = new[HIDDEN2];
            idx = 0;
            for (int n = 0; n < HIDDEN2; n++) begin
                exp[idx].is_thresh      = 1'b1;
                exp[idx].layer_sel      = 2'd1;
                exp[idx].neuron_idx     = CFG_NEURON_W'(n);
                exp[idx].weight_addr    = '0;
                exp[idx].weight_data    = '0;
                exp[idx].threshold_data = trunc_threshold(raw_thresholds[n], 2'd1);
                idx++;
            end

            send_message(8'd1, 8'd1, 16'd0, HIDDEN2[15:0], 16'd4, payload);
            wait_for_observed_count(base, exp.size(), 200);
            wait_for_cfg_drain(3, 200);
            check_segment("Test2_layer1_thresholds_into_core", base, exp);
        end

        begin
            logic [7:0] payload[];
            cfg_txn_t   exp[];
            int         base;
            int         idx;

            base    = observed_q.size();
            payload = new[L2_INPUT_BEATS * OUTPUTS];
            payload[0] = 8'hA5;
            payload[1] = 8'h3C;

            exp = new[payload.size()];
            idx = 0;
            for (int n = 0; n < OUTPUTS; n++) begin
                for (int b = 0; b < L2_INPUT_BEATS; b++) begin
                    exp[idx].is_thresh      = 1'b0;
                    exp[idx].layer_sel      = 2'd2;
                    exp[idx].neuron_idx     = CFG_NEURON_W'(n);
                    exp[idx].weight_addr    = CFG_WEIGHT_ADDR_W'(b);
                    exp[idx].weight_data    = payload[idx];
                    exp[idx].threshold_data = '0;
                    idx++;
                end
            end

            send_message(8'd0, 8'd2, HIDDEN2[15:0], OUTPUTS[15:0], L2_INPUT_BEATS[15:0], payload);
            wait_for_observed_count(base, exp.size(), 200);
            wait_for_cfg_drain(3, 200);
            check_segment("Test3_layer2_weights_into_core", base, exp);
        end

        begin
            logic [7:0] payload[];
            int         base;

            base    = observed_q.size();
            payload = new[3];
            payload[0] = 8'hDE;
            payload[1] = 8'hAD;
            payload[2] = 8'hBE;

            send_message(8'd0, 8'd9, 16'd8, 16'd1, 16'd1, payload);
            wait_for_cfg_drain(3, 200);

            if (observed_q.size() == base) begin
                $display("[PASS] Test4_unknown_layer_skipped_before_core");
                passed++;
            end else begin
                $display("[FAIL] Test4_unknown_layer_skipped_before_core: observed %0d unexpected txns",
                         observed_q.size() - base);
                failed++;
            end
        end

        $display("\n========================================");
        $display("config_manager -> bnn_core integration TB Complete");
        $display("Tests passed: %0d", passed);
        $display("Tests failed: %0d", failed);
        $display("========================================");
        $finish;
    end

    p_no_dual_manager_write :
    assert property (@(posedge clk) disable iff (rst) !(m_cfg_write_en && m_cfg_threshold_write))
    else $error("manager asserted weight and threshold write together");

    p_core_layer_onehot_cfg :
    assert property (@(posedge clk) disable iff (rst)
        $onehot0({core_dut.l1_cfg_write_en || core_dut.l1_cfg_thresh_write,
                  core_dut.l2_cfg_write_en || core_dut.l2_cfg_thresh_write,
                  core_dut.l3_cfg_write_en || core_dut.l3_cfg_thresh_write}))
    else $error("multiple core layer config paths active together");

endmodule

`default_nettype wire