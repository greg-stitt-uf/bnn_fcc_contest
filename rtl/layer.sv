module layer #(
    parameter BEAT_WIDTH = 16,
    parameter NUM_INPUTS = 784,
    parameter NUM_NEURONS = 256,
    parameter NUM_WEIGHTS = NUM_INPUTS,
    parameter int POPCOUNT_WIDTH = 32,
    parameter int NUM_BEATS = $ceil(NUM_INPUTS / BEAT_WIDTH) // 784/16 = 49 beats
)(
    input logic clk,
    input logic [BEAT_WIDTH-1:0] x,
    output logic [NUM_NEURONS-1:0] out,
    input logic rst, 
    input logic en, 
    input logic valid_in,
    input logic last,
    input logic [NUM_NEURONS-1:0][BEAT_WIDTH-1:0] w,
    output logic [NUM_NEURONS-1:0][POPCOUNT_WIDTH-1:0] popcount_outs,
    output logic [NUM_NEURONS-1:0] valid_outs

);
    generate
        for (genvar i = 0; i < NUM_NEURONS; i++) begin : neurons_loop
            neuron #(
                .NUM_WEIGHTS(BEAT_WIDTH),
                .NUM_INPUTS(BEAT_WIDTH), 
                .THRESHOLD_BITS(3), // abritary for now
                .POPCOUNT_WIDTH(POPCOUNT_WIDTH)
            ) N (
                .clk(clk),
                .rst(rst),
                .en(en),
                .valid_in(valid_in),
                .last(last),
                .w(w[i]),
                .x(x),
                .y(out[i]),
                .popcount_out(popcount_outs[i]),
                .valid_out(valid_outs[i])
            );
        end
    endgenerate
endmodule