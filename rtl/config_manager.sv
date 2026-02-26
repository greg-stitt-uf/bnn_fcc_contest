module config_manager
#(parameter int BUS_WIDTH,
  parameter int LAYERS,
  parameter int PARALLEL_INPUTS, 
  parameter int PARALLEL_NEURONS
)(
    input logic clk, 
    input logic rst, 
    input logic config_data,
    input logic config_valid, 
    input logic config_keep,
    input logic config_last, 
    output logic config_ready, 
    output logic weight_ram_wr_data, 
    output logic weight_ram_wr_en, 
    output logic threshold_ram_wr_data,
    output logic threshold_ram_wr_en
);

    
endmodule
