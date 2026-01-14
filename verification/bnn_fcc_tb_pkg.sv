// Greg Stitt
//
// This file implements the BNN FCC testbench package.
// This packaged includes the BNN_FCC_Model class, which provides
// a reference model to verify the DUT against, along with methods 
// that assist with debugging by providing the correct weights, thresholds,
// and layer outputs for all neurons across all layers.
//
// The package also includes the BNN_FCC_Stimulus class, which provides
// methods for loading test vectors for images from an existing dataset
// (e.g., MNIST), or alternatively generating random input images.

package bnn_fcc_tb_pkg;

    // Provides a reference model and testing/debugging methods for a BNN
    class BNN_FCC_Model #(
        int BUS_WIDTH = 32
    );
        typedef bit weight_row_t[];
        typedef weight_row_t layer_t[];
        typedef int thresh_row_t[];

        typedef bit [BUS_WIDTH-1:0] bus_word_t;
        typedef bus_word_t bus_stream_t[];

        typedef bit [BUS_WIDTH/8-1:0] bus_keep_t;
        typedef bus_keep_t keep_stream_t[];

        // Dimensions: [ LAYER ][ NEURON ][ INPUT_BIT ]
        layer_t      weight       [];

        // Dimensions: [ LAYER ][ NEURON ]
        thresh_row_t threshold    [];

        // Dimensions: [ LAYER ][ NEURON ]
        int          layer_outputs[] [];

        int          num_layers;

        //  [Inputs, L0_Neurons, L1_Neurons, ...]
        int          topology     [];

        bit          is_loaded           = 0;
        bit          outputs_valid       = 0;

        function new();
            is_loaded     = 0;
            outputs_valid = '0;
        endfunction

        // Compute the prediction, and the output of each layer, for the provided image.
        // The layer outputs can be used for deeper debugging/testing.
        // Returns the prediction.
        function int compute_reference(input bit [7:0] img_data[]);
            if (!is_loaded) begin
                $fatal(1, "BNN_FCC_Model Error: Attempted to use model before loading weights! Call load_from_file() or create_random() first.");
            end

            this.layer_outputs = new[num_layers];

            for (int l = 0; l < num_layers; l++) begin
                int fan_in = this.topology[l];
                int n_neurons = this.topology[l+1];

                this.layer_outputs[l] = new[n_neurons];

                for (int n = 0; n < n_neurons; n++) begin
                    int popcount = 0;

                    for (int i = 0; i < fan_in; i++) begin
                        bit in_bit;
                        bit w_bit;

                        if (l == 0) in_bit = (img_data[i] >= 8'd128) ? 1'b1 : 1'b0;
                        else in_bit = (this.layer_outputs[l-1][i] == 1) ? 1'b1 : 1'b0;

                        w_bit = this.weight[l][n][i];
                        if (in_bit == w_bit) popcount++;
                    end

                    if (l == num_layers - 1) this.layer_outputs[l][n] = popcount;
                    else this.layer_outputs[l][n] = (popcount >= this.threshold[l][n]) ? 1 : 0;
                end
            end

            this.outputs_valid = 1;
            return get_prediction();
        endfunction

        function int get_prediction();
            int last = num_layers - 1;
            int max_val = -1;
            int winner = 0;

            if (!outputs_valid) begin
                $fatal(1, "BNN_FCC_Model Error: Requested prediction but no inputs processed. Call compute_reference() first.");
            end

            for (int n = 0; n < this.layer_outputs[last].size(); n++) begin
                if (this.layer_outputs[last][n] > max_val) begin
                    max_val = this.layer_outputs[last][n];
                    winner  = n;
                end
            end
            return winner;
        endfunction

        // Returns the output value of a specific neuron in a specific layer.
        function int get_layer_output(int layer_idx, int neuron_idx);
            if (!outputs_valid) begin
                $fatal(1, "BNN_FCC_Model: Read attempted before compute_reference().");
            end

            if (layer_idx < 0 || layer_idx >= num_layers) begin
                $fatal(1, "BNN_FCC_Model: Layer index %0d out of bounds (0 to %0d).", layer_idx, num_layers - 1);
            end

            if (neuron_idx < 0 || neuron_idx >= layer_outputs[layer_idx].size()) begin
                $fatal(1, "BNN_FCC_Model: Neuron index %0d out of bounds for Layer %0d.", neuron_idx, layer_idx);
            end

            return layer_outputs[layer_idx][neuron_idx];
        endfunction

        // Generates the configuration stream for a given layer, a given mode (weight/threshold), and 
        // outputs both data (stream) and keep (keep_stream) for AXI streaming.
        // The keep is needed because the length of the stream might not be a multiple of BUS_WIDTH.
        // Example, for a 64-bit (8-byte bus), and a 13-byte payload, 3 bytes will have keep cleared 
        // so the DUT knows to ignore the data.
        function void get_layer_config(input int layer_idx, input bit is_threshold, output bus_stream_t stream, output keep_stream_t keep);
            bit [7:0] byte_q[$];
            bus_word_t word_q[$];
            bus_keep_t keep_q[$];

            int fan_in, n_neurons;
            int bytes_per_neuron;
            int layer_inputs;
            longint total_payload_bytes;
            bit [127:0] header_val;

            bus_word_t current_word;
            bus_keep_t current_keep;
            int bytes_per_beat;
            int byte_count;

            int w_idx;
            bit [7:0] byte_val;
            bit [31:0] t_val;

            fan_in = this.topology[layer_idx];
            n_neurons = this.topology[layer_idx+1];

            // Calculate Header Fields
            if (is_threshold) begin
                bytes_per_neuron = 4;  // Thresholds are 32-bit values
                layer_inputs     = 32;  // Should really ignore this value for thresholds
            end else begin
                bytes_per_neuron = (fan_in + 7) / 8;  // Round up to next # of bytes
                layer_inputs     = fan_in;  // Exact # of inputs (e.g., 784)
            end

            total_payload_bytes = bytes_per_neuron * n_neurons;

            // Build 128-bit Header
            header_val          = '0;

            // Word 0 (Lower 64 bits)
            header_val[07:00]   = (is_threshold) ? 8'd1 : 8'd0;  // msg_type (0=weights, 1=thresholds)
            header_val[15:08]   = layer_idx[7:0];  // layer_id
            header_val[31:16]   = layer_inputs[15:0];  // layer_inputs (exact)
            header_val[47:32]   = n_neurons[15:0];  // num_neurons
            header_val[63:48]   = bytes_per_neuron[15:0];  // bytes_per_neuron (rounded up to include padding)

            // Word 1 (Upper 64 bits)
            header_val[95:64]   = total_payload_bytes[31:0];  // total_bytes
            header_val[127:96]  = 32'd0;  // reserved

            // Push header bytes (Little Endian) into byte stream.
            for (int i = 0; i < 16; i++) byte_q.push_back(header_val[i*8+:8]);

            // Generate payload bytes
            for (int n = 0; n < n_neurons; n++) begin
                if (is_threshold) begin
                    // Thresholds: Push 4 bytes (Little Endian)
                    t_val = this.threshold[layer_idx][n];
                    for (int i = 0; i < 4; i++) byte_q.push_back(t_val[i*8+:8]);
                end else begin
                    // Weights: Pack bits into bytes
                    w_idx = 0;
                    for (int b = 0; b < bytes_per_neuron; b++) begin
                        for (int k = 0; k < 8; k++) begin
                            if (w_idx < fan_in) byte_val[k] = this.weight[layer_idx][n][w_idx];
                            else byte_val[k] = 1'b1; // Pad unused bits in the byte
                            w_idx++;
                        end
                        byte_q.push_back(byte_val);
                    end
                end
            end

            // Pack byte stream onto bus (data + keep)
            bytes_per_beat = BUS_WIDTH / 8;
            byte_count = 0;
            current_word = '0;

            foreach (byte_q[i]) begin
                current_word[byte_count*8+:8] = byte_q[i];
                byte_count++;

                if (byte_count == bytes_per_beat) begin
                    word_q.push_back(current_word);
                    keep_q.push_back({(BUS_WIDTH / 8) {1'b1}});

                    current_word = '0;
                    byte_count   = 0;
                end
            end

            // Flush partial beat
            if (byte_count > 0) begin
                word_q.push_back(current_word);

                // Generate partial keep
                current_keep = '0;
                for (int k = 0; k < byte_count; k++) current_keep[k] = 1'b1;
                keep_q.push_back(current_keep);
            end

            // Output data and keep arrays
            stream = new[word_q.size()];
            keep   = new[keep_q.size()];
            foreach (word_q[i]) begin
                stream[i] = word_q[i];
                keep[i]   = keep_q[i];
            end
        endfunction

        // Generates the configuration stream (weights and thresholds) for all layers (i.e. the full model). 
        // Outputs both data (stream) and keep (keep_stream) for AXI streaming.
        // The keep is needed because the length of the stream might not be a multiple of BUS_WIDTH.
        function void encode_configuration(output bus_stream_t full_stream, output keep_stream_t full_keep);
            bus_stream_t layer_stream;
            keep_stream_t layer_keep;

            full_stream = new[0];
            full_keep   = new[0];

            for (int l = 0; l < num_layers; l++) begin
                // Generate weights
                get_layer_config(l, 0, layer_stream, layer_keep);
                full_stream = {full_stream, layer_stream};
                full_keep   = {full_keep, layer_keep};

                // Generate thresholds, but skip output layer
                if (l < num_layers - 1) begin
                    get_layer_config(l, 1, layer_stream, layer_keep);
                    full_stream = {full_stream, layer_stream};
                    full_keep   = {full_keep, layer_keep};
                end
            end
        endfunction

        // Loads a model from the specified file for the specified topology.
        function void load_from_file(string data_dir, int expected_topology[]);
            this.topology = expected_topology;
            this.num_layers = expected_topology.size() - 1;
            this.weight    = new[num_layers];
            this.threshold = new[num_layers];

            for (int i = 0; i < num_layers; i++) begin
                string w_path = $sformatf("%s/l%0d_weights.txt", data_dir, i);
                string t_path = $sformatf("%s/l%0d_thresholds.txt", data_dir, i);
                load_single_layer(i, w_path, t_path);
            end

            is_loaded = 1;
            outputs_valid = 0;
        endfunction

        // Loads a single layer of a model from the specified weight and threshold files.
        protected function void load_single_layer(int l_idx, string w_file, string t_file);
            int fd;
            string line;
            weight_row_t w_queue[$];

            fd = $fopen(w_file, "r");
            if (fd == 0) $fatal(1, "BNN_FCC_Model: Could not open %s", w_file);

            // Load weights
            while ($fgets(
                line, fd
            )) begin
                if (line.len() > 0) begin
                    // Collect valid bits only (ignores \n, \r)
                    bit bit_q[$];
                    for (int i = 0; i < line.len(); i++) begin
                        if (line[i] == "1") bit_q.push_back(1'b1);
                        else if (line[i] == "0") bit_q.push_back(1'b0);
                    end

                    // If line had data, store it
                    if (bit_q.size() > 0) begin
                        weight_row_t row = new[bit_q.size()];
                        foreach (bit_q[k]) row[k] = bit_q[k];
                        w_queue.push_back(row);
                    end
                end
            end
            $fclose(fd);

            // Assign weights to class member
            this.weight[l_idx] = new[w_queue.size()];
            foreach (w_queue[i]) this.weight[l_idx][i] = w_queue[i];

            // Load thresholds into class member
            fd = $fopen(t_file, "r");
            if (fd == 0) $fatal(1, "BNN_FCC_Model: Could not open %s", t_file);
            this.threshold[l_idx] = new[w_queue.size()];
            for (int i = 0; i < w_queue.size(); i++) begin
                void'($fscanf(fd, "%d\n", this.threshold[l_idx][i]));
            end
            $fclose(fd);
        endfunction

        // Creates a randomized model (weights/thresholds) for the specified topology)
        function void create_random(int user_topology[]);
            this.topology = user_topology;
            this.num_layers = user_topology.size() - 1;
            this.weight    = new[num_layers];
            this.threshold = new[num_layers];

            for (int l = 0; l < num_layers; l++) begin
                int n_inputs  = topology[l];
                int n_neurons = topology[l+1];

                $display("Randomizing Layer %0d: %0d inputs -> %0d neurons", l, n_inputs, n_neurons);
                this.weight[l]    = new[n_neurons];
                this.threshold[l] = new[n_neurons];

                for (int n = 0; n < n_neurons; n++) begin
                    weight_row_t temp_w;
                    int temp_t;

                    temp_w = new[n_inputs];
                    if (!std::randomize(temp_w)) $fatal(1, "Rand Fail Weights");
                    this.weight[l][n] = temp_w;

                    if (!std::randomize(
                            temp_t
                        ) with {
                            temp_t >= 0;
                            temp_t <= n_inputs;
                            temp_t dist {
                                [n_inputs / 3 : 2 * n_inputs / 3] := 80,
                                [0 : n_inputs] := 20
                            };
                        })
                        $fatal(1, "Rand Fail Thresholds");
                    this.threshold[l][n] = temp_t;
                end

                if (l == num_layers - 1) begin
                    for (int n = 0; n < n_neurons; n++) this.threshold[l][n] = 0;
                end
            end

            is_loaded = 1;
            outputs_valid = 0;
        endfunction

        function void print_summary();
            $display("BNN Model: %0d Layers, %0d Inputs", num_layers, this.topology[0]);
            for (int i = 0; i < num_layers; i++) begin
                $display("  Layer %0d (%s): %0d Neurons", i, i == num_layers - 1 ? "output" : "hidden", weight[i].size());
            end
        endfunction

        function void print_neuron(int layer_idx, int neuron_idx, bit msb_first = 1);
            int fan_in;
            int w;
            int bits_printed;

            if (layer_idx < 0 || layer_idx >= num_layers) begin
                $display("Error: Layer Index %0d out of bounds.", layer_idx);
                return;
            end
            if (neuron_idx < 0 || neuron_idx >= this.weight[layer_idx].size()) begin
                $display("Error: Neuron Index %0d out of bounds for Layer %0d.", neuron_idx, layer_idx);
                return;
            end

            fan_in = this.weight[layer_idx][neuron_idx].size();

            $display("\n--- [DEBUG] Model Inspection: Layer %0d, Neuron %0d ---", layer_idx, neuron_idx);
            $display("  Fan-In:    %0d", fan_in);
            $display("  Threshold: %0d", this.threshold[layer_idx][neuron_idx]);

            if (msb_first) $display("  Weights:   (MSB [Idx %0d] ... LSB [Idx 0])", fan_in - 1);
            else $display("  Weights:   (LSB [Idx 0] ... MSB [Idx %0d])", fan_in - 1);

            $write("    ");
            bits_printed = 0;

            if (msb_first) begin
                for (w = fan_in - 1; w >= 0; w--) begin
                    $write("%b", this.weight[layer_idx][neuron_idx][w]);
                    bits_printed++;

                    if (w > 0) begin
                        if (bits_printed % 64 == 0) $write("\n    ");
                        else if (bits_printed % 8 == 0) $write("_");
                    end
                end
            end else begin
                for (w = 0; w < fan_in; w++) begin
                    $write("%b", this.weight[layer_idx][neuron_idx][w]);
                    bits_printed++;

                    if (w < fan_in - 1) begin
                        if (bits_printed % 64 == 0) $write("\n    ");
                        else if (bits_printed % 8 == 0) $write("_");
                    end
                end
            end

            $write("\n");
            $display("-------------------------------------------------------");
        endfunction

    endclass

    // Provides methods for loading stimulus images and/or randomly generating them.
    class BNN_FCC_Stimulus #(
        int PIXEL_WIDTH = 8
    );

        typedef bit [PIXEL_WIDTH-1:0] pixel_t;
        typedef pixel_t input_vector_t[];

        local input_vector_t input_db[$];
        local int input_size;

        function new(int size);
            this.input_size = size;
        endfunction

        function int get_num_vectors();
            return this.input_db.size();
        endfunction

        // Loads up to "num_images" images from sepcified hex File
        // num_images=-1 loads entire file. Stores vectors in input_db to be
        // retrieved via get_vector().
        function void load_from_file(string filename, int num_images = -1);
            int fd;
            bit [8191:0] buffer;
            int code;
            input_vector_t vec;
            int i, high, low;

            fd = $fopen(filename, "r");
            if (fd == 0) $fatal(1, "BNN_FCC_Stimulus: Could not open %s", filename);

            this.input_db.delete();

            while (!$feof(
                fd
            )) begin
                if (num_images != -1 && this.input_db.size() >= num_images) break;

                code = $fscanf(fd, "%h\n", buffer);
                if (code == 1) begin
                    vec = new[input_size];

                    for (i = 0; i < input_size; i++) begin
                        high = (input_size * PIXEL_WIDTH) - 1 - (i * PIXEL_WIDTH);
                        low = high - PIXEL_WIDTH + 1;
                        vec[i] = buffer[high-:PIXEL_WIDTH];
                    end
                    this.input_db.push_back(vec);
                end
            end
            $fclose(fd);
            if (this.input_db.size() < num_images) $warning("BNN_FCC_Stimulus: Unable to load %0d vectors from %s. Using %0d instead.", num_images, filename, input_db.size());
            $display("BNN_FCC_Stimulus: Loaded %0d vectors from %s", this.input_db.size(), filename);
        endfunction

        // Provides a single test vector for image index. Assumes images have already been loaded or created.
        function void get_vector(int index, output input_vector_t result);
            if (index >= 0 && index < this.input_db.size()) begin
                result = this.input_db[index];
            end else begin
                $warning("BNN_FCC_Stimulus: Index %0d out of bounds.", index);
                result = new[input_size];
            end
        endfunction

        // Generates num_vectors random input images, and stores them in input_db to be
        // retrieved via get_vector().
        function void generate_random_vectors(int num_vectors);
            input_vector_t vec;
            this.input_db.delete();

            $display("BNN_FCC_Stimulus: Generating %0d random vectors...", num_vectors);

            for (int i = 0; i < num_vectors; i++) begin
                // Get a random vector
                vec = new[input_size];
                if (!std::randomize(vec)) begin
                    $fatal(1, "BNN_FCC_Stimulus: Failed to randomize input vector.");
                end
                // Add to database
                this.input_db.push_back(vec);
            end
            //$display("BNN_FCC_Stimulus: Generated %0d random vectors.", this.input_db.size());
        endfunction

        // Generate one random input image and returns it without changing input_db.
        function void get_random_vector(output input_vector_t result);
            result = new[input_size];
            if (!std::randomize(result)) $fatal(1, "BNN_FCC_Stimulus: Randomization failed");
        endfunction

    endclass

endpackage
