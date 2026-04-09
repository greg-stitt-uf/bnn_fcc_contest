`timescale 1ns/1ps

module tb_config_manager #(
    parameter int BUS_WIDTH = 64,
    parameter int NUM_TESTS = 100,
    parameter int MIN_PAYLOAD_BYTES = 1,
    parameter int MAX_PAYLOAD_BYTES = 48
);

    localparam int BYTE_LANES = BUS_WIDTH / 8;

    typedef bit [BUS_WIDTH-1:0] bus_word_t;
    typedef bit [BYTE_LANES-1:0] keep_t;

    typedef struct packed {
        logic [7:0]  msg_type;
        logic [7:0]  layer_id;
        logic [15:0] layer_inputs;
        logic [15:0] num_neurons;
        logic [15:0] bytes_per_neuron;
        logic [31:0] total_bytes;
        logic [31:0] reserved;
    } header_t;

    logic                     clk = 1'b0;
    logic                     rst;
    logic [BUS_WIDTH-1:0]     config_data_in;
    logic                     config_valid;
    logic [BYTE_LANES-1:0]    config_keep;
    logic                     config_last;
    logic                     config_ready;

    logic [7:0]               msg_type;
    logic [7:0]               layer_id;
    logic [15:0]              layer_inputs;
    logic [15:0]              num_neurons;
    logic [15:0]              bytes_per_neuron;
    logic [31:0]              total_bytes;
    logic [31:0]              reserved;
    logic [7:0]               data_out[0:7];
    logic [7:0]               data_out_valid;
    logic                     error;

    int current_test_id;
    int unsigned passed;
    int unsigned failed;

    config_manager #(
        .BUS_WIDTH(BUS_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .config_data_in(config_data_in),
        .config_valid(config_valid),
        .config_keep(config_keep),
        .config_last(config_last),
        .config_ready(config_ready),
        .msg_type(msg_type),
        .layer_id(layer_id),
        .layer_inputs(layer_inputs),
        .num_neurons(num_neurons),
        .bytes_per_neuron(bytes_per_neuron),
        .total_bytes(total_bytes),
        .reserved(reserved),
        .data_out(data_out),
        .data_out_valid(data_out_valid),
        .error(error)
    );

    initial begin : generate_clock
        forever #5 clk = ~clk;
    end

    task automatic drive_idle();
        begin
            config_valid <= 1'b0;
            config_data_in <= '0;
            config_keep <= '0;
            config_last <= 1'b0;
        end
    endtask

    task automatic build_stream(
        input header_t header,
        input bit [7:0] payload_bytes[],
        output bus_word_t beats[],
        output keep_t keeps[]
    );
        bit [7:0] byte_q[$];
        bus_word_t beat_q[$];
        keep_t keep_q[$];
        bus_word_t current_word;
        keep_t current_keep;
        int byte_count;

        current_word = '0;
        current_keep = '0;
        byte_count = 0;

        byte_q.push_back(header.msg_type);
        byte_q.push_back(header.layer_id);
        byte_q.push_back(header.layer_inputs[7:0]);
        byte_q.push_back(header.layer_inputs[15:8]);
        byte_q.push_back(header.num_neurons[7:0]);
        byte_q.push_back(header.num_neurons[15:8]);
        byte_q.push_back(header.bytes_per_neuron[7:0]);
        byte_q.push_back(header.bytes_per_neuron[15:8]);
        byte_q.push_back(header.total_bytes[7:0]);
        byte_q.push_back(header.total_bytes[15:8]);
        byte_q.push_back(header.total_bytes[23:16]);
        byte_q.push_back(header.total_bytes[31:24]);
        byte_q.push_back(header.reserved[7:0]);
        byte_q.push_back(header.reserved[15:8]);
        byte_q.push_back(header.reserved[23:16]);
        byte_q.push_back(header.reserved[31:24]);

        foreach (payload_bytes[i]) begin
            byte_q.push_back(payload_bytes[i]);
        end

        foreach (byte_q[i]) begin
            current_word[byte_count*8 +: 8] = byte_q[i];
            current_keep[byte_count] = 1'b1;
            byte_count++;

            if (byte_count == BYTE_LANES) begin
                beat_q.push_back(current_word);
                keep_q.push_back(current_keep);
                current_word = '0;
                current_keep = '0;
                byte_count = 0;
            end
        end

        if (byte_count != 0) begin
            beat_q.push_back(current_word);
            keep_q.push_back(current_keep);
        end

        beats = new[beat_q.size()];
        keeps = new[keep_q.size()];
        foreach (beat_q[i]) begin
            beats[i] = beat_q[i];
            keeps[i] = keep_q[i];
        end
    endtask

    task automatic make_random_item(
        output header_t header,
        output bit [7:0] payload[]
    );
        int unsigned payload_size;
        int unsigned max_bytes_per_neuron;
        int unsigned num_neurons_tmp;
        int unsigned bytes_per_neuron_tmp;

        header = '0;
        header.msg_type = 8'($urandom_range(0, 1));
        header.layer_id = 8'($urandom);
        header.layer_inputs = 16'($urandom);
        header.reserved = 32'($urandom);

        payload_size = 0;
        while ((payload_size < MIN_PAYLOAD_BYTES) || (payload_size > MAX_PAYLOAD_BYTES)) begin
            num_neurons_tmp = $urandom_range(1, 12);
            max_bytes_per_neuron = MAX_PAYLOAD_BYTES / num_neurons_tmp;
            if (max_bytes_per_neuron == 0) begin
                max_bytes_per_neuron = 1;
            end
            bytes_per_neuron_tmp = $urandom_range(1, max_bytes_per_neuron);
            payload_size = num_neurons_tmp * bytes_per_neuron_tmp;
            header.num_neurons = 16'(num_neurons_tmp);
            header.bytes_per_neuron = 16'(bytes_per_neuron_tmp);
        end

        header.total_bytes = 32'(payload_size);
        payload = new[payload_size];
        foreach (payload[i]) begin
            payload[i] = 8'($urandom);
        end
    endtask

    task automatic run_test(input int test_id);
        header_t expected_header;
        bit [7:0] expected_payload[];
        bus_word_t beats[];
        keep_t keeps[];
        int unsigned expected_payload_idx;
        bit header_checked;
        bit test_failed;

        current_test_id = test_id;
        make_random_item(expected_header, expected_payload);
        build_stream(expected_header, expected_payload, beats, keeps);

        expected_payload_idx = 0;
        header_checked = 1'b0;
        test_failed = 1'b0;

        for (int beat = 0; beat < beats.size(); beat++) begin
            @(negedge clk);
            config_valid <= 1'b1;
            config_data_in <= beats[beat];
            config_keep <= keeps[beat];
            config_last <= (beat == beats.size() - 1);

            do begin
                @(posedge clk);
                // i set it to check for total_bytes so that we don't have to wait an arbitrary number
                // of clock cycles for the header to come out before we start checking it.
                // of the random numbers, if the number of total_bytes is the same from the previous test
                // to the current one, this will "fail". reviewing the waveform will show that the header is filled
                // properly. 
                if (!header_checked && total_bytes == expected_header.total_bytes) begin
                    if ((msg_type !== expected_header.msg_type) ||
                        (layer_id !== expected_header.layer_id) ||
                        (layer_inputs !== expected_header.layer_inputs) ||
                        (num_neurons !== expected_header.num_neurons) ||
                        (bytes_per_neuron !== expected_header.bytes_per_neuron) ||
                        (total_bytes !== expected_header.total_bytes) ||
                        (reserved !== expected_header.reserved)) begin
                        $display("FAIL time=%0t test=%0d header mismatch", $time, test_id);
                        $display("  exp msg_type=%0h layer_id=%0h layer_inputs=%0h num_neurons=%0h bytes_per_neuron=%0h total_bytes=%0h reserved=%0h",
                                 expected_header.msg_type, expected_header.layer_id, expected_header.layer_inputs,
                                 expected_header.num_neurons, expected_header.bytes_per_neuron, expected_header.total_bytes,
                                 expected_header.reserved);
                        test_failed = 1'b1;
                    end
                    header_checked = 1'b1;
                end

                if (data_out_valid != '0) begin
                    for (int lane = 0; lane < BYTE_LANES; lane++) begin
                        bit expected_valid;
                        bit [7:0] expected_byte;

                        expected_valid = (expected_payload_idx < expected_payload.size());
                        expected_byte = expected_valid ? expected_payload[expected_payload_idx] : 8'h00;

                        if (data_out_valid[lane] !== expected_valid) begin
                            $display("FAIL time=%0t test=%0d lane=%0d valid mismatch exp=%0b act=%0b payload_idx=%0d",
                                     $time, test_id, lane, expected_valid, data_out_valid[lane], expected_payload_idx);
                            test_failed = 1'b1;
                        end

                        if (expected_valid) begin
                            if (data_out[lane] !== expected_byte) begin
                                $display("FAIL time=%0t test=%0d lane=%0d data mismatch exp=0x%0h act=0x%0h payload_idx=%0d",
                                         $time, test_id, lane, expected_byte, data_out[lane], expected_payload_idx);
                                test_failed = 1'b1;
                            end
                            expected_payload_idx++;
                        end
                    end
                end
            end while (!(config_valid && config_ready));
        end

        @(negedge clk);
        drive_idle();

        repeat (6) begin
            @(posedge clk);

            if (!header_checked && total_bytes == expected_header.total_bytes) begin
                if ((msg_type !== expected_header.msg_type) ||
                    (layer_id !== expected_header.layer_id) ||
                    (layer_inputs !== expected_header.layer_inputs) ||
                    (num_neurons !== expected_header.num_neurons) ||
                    (bytes_per_neuron !== expected_header.bytes_per_neuron) ||
                    (total_bytes !== expected_header.total_bytes) ||
                    (reserved !== expected_header.reserved)) begin
                    $display("FAIL time=%0t test=%0d header mismatch", $time, test_id);
                    // $display("  exp msg_type=%0h layer_id=%0h layer_inputs=%0h num_neurons=%0h bytes_per_neuron=%0h total_bytes=%0h reserved=%0h",
                    //          expected_header.msg_type, expected_header.layer_id, expected_header.layer_inputs,
                    //          expected_header.num_neurons, expected_header.bytes_per_neuron, expected_header.total_bytes,
                    //          expected_header.reserved);
                    test_failed = 1'b1;
                end
                header_checked = 1'b1;
            end

            if (data_out_valid != '0) begin
                for (int lane = 0; lane < BYTE_LANES; lane++) begin
                    bit expected_valid;
                    bit [7:0] expected_byte;

                    expected_valid = (expected_payload_idx < expected_payload.size());
                    expected_byte = expected_valid ? expected_payload[expected_payload_idx] : 8'h00;

                    if (data_out_valid[lane] !== expected_valid) begin
                        $display("FAIL time=%0t test=%0d lane=%0d valid mismatch exp=%0b act=%0b payload_idx=%0d",
                                 $time, test_id, lane, expected_valid, data_out_valid[lane], expected_payload_idx);
                        test_failed = 1'b1;
                    end

                    if (expected_valid) begin
                        if (data_out[lane] !== expected_byte) begin
                            $display("FAIL time=%0t test=%0d lane=%0d data mismatch exp=0x%0h act=0x%0h payload_idx=%0d",
                                     $time, test_id, lane, expected_byte, data_out[lane], expected_payload_idx);
                            test_failed = 1'b1;
                        end
                        expected_payload_idx++;
                    end
                end
            end
        end

        if (!header_checked) begin
            $display("FAIL time=%0t test=%0d header was never observed", $time, test_id);
            test_failed = 1'b1;
        end

        if (expected_payload_idx != expected_payload.size()) begin
            $display("FAIL time=%0t test=%0d payload byte count mismatch: expected %0d observed %0d",
                     $time, test_id, expected_payload.size(), expected_payload_idx);
            test_failed = 1'b1;
        end

        if (error) begin
            $display("FAIL time=%0t test=%0d unexpected error asserted", $time, test_id);
            test_failed = 1'b1;
        end

        if (test_failed) begin
            failed++;
            $display("FAIL time=%0t test=%0d complete", $time, test_id);
        end else begin
            passed++;
            $display("PASS time=%0t test=%0d payload_bytes=%0d", $time, test_id, expected_payload.size());
        end
    endtask

    initial begin : test_runner
        rst <= 1'b1;
        drive_idle();
        current_test_id = -1;
        passed = 0;
        failed = 0;

        repeat (5) @(posedge clk);
        @(negedge clk);
        rst <= 1'b0;

        // run_test(0); // run a single test for now to make sure everything is working, can increase NUM_TESTS and loop over multiple tests later
        for (int test_id = 0; test_id < NUM_TESTS; test_id++) begin
            run_test(test_id);
        end

        current_test_id = -1;
        $display("Tests completed at time=%0t: %0d passed, %0d failed", $time, passed, failed);
        $finish;
    end

endmodule
