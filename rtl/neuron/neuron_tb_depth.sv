module neuron_tb_depth #(
    parameter int PW = 8,
    parameter NUM_TESTS = 1000,
    parameter int MIN_BEATS = 1,
    parameter int MAX_BEATS = 5,
    parameter int MIN_CYCLES_BETWEEN_TESTS = 1,
    parameter int MAX_CYCLES_BETWEEN_TESTS = 5
);

    logic clk = 1'b0;
    logic rst;
    logic [PW-1:0] x;
    logic [PW-1:0] w;
    logic [PW-1:0] threshold;
    logic valid_in;
    logic last;

    logic y;
    logic [PW-1:0] popcount;
    logic valid_out;

    logic [PW-1:0] xin, win, thresholdin; 
    logic lastin, validin;

    int passed, failed;

    neuron #(
        .PW(PW)
    ) dut (
        .clk(clk),
        .rst(rst),
        .x(x),
        .w(w),
        .threshold(threshold),
        .valid_in(valid_in),
        .last(last),
        .y(y),
        .popcount(popcount),
        .valid_out(valid_out)
    );

    mailbox scoreboard_input_mailbox = new;
    mailbox scoreboard_output_mailbox = new;
    mailbox driver_mailbox = new;

    class neuron_item;
        rand int unsigned num_beats;
        rand bit [PW-1:0] x_beats[];
        rand bit [PW-1:0] w_beats[];
        rand bit [PW-1:0] threshold;

        constraint c_num_beats {
            num_beats inside {[1:5]};
        }

        constraint c_sizes {
            x_beats.size() == num_beats;
            w_beats.size() == num_beats;
        }
    endclass

    typedef struct packed {
        logic [PW-1:0] popcount;
        logic          y;
    } model_out_t;

    typedef struct {
        bit [PW-1:0] x_beats[];
        bit [PW-1:0] w_beats[];
        bit [PW-1:0] threshold;
    } scoreboard_input_t;

    typedef struct packed {
        logic [PW-1:0] popcount;
        logic          y;
    } scoreboard_output_t;

    function automatic model_out_t model(
        input bit [PW-1:0] x_beats[],
        input bit [PW-1:0] w_beats[],
        input bit [PW-1:0] threshold
    );
        model_out_t result;
        logic [PW-1:0] beat_count;
        int i, j;
        begin
            result.popcount = '0;
            result.y        = 1'b0;

            for (i = 0; i < x_beats.size(); i++) begin
                beat_count = '0;
                for (j = 0; j < PW; j++) begin
                    beat_count = beat_count + (~(x_beats[i][j] ^ w_beats[i][j]));
                end
                result.popcount = result.popcount + beat_count;
            end

            result.y = (result.popcount >= threshold);
            return result;
        end
    endfunction

    initial begin : generate_clock
        forever #5 clk <= ~clk;
    end

    initial begin : initialization
        $timeformat(-9, 0, " ns");

        rst <= 1'b1;
        x <= '0;
        w <= '0;
        threshold <= '0;
        valid_in <= 1'b0;
        last <= 1'b0;

        repeat (5) @(posedge clk);
        @(negedge clk);
        rst <= 1'b0;
    end

    initial begin : generator
        neuron_item test;

        for(int i = 0; i < NUM_TESTS; i++) begin
            test = new();
            assert(test.randomize())
            else $fatal(1, "Failed to randomize neuron_item");
            
            driver_mailbox.put(test);
        end
    end

    initial begin : driver
        neuron_item item;

        @(posedge clk iff !rst);

        forever begin
            driver_mailbox.get(item);

            for(int i = 0; i < item.num_beats; i++) begin
                @(negedge clk);
                x <= item.x_beats[i];
                w <= item.w_beats[i];
                threshold <= item.threshold;
                valid_in <= 1'b1;
                last <= (i == item.num_beats - 1);
            end

            @(negedge clk);
            x <= '0;
            w <= '0;
            threshold <= '0;
            valid_in <= 1'b0;
            last <= 1'b0;

            repeat ($urandom_range(MIN_CYCLES_BETWEEN_TESTS - 1, MAX_CYCLES_BETWEEN_TESTS - 1)) @(posedge clk);
        end
    end

    initial begin : start_monitor
        scoreboard_input_t txn;
        bit [PW-1:0] x_q[$];
        bit [PW-1:0] w_q[$];

        forever begin
            @(posedge clk iff (!rst && valid_in));

            x_q.push_back(x);
            w_q.push_back(w);

            if (last) begin
                txn = '{x_beats:x_q, w_beats:w_q, threshold:threshold};
                scoreboard_input_mailbox.put(txn);
                x_q = {};
                w_q = {};
            end
        end
    end

    initial begin : done_monitor
        scoreboard_output_t out;

        forever begin
            @(posedge clk iff valid_out);
            out.popcount = popcount;
            out.y = y;
            scoreboard_output_mailbox.put(out);
        end
    end

    initial begin : scoreboard
        scoreboard_input_t in_txn;
        scoreboard_output_t actual;
        model_out_t expected;

        passed = 0;
        failed = 0;

        for (int i = 0; i < NUM_TESTS; i++) begin
            scoreboard_input_mailbox.get(in_txn);
            scoreboard_output_mailbox.get(actual);

            expected = model(in_txn.x_beats, in_txn.w_beats, in_txn.threshold);

            if ((actual.popcount === expected.popcount) &&
                (actual.y === expected.y)) begin
                $display("PASS time=%0t threshold=%0d popcount=%0d y=%0b",
                         $time, in_txn.threshold, actual.popcount, actual.y);
                passed++;
            end
            else begin
                $display("FAIL time=%0t threshold=%0d actual(popcount=%0d y=%0b) expected(popcount=%0d y=%0b)",
                         $time, in_txn.threshold,
                         actual.popcount, actual.y,
                         expected.popcount, expected.y);
                failed++;
            end
        end

        $display("Tests completed: %0d passed, %0d failed", passed, failed);
        disable generate_clock;
    end

endmodule