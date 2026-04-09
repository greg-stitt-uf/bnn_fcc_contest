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
//
// Configuration contract:
//   - Both cfg_write_en and cfg_threshold_write are gated by cfg_ready
//   - cfg_ready is only high when state_r == IDLE
//   - No weight or threshold write can reach any layer while busy
// =============================================================================
module bnn_core #(
    parameter  int INPUTS     = 784,
    parameter  int HIDDEN1    = 256,
    parameter  int HIDDEN2    = 256,
    parameter  int OUTPUTS    = 10,
    parameter  int PW         = 8,
    parameter  int PN         = 8,
    // -------------------------------------------------------------------------
    // Derived localparams — do not override
    // -------------------------------------------------------------------------
    // Per-layer popcount and threshold widths.
    // Each threshold must be wide enough to hold a popcount up to that
    // layer's input count.
    localparam int L1_COUNT_W = $clog2(INPUTS + 1),   // e.g. 784 inputs -> 10 bits
    localparam int L2_COUNT_W = $clog2(HIDDEN1 + 1),  // e.g. 256 inputs -> 9 bits
    localparam int L3_COUNT_W = $clog2(HIDDEN2 + 1),  // e.g. 256 inputs -> 9 bits

    // Config threshold port width — explicit three-way max across all layers
    localparam int THRESHOLD_W = (L1_COUNT_W > L2_COUNT_W) ?
                                 (L1_COUNT_W > L3_COUNT_W ? L1_COUNT_W : L3_COUNT_W) :
                                 (L2_COUNT_W > L3_COUNT_W ? L2_COUNT_W : L3_COUNT_W),

    // Output popcount bus
    localparam int POPCOUNT_OUT_W = OUTPUTS * L3_COUNT_W,

    // Inter-layer activation bus widths
    localparam int L1_ACT_W = HIDDEN1,
    localparam int L2_ACT_W = HIDDEN2,

    // Config neuron index width — three-way max including OUTPUTS
    // Guard against $clog2(1)=0 producing a zero-width port
    localparam int MAX_NEURONS  = (HIDDEN1 > HIDDEN2) ?
                                  (HIDDEN1 > OUTPUTS ? HIDDEN1 : OUTPUTS) :
                                  (HIDDEN2 > OUTPUTS ? HIDDEN2 : OUTPUTS),
    localparam int CFG_NEURON_W = (MAX_NEURONS > 1) ? $clog2(MAX_NEURONS) : 1,

    // Beat counts per layer
    localparam int MAX_BEATS_L1 = (INPUTS + PW - 1) / PW,
    localparam int MAX_BEATS_L2 = (HIDDEN1 + PW - 1) / PW,
    localparam int MAX_BEATS_L3 = (HIDDEN2 + PW - 1) / PW,

    // Config weight address width — max across all layers
    // Guard against $clog2(1)=0 producing a zero-width port
    localparam int MAX_WEIGHT_BEATS  = (MAX_BEATS_L1 > MAX_BEATS_L2) ?
                                       (MAX_BEATS_L1 > MAX_BEATS_L3 ? MAX_BEATS_L1 : MAX_BEATS_L3) :
                                       (MAX_BEATS_L2 > MAX_BEATS_L3 ? MAX_BEATS_L2 : MAX_BEATS_L3),
    localparam int CFG_WEIGHT_ADDR_W = (MAX_WEIGHT_BEATS > 1) ? $clog2(MAX_WEIGHT_BEATS) : 1,

    // Per-layer cfg port widths — used for explicit truncation at layer ports
    localparam int L1_CFG_NEURON_W      = (HIDDEN1 > 1) ? $clog2(HIDDEN1) : 1,
    localparam int L2_CFG_NEURON_W      = (HIDDEN2 > 1) ? $clog2(HIDDEN2) : 1,
    localparam int L3_CFG_NEURON_W      = (OUTPUTS > 1) ? $clog2(OUTPUTS) : 1,
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
    // popcounts_out is stable and valid whenever result_valid = 1
    // activations_l1 and activations_l2 are debug visibility only
    // -------------------------------------------------------------------------
    output logic      [   POPCOUNT_OUT_W-1:0] popcounts_out,
    output logic      [         L1_ACT_W-1:0] activations_l1,
    output logic      [         L2_ACT_W-1:0] activations_l2,
    // -------------------------------------------------------------------------
    // Configuration interface — only active when cfg_ready = 1
    // Both cfg_write_en and cfg_threshold_write are gated by cfg_ready
    // in hardware so no write of any kind can reach a layer while busy.
    // cfg_layer_sel: 2'b00=layer1, 2'b01=layer2, 2'b10=layer3
    // cfg_threshold_data is THRESHOLD_W wide (widest layer).
    // Each layer truncates to its own count width at instantiation.
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

    state_t state_r;  // current FSM state — type state_t not logic[2:0]
    state_t state_prev_r;  // previous state — same type, used for entry pulses
    logic   done_r;  // registered done pulse

    // =========================================================================
    // Post-reset stability flag
    // =========================================================================
    // Used to suppress $stable assertions for one cycle after reset releases.
    // Without this, the transition from X/0 during reset to stable 0 after
    // reset deassertion can cause false assertion failures in simulation.
    // Intentionally combinational: combines registered rst_prev_r with live
    // rst input to produce a one-cycle-wide strobe on the falling edge of rst.
    // =========================================================================
    logic   rst_prev_r;
    logic   post_reset_cycle;

    always_ff @(posedge clk) begin
        rst_prev_r <= rst;
    end

    // post_reset_cycle is combinational by design — it must be high on the
    // exact cycle that rst falls so assertions are suppressed before any
    // always_ff block has a chance to update its outputs
    assign post_reset_cycle = rst_prev_r && !rst;

    // =========================================================================
    // Inter-layer capture registers
    // =========================================================================
    // Latched on each layer's done pulse. Never wired directly from live
    // layer output ports. Stable whenever result_valid = 1.
    // Reset clears these but weights/thresholds inside bnn_layer are preserved.
    // =========================================================================
    logic [      L1_ACT_W-1:0] l1_activations_r;
    logic [      L2_ACT_W-1:0] l2_activations_r;
    logic [POPCOUNT_OUT_W-1:0] l3_popcounts_r;

    // =========================================================================
    // Layer control signals
    // =========================================================================
    logic l1_load, l2_load, l3_load;
    logic l1_start_pulse, l2_start_pulse, l3_start_pulse;
    logic l1_done, l2_done, l3_done;

    // Declared unconditionally so port connections are always legal.
    // l*_busy and l*_output_valid are used only in assertions.
    // Synthesis will optimize away these signals since nothing in the
    // synthesizable logic depends on them.
    logic l1_busy, l2_busy, l3_busy;
    logic l1_output_valid, l2_output_valid, l3_output_valid;

    // Layer cfg_ready — connected for assertion visibility.
    // bnn_core owns cfg_ready at top level and gates all writes itself.
    logic l1_cfg_ready, l2_cfg_ready, l3_cfg_ready;

    // =========================================================================
    // Layer output port wires
    // =========================================================================
    logic [      L1_ACT_W-1:0] l1_activations_out;
    logic [      L2_ACT_W-1:0] l2_activations_out;
    logic [POPCOUNT_OUT_W-1:0] l3_popcounts_out;

    // =========================================================================
    // Configuration routing
    // =========================================================================
    // Both cfg_write_en and cfg_threshold_write are gated by cfg_ready and
    // cfg_layer_sel so no write of any kind can reach any layer while busy.
    // This enforces the config contract in hardware not just assertions.
    // =========================================================================
    logic l1_cfg_write_en, l2_cfg_write_en, l3_cfg_write_en;
    logic l1_cfg_thresh_write, l2_cfg_thresh_write, l3_cfg_thresh_write;

    always_comb begin
        l1_cfg_write_en     = cfg_write_en && cfg_ready && (cfg_layer_sel == 2'd0);
        l2_cfg_write_en     = cfg_write_en && cfg_ready && (cfg_layer_sel == 2'd1);
        l3_cfg_write_en     = cfg_write_en && cfg_ready && (cfg_layer_sel == 2'd2);
        l1_cfg_thresh_write = cfg_threshold_write && cfg_ready && (cfg_layer_sel == 2'd0);
        l2_cfg_thresh_write = cfg_threshold_write && cfg_ready && (cfg_layer_sel == 2'd1);
        l3_cfg_thresh_write = cfg_threshold_write && cfg_ready && (cfg_layer_sel == 2'd2);
    end

    // =========================================================================
    // One-shot start pulse generation
    // =========================================================================
    // Entry into each RUN state detected by comparing state_r to state_prev_r.
    // Both are type state_t so width tracks enum changes automatically.
    // Keeps start generation fully inside bnn_core with no dependence on
    // l*_busy timing from the layer instances.
    // =========================================================================
    always_comb begin
        l1_start_pulse = (state_r == RUN_L1) && (state_prev_r != RUN_L1);
        l2_start_pulse = (state_r == RUN_L2) && (state_prev_r != RUN_L2);
        l3_start_pulse = (state_r == RUN_L3) && (state_prev_r != RUN_L3);
    end

    // =========================================================================
    // Control signal decode
    // =========================================================================
    // Pure combinational from state_r with explicit defaults to prevent
    // latch inference.
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

    // -------------------------------------------------------------------------
    // Layer 1: INPUTS -> HIDDEN1 (hidden layer)
    // -------------------------------------------------------------------------
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
        .output_valid       (l1_output_valid),
        .activations_out    (l1_activations_out),
        .popcounts_out      (),
        .cfg_write_en       (l1_cfg_write_en),
        .cfg_neuron_idx     (cfg_neuron_idx[L1_CFG_NEURON_W-1:0]),
        .cfg_weight_addr    (cfg_weight_addr[L1_CFG_WEIGHT_ADDR_W-1:0]),
        .cfg_weight_data    (cfg_weight_data),
        .cfg_threshold_data (cfg_threshold_data[L1_COUNT_W-1:0]),
        .cfg_threshold_write(l1_cfg_thresh_write),
        .cfg_ready          (l1_cfg_ready)
    );

    // -------------------------------------------------------------------------
    // Layer 2: HIDDEN1 -> HIDDEN2 (hidden layer)
    // Input is l1_activations_r — captured register, never live layer output
    // -------------------------------------------------------------------------
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
        .output_valid       (l2_output_valid),
        .activations_out    (l2_activations_out),
        .popcounts_out      (),
        .cfg_write_en       (l2_cfg_write_en),
        .cfg_neuron_idx     (cfg_neuron_idx[L2_CFG_NEURON_W-1:0]),
        .cfg_weight_addr    (cfg_weight_addr[L2_CFG_WEIGHT_ADDR_W-1:0]),
        .cfg_weight_data    (cfg_weight_data),
        .cfg_threshold_data (cfg_threshold_data[L2_COUNT_W-1:0]),
        .cfg_threshold_write(l2_cfg_thresh_write),
        .cfg_ready          (l2_cfg_ready)
    );

    // -------------------------------------------------------------------------
    // Layer 3: HIDDEN2 -> OUTPUTS (output layer, no thresholding)
    // Input is l2_activations_r — captured register, never live layer output
    // -------------------------------------------------------------------------
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
        .output_valid       (l3_output_valid),
        .activations_out    (),
        .popcounts_out      (l3_popcounts_out),
        .cfg_write_en       (l3_cfg_write_en),
        .cfg_neuron_idx     (cfg_neuron_idx[L3_CFG_NEURON_W-1:0]),
        .cfg_weight_addr    (cfg_weight_addr[L3_CFG_WEIGHT_ADDR_W-1:0]),
        .cfg_weight_data    (cfg_weight_data),
        .cfg_threshold_data (cfg_threshold_data[L3_COUNT_W-1:0]),
        .cfg_threshold_write(l3_cfg_thresh_write),
        .cfg_ready          (l3_cfg_ready)
    );

    // =========================================================================
    // Assertions
    // =========================================================================
    // synthesis translate_off

    // FSM transition correctness
    p_fsm_idle_to_load_l1 :
    assert property (@(posedge clk) disable iff (rst) (state_r == IDLE && start) |=> (state_r == LOAD_L1))
    else $error("FSM: IDLE+start did not transition to LOAD_L1");

    p_fsm_load_l1_to_run_l1 :
    assert property (@(posedge clk) disable iff (rst) (state_r == LOAD_L1) |=> (state_r == RUN_L1))
    else $error("FSM: LOAD_L1 did not transition to RUN_L1");

    p_fsm_run_l1_to_load_l2 :
    assert property (@(posedge clk) disable iff (rst) (state_r == RUN_L1 && l1_done) |=> (state_r == LOAD_L2))
    else $error("FSM: RUN_L1+l1_done did not transition to LOAD_L2");

    p_fsm_load_l2_to_run_l2 :
    assert property (@(posedge clk) disable iff (rst) (state_r == LOAD_L2) |=> (state_r == RUN_L2))
    else $error("FSM: LOAD_L2 did not transition to RUN_L2");

    p_fsm_run_l2_to_load_l3 :
    assert property (@(posedge clk) disable iff (rst) (state_r == RUN_L2 && l2_done) |=> (state_r == LOAD_L3))
    else $error("FSM: RUN_L2+l2_done did not transition to LOAD_L3");

    p_fsm_load_l3_to_run_l3 :
    assert property (@(posedge clk) disable iff (rst) (state_r == LOAD_L3) |=> (state_r == RUN_L3))
    else $error("FSM: LOAD_L3 did not transition to RUN_L3");

    p_fsm_run_l3_to_done :
    assert property (@(posedge clk) disable iff (rst) (state_r == RUN_L3 && l3_done) |=> (state_r == DONE))
    else $error("FSM: RUN_L3+l3_done did not transition to DONE");

    p_fsm_done_to_idle :
    assert property (@(posedge clk) disable iff (rst) (state_r == DONE) |=> (state_r == IDLE))
    else $error("FSM: DONE did not transition to IDLE");

    // Layer done pulses only arrive in correct FSM state
    p_l1_done_in_run_l1 :
    assert property (@(posedge clk) disable iff (rst) l1_done |-> (state_r == RUN_L1))
    else $error("l1_done arrived outside RUN_L1");

    p_l2_done_in_run_l2 :
    assert property (@(posedge clk) disable iff (rst) l2_done |-> (state_r == RUN_L2))
    else $error("l2_done arrived outside RUN_L2");

    p_l3_done_in_run_l3 :
    assert property (@(posedge clk) disable iff (rst) l3_done |-> (state_r == RUN_L3))
    else $error("l3_done arrived outside RUN_L3");

    // Never start a layer that is already busy
    p_l1_start_not_busy :
    assert property (@(posedge clk) disable iff (rst) l1_start_pulse |-> !l1_busy)
    else $error("l1_start_pulse fired while l1_busy");

    p_l2_start_not_busy :
    assert property (@(posedge clk) disable iff (rst) l2_start_pulse |-> !l2_busy)
    else $error("l2_start_pulse fired while l2_busy");

    p_l3_start_not_busy :
    assert property (@(posedge clk) disable iff (rst) l3_start_pulse |-> !l3_busy)
    else $error("l3_start_pulse fired while l3_busy");

    // Never assert load and start together for same layer
    p_no_l1_load_and_start :
    assert property (@(posedge clk) disable iff (rst) !(l1_load && l1_start_pulse))
    else $error("l1_load and l1_start_pulse asserted same cycle");

    p_no_l2_load_and_start :
    assert property (@(posedge clk) disable iff (rst) !(l2_load && l2_start_pulse))
    else $error("l2_load and l2_start_pulse asserted same cycle");

    p_no_l3_load_and_start :
    assert property (@(posedge clk) disable iff (rst) !(l3_load && l3_start_pulse))
    else $error("l3_load and l3_start_pulse asserted same cycle");

    // Only one layer starts at a time
    p_onehot_start_pulses :
    assert property (@(posedge clk) disable iff (rst) $onehot0(
        {l1_start_pulse, l2_start_pulse, l3_start_pulse}
    ))
    else $error("Multiple layer start pulses asserted same cycle");

    // done only pulses when previous state was DONE
    // done_r is registered so state_r has already moved to IDLE when done fires
    p_done_from_done_state :
    assert property (@(posedge clk) disable iff (rst) done |-> (state_prev_r == DONE))
    else $error("done asserted outside DONE state");

    // Internal gated cfg write enables only fire when cfg_ready
    p_l1_cfg_write_gated :
    assert property (@(posedge clk) disable iff (rst) l1_cfg_write_en |-> cfg_ready)
    else $error("l1_cfg_write_en fired while not cfg_ready");

    p_l2_cfg_write_gated :
    assert property (@(posedge clk) disable iff (rst) l2_cfg_write_en |-> cfg_ready)
    else $error("l2_cfg_write_en fired while not cfg_ready");

    p_l3_cfg_write_gated :
    assert property (@(posedge clk) disable iff (rst) l3_cfg_write_en |-> cfg_ready)
    else $error("l3_cfg_write_en fired while not cfg_ready");

    // Internal gated threshold write enables only fire when cfg_ready
    p_l1_cfg_thresh_gated :
    assert property (@(posedge clk) disable iff (rst) l1_cfg_thresh_write |-> cfg_ready)
    else $error("l1_cfg_thresh_write fired while not cfg_ready");

    p_l2_cfg_thresh_gated :
    assert property (@(posedge clk) disable iff (rst) l2_cfg_thresh_write |-> cfg_ready)
    else $error("l2_cfg_thresh_write fired while not cfg_ready");

    p_l3_cfg_thresh_gated :
    assert property (@(posedge clk) disable iff (rst) l3_cfg_thresh_write |-> cfg_ready)
    else $error("l3_cfg_thresh_write fired while not cfg_ready");

    // result_valid clears one cycle after accepted start
    p_result_valid_clears_on_start :
    assert property (@(posedge clk) disable iff (rst) (state_r == IDLE && start) |=> !result_valid)
    else $error("result_valid did not clear after start");

    // result_valid only asserted in IDLE or DONE
    p_result_valid_state :
    assert property (@(posedge clk) disable iff (rst) result_valid |-> (state_r == IDLE || state_r == DONE))
    else $error("result_valid asserted in unexpected state");

    // start while busy must not cause a new LOAD_L1 entry
    p_start_busy_no_load_l1 :
    assert property (@(posedge clk) disable iff (rst) (start && busy) |=> (state_r != LOAD_L1))
    else $error("Spurious LOAD_L1 entered after start-while-busy");

    // Layer cfg_ready signals must agree with core cfg_ready
    // All three layers are always co-idle with the core FSM
    p_l1_cfg_ready_agrees :
    assert property (@(posedge clk) disable iff (rst) cfg_ready |-> l1_cfg_ready)
    else $error("cfg_ready high but l1_cfg_ready low");

    p_l2_cfg_ready_agrees :
    assert property (@(posedge clk) disable iff (rst) cfg_ready |-> l2_cfg_ready)
    else $error("cfg_ready high but l2_cfg_ready low");

    p_l3_cfg_ready_agrees :
    assert property (@(posedge clk) disable iff (rst) cfg_ready |-> l3_cfg_ready)
    else $error("cfg_ready high but l3_cfg_ready low");

    // Capture registers only change on matching done pulse or reset
    // post_reset_cycle suppresses false fires on the cycle after reset releases
    p_l1_capture_stable :
    assert property (@(posedge clk) disable iff (rst || post_reset_cycle) !l1_done |=> $stable(
        l1_activations_r
    ))
    else $error("l1_activations_r changed without l1_done");

    p_l2_capture_stable :
    assert property (@(posedge clk) disable iff (rst || post_reset_cycle) !l2_done |=> $stable(
        l2_activations_r
    ))
    else $error("l2_activations_r changed without l2_done");

    p_l3_capture_stable :
    assert property (@(posedge clk) disable iff (rst || post_reset_cycle) !l3_done |=> $stable(
        l3_popcounts_r
    ))
    else $error("l3_popcounts_r changed without l3_done");

    // synthesis translate_on

endmodule
`default_nettype wire
