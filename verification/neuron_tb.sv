`timescale 1ns/100ps

module neuron_tb #(parameter int NUM_TESTS = 10000
);
    localparam int NUM_WEIGHTS = 4, NUM_INPUTS = 4;
    localparam int THRESHOLD_BITS = 3; 
    localparam int POPCOUNT_WIDTH = 32;
    logic clk = 1'b0, rst, valid_in;
    logic [NUM_WEIGHTS-1:0] w, x;
    logic [$clog2(NUM_WEIGHTS+1)-1:0] y; 
    logic valid_out; 
    logic [POPCOUNT_WIDTH-1:0] popcount_out;


    neuron #(.NUM_WEIGHTS(NUM_WEIGHTS), .NUM_INPUTS(NUM_INPUTS), .THRESHOLD_BITS(THRESHOLD_BITS), .POPCOUNT_WIDTH(POPCOUNT_WIDTH)) DUT (
        .en(1'b1),
        .*);


    initial begin : generate_clk
        forever #5 clk <= !clk;
    end  


    initial begin : generate_stim
        rst <= 1'b1; 
        x <= '0; 
        w <= '0; 
        valid_in <= 1'b0;
        repeat(10) @(posedge clk); 
        @(negedge clk);
        rst <= 1'b0;
        repeat(5) @(posedge clk);

        for(int i = 0; i < NUM_TESTS; i++) begin 
            x <= $urandom; 
            w <= $urandom; 
            valid_in <= 1'b1; 
            
            repeat(4) @(posedge clk);
            valid_in <= 1'b0; 
            @(posedge clk);

            $display("Test %d: The values are x = %b, w = %b, y = %b, popcount = %d\n", i, x, w, y, popcount_out);
        end

        $display("Tests Completed!!");
        disable generate_clk;
    end
endmodule