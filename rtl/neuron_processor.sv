// MODULE: neuron_processor
// PURPOSE: Process one BNN neuron in a streaming, pipelined fashion
//
// A BNN neuron compares input bits to weight bits using XNOR (match detection),
// counts how many match (popcount), and decides if the neuron activates.

module neuron_processor #(
    parameter int PW                = 8,    // Parallel width (how many inputs/weights per cycle)
    parameter int MAX_NEURON_INPUTS = 784,  // Largest neuron size
    parameter bit OUTPUT_LAYER      = 0     // 0=hidden, 1=output
) (
    input logic clk,
    input logic rst,
    // Stage 0 inputs
    input logic valid_in,  // True when x/w/threshold are valid 
    input logic last,  // Marks final beat of a neuron
    input logic [PW-1:0] x,  // Input activations
    input logic [PW-1:0] w,  // Weights
    input logic [$clog2(MAX_NEURON_INPUTS+1)-1:0] threshold,
    // Stage 3 outputs (this will arrive 3 cycles later)
    output logic valid_out,
    output logic activation,  // Thresholded output (hidden layers)
    output logic [$clog2(
MAX_NEURON_INPUTS+1
)-1:0] popcount_out  // Raw popcount for our output layer and future debugging 
);

    localparam int ACCUM_WIDTH = $clog2(MAX_NEURON_INPUTS + 1);
    localparam int PARTIAL_WIDTH = $clog2(PW + 1);

    // ========================================================================
    // Stage A -> Stage B: Register inputs and compute XNOR
    // ========================================================================
    logic stage_a_valid_r;
    logic stage_a_last_r;
    logic [PW-1:0] stage_a_xnor_result_r;
    logic [ACCUM_WIDTH-1:0] stage_a_threshold_r;

    always_ff @(posedge clk) begin
        if (rst) begin
            stage_a_valid_r <= '0;
            stage_a_last_r <= '0;
            stage_a_xnor_result_r <= '0;
            stage_a_threshold_r <= '0;
        end else begin
            stage_a_valid_r <= valid_in;
            stage_a_last_r <= last;
            stage_a_xnor_result_r <= x ~^ w;  // XNOR: 1 where x and w match
            stage_a_threshold_r <= threshold;
        end
    end

    // ========================================================================
    // Stage B -> Stage C: Popcount
    // ========================================================================

    logic stage_b_valid_r;
    logic stage_b_last_r;
    logic [PARTIAL_WIDTH-1:0] stage_b_partial_count_r;
    logic [ACCUM_WIDTH-1:0] stage_b_threshold_r;

    // Instantiate popcount tree
    logic [PARTIAL_WIDTH-1:0] partial_popcount;

    popcount_tree #(
        .WIDTH(PW)  //Count PW bits 
    ) u_popcount (
        .data (stage_a_xnor_result_r),  //XNOR result from Stage A
        .count(partial_popcount)        // Number of matches 
    );

    always_ff @(posedge clk) begin
        if (rst) begin
            stage_b_valid_r <= '0;
            stage_b_last_r <= '0;
            stage_b_partial_count_r <= '0;
            stage_b_threshold_r <= '0;
        end else begin
            stage_b_valid_r <= stage_a_valid_r;
            stage_b_last_r <= stage_a_last_r;
            stage_b_partial_count_r <= partial_popcount;
            stage_b_threshold_r <= stage_a_threshold_r;
        end
    end

    // ========================================================================
    // Stage C: Accumulate and output
    // 
    // This stage is pretty confusing so we are accumalting partial popcounts
    // multiple cycles. When the 'last' signal is true it outputs the final 
    // result and clears the accumlator for the next neuron
    // ========================================================================
    logic [ACCUM_WIDTH-1:0] accumulator_r;  //running sum of partial popcounts 
    logic [ACCUM_WIDTH-1:0] final_sum;      // accumlator + curr partial popcounts
    logic valid_out_r;                      
    logic activation_r;                 
    logic [ACCUM_WIDTH-1:0] popcount_out_r; //raw popcount result 


    //computing final sum 
    always_comb begin
        final_sum = accumulator_r + stage_b_partial_count_r;  // Removed cast
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            accumulator_r <= '0;
            valid_out_r <= '0;
            activation_r <= '0;
            popcount_out_r <= '0;
        end else begin
            //output is valid only when its the last chunck and have valid data 
            //only is true for one cycle when we have the final result (note for simulation)
            valid_out_r <= stage_b_valid_r && stage_b_last_r;

            if (stage_b_valid_r && stage_b_last_r) begin //check if this is last chunck of curr neuron
                popcount_out_r <= final_sum; //save total popcount 
                if (OUTPUT_LAYER) begin
                    activation_r <= 1'b0; //just pass raw popcount 
                end else begin
                    activation_r <= (final_sum >= stage_b_threshold_r);  //compare against threashold 
                    //if activation is 1 we matched enough bits 0 otherwise
                end
                accumulator_r <= '0;
            end else if (stage_b_valid_r) begin
                //this is the middle chunck 
                //add this partical count to the accumulator and continue 
                accumulator_r <= final_sum;
            end
        end
    end

    assign valid_out = valid_out_r;
    assign activation = activation_r;
    assign popcount_out = popcount_out_r;




endmodule
