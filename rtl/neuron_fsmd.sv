// Neuron but as a state machine so popcount can reset each test
module neuron_fsmd #(
    parameter NUM_WEIGHTS = 4,
    parameter NUM_INPUTS = 4, 
    parameter int THRESHOLD_BITS = 4,
    parameter int POPCOUNT_WIDTH = 32
)
(
    input logic clk, 
    input logic rst, 
    input logic en, 
    input logic valid_in,
    input logic [NUM_WEIGHTS-1:0] w,
    input logic [NUM_INPUTS-1:0] x,
    output logic y,
    output logic [POPCOUNT_WIDTH-1:0] popcount_out,
    output logic valid_out
);

    // Pipeline Registers
    logic [NUM_INPUTS-1:0] xnor_out_r, next_xnor_out; 
    logic [$clog2(NUM_WEIGHTS+1)-1:0] count_ones_out_r, next_count_ones_out;
    logic [POPCOUNT_WIDTH-1:0] accum_r, next_accum;
    
    // Status Registers
    logic [$clog2(NUM_INPUTS+1)-1:0] input_count_r, next_input_count;
    logic valid_r1, valid_r2, valid_r3, valid_r4;
    logic y_r, next_y;

    typedef enum logic [1:0] {
        START,
        COUNT_ONES,
        ACCUM,
        OUTPUT
    } state_t;

    state_t state_r, next_state;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state_r  <= START;
            xnor_out_r <= '0;
            count_ones_out_r <= '0;
            accum_r <= '0;
            input_count_r <= '0;
            y_r <= 1'b0;
        end else begin
            state_r <= next_state;
            xnor_out_r <= next_xnor_out;
            count_ones_out_r <= next_count_ones_out;
            accum_r <= next_accum;
            input_count_r <= next_input_count;
            y_r <= next_y;
        end
    end

    always_comb begin
        next_state = state_r;
        next_xnor_out = xnor_out_r;
        next_count_ones_out = count_ones_out_r;
        next_accum = accum_r;
        next_input_count = input_count_r;
        next_y = y_r;

        case(state_r)
            START: begin
                next_y = 1'b0;
                next_count_ones_out = '0;
                valid_out = 1'b0;
                if(en && valid_in) begin
                    next_xnor_out = x ~^ w; // get matches
                    next_state = COUNT_ONES;
                end
            end
            COUNT_ONES: begin
                next_count_ones_out = $countones(xnor_out_r); // get number of ones
                next_state = OUTPUT;
                next_y = (next_count_ones_out >= THRESHOLD_BITS) ? 1'b1 : 1'b0;
            end
            OUTPUT: begin
                valid_out = 1'b1;
                popcount_out = count_ones_out_r;
                next_state = START;
            end
            default: begin
                
            end
        endcase
    end

    assign y = y_r;
endmodule
