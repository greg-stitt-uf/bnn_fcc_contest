module neuron_tb #(
    parameter int PW = 8
);

    localparam int OUT_LATENCY = 2;

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

    logic [PW-1:0] xin, win, thresholdin, 
    logic lastin, validin;

    logic [PW-1:0] model_accum;
    logic [PW-1:0] model_popcount;
    logic [PW-1:0] model_threshold;
    logic          model_y;
    logic          model_valid_out;

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

    initial begin : generate_clock
        forever #5 clk = ~clk;
    end

    //TASKS
    task automatic drive_idle();
        begin
            x         <= '0;
            w         <= '0;
            threshold <= '0;
            valid_in  <= 1'b0;
            last      <= 1'b0;

            xin         <= '0;
            win         <= '0;
            thresholdin <= '0;
            validin     <= 1'b0;
            lastin      <= 1'b0;
        end
    endtask

    task automatic send_single_beat(
        input logic [PW-1:0] x_in,
        input logic [PW-1:0] w_in,
        input logic [PW-1:0] threshold_in,
        input logic last_in
        input logic valid_in_stim
    );
        begin
            x <= x_in;
            w <= w_in;
            threshold <= threshold_in;
            valid_in <= valid_in_stim;
            last <= last_in;

            xin         <= x_in;
            win         <= w_in;
            thresholdin <= threshold_in;
            validin     <= valid_in_stim;
            lastin      <= last_in;
        end
    endtask


    initial begin : drive_inputs
        $timeformat(-9, 0, " ns");

        rst <= 1'b1;
        x <= '0;
        w <= '0;
        threshold <= '0;
        valid_in  <= 1'b0;
        last      <= 1'b0;

        repeat (5) @(posedge clk);
        @(negedge clk);
        rst <= 1'b0;

        repeat(5) @(posedge clk);

        //TESTS
        drive_idle();
        @(posedge clk);

        send_single_beat(8'b10101010, 8'b11001100, 8'd4, 1'b1, 1'b1);
        repeat(OUT_LATENCY) @(posedge clk);

        disable generate_clock;
        disable neuron_model;
        $display("Tests completed.");
    end

    function automatic logic [PW-1:0] beat_popcount_fn(
        input logic [PW-1:0] x_f,
        input logic [PW-1:0] w_f
    );
        logic [PW-1:0] xnor_vals;
        logic [PW-1:0] count;
        int i;
        begin
            xnor_vals = ~(x_f ^ w_f);
            count = '0;

            for (i = 0; i < PW; i++) begin
                count = count + xnor_vals[i];
            end

            beat_popcount_fn = count;
        end
    endfunction

    always_ff @(posedge clk) begin : neuron_model
        logic [PW-1:0] beat_count;

        if (rst) begin
            model_accum      <= '0;
            model_popcount   <= '0;
            model_threshold  <= '0;
            model_y          <= 1'b0;
            model_valid_out  <= 1'b0;
        end
        else begin
            
        end
    end


endmodule