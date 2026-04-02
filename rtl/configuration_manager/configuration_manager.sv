module config_manager #(
    parameter int BUS_WIDTH       = 64, // bus stores 8 bytes
    parameter int LAYERS           = 3, // 3 layers in the bnn
    parameter int PARALLEL_INPUTS  = 8, // Pw and Pi
    parameter int PARALLEL_NEURONS [LAYERS] = '{default: 8} // packs array with default value 8
) (
    input logic                          clk,
    input logic                          rst,
    input logic [BUS_WIDTH-1:0]          config_data_in,
    input logic                          config_valid,
    input logic [(BUS_WIDTH/8)-1:0]      config_keep,
    input logic                          config_last,
    output logic                         config_ready,
    output logic [BUS_WIDTH-1:0]         weight_wr_data,
    output logic [LAYERS-1:0]            weight_wr_en,
    output logic [BUS_WIDTH-1:0]         threshold_wr_data,
    output logic [LAYERS-1:0]            threshold_wr_en
);
    

    /*
    Config manager follows a network-style communcation protocol. 
    Config header = 128 bits
        [7:0] = msg_type; 0=Weights, 1=Thresholds
        [15:8] = layer_id; index of current layer (1,2,3,..)
        [31:16] = layer_inputs; # of inputs fanned into layer (ignore when pushing threshholds)
        [47:32] = num_neurons; # of neurons in layer_id
        [63:48] = bytes_per_neuron; # of bytes in payload per neuron
        [95:64] = total_bytes; total # of bytes for the message
        [127:96] = reserved, ignore last 4 bytes for now
    */

    // 128 bit bus MSB-->LSB
    typedef struct packed {
        logic [31:0] reserved;
        logic [31:0] total_bytes;
        logic [15:0] bytes_per_neuron;
        logic [15:0] num_neurons;
        logic [15:0] layer_inputs;
        logic [7:0]  layer_id;
        logic [7:0]  msg_type;
    } config_header_t;
    config_header_t header;

    typedef enum {
        CONFIG1,
        CONFIG2,
        PAYLOAD
    } state_t;
    state_t curr_state, next_state;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            curr_state <= CONFIG1;
            header <= '0; // clears header
        end else begin
            curr_state <= next_state;
        end
    end

    always_comb begin
        case (curr_state)
            CONFIG1: begin
                if (config_valid) begin
                    header.msg_type = config_data_in[7:0];
                    header.layer_id = config_data_in[15:8];
                    header.layer_inputs = config_data_in[31:16];
                    header.num_neurons = config_data_in[47:32];
                    header.bytes_per_neuron = config_data_in[63:48];
                    next_state = CONFIG2;
                end else begin
                    next_state = CONFIG1;
                end
            end

            CONFIG2: begin
                if (config_valid) begin
                    header.total_bytes = config_data_in[31:0];
                    header.reserved = config_data_in[63:32];
                end
            end 

            PAYLOAD: begin
                
            end
        endcase
    end

    // Store the config header at first few addresses in RAM component
    // We'll create a ram component that can be addressed with axi for pipelined read/write potentially
    // Create a basic ram component to just read the inputs and store, tryd
    
    // process to read in 

endmodule


