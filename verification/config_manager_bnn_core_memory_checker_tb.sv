`default_nettype none

module config_manager_bnn_core_memory_checker_tb;

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

    logic              start;
    logic [INPUTS-1:0] input_vector;
    logic              done;
    logic              busy;
    logic              result_valid;

    int passed;
    int failed;

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
        .popcounts_out      (),
        .activations_l1     (),
        .activations_l2     (),
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
                8'h00, 8'h00, 8'h00, 8'h00
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
                $display("[FAIL] Timed out waiting for config drain");
                failed++;
            end
        end
    endtask

    function automatic logic [PW-1:0] read_l1_weight(input int neuron, input int addr);
        int np_idx;
        int group_idx;
        int local_addr;
        begin
            np_idx     = neuron % PN;
            group_idx  = neuron / PN;
            local_addr = group_idx * L0_INPUT_BEATS + addr;
            read_l1_weight = core_dut.u_layer1.weight_rams[np_idx][local_addr];
        end
    endfunction

    function automatic logic [L0_COUNT_WIDTH-1:0] read_l1_thresh(input int neuron);
        int np_idx;
        int group_idx;
        begin
            np_idx    = neuron % PN;
            group_idx = neuron / PN;
            read_l1_thresh = core_dut.u_layer1.threshold_rams[np_idx][group_idx];
        end
    endfunction

    function automatic logic [PW-1:0] read_l2_weight(input int neuron, input int addr);
        int np_idx;
        int group_idx;
        int local_addr;
        begin
            np_idx     = neuron % PN;
            group_idx  = neuron / PN;
            local_addr = group_idx * L1_INPUT_BEATS + addr;
            read_l2_weight = core_dut.u_layer2.weight_rams[np_idx][local_addr];
        end
    endfunction

    function automatic logic [L1_COUNT_WIDTH-1:0] read_l2_thresh(input int neuron);
        int np_idx;
        int group_idx;
        begin
            np_idx    = neuron % PN;
            group_idx = neuron / PN;
            read_l2_thresh = core_dut.u_layer2.threshold_rams[np_idx][group_idx];
        end
    endfunction

    function automatic logic [PW-1:0] read_l3_weight(input int neuron, input int addr);
        int np_idx;
        int group_idx;
        int local_addr;
        begin
            np_idx     = neuron % PN;
            group_idx  = neuron / PN;
            local_addr = group_idx * L2_INPUT_BEATS + addr;
            read_l3_weight = core_dut.u_layer3.weight_rams[np_idx][local_addr];
        end
    endfunction

    function automatic logic [L2_COUNT_WIDTH-1:0] read_l3_thresh(input int neuron);
        int np_idx;
        int group_idx;
        begin
            np_idx    = neuron % PN;
            group_idx = neuron / PN;
            read_l3_thresh = core_dut.u_layer3.threshold_rams[np_idx][group_idx];
        end
    endfunction

    task automatic check_l1_weights(input logic [7:0] payload[]);
        int idx;
        bit local_fail;
        begin
            idx = 0;
            local_fail = 1'b0;
            for (int n = 0; n < HIDDEN1; n++) begin
                for (int a = 0; a < L0_INPUT_BEATS; a++) begin
                    if (read_l1_weight(n, a) !== payload[idx][PW-1:0]) begin
                        $display("[FAIL] L1 weight mismatch n=%0d a=%0d got=%0h exp=%0h",
                                 n, a, read_l1_weight(n, a), payload[idx][PW-1:0]);
                        failed++;
                        local_fail = 1'b1;
                    end
                    idx++;
                end
            end
            if (!local_fail) begin
                $display("[PASS] checked L1 weight memory");
                passed++;
            end
        end
    endtask

    task automatic check_l2_weights(input logic [7:0] payload[]);
        int idx;
        bit local_fail;
        begin
            idx = 0;
            local_fail = 1'b0;
            for (int n = 0; n < HIDDEN2; n++) begin
                for (int a = 0; a < L1_INPUT_BEATS; a++) begin
                    if (read_l2_weight(n, a) !== payload[idx][PW-1:0]) begin
                        $display("[FAIL] L2 weight mismatch n=%0d a=%0d got=%0h exp=%0h",
                                 n, a, read_l2_weight(n, a), payload[idx][PW-1:0]);
                        failed++;
                        local_fail = 1'b1;
                    end
                    idx++;
                end
            end
            if (!local_fail) begin
                $display("[PASS] checked L2 weight memory");
                passed++;
            end
        end
    endtask

    task automatic check_l3_weights(input logic [7:0] payload[]);
        int idx;
        bit local_fail;
        begin
            idx = 0;
            local_fail = 1'b0;
            for (int n = 0; n < OUTPUTS; n++) begin
                for (int a = 0; a < L2_INPUT_BEATS; a++) begin
                    if (read_l3_weight(n, a) !== payload[idx][PW-1:0]) begin
                        $display("[FAIL] L3 weight mismatch n=%0d a=%0d got=%0h exp=%0h",
                                 n, a, read_l3_weight(n, a), payload[idx][PW-1:0]);
                        failed++;
                        local_fail = 1'b1;
                    end
                    idx++;
                end
            end
            if (!local_fail) begin
                $display("[PASS] checked L3 weight memory");
                passed++;
            end
        end
    endtask

    task automatic check_l1_thresh(input logic [31:0] raw[0:HIDDEN1-1]);
        logic [THRESHOLD_W-1:0] exp_t;
        bit local_fail;
        begin
            local_fail = 1'b0;
            for (int n = 0; n < HIDDEN1; n++) begin
                exp_t = trunc_threshold(raw[n], 2'd0);
                if (read_l1_thresh(n) !== exp_t[L0_COUNT_WIDTH-1:0]) begin
                    $display("[FAIL] L1 thresh mismatch n=%0d got=%0h exp=%0h",
                             n, read_l1_thresh(n), exp_t[L0_COUNT_WIDTH-1:0]);
                    failed++;
                    local_fail = 1'b1;
                end
            end
            if (!local_fail) begin
                $display("[PASS] checked L1 threshold memory");
                passed++;
            end
        end
    endtask

    task automatic check_l2_thresh(input logic [31:0] raw[0:HIDDEN2-1]);
        logic [THRESHOLD_W-1:0] exp_t;
        bit local_fail;
        begin
            local_fail = 1'b0;
            for (int n = 0; n < HIDDEN2; n++) begin
                exp_t = trunc_threshold(raw[n], 2'd1);
                if (read_l2_thresh(n) !== exp_t[L1_COUNT_WIDTH-1:0]) begin
                    $display("[FAIL] L2 thresh mismatch n=%0d got=%0h exp=%0h",
                             n, read_l2_thresh(n), exp_t[L1_COUNT_WIDTH-1:0]);
                    failed++;
                    local_fail = 1'b1;
                end
            end
            if (!local_fail) begin
                $display("[PASS] checked L2 threshold memory");
                passed++;
            end
        end
    endtask

    task automatic check_l3_thresh(input logic [31:0] raw[0:OUTPUTS-1]);
        logic [THRESHOLD_W-1:0] exp_t;
        bit local_fail;
        begin
            local_fail = 1'b0;
            for (int n = 0; n < OUTPUTS; n++) begin
                exp_t = trunc_threshold(raw[n], 2'd2);
                if (read_l3_thresh(n) !== exp_t[L2_COUNT_WIDTH-1:0]) begin
                    $display("[FAIL] L3 thresh mismatch n=%0d got=%0h exp=%0h",
                             n, read_l3_thresh(n), exp_t[L2_COUNT_WIDTH-1:0]);
                    failed++;
                    local_fail = 1'b1;
                end
            end
            if (!local_fail) begin
                $display("[PASS] checked L3 threshold memory");
                passed++;
            end
        end
    endtask

    initial begin
        logic [7:0]  l1_w_payload[];
        logic [7:0]  l2_w_payload[];
        logic [7:0]  l3_w_payload[];
        logic [7:0]  l1_t_payload[];
        logic [7:0]  l2_t_payload[];
        logic [7:0]  l3_t_payload[];
        logic [31:0] l1_t_raw[0:HIDDEN1-1];
        logic [31:0] l2_t_raw[0:HIDDEN2-1];
        logic [31:0] l3_t_raw[0:OUTPUTS-1];

        passed       = 0;
        failed       = 0;
        rst          = 1'b1;
        cfg_valid    = 1'b0;
        cfg_data     = '0;
        cfg_keep     = '0;
        cfg_last     = 1'b0;
        start        = 1'b0;
        input_vector = '0;

        $display("### MEMORY WRITE CHECKER TB ###");

        repeat (5) @(posedge clk);
        rst = 1'b0;
        repeat (2) @(posedge clk);

        l1_w_payload = new[HIDDEN1 * L0_INPUT_BEATS];
        for (int i = 0; i < l1_w_payload.size(); i++) l1_w_payload[i] = 8'(8'h20 + i);
        send_message(8'd0, 8'd0, INPUTS[15:0], HIDDEN1[15:0], L0_INPUT_BEATS[15:0], l1_w_payload);
        wait_for_cfg_drain(3, 200);
        check_l1_weights(l1_w_payload);

        for (int n = 0; n < HIDDEN1; n++) begin
            l1_t_raw[n] = 32'(n * 3 + 1);
        end
        l1_t_payload = new[4 * HIDDEN1];
        for (int n = 0; n < HIDDEN1; n++) begin
            l1_t_payload[n*4+0] = l1_t_raw[n][7:0];
            l1_t_payload[n*4+1] = l1_t_raw[n][15:8];
            l1_t_payload[n*4+2] = l1_t_raw[n][23:16];
            l1_t_payload[n*4+3] = l1_t_raw[n][31:24];
        end
        send_message(8'd1, 8'd0, 16'd0, HIDDEN1[15:0], 16'd4, l1_t_payload);
        wait_for_cfg_drain(3, 200);
        check_l1_thresh(l1_t_raw);

        l2_w_payload = new[HIDDEN2 * L1_INPUT_BEATS];
        for (int i = 0; i < l2_w_payload.size(); i++) l2_w_payload[i] = 8'(8'h50 + i);
        send_message(8'd0, 8'd1, HIDDEN1[15:0], HIDDEN2[15:0], L1_INPUT_BEATS[15:0], l2_w_payload);
        wait_for_cfg_drain(3, 200);
        check_l2_weights(l2_w_payload);

        for (int n = 0; n < HIDDEN2; n++) begin
            l2_t_raw[n] = 32'(n * 5 + 2);
        end
        l2_t_payload = new[4 * HIDDEN2];
        for (int n = 0; n < HIDDEN2; n++) begin
            l2_t_payload[n*4+0] = l2_t_raw[n][7:0];
            l2_t_payload[n*4+1] = l2_t_raw[n][15:8];
            l2_t_payload[n*4+2] = l2_t_raw[n][23:16];
            l2_t_payload[n*4+3] = l2_t_raw[n][31:24];
        end
        send_message(8'd1, 8'd1, 16'd0, HIDDEN2[15:0], 16'd4, l2_t_payload);
        wait_for_cfg_drain(3, 200);
        check_l2_thresh(l2_t_raw);

        l3_w_payload = new[OUTPUTS * L2_INPUT_BEATS];
        for (int i = 0; i < l3_w_payload.size(); i++) l3_w_payload[i] = 8'(8'h70 + i);
        send_message(8'd0, 8'd2, HIDDEN2[15:0], OUTPUTS[15:0], L2_INPUT_BEATS[15:0], l3_w_payload);
        wait_for_cfg_drain(3, 200);
        check_l3_weights(l3_w_payload);

        for (int n = 0; n < OUTPUTS; n++) begin
            l3_t_raw[n] = 32'(n * 7 + 3);
        end
        l3_t_payload = new[4 * OUTPUTS];
        for (int n = 0; n < OUTPUTS; n++) begin
            l3_t_payload[n*4+0] = l3_t_raw[n][7:0];
            l3_t_payload[n*4+1] = l3_t_raw[n][15:8];
            l3_t_payload[n*4+2] = l3_t_raw[n][23:16];
            l3_t_payload[n*4+3] = l3_t_raw[n][31:24];
        end
        send_message(8'd1, 8'd2, 16'd0, OUTPUTS[15:0], 16'd4, l3_t_payload);
        wait_for_cfg_drain(3, 200);
        check_l3_thresh(l3_t_raw);

        $display("");
        $display("========================================");
        $display("config_manager -> bnn_core memory checker complete");
        $display("Pass counters: %0d", passed);
        $display("Failure counters: %0d", failed);
        $display("========================================");
        $finish;
    end

endmodule

`default_nettype wire