`timescale 1ns/100ps

module neuron_tb #(parameter int NUM_TESTS = 10000
);
    localparam int NUM_WEIGHTS = 4, NUM_INPUTS = 4;
    localparam int THRESHOLD_BITS = 1; 
    logic clk = 1'b0, reset, en, valid_in;
    logic [NUM_WEIGHTS-1:0] w, x;
    logic [$clog2(NUM_WEIGHTS+1)-1:0] y; 
    logic valid_out; 


    neuron(.NUM_WEIGHTS(NUM_WEIGHTS), .NUM_INPUTS(NUM_INPUTS), .THRESHOLD_BITS(THRESHOLD_BITS))(.*);


    initial begin : generate_clk
        forever #5 clk <= !clk;
    end  

    initial begin : generate_stim
        rst <= 1'b1; 
        x <= '0; 
        w <= '0; 
        en <=  1'b0; 
        repeat(10) @(posedge clk); 
        @(negedge clk);
        repeat(5) @(posedge clk);

        for(int i = 0; i < NUM_TESTS; i++) begin 
            x <= $urandom; 
            w <= $urandom; 
            en <= 1'b1; 
            
            @(posedge clk);

            $display("Test %b: The values are x = %0b, w = %0b, y = %b\n", i, x, w, y);
        end
    end
endmodule
