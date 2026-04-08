`default_nettype none
module bnn_layer #(
    parameter int INPUTS                = 784,
    parameter int NEURONS               = 256,
    parameter int PW                    = 8,
    parameter int PN                    = 8,
    parameter bit OUTPUT_LAYER          = 0,
    parameter int COUNT_WIDTH           = $clog2(INPUTS + 1),
    parameter int INPUT_BEATS           = (INPUTS + PW - 1) / PW,
    parameter int CFG_NEURON_WIDTH      = (NEURONS > 1) ? $clog2(NEURONS) : 1,
    parameter int CFG_WEIGHT_ADDR_WIDTH = (INPUT_BEATS > 1) ? $clog2(INPUT_BEATS) : 1
) (
    input  wire logic                             clk,
    input  wire logic                             rst,
    input  wire logic                             input_load,
    input  wire logic [               INPUTS-1:0] input_vector,
    input  wire logic                             start,
    output logic                                  done,
    output logic                                  busy,
    output logic      [              NEURONS-1:0] activations_out,
    output logic      [  NEURONS*COUNT_WIDTH-1:0] popcounts_out,
    output logic                                  output_valid,
    input  wire logic                             cfg_write_en,
    input  wire logic [     CFG_NEURON_WIDTH-1:0] cfg_neuron_idx,
    input  wire logic [CFG_WEIGHT_ADDR_WIDTH-1:0] cfg_weight_addr,
    input  wire logic [                   PW-1:0] cfg_weight_data,
    input  wire logic [          COUNT_WIDTH-1:0] cfg_threshold_data,
    input  wire logic                             cfg_threshold_write,
    output logic                                  cfg_ready
);
    localparam int NEURON_GROUPS = (NEURONS + PN - 1) / PN;
    localparam int INPUT_ADDR_WIDTH = (INPUT_BEATS > 1) ? $clog2(INPUT_BEATS) : 1;
    localparam int WEIGHT_DEPTH = INPUT_BEATS * NEURON_GROUPS;
    localparam int WEIGHT_ADDR_WIDTH = (WEIGHT_DEPTH > 1) ? $clog2(WEIGHT_DEPTH) : 1;
    localparam int GROUP_WIDTH = (NEURON_GROUPS > 1) ? $clog2(NEURON_GROUPS) : 1;
    localparam int PADDED_INPUTS = INPUT_BEATS * PW;
    localparam int LAST_GROUP_ACTIVE = (NEURONS % PN == 0) ? PN : (NEURONS % PN);
    localparam logic [PN-1:0] LAST_GROUP_MASK = (1 << LAST_GROUP_ACTIVE) - 1;
    localparam logic [GROUP_WIDTH-1:0] LAST_GROUP_IDX = GROUP_WIDTH'(NEURON_GROUPS - 1);
    localparam logic [INPUT_ADDR_WIDTH-1:0] LAST_BEAT_IDX = INPUT_ADDR_WIDTH'(INPUT_BEATS - 1);

    function automatic int get_np_idx(input int neuron_idx);
        return neuron_idx % PN;
    endfunction
    function automatic int get_group_idx(input int neuron_idx);
        return neuron_idx / PN;
    endfunction

    typedef enum logic [2:0] {
        IDLE,
        DISPATCH,
        COMPUTE,
        WAIT_OUT
    } state_t;

    state_t                        state_r;
    logic   [     GROUP_WIDTH-1:0] group_idx_r;
    logic   [INPUT_ADDR_WIDTH-1:0] beat_idx_r;
    logic   [              PN-1:0] np_active_r;
    logic                          done_r;
    logic                          output_valid_r;
    logic                          collect_done;
    logic                          all_groups_done;
    logic                          all_np_done;
    logic                          np_valid_in;
    logic                          np_last;

    assign all_groups_done = (group_idx_r == LAST_GROUP_IDX);

    // -------------------------------------------------------------------------
    // Input buffer
    // -------------------------------------------------------------------------
    logic [           PW-1:0] input_buffer        [INPUT_BEATS];
    logic [PADDED_INPUTS-1:0] input_vector_padded;
    assign input_vector_padded = {{(PADDED_INPUTS - INPUTS) {1'b0}}, input_vector};

    always_ff @(posedge clk) begin
        if (input_load && !busy) begin
            for (int i = 0; i < INPUT_BEATS; i++) input_buffer[i] <= input_vector_padded[i*PW+:PW];
        end
    end

    // -------------------------------------------------------------------------
    // Weight and threshold RAMs
    // -------------------------------------------------------------------------
    logic [         PW-1:0] weight_rams   [PN][ WEIGHT_DEPTH];
    logic [COUNT_WIDTH-1:0] threshold_rams[PN][NEURON_GROUPS];

    always_ff @(posedge clk) begin
        if (cfg_write_en && !busy) begin
            automatic int np_idx = get_np_idx(cfg_neuron_idx);
            automatic int group_idx = get_group_idx(cfg_neuron_idx);
            automatic int local_addr = group_idx * INPUT_BEATS + int'(cfg_weight_addr);
            if (cfg_threshold_write) threshold_rams[np_idx][group_idx] <= cfg_threshold_data;
            else weight_rams[np_idx][local_addr] <= cfg_weight_data;
        end
    end

    // -------------------------------------------------------------------------
    // Weight address base per NP
    // -------------------------------------------------------------------------
    logic [WEIGHT_ADDR_WIDTH-1:0] weight_addr_base_r[PN];

    // -------------------------------------------------------------------------
    // Stage 1: Memory read — written during DISPATCH, stable during COMPUTE
    // NPs are fed directly from stage1 and sampled during COMPUTE.
    // This eliminates the one-beat lag that stage2 introduced.
    // -------------------------------------------------------------------------
    logic [               PW-1:0] weight_data_s1    [PN];
    logic [      COUNT_WIDTH-1:0] threshold_data_s1 [PN];
    logic [               PW-1:0] input_chunk_s1;
    logic                         last_s1;
    logic [               PN-1:0] np_active_s1;
    logic [      COUNT_WIDTH-1:0] threshold_cache   [PN];

    always_ff @(posedge clk) begin
        if (rst) begin
            threshold_cache   <= '{default: '0};
            input_chunk_s1    <= '0;
            last_s1           <= 1'b0;
            np_active_s1      <= '0;
            weight_data_s1    <= '{default: '0};
            threshold_data_s1 <= '{default: '0};
        end else if (state_r == DISPATCH) begin
            input_chunk_s1 <= input_buffer[beat_idx_r];
            last_s1        <= (beat_idx_r == LAST_BEAT_IDX);
            np_active_s1   <= np_active_r;
            for (int i = 0; i < PN; i++) begin
                weight_data_s1[i] <= weight_rams[i][weight_addr_base_r[i]+beat_idx_r];
                if (beat_idx_r == '0) begin
                    automatic logic [COUNT_WIDTH-1:0] tr = threshold_rams[i][group_idx_r];
                    threshold_cache[i]   <= tr;
                    threshold_data_s1[i] <= tr;
                end else begin
                    threshold_data_s1[i] <= threshold_cache[i];
                end
            end
        end else begin
            weight_data_s1 <= '{default: '0};
            input_chunk_s1 <= '0;
            // Keep last_s1 and threshold stable so NPs see clean signals
        end
    end

    // -------------------------------------------------------------------------
    // NP active mask
    // -------------------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (rst) begin
            np_active_r <= '0;
        end else if (state_r == IDLE && start) begin
            np_active_r <= (NEURONS >= PN) ? {PN{1'b1}} : LAST_GROUP_MASK;
        end else if (state_r == WAIT_OUT && all_np_done) begin
            if (group_idx_r == LAST_GROUP_IDX - GROUP_WIDTH'(1)) np_active_r <= LAST_GROUP_MASK;
            else np_active_r <= {PN{1'b1}};
        end
    end

    // -------------------------------------------------------------------------
    // NP control signals
    // valid_in fires during COMPUTE; at that point stage1 regs hold the
    // data written during the preceding DISPATCH cycle — fully stable.
    // -------------------------------------------------------------------------
    assign np_valid_in = (state_r == COMPUTE);
    assign np_last     = (state_r == COMPUTE) && last_s1;

    // -------------------------------------------------------------------------
    // NP instantiation — fed directly from stage1
    // -------------------------------------------------------------------------
    logic [         PN-1:0] np_valid_out;
    logic [         PN-1:0] np_activation;
    logic [COUNT_WIDTH-1:0] np_popcount   [PN];

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
                .valid_in    (np_valid_in && np_active_s1[i]),
                .last        (np_last),
                .x           (np_active_s1[i] ? input_chunk_s1 : '0),
                .w           (np_active_s1[i] ? weight_data_s1[i] : '0),
                .threshold   (threshold_data_s1[i]),
                .valid_out   (np_valid_out[i]),
                .activation  (np_activation[i]),
                .popcount_out(np_popcount[i])
            );
        end
    endgenerate

    // -------------------------------------------------------------------------
    // Output collection
    // -------------------------------------------------------------------------
    logic [    NEURONS-1:0] activations_buffer;
    logic [COUNT_WIDTH-1:0] popcounts_buffer   [NEURONS];

    always_ff @(posedge clk) begin
        if (rst) begin
            activations_buffer <= '0;
            popcounts_buffer   <= '{default: '0};
            collect_done       <= 1'b0;
        end else begin
            collect_done <= 1'b0;
            if (state_r == IDLE && start) begin
                activations_buffer <= '0;
                popcounts_buffer   <= '{default: '0};
            end else if (state_r == WAIT_OUT && all_np_done) begin
                for (int i = 0; i < PN; i++) begin
                    if (np_valid_out[i]) begin
                        automatic int neuron_idx = int'(group_idx_r) * PN + i;
                        if (neuron_idx < NEURONS) begin
                            popcounts_buffer[neuron_idx] <= np_popcount[i];
                            if (OUTPUT_LAYER) activations_buffer[neuron_idx] <= 1'b0;
                            else activations_buffer[neuron_idx] <= np_activation[i];
                        end
                    end
                end
                if (all_groups_done) collect_done <= 1'b1;
            end
        end
    end

    // -------------------------------------------------------------------------
    // FSM
    // -------------------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (rst) begin
            state_r            <= IDLE;
            group_idx_r        <= '0;
            beat_idx_r         <= '0;
            done_r             <= 1'b0;
            output_valid_r     <= 1'b0;
            weight_addr_base_r <= '{default: '0};
        end else begin
            done_r <= 1'b0;
            if (collect_done) begin
                output_valid_r <= 1'b1;
                done_r         <= 1'b1;
            end else if (state_r == IDLE && start) begin
                output_valid_r <= 1'b0;
            end

            case (state_r)
                IDLE: begin
                    if (start) begin
                        state_r            <= DISPATCH;
                        group_idx_r        <= '0;
                        beat_idx_r         <= '0;
                        weight_addr_base_r <= '{default: '0};
                    end
                end

                DISPATCH: begin
                    state_r <= COMPUTE;
                end

                COMPUTE: begin
                    // last_s1 was written during DISPATCH (previous cycle) — stable now
                    if (last_s1) begin
                        state_r    <= WAIT_OUT;
                        beat_idx_r <= '0;
                    end else begin
                        beat_idx_r <= beat_idx_r + INPUT_ADDR_WIDTH'(1);
                        state_r    <= DISPATCH;
                    end
                end

                WAIT_OUT: begin
                    if (all_np_done) begin
                        if (all_groups_done) begin
                            state_r <= IDLE;
                        end else begin
                            group_idx_r <= group_idx_r + GROUP_WIDTH'(1);
                            for (int i = 0; i < PN; i++)
                            weight_addr_base_r[i] <= weight_addr_base_r[i] + WEIGHT_ADDR_WIDTH'(INPUT_BEATS);
                            state_r <= DISPATCH;
                        end
                    end
                end

                default: state_r <= IDLE;
            endcase
        end
    end

    // -------------------------------------------------------------------------
    // Output assignments
    // -------------------------------------------------------------------------
    assign busy            = (state_r != IDLE);
    assign done            = done_r;
    assign cfg_ready       = !busy;
    assign output_valid    = output_valid_r;
    assign activations_out = activations_buffer;

    always_comb begin
        for (int i = 0; i < NEURONS; i++) popcounts_out[i*COUNT_WIDTH+:COUNT_WIDTH] = popcounts_buffer[i];
    end

endmodule
`default_nettype wire
