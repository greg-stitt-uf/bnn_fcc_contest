module bnn_layer #(
    parameter CONFIG_WIDTH = 64,
    parameter INPUT_WIDTH = 64,
    parameter NEURON_PROCESSORS= 8,
    parameter NEURONS = 256,
    parameter INPUT_NEURONS = 784
)(
    input  logic clk,
    input  logic rst,

    input logic start_input,
    input logic [INPUT_WIDTH-1:0] actual_input,

    // RAM interfaces
    input logic start_thresholds,
    input logic start_weights,
    input logic [CONFIG_WIDTH-1:0] config_stream, //all thresholds and weights are stored in ram before input starts

    // output stream
    output logic start_output, //
    output logic [CONFIG_WIDTH-1:0] layer_out //output this the same way i got input
);

    localparam NEURONS_PER_PROC = NEURONS / NEURON_PROCESSORS; 

    localparam WEIGHTS_PER_PROC = INPUT_NEURONS * NEURONS_PER_PROC;
    localparam WEIGHT_WORDS     = WEIGHTS_PER_PROC / CONFIG_WIDTH;
    

    // RAMS for weights and thresholds
    logic [CONFIG_WIDTH-1:0] weight_rams [NEURON_PROCESSORS-1:0][WEIGHT_WORDS-1:0]; 
    logic [9:0] threshold_rams [NEURON_PROCESSORS-1:0][NEURONS_PER_PROC-1:0];

    // 
    logic writing_weights, writing_thresholds;

    logic [$clog2(WEIGHT_WORDS):0] weight_addr;
    logic [$clog2(NEURON_PROCESSORS):0] proc_sel;
    logic [$clog2(NEURONS):0] thresh_addr;


    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            writing_weights    <= 0;
            writing_thresholds <= 0;
            weight_addr <= 0;
            proc_sel    <= 0;
            thresh_addr <= 0;
        end else begin

            if (start_weights) begin
                writing_weights <= 1;
                weight_addr <= 0;
                proc_sel <= 0;
            end

            if (start_thresholds) begin
                writing_thresholds <= 1;
                thresh_addr <= 0;
            end

            // ======================
            // Load weights
            // ======================
            if (writing_weights) begin
                weight_rams[proc_sel][weight_addr] <= config_stream;

                if (proc_sel == NEURON_PROCESSORS-1) begin
                    proc_sel <= 0;
                    weight_addr <= weight_addr + 1;
                end else begin
                    proc_sel <= proc_sel + 1;
                end

                if (weight_addr == WEIGHT_WORDS-1 &&
                    proc_sel == NEURON_PROCESSORS-1) begin
                    writing_weights <= 0;
                end
            end

            // ======================
            // Load thresholds
            // ======================
            if (writing_thresholds) begin
                threshold_rams[thresh_addr] <= config_stream[9:0];
                threshold_rams[thresh_addr+1] <= config_stream[41:32];
                thresh_addr <= thresh_addr + 2;

                if (thresh_addr == NEURONS-1) begin
                    writing_thresholds <= 0;
                end
            end
        end
    end
endmodule