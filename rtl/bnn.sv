module bnn #(
    parameter int LAYERS  = 3,
    parameter int NUM_INPUTS   = 64,
    parameter int NUM_NEURONS   = 64,
    parameter int PARALLEL_INPUTS  = 32,
    parameter int PARALLEL_NEURONS = 4,
    parameter int MAX_PARALLEL_INPUTS = 4,
    parameter int THRESHOLD_DATA_WIDTH = 67
)(
        input logic clk,
        input logic rst,
        input logic en,
        logic ready,
        logic [MAX_PARALLEL_INPUTS-1:0] weight_wr_data,
        logic [LAYERS-1:0] weight_wr_en,
        logic [THRESHOLD_DATA_WIDTH-1:0] threshold_wr_data,
        logic [LAYERS-1:0] threshold_wr_en,
        logic [PARALLEL_INPUTS-1:0] data_in,
        logic data_in_valid,
        output logic data_out,
        logic [THRESHOLD_DATA_WIDTH-1:0] count_out,
        logic data_out_valid
);

// 784 then 256 (layer 1) then 256 (layer 2) then 10 (layer 3)

    layer #(
        .BEAT_WIDTH(16),
        .NUM_INPUTS(784),
        .NUM_NEURONS(256),
        .POPCOUNT_WIDTH(32)
    ) L1 (
        .clk(clk),
        .x(),
        .rst(rst),
        .en(en),
        .valid_in(data_in_valid),
        .last(),
        .w(),
        .out(),
        .popcount_outs(),
        .valid_outs()
    );

    layer #(
        .BEAT_WIDTH(16),
        .NUM_INPUTS(256),
        .NUM_NEURONS(256),
        .POPCOUNT_WIDTH(32)
    ) L2 (
        .clk(clk),
        .x(),
        .rst(rst),
        .en(en),
        .valid_in(data_in_valid),
        .last(),
        .w(),
        .out(),
        .popcount_outs(),
        .valid_outs()
    );

    layer #(
        .BEAT_WIDTH(16),
        .NUM_INPUTS(256),
        .NUM_NEURONS(10),
        .POPCOUNT_WIDTH(32)
    ) L_OUT (
        .clk(clk),
        .x(),
        .rst(rst),
        .en(en),
        .valid_in(data_in_valid),
        .last(),
        .w(),
        .out(),
        .popcount_outs(),
        .valid_outs()
    );

endmodule
