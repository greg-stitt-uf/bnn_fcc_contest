// Layer 0 (F[0] inputs per neuron):
//   Neuron 0: W0,0 ... W0,F[0]-1 | Threshold0
//   Neuron 1: W1,0 ... W1,F[0]-1 | Threshold1
//   ...
//   Neuron N[0]-1: ...           | ThresholdN[0]-1

// Layer 1 (F[1] inputs per neuron):
//   Neuron 0: W0,0 ... W0,F[1]-1 | Threshold0
//   Neuron 1: W1,0 ... W1,F[1]-1 | Threshold1
//   ...

module bnn_fcc #(
    parameter int INPUT_DATA_WIDTH  = 8,
    parameter int INPUT_BUS_WIDTH   = 64,
    parameter int CONFIG_BUS_WIDTH  = config_pkg::CONFIG_BUS_WIDTH,
    parameter int OUTPUT_DATA_WIDTH = 4,
    parameter int OUTPUT_BUS_WIDTH  = 8,

    parameter int TOTAL_LAYERS = 4,  // Includes input, hidden, and output
    parameter int TOPOLOGY[TOTAL_LAYERS] = '{0: 784, 1: 256, 2: 256, 3: 10, default: 0},  // 0: input, TOTAL_LAYERS-1: output

    parameter int PARALLEL_INPUTS = 8,
    parameter int PARALLEL_NEURONS[TOTAL_LAYERS-1] = '{default: 8},

    localparam int THRESHOLD_DATA_WIDTH = 32
) (
    input logic clk,
    input logic rst,

    // AXI streaming configuration interface (consumer)
    input  logic                          config_valid,
    output logic                          config_ready,
    input  logic [  CONFIG_BUS_WIDTH-1:0] config_data,
    input  logic [config_pkg::CONFIG_KEEP_SIZE-1:0] config_keep,
    input  logic                          config_last,

    // AXI streaming image input interface (consumer)
    input  logic                         data_in_valid,
    output logic                         data_in_ready,
    input  logic [  INPUT_BUS_WIDTH-1:0] data_in_data,
    input  logic [INPUT_BUS_WIDTH/8-1:0] data_in_keep,
    input  logic                         data_in_last,

    // AXI streaming classification output interface (producer)
    output logic                          data_out_valid,
    input  logic                          data_out_ready,
    output logic [  OUTPUT_BUS_WIDTH-1:0] data_out_data,
    output logic [OUTPUT_BUS_WIDTH/8-1:0] data_out_keep,
    output logic                          data_out_last
);
    localparam int LAYERS = TOTAL_LAYERS - 1;

    function automatic int get_max_parallel_inputs();
        int max_v = PARALLEL_INPUTS;
        for (int i = 0; i < LAYERS - 1; i++) begin
            if (PARALLEL_NEURONS[i] > max_v) max_v = PARALLEL_NEURONS[i];
        end
        return max_v;
    endfunction

    localparam int NUM_NEURONS[LAYERS] = TOPOLOGY[1:LAYERS];
    localparam int INPUT_BUS_ELEMENTS = INPUT_BUS_WIDTH / INPUT_DATA_WIDTH;
    localparam int INPUT_BINARIZATION_THRESHOLD = 1 << (INPUT_DATA_WIDTH - 1);
    localparam int MAX_PARALLEL_INPUTS = get_max_parallel_inputs();

    logic [INPUT_DATA_WIDTH-1:0] pixels[INPUT_BUS_ELEMENTS];

    logic [MAX_PARALLEL_INPUTS-1:0] weight_wr_data;
    logic [             LAYERS-1:0] weight_wr_en;
    logic [THRESHOLD_DATA_WIDTH-1:0] threshold_wr_data;
    logic [              LAYERS-1:0] threshold_wr_en;

    logic bnn_ready;
    logic [PARALLEL_INPUTS-1:0] bnn_data_in;
    logic                       bnn_data_in_valid;
    logic [THRESHOLD_DATA_WIDTH-1:0] bnn_count_out[PARALLEL_NEURONS[LAYERS-1]];
    logic                            bnn_count_valid;

    initial begin
        if (INPUT_BUS_ELEMENTS != PARALLEL_INPUTS) $fatal(1, "bnn_fcc requires PARALLEL_INPUTS to match the pixels/beat");
        for (int i = 0; i < LAYERS - 1; i++) begin
            if (PARALLEL_NEURONS[i] != PARALLEL_INPUTS) $fatal(1, "bnn_fcc requires PARALLEL_NEURONS to match PARALLEL_INPUTS in all hidden layers");
        end
        if (TOPOLOGY[0] % PARALLEL_INPUTS) $fatal(1, "bnn_fcc requires total inputs to be a multiple of PARALLEL_INPUTS."); 
        if (PARALLEL_INPUTS != 8) $fatal(1, "bnn_fcc currently requires PARALLEL_INPUTS=8");
    end

    config_manager #(
        .BUS_WIDTH        (INPUT_BUS_WIDTH),        
        .LAYERS           (LAYERS),        
        .PARALLEL_INPUTS  (PARALLEL_INPUTS),
        .PARALLEL_NEURONS (PARALLEL_NEURONS)
    ) config_manager (
        .clk                  (clk),
        .rst                  (rst),
        .config_data_in       (config_data),
        .config_valid         (config_valid),
        .config_keep          (config_keep),
        .config_last          (config_last),
        .config_ready         (config_ready),
        .weight_ram_wr_data   (weight_wr_data),
        .weight_ram_wr_en     (weight_wr_en),
        .threshold_ram_wr_data(threshold_wr_data),
        .threshold_ram_wr_en  (threshold_wr_en)
    );

    assign pixels = {<<INPUT_DATA_WIDTH{data_in_data}};
    assign data_in_ready = bnn_ready && config_ready;

    always_ff @(posedge clk) begin : binarization
        if (data_in_ready) begin
            for (int i = 0; i < INPUT_BUS_ELEMENTS; i++) bnn_data_in[i] <= pixels[i] >= INPUT_BINARIZATION_THRESHOLD;
            bnn_data_in_valid <= data_in_valid;
        end
    end

    bnn #(
        .LAYERS              (LAYERS),
        .NUM_INPUTS          (TOPOLOGY[0]),
        .NUM_NEURONS         (NUM_NEURONS),
        .PARALLEL_INPUTS     (INPUT_BUS_WIDTH / 8),
        .PARALLEL_NEURONS    (PARALLEL_NEURONS),
        .MAX_PARALLEL_INPUTS (MAX_PARALLEL_INPUTS),
        .THRESHOLD_DATA_WIDTH(THRESHOLD_DATA_WIDTH)
    ) bnn_main (
        .clk              (clk),
        .rst              (rst),
        .en               (data_out_ready),
        .ready            (bnn_ready),
        .weight_wr_data   (weight_wr_data),
        .weight_wr_en     (weight_wr_en),
        .threshold_wr_data(threshold_wr_data),
        .threshold_wr_en  (threshold_wr_en),
        .data_in          (bnn_data_in),
        .data_in_valid    (bnn_data_in_valid),
        .data_out         (),
        .count_out        (bnn_count_out),
        .data_out_valid   (bnn_count_valid)
    );

    logic [THRESHOLD_DATA_WIDTH-1:0] max_count;

    always_comb begin : argmax
        if (PARALLEL_NEURONS[LAYERS-1] != TOPOLOGY[LAYERS]) $fatal(1, "bnn_fcc currently requires output layer neurons to match PARALLEL_NEURONS for that layer");
        
        data_out_valid = bnn_count_valid;

        // This is beyond horrible for synthesis and is solely intended to test the testbench framework.
        max_count = bnn_count_out[0];
        data_out_data = '0;
        for (int i=1; i < TOPOLOGY[LAYERS]; i++) begin
            if (bnn_count_out[i] > max_count) begin 
                data_out_data = i;
                max_count = bnn_count_out[i];
            end
        end
    end

endmodule
