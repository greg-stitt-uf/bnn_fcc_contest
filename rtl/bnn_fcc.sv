module bnn_fcc #(
    parameter int INPUT_DATA_WIDTH  = 8,
    parameter int INPUT_BUS_WIDTH   = 64,
    parameter int CONFIG_BUS_WIDTH  = 64,
    parameter int OUTPUT_DATA_WIDTH = 4,
    parameter int OUTPUT_BUS_WIDTH  = 8,

    parameter int TOTAL_LAYERS = 4,  // Includes input, hidden, and output
    parameter int TOPOLOGY[TOTAL_LAYERS] = '{0: 784, 1: 256, 2: 256, 3: 10, default: 0},  // 0: input, TOTAL_LAYERS-1: output

    parameter int PARALLEL_INPUTS = 8,
    parameter int PARALLEL_NEURONS[TOTAL_LAYERS-1] = '{default: 8}
) (
    input logic clk,
    input logic rst,

    // AXI streaming configuration interface (consumer)
    input  logic                          config_valid,
    output logic                          config_ready,
    input  logic [  CONFIG_BUS_WIDTH-1:0] config_data,
    input  logic [(CONFIG_BUS_WIDTH/8)-1:0] config_keep,
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

    always_comb begin
        config_ready  = 1'b1;
        data_in_ready = 1'b1;
    end


    // will read the header fields and store it
    config_manager #(
        .BUS_WIDTH(CONFIG_BUS_WIDTH)
    ) config_manager_inst (
        .clk(clk),
        .rst(rst),
        .config_data_in(config_data),
        .config_valid(config_valid),
        .config_keep(config_keep),
        .config_last(config_last),
        .config_ready(config_ready),

        .reserved(reserved),
        .total_bytes(total_bytes),
        .bytes_per_neuron(bytes_per_neuron),
        .num_neurons(num_neurons),
        .layer_inputs(layer_inputs),
        .layer_id(layer_id),
        .msg_type(msg_type)
    );
    
    // will read the image data and push out the data to the neurons as it's being streamed in
    // img_data_out: logic[INPUT_DATA_WIDTH/4-1:0] img_data_out[INPUT_BUS_WIDTH/4];
    // aka 4 16-bit logics that hold 2 8-bit pixel values for a total of 8 image data streams
    data_in #(
        .INPUT_BUS_WIDTH(INPUT_BUS_WIDTH)
    ) data_in_inst (
        .clk(clk),
        .rst(rst),
        .data_in_valid(data_in_valid),
        .data_in_ready(data_in_ready),
        .data_in_data(data_in_data),
        .data_in_keep(data_in_keep),
        .data_in_last(data_in_last),

        .reserved(reserved),
        .total_bytes(total_bytes),
        .bytes_per_neuron(bytes_per_neuron),
        .num_neurons(num_neurons),
        .layer_inputs(layer_inputs),
        .layer_id(layer_id),
        .msg_type(msg_type),

        .img_data_out(img_data_out)
    );



endmodule
