// MODULE: popcount_tree
// PURPOSE: Counts how many 1s are in a bit vector using a balanced tree
// Pure combinational logic that builds a binary tree where each level adds
// pairs of counts together. Works correctly for any WIDTH including
// non-power-of-two values by using ceiling division for element counts.
// The output is the total number of 1s in the input.
module popcount_tree #(
    parameter int WIDTH = 8
) (
    input  logic [          WIDTH-1:0] data,
    output logic [$clog2(WIDTH+1)-1:0] count  // # of 1's
);

    localparam int OUTPUT_WIDTH = $clog2(WIDTH + 1);
    localparam int NUM_STAGES = $clog2(WIDTH) + 1;

    // Tree storage: tree[level][element]
    // Level 0 has WIDTH elements of 1 bit each
    // Level 1 has ceil(WIDTH/2) elements of 2 bits each, etc.
    // All counts are OUTPUT_WIDTH bits wide to avoid overflow
    logic [OUTPUT_WIDTH-1:0] tree[NUM_STAGES][WIDTH];

    // Build the popcount tree
    // 1. Level 0: convert each input bit to a count (0 or 1)
    // 2. Levels 1+: add pairs of counts from previous level
    // 3. Odd element at any level is passed forward unpaired (ceiling division
    //    ensures the element count is always large enough to hold it)
    always_comb begin
        // Initialize entire tree to prevent X propagation
        for (int s = 0; s < NUM_STAGES; s++) begin
            for (int e = 0; e < WIDTH; e++) begin
                tree[s][e] = '0;
            end
        end

        // Level 0: each input bit becomes a padded count
        for (int i = 0; i < WIDTH; i++) begin
            tree[0][i] = OUTPUT_WIDTH'(data[i]);
        end

        // Levels 1+: add pairs, carry forward lone element if count is odd
        for (int stage = 1; stage < NUM_STAGES; stage++) begin
            // Ceiling division: ensures we allocate a slot for an odd leftover
            automatic int prev_elements = (WIDTH + (1 << (stage - 1)) - 1) >> (stage - 1);
            automatic int num_elements = (prev_elements + 1) / 2;
            // Add pairs from previous level
            for (int i = 0; i < num_elements; i++) begin
                if (2 * i + 1 < prev_elements) begin
                    // Normal case: two elements to add
                    tree[stage][i] = tree[stage-1][2*i] + tree[stage-1][2*i+1];
                end else begin
                    // Odd leftover: pass the lone element forward unpaired
                    tree[stage][i] = tree[stage-1][2*i];
                end
            end
        end

        // Final result is at the root of the tree
        count = tree[NUM_STAGES-1][0];
    end

endmodule
