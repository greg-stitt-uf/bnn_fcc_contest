// Greg Stitt
//
// MODULE: bnn_fcc_tb
//
// DESCRIPTION:
// Testbench for the binary neural net (bnn) fully connected classifier (fcc).
//
// There are two modes for the testbench. If you enable USE_CUSTOM_TOPOLOGY, the testbench
// evaluates the topology specified by CUSTOM_TOPOLOGY using a random model (weights+thresholds).
//
// For USE_CUSTOM_TOPOLOGY=0, the testbench uses the SFC topology (784->256->256->10) for MNIST from the FINN paper:
// Umuroglu, Y., Fraser, N. J., Gambardella, G., Blott, M., Leong, P., Jahre, M., & Vissers, K. (2017). FINN: A Framework for Fast, Scalable Binarized Neural Network Inference. In Proceedings of the 2017 ACM/SIGDA International Symposium on Field-Programmable Gate Arrays (pp. 65-74). DOI: 10.1145/3020078.3021744
//
// For the SFC topology, the testbench uses trained weights and thresholds from Python code.
//
// The testbench compares the actual outputs with the expected outputs provided in the BNN_FCC_Model
// class (see bnn_fcc_tb_pkg.sv). That class also contains a variety of functions that you might find
// useful for debugging.
//
// bnn_fcc_tb_pkg.sv also provides a BNN_FCC_Stimulus class that loads images from files (in the
// case of MNIST) or randomly generates test images (for USE_CUSTOM_TOPOLOGY=0).
//
// USAGE INSTRUCTIONS:
// Set the testbench configuration parameters based on the type of test you want to perform.
// To test MNIST handwriting recognition with the required SFC topology, set USE_CUSTOM_TOPOLOGY
// to 0. For debugging, you will likely want to test much smaller custom topologies first.
// You can do this by enabling USE_CUSTOM_TOPOLOGY and setting CUSTOM_TOPOLOGY to something
// easier to test and debug (e.g., 4->2->2->2).
//
// When using MNIST, make sure BASE_DIR is set to the Python training folder. This can be 
// tricky because the path must be relative to the simulator's working directory. Normally,
// if you add a sim/ folder to the repo's base directory, the default value should work with
// Questa, as long as the Questa project is in the sim/ folder. You can easily find the working
// directory in the Questa GUI by starting the simulation and typing "pwd" into the transcript
// window.
//
// To fully pass testing for the contest, you must set TOGGLE_DATA_OUT_READY=1, 
// CONFIG_VALID_PROBABILITY=0.8, and DATA_IN_VALID_PROBABILITY=0.8. However, leaving these at
// the defaults will make initial testing easier. Similarly, when measuring performance, 
// leave these at their defaults to avoid artificially hurting performance.
//
// PARAMETERS:
// [Testbench Configuration]
// USE_CUSTOM_TOPOLOGY       - Enable user-defined NN topology specified by CUSTOM_TOPOLOGY
//                             instead of the default SFC topology for MNIST.
// CUSTOM_LAYERS             - Total layers (Includes input, hidden, and output) if using a custom topology.
// CUSTOM_TOPOLOGY           - Array defining neurons per layer, with the exception of
//                             CUSTOM_TOPOLOGY[0], which specifies the number of inputs.
// NUM_TEST_IMAGES           - Number of stimulus images for simulation
// VERIFY_PYTHON             - Cross-check SV results against Python model 
//                             (only applicable to USE_CUSTOM_TOPOLOGY=1'b0)
// BASE_DIR                  - Path to Python reference/training data (must be set relative to
//                             your simulator's working directory)
// TOGGLE_DATA_OUT_READY     - Randomly toggles data_out_ready to simulate back-pressure. Must be enabled
//                             to fully pass tests for contest. Disable to measure throughput and latency.
// CONFIG_VALID_PROBABILITY  - Real value from 0.0 to 1.0 that specifies the probability of the
//                             configuration bus providing valid data while the DUT is ready. Used to
//                             simulate a slow upstream producer. Must be set to a value less than 1.0
//                             to full pass testing, but should be set to 1 to measure performance.
// DATA_IN_VALID_PROBABILITY - Real value from 0.0 to 1.0 that specifies the probability of the
//                             data_in bus providing valid pixels while the DUT is ready. Used to
//                             simulate a slow upstream producer. Must be set to a value less than 1.0
//                             to fully pass testing, but should be set to 1 to measure performance.
// TIMEOUT                   - Realtime value that specifies the maximum amount of time the testbench is
//                             allowed to run before being terminated. Adjust based on the expected 
//                             performance of your design.
//
// [Bus Configuration]
// CONFIG_BUS_WIDTH          - Bit-width for configuration bus (AXI streaming)
// INPUT_BUS_WIDTH           - Bit-width for primary input data stream (AXI streaming)
// OUTPUT_BUS_WIDTH          - Bit-width for output (AXI streaming)
//
// [App Configuration]       (Note: changes to the defaults have not been tested, may break classes in bnn_fcc_tb_pkg)
// INPUT_DATA_WIDTH          - Bit-width of individual input elements (8-bit for MNIST)
// OUTPUT_DATA_WIDTH         - Bit-width of individual output elements
//
// [DUT Configuration]       (TODO: Adapt to your own DUT if necessary. Feel free to create, ignore, and/or remove parameters)
// PARALLELIZE_LAYERS        - Enable pipelining across multiple layers
// PARALLEL_NEURONS          - Number of neurons processed in parallel
// PARALLEL_INPUTS           - Number of inputs/weights processed in parallel per neuron

`timescale 1ns / 100ps

module bnn_fcc_tb #(
    // Testbench configuration
    parameter int      USE_CUSTOM_TOPOLOGY                           = 1'b0,
    parameter int      CUSTOM_LAYERS                                 = 4,
    parameter int      CUSTOM_TOPOLOGY               [CUSTOM_LAYERS] = '{8, 4, 4, 2},
    parameter int      NUM_TEST_IMAGES                               = 10,
    parameter bit      VERIFY_SV_MODEL_AGAINST_PYTHON                = 1,
    parameter string   BASE_DIR                                      = "../python",
    parameter bit      TOGGLE_DATA_OUT_READY                         = 1'b1,
    parameter real     CONFIG_VALID_PROBABILITY                      = 1.0,
    parameter real     DATA_IN_VALID_PROBABILITY                     = 1.0,
    parameter realtime TIMEOUT                                       = 10ms,

    // Bus configuration
    parameter int CONFIG_BUS_WIDTH = 64,
    parameter int INPUT_BUS_WIDTH  = 64,
    parameter int OUTPUT_BUS_WIDTH = 8,

    // App configuration
    parameter  int INPUT_DATA_WIDTH  = 8,
    localparam int INPUTS_PER_CYCLE  = INPUT_BUS_WIDTH / INPUT_DATA_WIDTH,
    localparam int BYTES_PER_INPUT   = INPUT_DATA_WIDTH / 8,
    parameter  int OUTPUT_DATA_WIDTH = 4,

    // DUT configuration (can be extended for your own DUT)
    parameter bit PARALLELIZE_LAYERS = 1'b0,
    parameter int PARALLEL_NEURONS = 1,
    parameter int PARALLEL_INPUTS = 4
);
    import bnn_fcc_tb_pkg::*;

    localparam int TRAINED_LAYERS = 4;
    localparam int TRAINED_TOPOLOGY[TRAINED_LAYERS] = '{784, 256, 256, 10};

    localparam int ACTUAL_TOTAL_LAYERS = USE_CUSTOM_TOPOLOGY ? CUSTOM_LAYERS : TRAINED_LAYERS;
    localparam int ACTUAL_TOPOLOGY[ACTUAL_TOTAL_LAYERS] = USE_CUSTOM_TOPOLOGY ? CUSTOM_TOPOLOGY : TRAINED_TOPOLOGY;

    localparam string MNIST_TEST_VECTOR_INPUT_PATH = "test_vectors/inputs.hex";
    localparam string MNIST_TEST_VECTOR_OUTPUT_PATH = "test_vectors/expected_outputs.txt";
    localparam string MNIST_MODEL_DATA_PATH = "training_data";

    initial begin
        assert (INPUT_DATA_WIDTH == 8)
        else $fatal(1, "TB ERROR: INPUT_DATA_WIDTH must be 8. Sub-byte or multi-byte packing logic not yet implemented.");
    end

    // Returns 1 with probability p, 0 with probability 1-p.
    function automatic bit chance(real p);
        if (p > 1.0 || p < 0.0) $fatal(1, "Invalid probability in chance()");
        return ($urandom < (p * (2.0 ** 32)));
    endfunction

    BNN_FCC_Model #(CONFIG_BUS_WIDTH) model;
    BNN_FCC_Stimulus #(INPUT_DATA_WIDTH) stim;

    typedef bit [CONFIG_BUS_WIDTH-1:0] config_bus_word_t;
    typedef config_bus_word_t config_bus_data_stream_t[];

    localparam CONFIG_KEEP_WIDTH = CONFIG_BUS_WIDTH / 8;
    typedef bit [CONFIG_KEEP_WIDTH-1:0] config_bus_keep_t;
    typedef config_bus_keep_t config_keep_stream_t[];

    bit [CONFIG_BUS_WIDTH-1:0] config_bus_data_stream[];
    bit [CONFIG_BUS_WIDTH/8-1:0] config_bus_keep_stream[];

    int num_tests;
    int passed;
    int failed;

    logic clk = 1'b0;
    logic rst;

    axi4_stream_if #(
        .DATA_WIDTH(CONFIG_BUS_WIDTH)
    ) config_in (
        .aclk   (clk),
        .aresetn(!rst)
    );

    axi4_stream_if #(
        .DATA_WIDTH(INPUT_BUS_WIDTH)
    ) data_in (
        .aclk   (clk),
        .aresetn(!rst)
    );

    axi4_stream_if #(
        .DATA_WIDTH(OUTPUT_BUS_WIDTH)
    ) data_out (
        .aclk   (clk),
        .aresetn(!rst)
    );

    bnn_fcc #(
        .INPUT_DATA_WIDTH  (INPUT_DATA_WIDTH),
        .INPUT_BUS_WIDTH   (INPUT_BUS_WIDTH),
        .CONFIG_BUS_WIDTH  (CONFIG_BUS_WIDTH),
        .OUTPUT_DATA_WIDTH (OUTPUT_DATA_WIDTH),
        .OUTPUT_BUS_WIDTH  (OUTPUT_BUS_WIDTH),
        .TOTAL_LAYERS      (ACTUAL_TOTAL_LAYERS),
        .TOPOLOGY          (ACTUAL_TOPOLOGY),
        .PARALLELIZE_LAYERS(PARALLELIZE_LAYERS),
        .PARALLEL_NEURONS  (PARALLEL_NEURONS),
        .PARALLEL_INPUTS   (PARALLEL_INPUTS)
    ) DUT (
        .clk(clk),
        .rst(rst),

        .config_valid(config_in.tvalid),
        .config_ready(config_in.tready),
        .config_data (config_in.tdata),
        .config_keep (config_in.tkeep),
        .config_last (config_in.tlast),

        .data_in_valid(data_in.tvalid),
        .data_in_ready(data_in.tready),
        .data_in_data (data_in.tdata),
        .data_in_keep (data_in.tkeep),
        .data_in_last (data_in.tlast),

        .data_out_valid(data_out.tvalid),
        .data_out_ready(data_out.tready),
        .data_out_data (data_out.tdata),
        .data_out_keep (data_out.tkeep),
        .data_out_last (data_out.tlast)
    );

    initial begin : generate_clock
        forever #5 clk <= ~clk;
    end

    task verify_model();
        int python_preds[];
        bit [INPUT_DATA_WIDTH-1:0] current_img[];
        string input_path;
        string output_path;
        input_path  = $sformatf("%s/%s", BASE_DIR, MNIST_TEST_VECTOR_INPUT_PATH);
        output_path = $sformatf("%s/%s", BASE_DIR, MNIST_TEST_VECTOR_OUTPUT_PATH);

        // Load stimulus images
        stim.load_from_file(input_path);
        num_tests = stim.get_num_vectors();

        // Load Python predictions (i.e. truth)
        python_preds = new[num_tests];
        $readmemh(output_path, python_preds);

        for (int i = 0; i < num_tests; i++) begin
            int sv_pred;
            stim.get_vector(i, current_img);
            sv_pred = model.compute_reference(current_img);  // SV calculates result            

            // Self-check the SV model.
            if (sv_pred !== python_preds[i]) begin
                $error("TB LOGIC ERROR: Img %0d. SV Model says %0d, Python says %0d", i, sv_pred, python_preds[i]);
                $finish;  // Stop immediately, the testbench is broken
                /*end else begin
                $display("Img %0d: Class %0d (Matched Python)", i, sv_pred);*/
            end
        end

        $display("SV model successfully verified.");
    endtask

    // ===========================================================================
    // Initialize model and config memory
    // ===========================================================================
    initial begin : l_init_model
        string path;
        model = new();
        stim  = new(ACTUAL_TOPOLOGY[0]);

        if (!USE_CUSTOM_TOPOLOGY) begin
            // Load Weights & Configure Memory
            $display("--- Loading Trained Model ---");
            path = $sformatf("%s/%s", BASE_DIR, MNIST_MODEL_DATA_PATH);
            model.load_from_file(path, ACTUAL_TOPOLOGY);
            if (VERIFY_SV_MODEL_AGAINST_PYTHON) verify_model();
            model.encode_configuration(config_bus_data_stream, config_bus_keep_stream);
            $display("--- Configuration created: %0d words (%0d-bit wide) ---", config_bus_data_stream.size(), CONFIG_BUS_WIDTH);

            // Load input images
            $display("--- Loading Test Vectors ---");
            path = $sformatf("%s/%s", BASE_DIR, MNIST_TEST_VECTOR_INPUT_PATH);
            stim.load_from_file(path, NUM_TEST_IMAGES);
        end else begin
            $display("--- Loading Randomized Model ---");
            model.create_random(ACTUAL_TOPOLOGY);
            model.encode_configuration(config_bus_data_stream, config_bus_keep_stream);
            $display("--- Configuration created: %0d words (%0d-bit wide) ---", config_bus_data_stream.size(), CONFIG_BUS_WIDTH);

            $display("--- Generating Random Test Vectors ---");
            stim.generate_random_vectors(NUM_TEST_IMAGES);
        end

        num_tests = stim.get_num_vectors();
        model.print_summary();

        // NOTE: You can debug by looking at the model's weights, thresholds, and layer ouputs. 
        // For example, this prints the model for all neurons in the first hidden layer:
        // for (int i = 0; i < ACTUAL_TOPOLOGY[1]; i++) model.print_neuron(0, i);      
        //
        // where the parameters specify the layer and neuron. This loop iterates over all
        // neurons in the first hidden layer. Note that the parameters treat the first hidden layer
        // as layer 0, essentially excluding the input layer since it has no neurons.
        //
        // Weights are accessible via model.weight[][][], where the dimensions are:
        // [layer][neuron][bit]
        //
        // thresholds are accessible via model.threshold[][], where the dimensions are:
        // [layer][neuron]
    end

    logic [OUTPUT_DATA_WIDTH-1:0] expected_outputs[$];

    assign config_in.tstrb = config_in.tkeep;
    assign data_in.tstrb   = data_in.tkeep;

    initial begin : l_sequencer_and_driver
        $timeformat(-9, 0, " ns", 0);

        rst              <= 1'b1;
        config_in.tvalid <= 1'b0;
        config_in.tdata  <= '0;
        config_in.tkeep  <= '0;
        config_in.tlast  <= 1'b0;
        config_in.tuser  <= '0;
        config_in.tid    <= '0;
        config_in.tdest  <= '0;
        data_in.tvalid   <= 1'b0;
        data_in.tdata    <= '0;
        data_in.tkeep    <= '0;
        data_in.tlast    <= 1'b0;
        data_in.tuser    <= '0;
        data_in.tid      <= '0;
        data_in.tdest    <= '0;

        repeat (5) @(posedge clk);
        @(negedge clk);
        rst <= 1'b0;
        repeat (5) @(posedge clk);

        // Stream in weights and thresholds.
        $display("[%0t] Streaming weights and thresholds.", $realtime);
        for (int i = 0; i < config_bus_data_stream.size(); i++) begin

            // Simulate gaps on configuration bus.
            while (!chance(
                CONFIG_VALID_PROBABILITY
            )) begin
                config_in.tvalid <= 1'b0;
                @(posedge clk iff config_in.tready);
            end

            config_in.tvalid <= 1'b1;
            config_in.tdata  <= config_bus_data_stream[i];
            config_in.tlast  <= i == config_bus_data_stream.size() - 1;
            config_in.tkeep  <= config_bus_keep_stream[i];
            @(posedge clk iff config_in.tready);
        end
        config_in.tvalid <= 1'b0;
        config_in.tlast  <= 1'b0;
        repeat (5) @(posedge clk);

        for (int i = 0; i < num_tests; i++) begin
            int expected_pred;
            bit expected_bit;
            bit [INPUT_DATA_WIDTH-1:0] current_img[];

            // Fetch stimulus image i (pre-created by either stim.load_from_file() or stim.generate_random_vectors())
            stim.get_vector(i, current_img);

            // Compute expected output for current image. This also generates references for each layer's
            // outputs, which can be accessed via model.layer_outputs[layer][neuron] for deeper verification.
            expected_pred = model.compute_reference(current_img);
            expected_outputs.push_back(expected_pred);

            // Stream image into DUT.
            $display("[%0t] Streaming image %0d.", $realtime, i);
            for (int j = 0; j < current_img.size(); j += INPUTS_PER_CYCLE) begin
                // Pack multiple pixels into a single AXI beat.
                for (int k = 0; k < INPUTS_PER_CYCLE; k++) begin
                    if (j + k < current_img.size()) begin
                        data_in.tdata[k*INPUT_DATA_WIDTH+:INPUT_DATA_WIDTH] <= current_img[j+k];
                        data_in.tkeep[k*BYTES_PER_INPUT+:BYTES_PER_INPUT]   <= '1;
                    end else begin
                        data_in.tdata[k*INPUT_DATA_WIDTH+:INPUT_DATA_WIDTH] <= '0;
                        data_in.tkeep[k*BYTES_PER_INPUT+:BYTES_PER_INPUT]   <= '0;
                    end
                end

                // Simulate gaps on data_in bus.
                while (!chance(
                    DATA_IN_VALID_PROBABILITY
                )) begin
                    data_in.tvalid <= 1'b0;
                    @(posedge clk iff data_in.tready);
                end
                data_in.tvalid <= 1'b1;
                data_in.tlast  <= (j + INPUTS_PER_CYCLE >= current_img.size());
                @(posedge clk iff data_in.tready);
            end

            data_in.tvalid <= 1'b0;
            data_in.tlast  <= 1'b0;
            data_in.tkeep  <= '0;
            @(posedge clk);
        end

        $display("[%0t] All images loaded, waiting for outputs.", $realtime);
        wait (expected_outputs.size() == 0);
        repeat (5) @(posedge clk);

        disable generate_clock;
        if (passed == num_tests) $display("SUCCESS: all %0d tests completed successfully.", num_tests);
        else $error("FAILED: %0d out of %0d tests failed.", failed, num_tests);
    end

    initial begin : l_toggle_ready
        data_out.tready <= 1'b1;
        @(posedge clk iff !rst);
        if (TOGGLE_DATA_OUT_READY) begin
            forever begin
                data_out.tready <= $urandom();
                @(posedge clk);
            end
        end else data_out.tready <= 1'b1;
    end

    initial begin : l_output_monitor
        forever begin
            @(posedge clk iff data_out.tvalid && data_out.tready);
            assert (expected_outputs.size() > 0)
            else $fatal(1, "No expected output for actual output");
            assert (data_out.tdata == expected_outputs[0]) begin
                passed++;
            end else begin
                $error("Output incorrect: actual = %0d vs expected = %0d", data_out.tdata, expected_outputs[0]);
                failed++;
            end
            void'(expected_outputs.pop_front());
        end
    end

    initial begin : l_timeout
        #TIMEOUT;
        $fatal(1, $sformatf("Simulation failed due to timeout of %0t.", TIMEOUT));
    end

endmodule
