The purpose of this text file is to take annotated notes on stitt's testbench and understand it's input stimuli, verification, and anything else.

# Intro

- Can be tested for either the custom topology or the apple topology [784, 256, 256, 10]
- Weights and thresholds on the apply topology come from python and trained data
- bnn_fcc_tb_pkg.sv provides a BNN_FCC_Stimulus class that loads images from files or randomly generates test images (custom topology)
- When using it, test with a custom small topology first
- When using the apple topology, make sure BASE_DIR is the python training folder. Add a `sim` folder and throw questa in there so it works without having to change too much
- To fully pass testing, set TOGGLE_DATA_OUT_READY=1, CONFIG_VALID_PROBABILITY=0.8, and DATA_IN_VALID_PROBABILITY=0.8
- Leaving those values default initially will make initial testing easier. When measuring performance, leave them at their defaults to avoid artifically hurting performance.

# Parameters

| Name                      | Function                                                                                                                                                                                          |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| USE_CUSTOM_TOPOLOGY       | Enables user defined NN topology specified by CUSTOM_TOPOLOGY                                                                                                                                     |
| CUSTOM_LAYERS             | Total layers (includes input, hidden, output)**if**                                                                                                                                        |
| CUSTOM_TOPOLOGY           | Array defining neurons per layer. CUSTOM_TOPOLOGY[0] defined the number of inputs, rest are hidden, last is output                                                                                |
| NUM_TEST_IMAGES           | Number of stimulus images for simulation                                                                                                                                                          |
| VERIFY_MODEL              | Cross-check SV results against python (not applicable for custom topologies)                                                                                                                      |
| BASE_DIR                  | Path to python modeldata and test vectors (set relative to the sim's working directory)                                                                                                           |
| TOGGLE_DATA_OUT_READY     | Randomly toggles data_out_ready to simulate back-pressure. Must be enbaled to fully pass tests of the contest, disable to measure throughput and latency                                          |
| CONFIG_VALID_PROBABILITY  | 0->1 value that specifies the probability of the config bus providing valid data while DUT is ready. Used to simulate a slow upstream producer. Leave at 1 for testing,                           |
| DATA_IN_VALID_PROBABILITY | 0->1 value that specifies the probability of the data_in bus giving valid data while the DUT is ready. Used to simulate a slow upstream producer. Leave at 1 for testing, 0.8 for contest testing |
| TIMEOUT                   | Real-time value that specifies the max amount of time the testbench hould run before being terminated                                                                                             |
| CLK_PERIOD                | Self-explanatory                                                                                                                                                                                  |
| DEBUG                     | Set to print model details and inference trace for each layer                                                                                                                                     |


# BNN_FCC_TB

## Ports

### Parameters

- Defined above in table
- AXI Bus Config
- App config

  - INPUT_DATA_WIDTH is 8 bits,
  - INPUTS_PER_CYCLE is bus width / input width, so 64/8=8 (constant)
  - BYTES_PER_INPUT is data width / 8, so 8/8=1 (constant)
  - OUTPUT_DATA_WIDTH = 4, 4 bits represents 0-9
- Trained stuff shouldn't be changed for non-custom topology
- DUT config

  - can be modified
  - NON_INPUT_LAYERS is either CUSTOM_LAYERS-1 or TRAINED_LAYERS-1 for if a custom topology is used (constant)
  - PARALLEL_INPUTS is default to 8
  - PARALLEL_NEURONS[NON_INPUT_LAYERS]  is an array of NON_INPUT_LAYERS size, being 3 in this instance defaulted to 8,8,10

## Initialization

- ACTUAL_TOTAL_LAYERS depends on if a custom topology, it uses the defined custom layers or trained layers parameters (constant)
- ACTUAL_TOPOLOGY[ACTUAL_TOTAL_LAYERS] again depends on if a custom topology, and then uses either custom topology or the defined one (constat)
- Sone strings for the MNIST competition testing
- Assert 8-bit input data width
- `chance(real p)` function for probability. if p=1, $urandom is always less than 32-bit unsigned max value + 1, if p=0 it's always greater than it. probability is returned for this

## BNN_FCC_Model (500 lines)

Instantiated as `model` in the tesbench. Here is the rundown of it

- Typedefs

  - `weight_row_t[]` of type `bit` that is dynamically allocated and represents the row of weights for 1 neuron. it's the weight bits for 1 neuron
  - `layer_t[]` is of type `weight_row_t[]` is a dynamic array or a dynamic array of bits representing all the neuron weights for 1 layer.
  - `thresh_row_t[]` is of type `int` is a dynamic array of integers that store the the thresholds for a layer, aka one threshold per neuron
  - `bus_word_t` is of type `bit` that is a word of BUS_WIDTH size.
  - `bus_stream_t[]` is of type `bus_word_t` that is a dynamic array of `bus_word_t`'s that will hold an AXI-Style stream of list of bus words
  - `bus_keep_t` is of type `bit` that's `BUS_WIDTH/8-1:0` size that is the `tkeep` mask for one bus beat
  - `keep_stream_t[]` is of type `bus_keep_t` that is a dynamic array of  keep masks, where it holds one per bus word in the stream
  - `weight` is of type `layer_t` and is a dynamic array that has the dimensions [LAYER] [NEURON] [INPUT_BIT]
  - `threshold` is of type `thresh_row_t` and is a dynamic array that has the dimensions [LAYER] [NEURON]
  - `layer_outputs` is a 2D dynamically allocated `int` array that has dimensions [layer] [neuron] and is written out instead of using typedefs.
  - `num_layers` is of type `int` and is self explanatory. **does NOT iclude the input layer**
  - `topology` is a dynamic array of `int` that represents the topology, `topology[0]` is input, `topology[num_layers-1]` is output, eevrything inbetween is hidden
  - `is_loaded` and `outputs_valid` are bits that hold boolean values to those questions
  - `last_input` is a dynamic array of 8-bit values that holds the last input pushed in
- Functions

  - `new()`
    - Resets is_loaded and outputs_valid
  - `int compute_reference(input bit [7:0] img_data[])`
    - Checks if loaded first
    - Sets this.last_input to passed in `img_data`
    - Allocates a new array of `num_layers` for this.layer_outputs.
    - For layer `l` in `this.topology`
      - fan_in is `this.topology[l]`
      - n_neurons is `this.topology[l+1]`
      - For `n` in `n_neurons`
        - reset popcount
        - For `i` in `fan_in`
          - define `in_bit` and `w_bit`
          - if first layer, in_bit is 1 if `img_data[i] >= 8'd128` else 0
          - else in_bit is `(this.layer_outputs[l-1][i])`
          - w_bit is `this.weight[l][n][i]`
          - if in_bit == w_bit, increment popcount
        - if `l` is the last layer, `this.layer_outputs[l][n]` is equal to the popcount
        - else `this.layer_outputs[l][n]` is 1 if popcount >= `this.threshold[l][n]`, else 0
    - `this.outputs_valid = 1`
    - return `get_prediction()`
  - `int get_prediction()`
    - last = num_layers -1
    - max_val = -1
    - winner = 0
    - For `n` in `this.layer_outputs[last][n].size()`
      - compares last 10 neuron to see which final neuron has the highest popcount, picks the max, and returns the neuron number that has the highest popcount
  - `int get_layer_output(int layer_idx, int neuron_idx)`
    - Checks if outputs are valid
    - Checks if layer_idx is within range
    - Checks if neuron_idx is within range
    - `return layer_outputs[layer_idx][neuron_idx]`
  - Writing detailed comments for this one since i'm basically going to reading the output of this in the DUT for the testbench
  - `void get_layer_config(input int layer_idx, input bit is_threshold, output bus_stream_t stream, output keep_stream_t keep)`
    - `[$]` defined a queue
    - Define an 88-bit byte queue
    - Define a word queue of type `bus_word_t`
    - Define a keep queue of type `bus_keep_t`
    - Define fan_in, n_neurons, bytes_per_neuron, layer_inputs, total_payload_bytes, 128 bit header value
    - Define current word, current keep, bytes_per_beat, byte_count
    - Define w_idx, 8-bit byte_val, 32-bit t_val
    - Sets fan_in to `this.topology[layer_idx]`
    - Sets n_neurons to `this.topology[layer_idx+1]`
    - If threshold

      - bytes_per_neuron is 4 since they're 32-bit values
      - layer_inputs is 32, but should be ignored for thresholds
    - Else

      - bytes_per_neuron = (fan_in + 7) / 8, which is fan_in rounded up to the next # byte
      - layer_inputs = fan_in
    - total_payload_bytes = bytes_per_neuron * n_neurons
    - Build header with defined config
    - Reads 2 words, lower and upper 64 bits and assigns them to the right values
    - For `i` in 0->16, push the header bytes into the byte queue in little endian format
    - Generate payload bytes
    - For `n` in `n_neurons`

      - if threshold
        - t_val = `this.threshold[layer_idx][n]`
        - For `i` in 0->4, push threshold in little endian format (32 bits)
      - Else
        - w_idx = 0
        - For `b` in `bytes_per_neuron`
          - For `k` in 0->8
            - if (w_idx < fan)in) byte_val[k] = `this.weight[layer_idx][n][w_idx]`
            - else byte_val[k] = 1'b1; // padding bytes
            - w_idx++
          - push byte_val into the byte queue
    - bytes_per_beat is the BUS_WIDTH / 8
    - set byte_count and current_word to 8
    - `foreach (byte_q[i])`

      - `current_word[byte_count*8+:8] = byte_q[i]`
      - ^^^ This basically packs bytes for each 8 bits, so if byte_count==0, it writes to current_word[7:0], 1->[15:8], so on
      - byte_count++
      - if byte_count == bytes_per_beat
        - push current word to word queue
        - pushes 1 for  (BUS_WIDTH/8) bits, so it becomes 8'b11111111 for BUS_WIDTH=64, 4'b1111 if BUS_WIDTH=32
        - reset byte_count and current_word
    - for partial beats

      - push current_word to word queue
      - generate partial keep where
      - for `k` in `byte_count`, current_keep[k] = 1'b1
      - push current_keep to keep queue
    - declare stream be a new array of word_q.size()
    - declare keep to be a new array of keep_q.size()
    - `foreach (word_q[i])` stream[i] = word_q[i]; keep[i] = keep_q[i]
  - `void encode_configuration(output bus_stream_t full_stream, output keep_stream_t full_keep)`
    - create a bus stream and keep stream objects layer_stream and layer_keep respectively
    - reset full_stream and full_keep to be dynamic arrays of size 0
    - For `l` in num_layers
      - get_layer_config(l, 0, layer_stream, layer_keep)
      - concatenate full_stream with the new layer_stream, ditto for full_keep
      - if not the last layer
        - get_layer_config(l, 1, layer_stream, layer_keep)
        - concatenate
    - This function generates packets for each layer of weights and thresholds and appends them all together
  - `protected void load_single_layer(int l_idx, string w_file, string t_file)`
    - Won't go through all of this, but this reads one layer's weights and thresholds from 2 text files and stores them in the model's internal arrays.
    - It opens the weight file, reads it line by line, converts each line of 0 and 1 characters into a dynamic array of bits, stores those rows as neurons for that layer
    - Opens the threshold file, reads one integer threshold per neuron, stores those thresholds for the same layer
  - `void create_random(int user_topology[])`
    - Creates a randomized model of weights and thresholds for a custom topology
  - `void print_summary()`
    - Prints summary of bnn model
  - `void print_neuron(int layer_idx, int neuron_idx, bit msb_first = 1)`
    - Prints the data within a neuron. prints it's fan_in, threshold, and weights
  - `void print_modelbit msb_first = 1)`
    - Prints entire model by calling print_neuron for each layer' and number of neurons
  - `void print_inference_trace(bit msb_first = 1)`
    - Prints everything in detail within the neurons
