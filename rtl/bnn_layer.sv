`default_nettype none

// =============================================================================
// Module: bnn_layer
// =============================================================================
// Implements a single fully-connected binary neural network layer.
//
// Architecture overview:
//   - NEURONS total neurons are split into NEURON_GROUPS of up to PN neurons
//     each. All PN neurons in a group are processed in parallel by dedicated
//     neuron_processor (NP) instances.
//   - The input vector is sliced into INPUT_BEATS chunks of PW bits each and
//     streamed to the NPs one beat per cycle.
//   - A single-stage registered pipeline (stage1) sits between the RAMs and
//     the NPs. Data is latched during DISPATCH and consumed during COMPUTE,
//     guaranteeing the NPs always see fully stable inputs.
//
// FSM state sequence for one full inference:
//   IDLE -> DISPATCH -> COMPUTE -> (repeat per beat) -> WAIT_OUT
//        -> (repeat per group) -> IDLE
//
// Configuration:
//   - Weights and thresholds are written via the cfg_* interface while the
//     module is idle (cfg_ready = 1).
//   - Weights are stored per NP slot: weight_rams[np_idx][group*BEATS + beat]
//   - Thresholds are stored per NP slot: threshold_rams[np_idx][group_idx]
//
// Parameters:
//   INPUTS     - Number of binary input bits (e.g. 784 for MNIST)
//   NEURONS    - Total number of neurons in this layer (e.g. 256)
//   PW         - Input/weight parallelism: bits processed per beat
//   PN         - Neuron parallelism: neurons processed simultaneously
//   OUTPUT_LAYER - When 1, activations are suppressed (raw popcounts only)
// =============================================================================
module bnn_layer #(
    parameter int INPUTS       = 784,
    parameter int NEURONS      = 256,
    parameter int PW           = 8,
    parameter int PN           = 8,
    parameter bit OUTPUT_LAYER = 0,

    // Derived parameters — do not override
    parameter int COUNT_WIDTH = $clog2(INPUTS + 1),  // bits needed to hold a popcount up to INPUTS
    parameter int INPUT_BEATS = (INPUTS + PW - 1) / PW,  // number of PW-wide chunks that cover all inputs
    parameter int CFG_NEURON_WIDTH = (NEURONS > 1) ? $clog2(NEURONS) : 1,  // address bits for neuron index
    parameter int CFG_WEIGHT_ADDR_WIDTH = (INPUT_BEATS > 1) ? $clog2(
        INPUT_BEATS
    ) : 1  // address bits for beat index
) (
    input wire logic clk,
    input wire logic rst,

    // ------------------------------------------------------------------
    // Data input interface
    // input_load: strobe — latch input_vector into the input buffer.
    //             Ignored while busy.
    // input_vector: full binarized input, INPUTS bits wide.
    // start: single-cycle pulse — begin inference on the buffered input.
    // ------------------------------------------------------------------
    input wire logic              input_load,
    input wire logic [INPUTS-1:0] input_vector,
    input wire logic              start,

    // ------------------------------------------------------------------
    // Status outputs
    // done: single-cycle pulse asserted when inference is complete.
    // busy: high throughout the inference; low in IDLE.
    // output_valid: latched high after the first completed inference;
    //               cleared when a new inference starts.
    // ------------------------------------------------------------------
    output logic done,
    output logic busy,
    output logic output_valid,

    // ------------------------------------------------------------------
    // Inference result outputs
    // activations_out: 1-bit activation per neuron (0 for output layers).
    // popcounts_out:   packed COUNT_WIDTH-bit popcount per neuron.
    //                  Neuron i occupies bits [i*COUNT_WIDTH +: COUNT_WIDTH].
    // ------------------------------------------------------------------
    output logic [            NEURONS-1:0] activations_out,
    output logic [NEURONS*COUNT_WIDTH-1:0] popcounts_out,

    // ------------------------------------------------------------------
    // Configuration interface — only active when cfg_ready is high.
    // cfg_write_en:         strobe to write one weight or threshold word.
    // cfg_neuron_idx:       selects which neuron is being configured.
    // cfg_weight_addr:      beat index within that neuron's weight row.
    // cfg_weight_data:      PW-bit weight word to write.
    // cfg_threshold_data:   COUNT_WIDTH-bit threshold to write.
    // cfg_threshold_write:  when high, write threshold instead of weight.
    // cfg_ready:            high when safe to write (module not busy).
    // ------------------------------------------------------------------
    input  wire logic                             cfg_write_en,
    input  wire logic [     CFG_NEURON_WIDTH-1:0] cfg_neuron_idx,
    input  wire logic [CFG_WEIGHT_ADDR_WIDTH-1:0] cfg_weight_addr,
    input  wire logic [                   PW-1:0] cfg_weight_data,
    input  wire logic [          COUNT_WIDTH-1:0] cfg_threshold_data,
    input  wire logic                             cfg_threshold_write,
    output logic                                  cfg_ready
);

    // -------------------------------------------------------------------------
    // Derived local parameters
    // -------------------------------------------------------------------------

    // Number of groups of PN neurons (ceiling division)
    localparam int NEURON_GROUPS = (NEURONS + PN - 1) / PN;

    // Bit width of the beat index counter
    localparam int INPUT_ADDR_WIDTH = (INPUT_BEATS > 1) ? $clog2(INPUT_BEATS) : 1;

    // Total weight RAM depth: one row of INPUT_BEATS words per group, per NP slot
    localparam int WEIGHT_DEPTH = INPUT_BEATS * NEURON_GROUPS;

    // Bit width of the flat weight RAM address
    localparam int WEIGHT_ADDR_WIDTH = (WEIGHT_DEPTH > 1) ? $clog2(WEIGHT_DEPTH) : 1;

    // Bit width of the group index counter
    localparam int GROUP_WIDTH = (NEURON_GROUPS > 1) ? $clog2(NEURON_GROUPS) : 1;

    // Total bit width after zero-padding the input to a multiple of PW
    localparam int PADDED_INPUTS = INPUT_BEATS * PW;

    // How many NPs are actually active in the final (possibly partial) group
    localparam int LAST_GROUP_ACTIVE = (NEURONS % PN == 0) ? PN : (NEURONS % PN);

    // One-hot mask enabling only the active NPs in the last group
    localparam logic [PN-1:0] LAST_GROUP_MASK = (1 << LAST_GROUP_ACTIVE) - 1;

    // Index of the last neuron group (used for terminal-condition checks)
    localparam logic [GROUP_WIDTH-1:0] LAST_GROUP_IDX = GROUP_WIDTH'(NEURON_GROUPS - 1);

    // Index of the last beat (used to signal end-of-row to the NPs)
    localparam logic [INPUT_ADDR_WIDTH-1:0] LAST_BEAT_IDX = INPUT_ADDR_WIDTH'(INPUT_BEATS - 1);

    // -------------------------------------------------------------------------
    // Helper functions
    // -------------------------------------------------------------------------

    // Returns the NP slot index (0..PN-1) for a given global neuron index.
    // Neurons are assigned to NP slots in round-robin order within each group.
    function automatic int get_np_idx(input int neuron_idx);
        return neuron_idx % PN;
    endfunction

    // Returns the group index for a given global neuron index.
    function automatic int get_group_idx(input int neuron_idx);
        return neuron_idx / PN;
    endfunction

    // -------------------------------------------------------------------------
    // FSM state encoding
    // -------------------------------------------------------------------------
    // IDLE     : waiting for start pulse; cfg interface is open.
    // DISPATCH : load one beat of input + weights into stage1 registers.
    // COMPUTE  : NPs consume stage1 data (which is stable from DISPATCH).
    //            Advance beat counter or transition to WAIT_OUT on last beat.
    // WAIT_OUT : wait for all active NPs to signal valid_out, then collect
    //            results. Advance to next group or return to IDLE.
    typedef enum logic [2:0] {
        IDLE,
        DISPATCH,
        COMPUTE,
        WAIT_OUT
    } state_t;

    // -------------------------------------------------------------------------
    // FSM and control registers
    // -------------------------------------------------------------------------
    state_t                        state_r;  // current FSM state
    logic   [     GROUP_WIDTH-1:0] group_idx_r;  // which neuron group is being processed
    logic   [INPUT_ADDR_WIDTH-1:0] beat_idx_r;  // which input beat is being processed
    logic   [              PN-1:0] np_active_r;  // which NP slots are enabled this group
    logic                          done_r;  // registered done pulse
    logic                          output_valid_r;  // latched output valid flag
    logic                          collect_done;  // single-cycle strobe: last group results collected
    logic                          all_groups_done;  // true when group_idx_r points at the last group
    logic                          all_np_done;  // true when every active NP has valid_out asserted
    logic                          np_valid_in;  // asserted during COMPUTE to clock NPs
    logic                          np_last;  // tells NPs this is the final beat of the row

    // Combinational: are we on the last group right now?
    assign all_groups_done = (group_idx_r == LAST_GROUP_IDX);

    // =========================================================================
    // Input buffer
    // =========================================================================
    // Holds the binarized input vector, sliced into INPUT_BEATS chunks of PW
    // bits. Loaded from input_vector when input_load is asserted and the
    // module is not busy. Zero-padding is applied on the MSB side so the
    // total width is a multiple of PW.
    // =========================================================================
    logic [           PW-1:0] input_buffer        [INPUT_BEATS];
    logic [PADDED_INPUTS-1:0] input_vector_padded;

    // Pad input_vector to PADDED_INPUTS bits (MSB zeros fill any unused slots)
    assign input_vector_padded = {{(PADDED_INPUTS - INPUTS) {1'b0}}, input_vector};

    always_ff @(posedge clk) begin
        if (input_load && !busy) begin
            // Slice the padded input into PW-wide beats and store each one
            for (int i = 0; i < INPUT_BEATS; i++) input_buffer[i] <= input_vector_padded[i*PW+:PW];
        end
    end

    // =========================================================================
    // Weight and threshold RAMs
    // =========================================================================
    // weight_rams[np][addr]: PW-bit weight word for NP slot np at flat address
    //   addr = group_idx * INPUT_BEATS + beat_idx
    // threshold_rams[np][group]: COUNT_WIDTH-bit threshold for NP slot np in
    //   neuron group group.
    //
    // Writes are only allowed when cfg_ready is high (module idle).
    // =========================================================================
    logic [         PW-1:0] weight_rams   [PN][ WEIGHT_DEPTH];
    logic [COUNT_WIDTH-1:0] threshold_rams[PN][NEURON_GROUPS];

    always_ff @(posedge clk) begin
        if (!busy) begin
            automatic int np_idx;
            automatic int group_idx;
            automatic int local_addr;

            np_idx     = get_np_idx(cfg_neuron_idx);
            group_idx  = get_group_idx(cfg_neuron_idx);
            local_addr = group_idx * INPUT_BEATS + int'(cfg_weight_addr);

            if (cfg_threshold_write && !cfg_write_en) begin
                threshold_rams[np_idx][group_idx] <= cfg_threshold_data;
            end else if (cfg_write_en && !cfg_threshold_write) begin
                weight_rams[np_idx][local_addr] <= cfg_weight_data;
            end
        end
    end

    // =========================================================================
    // Weight address base per NP slot
    // =========================================================================
    // Each NP slot has its own base pointer into weight_rams. On the first
    // group this is 0; it advances by INPUT_BEATS each time a group completes.
    // Keeping a per-NP base allows a simple single-cycle address computation:
    //   weight_rams[i][weight_addr_base_r[i] + beat_idx_r]
    // =========================================================================
    logic [WEIGHT_ADDR_WIDTH-1:0] weight_addr_base_r[PN];

    // =========================================================================
    // Stage 1 pipeline registers (DISPATCH -> COMPUTE)
    // =========================================================================
    // All data written here during DISPATCH is fully stable by the next cycle
    // (COMPUTE), when the NPs sample it. This single registered stage removes
    // the combinational path from RAM output to NP input and ensures
    // simulation matches synthesis [1].
    //
    // Threshold handling:
    //   - On beat 0 of each group: read fresh threshold from threshold_rams
    //     and cache it in threshold_cache[].
    //   - On beats 1..N-1: reuse threshold_cache[] to avoid redundant reads.
    //   This saves power by avoiding repeated memory accesses [1].
    // =========================================================================
    logic [PW-1:0] weight_data_s1[PN];  // weight words for this beat, one per NP
    logic [COUNT_WIDTH-1:0] threshold_data_s1[PN];  // threshold for this group, one per NP
    logic [PW-1:0] input_chunk_s1;  // input chunk for this beat (shared by all NPs)
    logic last_s1;  // high when this is the last beat of the row
    logic [PN-1:0] np_active_s1;  // which NP slots are active (forwarded from np_active_r)
    logic [COUNT_WIDTH-1:0] threshold_cache[PN];  // holds threshold across beats within a group

    always_ff @(posedge clk) begin
        if (rst) begin
            // Clear all stage1 registers on reset to prevent X propagation
            threshold_cache   <= '{default: '0};
            input_chunk_s1    <= '0;
            last_s1           <= 1'b0;
            np_active_s1      <= '0;
            weight_data_s1    <= '{default: '0};
            threshold_data_s1 <= '{default: '0};
        end else if (state_r == DISPATCH) begin
            // Latch this beat's input chunk and last-beat flag
            input_chunk_s1 <= input_buffer[beat_idx_r];
            last_s1        <= (beat_idx_r == LAST_BEAT_IDX);
            np_active_s1   <= np_active_r;

            for (int i = 0; i < PN; i++) begin
                // Read weight for NP slot i: base + current beat offset
                weight_data_s1[i] <= weight_rams[i][weight_addr_base_r[i]+beat_idx_r];

                if (beat_idx_r == '0) begin
                    // First beat of a new group: read and cache fresh threshold
                    automatic logic [COUNT_WIDTH-1:0] tr = threshold_rams[i][group_idx_r];
                    threshold_cache[i]   <= tr;
                    threshold_data_s1[i] <= tr;
                end else begin
                    // Subsequent beats: reuse cached threshold (avoids re-reading RAM)
                    threshold_data_s1[i] <= threshold_cache[i];
                end
            end
        end else begin
            // When not dispatching, zero weight and input to prevent spurious
            // toggling in the NPs (operand isolation for power savings) [1]
            weight_data_s1 <= '{default: '0};
            input_chunk_s1 <= '0;
            // last_s1 and threshold_data_s1 are intentionally held stable
            // so NPs do not see glitches on control inputs between beats
        end
    end

    // =========================================================================
    // NP active mask register
    // =========================================================================
    // Tracks which of the PN NP slots are in use for the current group.
    // All PN slots are active for all full groups. Only LAST_GROUP_ACTIVE
    // slots are active for the final group if NEURONS is not a multiple of PN.
    // The mask is set at inference start and updated each time a group
    // completes, one cycle ahead of when it will actually be needed.
    // =========================================================================
    always_ff @(posedge clk) begin
        if (rst) begin
            np_active_r <= '0;
        end else if (state_r == IDLE && start) begin
            // First group: all slots active (or last-group mask if only one group)
            np_active_r <= (NEURONS >= PN) ? {PN{1'b1}} : LAST_GROUP_MASK;
        end else if (state_r == WAIT_OUT && all_np_done) begin
            // Pre-load mask for the group that is about to start next cycle.
            // If the next group is the last, apply the partial mask.
            if (group_idx_r == LAST_GROUP_IDX - GROUP_WIDTH'(1)) np_active_r <= LAST_GROUP_MASK;
            else np_active_r <= {PN{1'b1}};
        end
    end

    // =========================================================================
    // NP control signals
    // =========================================================================
    // np_valid_in: clocks a new accumulation beat into all active NPs.
    //   Asserted during COMPUTE. At this point stage1 holds data written
    //   during the preceding DISPATCH cycle — fully stable.
    //
    // np_last: tells NPs that this is the final beat of the current row.
    //   When NPs see valid_in && last, they finalize and assert valid_out.
    //   Uses last_s1 (registered during DISPATCH) rather than any in-flight
    //   combinational signal, preventing delta-cycle ambiguity.
    // =========================================================================
    assign np_valid_in = (state_r == COMPUTE);
    assign np_last     = (state_r == COMPUTE) && last_s1;

    // =========================================================================
    // Neuron processor instances
    // =========================================================================
    // PN NP instances run in parallel, each handling one neuron slot per group.
    // Inactive NPs (np_active_s1[i] == 0) receive zeroed inputs to avoid
    // unnecessary switching activity (operand isolation) [1].
    //
    // all_np_done: true when every *active* NP has raised valid_out.
    //   Inactive NPs are masked out by ORing with ~np_active_s1 so they
    //   do not stall the WAIT_OUT -> next-group transition.
    // =========================================================================
    logic [PN-1:0] np_valid_out;  // valid_out from each NP
    logic [PN-1:0] np_activation;  // binary activation output from each NP
    logic [COUNT_WIDTH-1:0] np_popcount[PN];  // raw popcount from each NP

    // All active NPs have produced a result (inactive slots are don't-cares)
    assign all_np_done = &(np_valid_out | ~np_active_s1);

    generate
        for (genvar i = 0; i < PN; i++) begin : gen_nps
            neuron_processor #(
                .PW               (PW),
                .MAX_NEURON_INPUTS(INPUTS),
                .OUTPUT_LAYER     (OUTPUT_LAYER)
            ) u_np (
                .clk         (clk),
                .rst         (rst),
                // Gate valid_in per slot so inactive NPs never accumulate
                .valid_in    (np_valid_in && np_active_s1[i]),
                .last        (np_last),
                // Zero inputs to inactive slots (operand isolation) [1]
                .x           (np_active_s1[i] ? input_chunk_s1 : '0),
                .w           (np_active_s1[i] ? weight_data_s1[i] : '0),
                .threshold   (threshold_data_s1[i]),
                .valid_out   (np_valid_out[i]),
                .activation  (np_activation[i]),
                .popcount_out(np_popcount[i])
            );
        end
    endgenerate

    // =========================================================================
    // Output collection buffers
    // =========================================================================
    // Results from each group are written into the appropriate slice of
    // activations_buffer / popcounts_buffer as each group completes.
    // collect_done is a single-cycle strobe that fires when the last group
    // has been written, signalling the FSM to assert done and output_valid.
    //
    // For OUTPUT_LAYER == 1, activations are forced to 0 because the top
    // level uses the raw popcounts for argmax rather than binary activations.
    // =========================================================================
    logic [NEURONS-1:0] activations_buffer;  // accumulated binary activations
    logic [COUNT_WIDTH-1:0] popcounts_buffer[NEURONS];  // accumulated raw popcounts

    always_ff @(posedge clk) begin
        if (rst) begin
            activations_buffer <= '0;
            popcounts_buffer   <= '{default: '0};
            collect_done       <= 1'b0;
        end else begin
            collect_done <= 1'b0;  // default: no completion this cycle

            if (state_r == IDLE && start) begin
                // Clear output buffers at the start of each new inference
                // so stale results from a previous run are never output
                activations_buffer <= '0;
                popcounts_buffer   <= '{default: '0};

            end else if (state_r == WAIT_OUT && all_np_done) begin
                // Write each active NP's result into the correct neuron slot
                for (int i = 0; i < PN; i++) begin
                    if (np_valid_out[i]) begin
                        // Global neuron index for NP slot i in the current group
                        automatic int neuron_idx = int'(group_idx_r) * PN + i;
                        if (neuron_idx < NEURONS) begin
                            popcounts_buffer[neuron_idx] <= np_popcount[i];
                            // Output layer: suppress activations (argmax uses popcounts)
                            if (OUTPUT_LAYER) activations_buffer[neuron_idx] <= 1'b0;
                            else activations_buffer[neuron_idx] <= np_activation[i];
                        end
                    end
                end

                // If this was the last group, signal completion to the FSM
                if (all_groups_done) collect_done <= 1'b1;
            end
        end
    end

    // =========================================================================
    // Main FSM
    // =========================================================================
    // Controls sequencing across groups and beats. Also manages done_r and
    // output_valid_r which are driven from collect_done one cycle after the
    // last group's results are written.
    // =========================================================================
    always_ff @(posedge clk) begin
        if (rst) begin
            state_r            <= IDLE;
            group_idx_r        <= '0;
            beat_idx_r         <= '0;
            done_r             <= 1'b0;
            output_valid_r     <= 1'b0;
            weight_addr_base_r <= '{default: '0};
        end else begin
            done_r <= 1'b0;  // done is a single-cycle pulse; clear by default

            if (collect_done) begin
                // All groups processed: latch valid outputs and pulse done
                output_valid_r <= 1'b1;
                done_r         <= 1'b1;
            end else if (state_r == IDLE && start) begin
                // Clear output_valid at the start of a new inference so a
                // consumer cannot mistake stale results for fresh ones
                output_valid_r <= 1'b0;
            end

            case (state_r)
                // ---------------------------------------------------------
                // IDLE: wait for start. Reset all counters on departure.
                // ---------------------------------------------------------
                IDLE: begin
                    if (start) begin
                        state_r            <= DISPATCH;
                        group_idx_r        <= '0;
                        beat_idx_r         <= '0;
                        weight_addr_base_r <= '{default: '0};
                    end
                end

                // ---------------------------------------------------------
                // DISPATCH: one cycle to load stage1 registers from RAMs.
                // Always advances to COMPUTE unconditionally.
                // ---------------------------------------------------------
                DISPATCH: begin
                    state_r <= COMPUTE;
                end

                // ---------------------------------------------------------
                // COMPUTE: NPs consume stage1 data this cycle.
                // last_s1 was written in the preceding DISPATCH cycle and
                // is fully stable here — safe to use for branching.
                // ---------------------------------------------------------
                COMPUTE: begin
                    if (last_s1) begin
                        // Final beat of this group's row: wait for NP results
                        state_r    <= WAIT_OUT;
                        beat_idx_r <= '0; // reset for next group
                    end else begin
                        // More beats remain: advance beat counter and re-dispatch
                        beat_idx_r <= beat_idx_r + INPUT_ADDR_WIDTH'(1);
                        state_r    <= DISPATCH;
                    end
                end

                // ---------------------------------------------------------
                // WAIT_OUT: hold until all active NPs assert valid_out.
                // Then either advance to the next group or finish.
                // ---------------------------------------------------------
                WAIT_OUT: begin
                    if (all_np_done) begin
                        if (all_groups_done) begin
                            // All groups complete — return to IDLE.
                            // collect_done will have been set this same cycle
                            // in the output-collection always_ff block.
                            state_r <= IDLE;
                        end else begin
                            // Advance group counter and move each NP's weight
                            // base pointer forward by one full row (INPUT_BEATS)
                            group_idx_r <= group_idx_r + GROUP_WIDTH'(1);
                            for (int i = 0; i < PN; i++)
                            weight_addr_base_r[i] <= weight_addr_base_r[i] + WEIGHT_ADDR_WIDTH'(INPUT_BEATS);
                            state_r <= DISPATCH;
                        end
                    end
                end

                // Safety net: any illegal state returns to IDLE
                default: state_r <= IDLE;
            endcase
        end
    end

    // =========================================================================
    // Output assignments
    // =========================================================================
    // busy is combinational from state_r so it deasserts in the same cycle
    // the FSM returns to IDLE. done_r (registered) follows one delta later,
    // which is the expected single-cycle pulse behaviour.
    // cfg_ready mirrors !busy: configuration writes are safe only when idle.
    // =========================================================================
    assign busy            = (state_r != IDLE);
    assign done            = done_r;
    assign cfg_ready       = !busy;
    assign output_valid    = output_valid_r;
    assign activations_out = activations_buffer;

    // Unpack the popcounts array into a flat packed bus for the output port.
    // Neuron i occupies bits [i*COUNT_WIDTH +: COUNT_WIDTH].
    always_comb begin
        for (int i = 0; i < NEURONS; i++) popcounts_out[i*COUNT_WIDTH+:COUNT_WIDTH] = popcounts_buffer[i];
    end

endmodule
`default_nettype wire
