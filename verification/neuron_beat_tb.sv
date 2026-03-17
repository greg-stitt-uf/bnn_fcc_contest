`timescale 1ns/100ps

module neuron_beat_tb #(parameter int NUM_TESTS = 500
);
    localparam int NUM_WEIGHTS = 4, NUM_INPUTS = 4;
    localparam int THRESHOLD_BITS = 5; 
    localparam int POPCOUNT_WIDTH = 32;
    logic clk = 1'b0, rst, valid_in;
    logic [NUM_WEIGHTS-1:0] w, x;
    logic [NUM_WEIGHTS-1:0] w_b0, x_b0;
    logic y; 
    logic last;
    logic valid_out; 
    logic [POPCOUNT_WIDTH-1:0] popcount_out;
    integer i; 



    neuron_beat #(.NUM_WEIGHTS(NUM_WEIGHTS), .NUM_INPUTS(NUM_INPUTS), .THRESHOLD_BITS(THRESHOLD_BITS), .POPCOUNT_WIDTH(POPCOUNT_WIDTH)) DUT (
        .en(1'b1),
        .*);


    initial begin : generate_clk
        forever #5 clk <= !clk;
    end  


    initial begin : generate_stim
        rst <= 1'b1; 
        x <= '0; 
        w <= '0; 
        last <= '0;
        valid_in <= 1'b0;
        repeat(10) @(posedge clk); 
        @(negedge clk);
        rst <= 1'b0;
        @(posedge clk);

        for(i = 0; i < NUM_TESTS; i++) begin 
            x <= $urandom; 
            w <= $urandom; 
            valid_in <= 1'b1;
            last <= 1'b0; 
            @(posedge clk); // START
            valid_in <= 1'b1;
            last <= 1'b0; 
            x_b0 <= x;
            w_b0 <= w;
            x <= $urandom; // Change inputs to test another beat
            w <= $urandom; 
            @(posedge clk); // COUNT_ONES
            valid_in <= 1'b1;
            last <= 1'b1;
            @(posedge clk); // COUNT_ONES one more
            valid_in <= 1'b1;
            last <= 1'b0;
            $display("Test %d: The values in beat 0 are x = %b, w = %b, popcount = %d\n", i, x_b0, w_b0, popcount_out);
            @(posedge clk); // OUTPUT
            $display("Test %d: The values in beat 1 are x = %b, w = %b, y (popcount >= threshold) = %b, popcount = %d\n", i, x, w, y, popcount_out);
        end

        $display("Tests Completed!!");
        disable generate_clk;
    end
endmodule