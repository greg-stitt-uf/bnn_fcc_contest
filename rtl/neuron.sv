module neuron #(
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
    inout logic [POPCOUNT_WIDTH-1:0] popcount,
    input logic [NUM_WEIGHTS-1:0] w,
    input logic [NUM_INPUTS-1:0] x,
    output logic [$clog2(NUM_WEIGHTS+1)-1:0] y,
    output logic valid_out
);

    logic [NUM_INPUTS-1:0] xnor_out_r; 
    logic [$clog2(NUM_WEIGHTS+1)-1:0] y_r, count_ones_out_r;
    logic [31:0] popcount_r; // hardcoding popcount size
    logic valid_r, valid_r2, valid_r3, valid_r4;

    // assign count_ones_out = $countones(xnor_block_out); // popcount

    // adding the inputs and weights done here (pipeline this)

    always_ff @(posedge clk or posedge rst) begin // first implement with a basic pipeline 
        if (rst) begin
            xnor_out_r <= '0; 
            count_ones_out_r <= '0; 
            popcount_r <= '0;
            y_r <= '0; 
            valid_r <= 1'b0; 
            valid_r2 <= 1'b0; 
            valid_r3 <= 1'b0;
            valid_r4 <= 1'b0;
        end else if (en) begin 
            /* Stage 1 */
            xnor_out_r <= x ~^ w; 
            valid_r <= valid_in; 

            /* Stage 2 */
            count_ones_out_r <= $countones(xnor_out_r);
            valid_r2 <= valid_r; 

            /* Stage 3 */
            popcount_r <= count_ones_out_r + popcount;
            valid_r3 <= valid_r2;


            /* Stage 4 */
            if(count_ones_out_r >= THRESOLD_BITS) begin 
                y_r <= count_ones_out_r;
            end else begin 
                y_r <= '0; 
            end

            valid_r4 <= valid_r3;
        end
    end

    // assign outputs at the end (need the valid signal to check when pipeline is done)
    assign y = y_r;
    assign valid_out = valid_r4;
    assign popcount = popcount_r;

endmodule
