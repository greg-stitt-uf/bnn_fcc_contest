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

    typedef struct packed {
        logic [31:0] weight;
    } weight_t;

    typedef enum {
        HEADER,
        PAYLOAD
    } state_t;
    state_t curr_state, next_state;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            curr_state <= HEADER;
            header <= '0; // clears header
        end else begin
            curr_state <= next_state;
        end
    end

    always_comb begin
        case (curr_state)
            HEADER: begin
                if (config_valid && !config_last) begin
                    header.msg_type = (config_keep[0]) ? config_data_in[7:0] : '0;
                    header.layer_id = (config_keep[1]) ? config_data_in[15:8] : '0;
                    header.layer_inputs[7:0] = (config_keep[2]) ? config_data_in[23:16] : '0;
                    header.layer_inputs[15:8] = (config_keep[3]) ? config_data_in[31:24] : '0;
                    header.num_neurons[7:0] = (config_keep[4]) ? config_data_in[39:32] : '0;
                    header.num_neurons[15:8] = (config_keep[5]) ? config_data_in[47:40] : '0;
                    header.bytes_per_neuron[7:0] = (config_keep[6]) ? config_data_in[55:48] : '0;
                    header.bytes_per_neuron[15:8] = (config_keep[7]) ? config_data_in[63:56] : '0;
                    next_state = HEADER;
                end else if (config_valid && config_last) begin
                    header.total_bytes[7:0] = (config_keep[0]) ? config_data_in[7:0] : '0;
                    header.total_bytes[15:8] = (config_keep[1]) ? config_data_in[15:8] : '0;
                    header.total_bytes[23:16] = (config_keep[2]) ? config_data_in[23:16] : '0;
                    header.total_bytes[31:24] = (config_keep[3]) ? config_data_in[31:24] : '0;
                    header.reserved[7:0] = (config_keep[4]) ? config_data_in[39:32] : '0;
                    header.reserved[15:8] = (config_keep[5]) ? config_data_in[47:40] : '0;
                    header.reserved[23:16] = (config_keep[6]) ? config_data_in[55:48] : '0; 
                    header.reserved[31:24] = (config_keep[7]) ? config_data_in[63:56] : '0;
                    next_state = PAYLOAD;
                end else begin
                    next_state = HEADER;
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


