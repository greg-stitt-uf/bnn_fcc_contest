module config_manager (
    input  logic         clk,
    input  logic         rst,

    input  logic         s_valid,
    input  logic [63:0]  s_data,

    output logic         header_valid,
    //output config_header_t header
);

    typedef enum logic [1:0] {
        IDLE, 
        HEAD1, 
        HEAD2, 
        PAYLOAD } state_t;

    logic [7:0]  msg_type;
    logic [7:0]  layer_id;
    logic [15:0] num_neurons;
    logic [15:0] bytes_per_neuron;
    logic [31:0] total_bytes;


    always_ff @(posedge clk or posedge rst) begin
        
    end

endmodule