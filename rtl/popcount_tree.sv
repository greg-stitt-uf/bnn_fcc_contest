// MODULE: popcount_tree
// PURPOSE: Counts how many 1s are in a bit vector using a balanced tree

// This module is straight comb logic and it build a binary tree where each level 
// adds pairs of counts together. The output is the total number of 1s in the input

module popcount_tree #(
    parameter int WIDTH = 8
) (
    input  logic [          WIDTH-1:0] data,
    output logic [$clog2(WIDTH+1)-1:0] count  //# of 1's 
);


    localparam int OUTPUT_WIDTH = $clog2(WIDTH + 1);
    localparam int NUM_STAGES = $clog2(WIDTH) + 1;

    // Tree storage: stage[level][element]
    // Level 0 has WIDTH elements of 1 bit each
    // Level 1 has WIDTH/2 elements of 2 bits each, etc.
    // tree[level][element] stores the count at that position
    // All counts are OUTPUT_WIDTH bits wide to avoid overflow
    logic [OUTPUT_WIDTH-1:0] tree[NUM_STAGES][WIDTH];


    //Build the popcount tree
    // 1. Level 0: It converts each intput bit to a count (0 or 1)
    // 2. Levels 1+: Add pairs of counts from prev level
    // 3. If we have odd numbers amount we just pass the last elem forward 
    always_comb begin
        //each input bit is a 1-bit count and we pad to make all same size
        for (int i = 0; i < WIDTH; i++) begin
            tree[0][i] = {{(OUTPUT_WIDTH - 1) {1'b0}}, data[i]};
        end

        //add pairs and tree is built 
        for (int stage = 1; stage < NUM_STAGES; stage++) begin
            automatic int num_elements = WIDTH >> stage;  // Number of elements at this stage
            automatic int prev_elements = WIDTH >> (stage - 1);

            for (int i = 0; i < num_elements; i++) begin
                tree[stage][i] = tree[stage-1][2*i] + tree[stage-1][2*i+1];
            end

            // Handle odd element (if previous stage had odd count)
            if (prev_elements % 2 == 1) begin
                tree[stage][num_elements] = tree[stage-1][prev_elements-1];
            end
        end

        // Final result is at the root of the tree
        count = tree[NUM_STAGES-1][0];
    end

endmodule
