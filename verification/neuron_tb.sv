`timescale 1ns/100ps

module neuron_tb #(parameter int NUM_TESTS = 15
);
    localparam int NUM_WEIGHTS = 4, NUM_INPUTS = 4;
    localparam int THRESHOLD_BITS = 3; 
    localparam int POPCOUNT_WIDTH = 32;
    logic clk = 1'b0, rst, valid_in;
    logic [NUM_WEIGHTS-1:0] w, x;
    logic y; 
    logic valid_out; 
    logic [POPCOUNT_WIDTH-1:0] popcount_out;
    logic last;
    integer i; 


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
        @(posedge clk);
        
        $display("Test 1");
        for(i = 0; i < NUM_TESTS; i++) begin 
            x <= i; 
            w <= i-1; 
            valid_in <= 1'b1; 
            @(posedge clk);
            valid_in <= 1'b0; 
            @(posedge clk);
            $display("Test %d: The values are x = %b, w = %b, y = %b, popcount = %d\n", i, x, w, y, popcount_out);
        end
        last <= 1'b1; 
        repeat(3) @(posedge clk);
        last <= 1'b0;
        $display("Test %d: The values are x = %b, w = %b, y = %b, popcount = %d\n", i, x, w, y, popcount_out);
        @(posedge clk);

        $display("Test 2");
        for(i = 0; i < NUM_TESTS; i++) begin 
            x <= i; 
            w <= i-1;  
            valid_in <= 1'b1; 
            @(posedge clk);
            valid_in <= 1'b0; 
            @(posedge clk);
            $display("Test %d: The values are x = %b, w = %b, y = %b, popcount = %d\n", i, x, w, y, popcount_out);
        end
        last <= 1'b1; 
        repeat (3) @(posedge clk);
        $display("Test %d: The values are x = %b, w = %b, y = %b, popcount = %d\n", i, x, w, y, popcount_out);
        
        $display("Tests Completed!!");
        disable generate_clk;
    end
endmodule
