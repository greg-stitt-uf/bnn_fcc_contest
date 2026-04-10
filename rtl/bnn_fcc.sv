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
    output logic [OUTPUT_BUS_WIDTH/8-1:0] data_out_keep, // a single bit
    output logic                          data_out_last
);

    // current header being read in
    typedef struct packed {
        logic [7:0]               msg_type;
        logic [7:0]               layer_id;
        logic [15:0]              layer_inputs;
        logic [15:0]              num_neurons;
        logic [15:0]              bytes_per_neuron;
        logic [31:0]              total_bytes;
        logic [31:0]              reserved;
    } header_t;
    header_t cfg_header_out;
    logic cfg_header_out_valid;

    logic [INPUT_BUS_WIDTH-1:0] cfg_data_out;
    config_manager #(
        .CONFIG_BUS_WIDTH(CONFIG_BUS_WIDTH)
    ) config_manager_inst (
        .clk(clk),
        .rst(rst),
        .config_valid(config_valid),
        .config_ready(config_ready),
        .config_data(config_data),
        .config_keep(config_keep),
        .config_last(config_last),
        .msg_type(cfg_header_out.msg_type),
        .layer_id(cfg_header_out.layer_id),
        .layer_inputs(cfg_header_out.layer_inputs),
        .num_neurons(cfg_header_out.num_neurons),
        .bytes_per_neuron(cfg_header_out.bytes_per_neuron),
        .total_bytes(cfg_header_out.total_bytes),
        .reserved(cfg_header_out.reserved)
    );
    



endmodule
