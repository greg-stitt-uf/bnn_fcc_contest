module bnn_fcc #(
    parameter int INPUT_DATA_WIDTH  = 16,
    parameter int INPUT_BUS_WIDTH   = 32,
    parameter int CONFIG_BUS_WIDTH  = 32,
    parameter int OUTPUT_DATA_WIDTH = 4,
    parameter int OUTPUT_BUS_WIDTH  = 8,

    parameter int TOTAL_LAYERS = 4,  // Includes input, hidden, and output
    parameter int TOPOLOGY[TOTAL_LAYERS] = '{0: 784, 1: 256, 2: 256, 3: 10, default: 0},  // 0: input, TOTAL_LAYERS-1: output

    parameter bit PARALLELIZE_LAYERS = 1'b0,
    parameter int PARALLEL_NEURONS   = 1,
    parameter int PARALLEL_INPUTS    = 32
) (
    input logic clk,
    input logic rst,

    // AXI streaming configuration interface (consumer)
    input  logic                          config_valid,
    output logic                          config_ready,
    input  logic [  CONFIG_BUS_WIDTH-1:0] config_data,
    input  logic [CONFIG_BUS_WIDTH/8-1:0] config_keep,
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
        config_ready = 1'b1;
        data_in_ready = 1'b1;
    end

endmodule
