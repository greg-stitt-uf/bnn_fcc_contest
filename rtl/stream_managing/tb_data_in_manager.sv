`timescale 1ns/1ps

module tb_data_in_manager #(
    parameter int INPUT_DATA_WIDTH = 8,
    parameter int INPUT_BUS_WIDTH = 64,
    parameter int NUM_TESTS = 250,
    parameter int MIN_BEATS = 1,
    parameter int MAX_BEATS = 6
);

    localparam int BYTE_LANES = INPUT_BUS_WIDTH / 8;
    localparam int OUT_LANES = INPUT_BUS_WIDTH / 16;
    localparam int OUT_CHUNK_W = INPUT_DATA_WIDTH * 2;

    typedef bit [INPUT_BUS_WIDTH-1:0] bus_word_t;
    typedef bit [BYTE_LANES-1:0] keep_t;
    typedef bit [OUT_CHUNK_W-1:0] out_chunk_t;

    logic                             clk = 1'b0;
    logic                             rst;
    logic                             data_in_valid;
    logic                             data_in_ready;
    logic [INPUT_BUS_WIDTH-1:0]       data_in_data;
    logic [BYTE_LANES-1:0]            data_in_keep;
    logic                             data_in_last;

    logic [OUT_CHUNK_W-1:0]           img_data_out[OUT_LANES];
    logic [OUT_LANES-1:0]             img_data_out_valid;
    logic                             img_data_out_last;
    logic                             img_data_out_error;

    int                               current_test_id;
    int                               current_beat_id;
    int unsigned                      passed;
    int unsigned                      failed;

    data_in_manager #(
        .INPUT_DATA_WIDTH(INPUT_DATA_WIDTH),
        .INPUT_BUS_WIDTH(INPUT_BUS_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .data_in_valid(data_in_valid),
        .data_in_ready(data_in_ready),
        .data_in_data(data_in_data),
        .data_in_keep(data_in_keep),
        .data_in_last(data_in_last),
        .img_data_out(img_data_out),
        .img_data_out_valid(img_data_out_valid),
        .img_data_out_last(img_data_out_last),
        .img_data_out_error(img_data_out_error)
    );

    initial begin : generate_clock
        forever #5 clk = ~clk;
    end

    task automatic drive_idle();
        begin
            data_in_valid <= 1'b0;
            data_in_data <= '0;
            data_in_keep <= '0;
            data_in_last <= 1'b0;
        end
    endtask

    task automatic make_random_stream(
        output bus_word_t beats[],
        output keep_t keeps[]
    );
        int unsigned num_beats;

        num_beats = $urandom_range(MIN_BEATS, MAX_BEATS);
        beats = new[num_beats];
        keeps = new[num_beats];

        foreach (beats[i]) begin
            beats[i] = bus_word_t'($urandom);
            beats[i][63:32] = $urandom;
            if (i == num_beats - 1) begin
                keeps[i] = keep_t'((1 << $urandom_range(1, BYTE_LANES)) - 1);
            end else begin
                keeps[i] = '1;
            end
        end
    endtask

    task automatic build_expected(
        input bus_word_t beat,
        input keep_t keep,
        input bit is_last,
        output out_chunk_t expected_chunks[OUT_LANES],
        output logic [OUT_LANES-1:0] expected_valid,
        output logic expected_last,
        output logic expected_error
    );
        bus_word_t masked_beat;

        masked_beat = '0;
        expected_valid = '0;
        expected_last = is_last;
        expected_error = 1'b0;

        for (int byte_idx = 0; byte_idx < BYTE_LANES; byte_idx++) begin
            if (keep[byte_idx]) begin
                masked_beat[byte_idx*8 +: 8] = beat[byte_idx*8 +: 8];
            end
        end

        for (int lane = 0; lane < OUT_LANES; lane++) begin
            expected_chunks[lane] = masked_beat[lane*16 +: 16];
            expected_valid[lane] = keep[2*lane] | keep[2*lane + 1];
        end
    endtask

    task automatic check_output_beat(
        input int test_id,
        input int beat_id,
        input out_chunk_t expected_chunks[OUT_LANES],
        input logic [OUT_LANES-1:0] expected_valid,
        input logic expected_last,
        input logic expected_error,
        inout bit test_failed
    );
        for (int lane = 0; lane < OUT_LANES; lane++) begin
            if (img_data_out_valid[lane] !== expected_valid[lane]) begin
                $display("FAIL time=%0t test=%0d beat=%0d lane=%0d valid mismatch exp=%0b act=%0b",
                         $time, test_id, beat_id, lane, expected_valid[lane], img_data_out_valid[lane]);
                test_failed = 1'b1;
            end

            if (img_data_out[lane] !== expected_chunks[lane]) begin
                $display("FAIL time=%0t test=%0d beat=%0d lane=%0d data mismatch exp=0x%0h act=0x%0h",
                         $time, test_id, beat_id, lane, expected_chunks[lane], img_data_out[lane]);
                test_failed = 1'b1;
            end
        end

        if (img_data_out_last !== expected_last) begin
            $display("FAIL time=%0t test=%0d beat=%0d last mismatch exp=%0b act=%0b",
                     $time, test_id, beat_id, expected_last, img_data_out_last);
            test_failed = 1'b1;
        end

        if (img_data_out_error !== expected_error) begin
            $display("FAIL time=%0t test=%0d beat=%0d error mismatch exp=%0b act=%0b",
                     $time, test_id, beat_id, expected_error, img_data_out_error);
            test_failed = 1'b1;
        end
    endtask

    task automatic run_test(input int test_id);
        bus_word_t beats[];
        keep_t keeps[];
        bit test_failed;

        current_test_id = test_id;
        current_beat_id = -1;
        test_failed = 1'b0;

        make_random_stream(beats, keeps);

        for (int beat = 0; beat < beats.size(); beat++) begin
            out_chunk_t expected_chunks[OUT_LANES];
            logic [OUT_LANES-1:0] expected_valid;
            logic expected_last;
            logic expected_error;

            current_beat_id = beat;
            build_expected(beats[beat], keeps[beat], beat == beats.size() - 1,
                           expected_chunks, expected_valid, expected_last, expected_error);

            @(negedge clk);
            data_in_valid <= 1'b1;
            data_in_data <= beats[beat];
            data_in_keep <= keeps[beat];
            data_in_last <= (beat == beats.size() - 1);

            @(posedge clk iff data_in_ready);

            @(negedge clk);
            drive_idle();

            @(posedge clk);
            @(negedge clk);
            check_output_beat(test_id, beat, expected_chunks, expected_valid, expected_last, expected_error, test_failed);
        end

        if (test_failed) begin
            failed++;
            $display("FAIL time=%0t test=%0d complete", $time, test_id);
        end else begin
            passed++;
            $display("PASS time=%0t test=%0d beats=%0d", $time, test_id, beats.size());
        end
    endtask

    initial begin : test_runner
        rst <= 1'b1;
        drive_idle();
        current_test_id = -1;
        current_beat_id = -1;
        passed = 0;
        failed = 0;

        repeat (5) @(posedge clk);
        @(negedge clk);
        rst <= 1'b0;

        for (int test_id = 0; test_id < NUM_TESTS; test_id++) begin
            run_test(test_id);
        end

        current_test_id = -1;
        current_beat_id = -1;
        $display("Tests completed at time=%0t: %0d passed, %0d failed", $time, passed, failed);
        $finish;
    end

endmodule
