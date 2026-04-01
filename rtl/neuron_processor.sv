//inputs : input, weight, threshold, valid_in, last/eof (for not all inputs coming in at once for some reason)
//outputs : one-bit activation output, multi-bit popcount, valid_out
//need some registers in the middle of this to get high clock speed

module neuron_processor #(
    parameter int INPUT_WIDTH = 8,
    parameter int NEURON_COUNT = 784
) (
    input logic clk,
    input logic rst,
    input logic [INPUT_WIDTH-1:0] in,
    input logic [INPUT_WIDTH-1:0] weights,
    input logic [$clog2(NEURON_COUNT + 1)-1:0] threshold,

    input logic valid_in,
    input logic last,

    output logic [$clog2(NEURON_COUNT + 1)-1:0] popcount,
    output logic valid_out,
    output logic y 
);
    localparam int beat_count = 8/INPUT_WIDTH - 1;

    logic [INPUT_WIDTH-1:0] xnor_r;
    logic [$clog2(NEURON_COUNT + 1)-1:0] popcount_r, stored_popcount_r, adder_wire;
    logic [$clog2(NEURON_COUNT + 1)-1:0] threshold1_r, threshold2_r;
    
    logic last1_r, last2_r, last3_r;

    logic y_r;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            stored_popcount_r <= 0;
            popcount_r        <= 0;
            xnor_r            <= 0;
            last1_r           <= 0;
            last2_r           <= 0;
            last3_r           <= 0;
            y_r               <= 0;
        end else begin
        //stage 1
            if (valid_in) xnor_r <= in ~^ weights;
            last1_r              <= last;
            threshold1_r         <= threshold;

            //stage 2
            popcount_r       <= $countones(xnor_r);
            last2_r          <= last1_r;
            threshold2_r     <= threshold1_r;

            //output stage
            stored_popcount_r <= adder_wire;
            y_r               <= (adder_wire >= threshold2_r);
            last3_r           <= last2_r;
        end
    end

    always_comb begin
        adder_wire = (last3_r) ? popcount_r : popcount_r + stored_popcount_r; 
        popcount = stored_popcount_r;
        valid_out = last3_r;
        y = y_r;
    end
endmodule