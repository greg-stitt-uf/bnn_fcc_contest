// Greg Stitt
//
// MODULE: bnn_fcc_timing
//
// DESCRIPTION:
// Top-level module for performing out-of-context timing analysis of the bnn_fcc module.
// This module simply instantiating bnn_fcc and registers the I/O for more accurate
// timing analysis.
//
// INSTRUCTIONS: Update the application-specific parameters as required by your implementation.
// This should only be PARALLEL_INPUTS and PARALLEL_NEURONS, unless you added more parameters.

module bnn_fcc_timing #(
    parameter int INPUT_DATA_WIDTH  = 8,
    parameter int INPUT_BUS_WIDTH   = 64,
    parameter int CONFIG_BUS_WIDTH  = 64,
    parameter int OUTPUT_DATA_WIDTH = 4,
    parameter int OUTPUT_BUS_WIDTH  = 8,

    parameter int TOTAL_LAYERS = 4,
    parameter int TOPOLOGY[TOTAL_LAYERS] = '{0: 784, 1: 256, 2: 256, 3: 10, default: 0},

    // TODO: UPDATE BASED ON IMPLEMENTATION-SPECIFIC PARAMETERS
    parameter int PARALLEL_INPUTS = 8,
    parameter int PARALLEL_NEURONS[TOTAL_LAYERS-1] = '{8, 8, 10}    
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
    logic                          config_valid_r;
    logic                          config_ready_s;
    logic [  CONFIG_BUS_WIDTH-1:0] config_data_r;
    logic [CONFIG_BUS_WIDTH/8-1:0] config_keep_r;
    logic                          config_last_r;

    logic                         data_in_valid_r;
    logic                         data_in_ready_s;
    logic [  INPUT_BUS_WIDTH-1:0] data_in_data_r;
    logic [INPUT_BUS_WIDTH/8-1:0] data_in_keep_r;
    logic                         data_in_last_r;

    logic                          data_out_valid_s;
    logic                          data_out_ready_r;
    logic [  OUTPUT_BUS_WIDTH-1:0] data_out_data_s;
    logic [OUTPUT_BUS_WIDTH/8-1:0] data_out_keep_s;
    logic                          data_out_last_s;

    bnn_fcc #(
        .INPUT_DATA_WIDTH (INPUT_DATA_WIDTH),
        .INPUT_BUS_WIDTH  (INPUT_BUS_WIDTH),
        .CONFIG_BUS_WIDTH (CONFIG_BUS_WIDTH),
        .OUTPUT_DATA_WIDTH(OUTPUT_DATA_WIDTH),
        .TOTAL_LAYERS     (TOTAL_LAYERS),
        .TOPOLOGY         (TOPOLOGY),
        .PARALLEL_INPUTS  (PARALLEL_INPUTS),
        .PARALLEL_NEURONS (PARALLEL_NEURONS)
    ) DUT (
        .clk          (clk),
        .rst          (rst),
        .config_valid (config_valid_r),
        .config_ready (config_ready_s),
        .config_data  (config_data_r),
        .config_keep  (config_keep_r),
        .config_last  (config_last_r),
        .data_in_valid(data_in_valid_r),
        .data_in_ready(data_in_ready_s),
        .data_in_data (data_in_data_r),
        .data_in_keep (data_in_keep_r),
        .data_in_last (data_in_last_r),

        .data_out_valid(data_out_valid_s),
        .data_out_ready(data_out_ready_r),
        .data_out_data (data_out_data_s),
        .data_out_keep (data_out_keep_s),
        .data_out_last (data_out_last_s)
    );

    always_ff @(posedge clk) begin
        config_valid_r <= config_valid;
        config_ready <= config_ready_s;
        config_data_r <= config_data;
        config_keep_r <= config_keep;
        config_last_r <= config_last;

        data_in_valid_r <= data_in_valid;
        data_in_ready <= data_in_ready_s;
        data_in_data_r <= data_in_data;
        data_in_keep_r <= data_in_keep;
        data_in_last_r <= data_in_last;

        data_out_valid <= data_out_valid_s;
        data_out_ready_r <= data_out_ready;
        data_out_data <= data_out_data_s;
        data_out_keep <= data_out_keep_s;
        data_out_last <= data_out_last_s;
    end

endmodule
