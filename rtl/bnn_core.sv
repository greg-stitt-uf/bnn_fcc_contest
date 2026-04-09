`default_nettype none
// =============================================================================
// Module: bnn_core
// =============================================================================
// Connects three bnn_layer instances sequentially to implement the full
// 784 -> 256 -> 256 -> 10 BNN topology.
//
// Processing is strictly layer-by-layer with no cross-layer overlap:
//   1. Load input_vector into layer1, run layer1, capture activations
//   2. Load layer1 activations into layer2, run layer2, capture activations
//   3. Load layer2 activations into layer3, run layer3, capture popcounts
//   4. Assert done, hold popcounts_out stable via result_valid
//
// FSM state sequence per inference:
//   IDLE -> LOAD_L1 -> RUN_L1 -> LOAD_L2 -> RUN_L2
//        -> LOAD_L3 -> RUN_L3 -> DONE -> IDLE
//
// Reset behavior:
//   - Synchronous reset clears all FSM state and capture registers
//   - Weight and threshold RAMs inside bnn_layer are NOT reset
//   - After reset the loaded model is preserved
//
// Output contract:
//   - popcounts_out is stable and valid whenever result_valid = 1
//   - done is a single cycle completion pulse only
//   - Downstream argmax must use result_valid not done
// =============================================================================
module bnn_core #(
    parameter int INPUTS = 784,
    parameter int HIDDEN1 = 256,
    parameter int HIDDEN2 = 256,
    parameter int OUTPUTS = 10,
    parameter int PW = 8,
    parameter int PN = 8,
    // -------------------------------------------------------------------------
    // Derived localparams — do not override
    // -------------------------------------------------------------------------
    localparam int L1_COUNT_W = $clog2(INPUTS + 1),
    localparam int L2_COUNT_W = $clog2(HIDDEN1 + 1),
    localparam int L3_COUNT_W = $clog2(HIDDEN2 + 1),
    localparam int THRESHOLD_W = L1_COUNT_W,
    localparam int POPCOUNT_OUT_W = OUTPUTS * L3_COUNT_W,
    localparam int L1_ACT_W = HIDDEN1,
    localparam int L2_ACT_W = HIDDEN2,
    localparam int MAX_NEURONS = (HIDDEN1 > HIDDEN2) ? HIDDEN1 : HIDDEN2,
    localparam int CFG_NEURON_W = $clog2(MAX_NEURONS),
    localparam int MAX_BEATS_L1 = (INPUTS + PW - 1) / PW,
    localparam int MAX_BEATS_L2 = (HIDDEN1 + PW - 1) / PW,
    localparam int MAX_BEATS_L3 = (HIDDEN2 + PW - 1) / PW,
    localparam int MAX_WEIGHT_BEATS  = (MAX_BEATS_L1 > MAX_BEATS_L2) ?
                                       (MAX_BEATS_L1 > MAX_BEATS_L3 ? MAX_BEATS_L1 : MAX_BEATS_L3) :
                                       (MAX_BEATS_L2 > MAX_BEATS_L3 ? MAX_BEATS_L2 : MAX_BEATS_L3),
    localparam int CFG_WEIGHT_ADDR_W = $clog2(MAX_WEIGHT_BEATS),
    // Per-layer cfg port widths — used for truncation at layer ports
    localparam int L1_CFG_NEURON_W = (HIDDEN1 > 1) ? $clog2(HIDDEN1) : 1,
    localparam int L2_CFG_NEURON_W = (HIDDEN2 > 1) ? $clog2(HIDDEN2) : 1,
    localparam int L3_CFG_NEURON_W = (OUTPUTS > 1) ? $clog2(OUTPUTS) : 1,
    localparam int L1_CFG_WEIGHT_ADDR_W = (MAX_BEATS_L1 > 1) ? $clog2(MAX_BEATS_L1) : 1,
    localparam int L2_CFG_WEIGHT_ADDR_W = (MAX_BEATS_L2 > 1) ? $clog2(MAX_BEATS_L2) : 1,
    localparam int L3_CFG_WEIGHT_ADDR_W = (MAX_BEATS_L3 > 1) ? $clog2(MAX_BEATS_L3) : 1
) (
    input  wire logic                         clk,
    input  wire logic                         rst,
    // -------------------------------------------------------------------------
    // Inference interface
    // -------------------------------------------------------------------------
    input  wire logic                         start,
    input  wire logic [           INPUTS-1:0] input_vector,
    output logic                              done,
    output logic                              busy,
    output logic                              result_valid,
    // -------------------------------------------------------------------------
    // Result outputs
    // -------------------------------------------------------------------------
    output logic      [   POPCOUNT_OUT_W-1:0] popcounts_out,
    output logic      [         L1_ACT_W-1:0] activations_l1,
    output logic      [         L2_ACT_W-1:0] activations_l2,
    // -------------------------------------------------------------------------
    // Configuration interface
    // -------------------------------------------------------------------------
    input  wire logic                         cfg_write_en,
    input  wire logic [                  1:0] cfg_layer_sel,
    input  wire logic [     CFG_NEURON_W-1:0] cfg_neuron_idx,
    input  wire logic [CFG_WEIGHT_ADDR_W-1:0] cfg_weight_addr,
    input  wire logic [               PW-1:0] cfg_weight_data,
    input  wire logic [      THRESHOLD_W-1:0] cfg_threshold_data,
    input  wire logic                         cfg_threshold_write,
    output logic                              cfg_ready
);
    // =========================================================================
    // FSM state encoding
    // =========================================================================
    typedef enum logic [2:0] {
        IDLE,
        LOAD_L1,
        RUN_L1,
        LOAD_L2,
        RUN_L2,
        LOAD_L3,
        RUN_L3,
        DONE
    } state_t;

    state_t                      state_r;
    state_t                      state_prev_r;
    logic                        done_r;

    // =========================================================================
    // Inter-layer capture registers
    // =========================================================================
    logic   [      L1_ACT_W-1:0] l1_activations_r;
    logic   [      L2_ACT_W-1:0] l2_activations_r;
    logic   [POPCOUNT_OUT_W-1:0] l3_popcounts_r;

    // =========================================================================
    // Layer control wires
    // =========================================================================
    logic l1_load, l2_load, l3_load;
    logic l1_start_pulse, l2_start_pulse, l3_start_pulse;
    logic l1_done, l2_done, l3_done;
    logic l1_busy, l2_busy, l3_busy;

    // =========================================================================
    // Layer output port wires
    // =========================================================================
    logic [      L1_ACT_W-1:0] l1_activations_out;
    logic [      L2_ACT_W-1:0] l2_activations_out;
    logic [POPCOUNT_OUT_W-1:0] l3_popcounts_out;

    // =========================================================================
    // Configuration routing
    // =========================================================================
    logic l1_cfg_write_en, l2_cfg_write_en, l3_cfg_write_en;

    always_comb begin
        l1_cfg_write_en = cfg_write_en && cfg_ready && (cfg_layer_sel == 2'd0);
        l2_cfg_write_en = cfg_write_en && cfg_ready && (cfg_layer_sel == 2'd1);
        l3_cfg_write_en = cfg_write_en && cfg_ready && (cfg_layer_sel == 2'd2);
    end

    // =========================================================================
    // One-shot start pulse generation
    // =========================================================================
    always_comb begin
        l1_start_pulse = (state_r == RUN_L1) && (state_prev_r != RUN_L1);
        l2_start_pulse = (state_r == RUN_L2) && (state_prev_r != RUN_L2);
        l3_start_pulse = (state_r == RUN_L3) && (state_prev_r != RUN_L3);
    end

    // =========================================================================
    // Control signal decode
    // =========================================================================
    always_comb begin
        l1_load   = 1'b0;
        l2_load   = 1'b0;
        l3_load   = 1'b0;
        busy      = 1'b1;
        cfg_ready = 1'b0;

        case (state_r)
            IDLE: begin
                busy      = 1'b0;
                cfg_ready = 1'b1;
            end
            LOAD_L1: l1_load = 1'b1;
            LOAD_L2: l2_load = 1'b1;
            LOAD_L3: l3_load = 1'b1;
            default: ;
        endcase
    end

    // =========================================================================
    // Main FSM + capture registers
    // =========================================================================
    always_ff @(posedge clk) begin
        if (rst) begin
            state_r          <= IDLE;
            state_prev_r     <= IDLE;
            done_r           <= 1'b0;
            result_valid     <= 1'b0;
            l1_activations_r <= '0;
            l2_activations_r <= '0;
            l3_popcounts_r   <= '0;
        end else begin
            state_prev_r <= state_r;
            done_r       <= 1'b0;

            case (state_r)
                IDLE: begin
                    if (start) begin
                        result_valid <= 1'b0;
                        state_r      <= LOAD_L1;
                    end
                end

                LOAD_L1: state_r <= RUN_L1;

                RUN_L1: begin
                    if (l1_done) begin
                        l1_activations_r <= l1_activations_out;
                        state_r          <= LOAD_L2;
                    end
                end

                LOAD_L2: state_r <= RUN_L2;

                RUN_L2: begin
                    if (l2_done) begin
                        l2_activations_r <= l2_activations_out;
                        state_r          <= LOAD_L3;
                    end
                end

                LOAD_L3: state_r <= RUN_L3;

                RUN_L3: begin
                    if (l3_done) begin
                        l3_popcounts_r <= l3_popcounts_out;
                        result_valid   <= 1'b1;
                        state_r        <= DONE;
                    end
                end

                DONE: begin
                    done_r  <= 1'b1;
                    state_r <= IDLE;
                end

                default: state_r <= IDLE;
            endcase
        end
    end

    // =========================================================================
    // Output assignments
    // =========================================================================
    assign done           = done_r;
    assign popcounts_out  = l3_popcounts_r;
    assign activations_l1 = l1_activations_r;
    assign activations_l2 = l2_activations_r;

    // =========================================================================
    // Layer instantiation
    // =========================================================================

    bnn_layer #(
        .INPUTS      (INPUTS),
        .NEURONS     (HIDDEN1),
        .PW          (PW),
        .PN          (PN),
        .OUTPUT_LAYER(0)
    ) u_layer1 (
        .clk                (clk),
        .rst                (rst),
        .input_load         (l1_load),
        .input_vector       (input_vector),
        .start              (l1_start_pulse),
        .done               (l1_done),
        .busy               (l1_busy),
        .output_valid       (),
        .activations_out    (l1_activations_out),
        .popcounts_out      (),
        .cfg_write_en       (l1_cfg_write_en),
        .cfg_neuron_idx     (cfg_neuron_idx[L1_CFG_NEURON_W-1:0]),
        .cfg_weight_addr    (cfg_weight_addr[L1_CFG_WEIGHT_ADDR_W-1:0]),
        .cfg_weight_data    (cfg_weight_data),
        .cfg_threshold_data (cfg_threshold_data[L1_COUNT_W-1:0]),
        .cfg_threshold_write(cfg_threshold_write),
        .cfg_ready          ()
    );

    bnn_layer #(
        .INPUTS      (HIDDEN1),
        .NEURONS     (HIDDEN2),
        .PW          (PW),
        .PN          (PN),
        .OUTPUT_LAYER(0)
    ) u_layer2 (
        .clk                (clk),
        .rst                (rst),
        .input_load         (l2_load),
        .input_vector       (l1_activations_r),
        .start              (l2_start_pulse),
        .done               (l2_done),
        .busy               (l2_busy),
        .output_valid       (),
        .activations_out    (l2_activations_out),
        .popcounts_out      (),
        .cfg_write_en       (l2_cfg_write_en),
        .cfg_neuron_idx     (cfg_neuron_idx[L2_CFG_NEURON_W-1:0]),
        .cfg_weight_addr    (cfg_weight_addr[L2_CFG_WEIGHT_ADDR_W-1:0]),
        .cfg_weight_data    (cfg_weight_data),
        .cfg_threshold_data (cfg_threshold_data[L2_COUNT_W-1:0]),
        .cfg_threshold_write(cfg_threshold_write),
        .cfg_ready          ()
    );

    bnn_layer #(
        .INPUTS      (HIDDEN2),
        .NEURONS     (OUTPUTS),
        .PW          (PW),
        .PN          (PN),
        .OUTPUT_LAYER(1)
    ) u_layer3 (
        .clk                (clk),
        .rst                (rst),
        .input_load         (l3_load),
        .input_vector       (l2_activations_r),
        .start              (l3_start_pulse),
        .done               (l3_done),
        .busy               (l3_busy),
        .output_valid       (),
        .activations_out    (),
        .popcounts_out      (l3_popcounts_out),
        .cfg_write_en       (l3_cfg_write_en),
        .cfg_neuron_idx     (cfg_neuron_idx[L3_CFG_NEURON_W-1:0]),
        .cfg_weight_addr    (cfg_weight_addr[L3_CFG_WEIGHT_ADDR_W-1:0]),
        .cfg_weight_data    (cfg_weight_data),
        .cfg_threshold_data (cfg_threshold_data[L3_COUNT_W-1:0]),
        .cfg_threshold_write(cfg_threshold_write),
        .cfg_ready          ()
    );

    // =========================================================================
    // Assertions
    // =========================================================================
    // synthesis translate_off

    // FSM transition correctness
    assert property (@(posedge clk) disable iff (rst) (state_r == IDLE && start) |=> (state_r == LOAD_L1))
    else $error("FSM: IDLE+start did not transition to LOAD_L1");

    assert property (@(posedge clk) disable iff (rst) (state_r == LOAD_L1) |=> (state_r == RUN_L1))
    else $error("FSM: LOAD_L1 did not transition to RUN_L1");

    assert property (@(posedge clk) disable iff (rst) (state_r == RUN_L1 && l1_done) |=> (state_r == LOAD_L2))
    else $error("FSM: RUN_L1+l1_done did not transition to LOAD_L2");

    assert property (@(posedge clk) disable iff (rst) (state_r == LOAD_L2) |=> (state_r == RUN_L2))
    else $error("FSM: LOAD_L2 did not transition to RUN_L2");

    assert property (@(posedge clk) disable iff (rst) (state_r == RUN_L2 && l2_done) |=> (state_r == LOAD_L3))
    else $error("FSM: RUN_L2+l2_done did not transition to LOAD_L3");

    assert property (@(posedge clk) disable iff (rst) (state_r == LOAD_L3) |=> (state_r == RUN_L3))
    else $error("FSM: LOAD_L3 did not transition to RUN_L3");

    assert property (@(posedge clk) disable iff (rst) (state_r == RUN_L3 && l3_done) |=> (state_r == DONE))
    else $error("FSM: RUN_L3+l3_done did not transition to DONE");

    assert property (@(posedge clk) disable iff (rst) (state_r == DONE) |=> (state_r == IDLE))
    else $error("FSM: DONE did not transition to IDLE");

    // Layer done pulses only arrive in correct FSM state
    assert property (@(posedge clk) disable iff (rst) l1_done |-> (state_r == RUN_L1))
    else $error("l1_done arrived outside RUN_L1");

    assert property (@(posedge clk) disable iff (rst) l2_done |-> (state_r == RUN_L2))
    else $error("l2_done arrived outside RUN_L2");

    assert property (@(posedge clk) disable iff (rst) l3_done |-> (state_r == RUN_L3))
    else $error("l3_done arrived outside RUN_L3");

    // Never start a layer that is already busy
    assert property (@(posedge clk) disable iff (rst) l1_start_pulse |-> !l1_busy)
    else $error("l1_start_pulse fired while l1_busy");

    assert property (@(posedge clk) disable iff (rst) l2_start_pulse |-> !l2_busy)
    else $error("l2_start_pulse fired while l2_busy");

    assert property (@(posedge clk) disable iff (rst) l3_start_pulse |-> !l3_busy)
    else $error("l3_start_pulse fired while l3_busy");

    // Never assert load and start together for same layer
    assert property (@(posedge clk) disable iff (rst) !(l1_load && l1_start_pulse))
    else $error("l1_load and l1_start_pulse asserted same cycle");

    assert property (@(posedge clk) disable iff (rst) !(l2_load && l2_start_pulse))
    else $error("l2_load and l2_start_pulse asserted same cycle");

    assert property (@(posedge clk) disable iff (rst) !(l3_load && l3_start_pulse))
    else $error("l3_load and l3_start_pulse asserted same cycle");

    // Only one layer starts at a time
    assert property (@(posedge clk) disable iff (rst) $onehot0(
        {l1_start_pulse, l2_start_pulse, l3_start_pulse}
    ))
    else $error("Multiple layer start pulses asserted same cycle");

    // done only pulses from DONE state — check previous state since
    // done_r is registered and state_r has already moved to IDLE
    assert property (@(posedge clk) disable iff (rst) done |-> (state_prev_r == DONE))
    else $error("done asserted outside DONE state");

    // Internal gated cfg enables only fire when cfg_ready
    assert property (@(posedge clk) disable iff (rst) l1_cfg_write_en |-> cfg_ready)
    else $error("l1_cfg_write_en fired while not cfg_ready");

    assert property (@(posedge clk) disable iff (rst) l2_cfg_write_en |-> cfg_ready)
    else $error("l2_cfg_write_en fired while not cfg_ready");

    assert property (@(posedge clk) disable iff (rst) l3_cfg_write_en |-> cfg_ready)
    else $error("l3_cfg_write_en fired while not cfg_ready");

    // result_valid clears one cycle after accepted start
    assert property (@(posedge clk) disable iff (rst) (state_r == IDLE && start) |=> !result_valid)
    else $error("result_valid did not clear after start");

    // result_valid only asserted after at least one completed inference
    assert property (@(posedge clk) disable iff (rst) result_valid |-> (state_r == IDLE || state_r == DONE))
    else $error("result_valid asserted in unexpected state");

    // start while busy must not cause a new LOAD_L1 entry
    assert property (@(posedge clk) disable iff (rst) (start && busy) |=> (state_r != LOAD_L1))
    else $error("Spurious LOAD_L1 entered after start-while-busy");

    // Capture registers only change on matching done pulse or reset
    assert property (@(posedge clk) disable iff (rst) !l1_done |=> $stable(l1_activations_r))
    else $error("l1_activations_r changed without l1_done");

    assert property (@(posedge clk) disable iff (rst) !l2_done |=> $stable(l2_activations_r))
    else $error("l2_activations_r changed without l2_done");

    assert property (@(posedge clk) disable iff (rst) !l3_done |=> $stable(l3_popcounts_r))
    else $error("l3_popcounts_r changed without l3_done");

endmodule
`default_nettype wire
