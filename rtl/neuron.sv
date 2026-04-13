// module neuron #(
//     parameter NUM_WEIGHTS = 4,
//     parameter NUM_INPUTS = 4, 
//     parameter int THRESHOLD_BITS = 4,
//     parameter int POPCOUNT_WIDTH = 32
// )
// (
//     input logic clk, 
//     input logic rst, 
//     input logic en, 
//     input logic valid_in,
//     input logic last,
//     input logic [NUM_WEIGHTS-1:0] w,
//     input logic [NUM_INPUTS-1:0] x,
//     output logic y,
//     output logic [POPCOUNT_WIDTH-1:0] popcount_out,
//     output logic valid_out
// );

//     // Pipeline Registers
//     logic [NUM_INPUTS-1:0] xnor_out_r; 
//     logic [$clog2(NUM_WEIGHTS+1)-1:0] count_ones_out_r;
//     logic [POPCOUNT_WIDTH-1:0] accum_r;
    
//     // Status Registers
//     logic [$clog2(NUM_INPUTS+1)-1:0] input_count_r;
//     logic valid_r1, valid_r2, valid_r3, valid_r4;
//     logic last_r1, last_r2, last_r3;
//     logic y_r;
//     // Get last and then reset
//     // Add accumulator 
//     always_ff @(posedge clk or posedge rst) begin
//         if (rst) begin
//             xnor_out_r       <= '0; 
//             count_ones_out_r <= '0; 
//             accum_r          <= '0;
//             input_count_r    <= '0;
//             y_r              <= '0; 
//             valid_r1 <= 1'b0; valid_r2 <= 1'b0; valid_r3 <= 1'b0; valid_r4 <= 1'b0;
//             last_r1 <= 1'b0; last_r2 <= 1'b0; last_r3 <= 1'b0;
//         end else if (en) begin 

//             /* Stage 1*/ 
//             xnor_out_r <= x ~^ w;
//             valid_r1   <= valid_in; 
//             last_r1    <= last;

//             /* Stage 2 */
//             count_ones_out_r <= $countones(xnor_out_r);
//             valid_r2         <= valid_r1;
//             last_r2          <= last_r1;

//             /* Stage 3*/
//             if(valid_r2) begin
//                 accum_r       <= accum_r + count_ones_out_r;
//                 input_count_r <= input_count_r + 1'b1;
//             end
//             //last_r3 <= last_r2;
//             valid_r3 <= valid_r2;
//             last_r3  <= last_r2;

//             /* Stage 4 */
//             // need to fix the logic for valid
//             // if the last signal is true then we can output the result
//             if (last_r3) begin
//                 y_r      <= (input_count_r >= THRESHOLD_BITS) ? 1'b1 : 1'b0;
//                 accum_r  <= '0; // reset the accumulator
//                 valid_r4 <= 1'b1; 
//             end else begin 
//                 y_r      <= '0;
//                 valid_r4 <= '0; 
//             end 
//         end
//     end

//     assign y            = y_r;
//     assign valid_out    = valid_r4;
//     assign popcount_out = accum_r;

// endmodule

module neuron #(
    parameter NUM_WEIGHTS = 4,
    parameter NUM_INPUTS = 4, 
    parameter int THRESHOLD = 4,
    parameter int POPCOUNT_WIDTH = 32
)
(
    input logic clk, 
    input logic rst, 
    input logic en, 
    input logic valid_in,
    input logic last,
    input logic [NUM_WEIGHTS-1:0] w,
    input logic [NUM_INPUTS-1:0] x,
    output logic y,
    output logic [POPCOUNT_WIDTH-1:0] popcount_out,
    output logic valid_out
);

    // Pipeline Registers
    logic [$clog2(NUM_WEIGHTS+1)-1:0] count_ones_out_r;
    logic [POPCOUNT_WIDTH-1:0] accum_r;
    logic [POPCOUNT_WIDTH-1:0] accum_next;
    logic [POPCOUNT_WIDTH-1:0] popcount_out_r;
    
    // Status Registers
    logic valid_r1, valid_out_r;
    logic last_r1;
    logic y_r;
    
    always_comb begin
        accum_next = accum_r;
        if(valid_r1) begin
            accum_next = accum_r + count_ones_out_r;
        end
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            count_ones_out_r <= '0; 
            accum_r          <= '0;
            y_r              <= '0; 
            valid_r1 <= 1'b0;
            valid_out_r <= 1'b0; 
            last_r1 <= 1'b0; 
            popcount_out_r   <= '0; 
        end else if (en) begin 
            valid_out_r <= 1'b0;
            /* Stage 1*/ 
            count_ones_out_r <= $countones(x ~^ w);
            valid_r1   <= valid_in; 
            last_r1    <= last;

            /* Stage 2 */
            if(last_r1 && valid_r1) begin
                y_r     <= (accum_next >= THRESHOLD);
                valid_out_r <= 1'b1;
                accum_r <= '0;
                popcount_out_r <= accum_next;
            end else begin
                y_r <= 1'b0;
                accum_r <= accum_next;
            end
        end
    end

    assign y            = y_r;
    assign valid_out    = valid_out_r;
    assign popcount_out = popcount_out_r;

endmodule
