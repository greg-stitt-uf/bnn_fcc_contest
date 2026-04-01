`timescale 1ns/1ps

// module tb_neuron();

// parameter PW = 4;           // Width is 4
// parameter TOTAL_BITS = 8;    // Total is 8 (so 2 beats per neuron)

// logic clk;
// logic rst;
// logic [PW-1:0] in;
// logic [PW-1:0] weights;
// logic [$clog2(TOTAL_BITS+1)-1:0] threshold;
// logic valid_in;
// logic last;

// logic [$clog2(TOTAL_BITS+1)-1:0] popcount;
// logic valid_out;
// logic y;

// // DUT
// neuron_processor #(
//     .INPUT_WIDTH(PW),
//     .NEURON_COUNT(TOTAL_BITS)
// ) uut (
//     .clk(clk),
//     .rst(rst),
//     .in(in),
//     .weights(weights),
//     .threshold(threshold),
//     .valid_in(valid_in),
//     .last(last),
//     .popcount(popcount),
//     .valid_out(valid_out),
//     .y(y)
// );

// // clock
// initial clk = 0;
// always #5 clk = ~clk;

// // stimulus
// initial begin
//     // initialize
//     rst = 1;
//     valid_in = 0;
//     in = 0;
//     weights = 0;
//     threshold = 0;
//     last = 0;

//     #20;
//     rst = 0;

//     // --- NEURON 1 (2 beats) ---
//     #10;
//     valid_in = 1;
//     threshold = 7;
//     in = 4'b1111;      // First 4 bits
//     weights = 4'b1111;
//     last = 0;          // Not the end yet
    
//     #10;
//     in = 4'b1111;      // Last 4 bits
//     weights = 4'b1111;
//     last = 1;          // Now it's the end

//     // --- NEURON 2 (2 beats) ---
//     #10;
//     threshold = 5;
//     in = 4'b0000;      // First 4 bits
//     weights = 4'b1010;
//     last = 0;
    
//     #10;
//     in = 4'b1111;      // Last 4 bits
//     weights = 4'b1010;
//     last = 1;

//     // --- NEURON 3 (2 beats) ---
//     #10;
//     threshold = 1;
//     in = 4'b1111;      // First 4 bits
//     weights = 4'b0000;
//     last = 0;
    
//     #10;
//     in = 4'b1111;      // Last 4 bits
//     weights = 4'b0000;
//     last = 1;

//     // Cleanup
//     #10;
//     valid_in = 0;
//     last = 0;
//     in = 0;

//     #100;
//     $finish;
// end

// always @(posedge clk) begin
//     if (valid_out) begin
//         $display("time=%0t popcount=%0d y=%b", $time, popcount, y);
//     end
// end

// endmodule

// module tb_neuron();

// parameter PW = 8;           // Width is 4
// parameter TOTAL_BITS = 8;    // Total is 8 (so 2 beats per neuron)

// logic clk;
// logic rst;
// logic [PW-1:0] in;
// logic [PW-1:0] weights;
// logic [$clog2(TOTAL_BITS+1)-1:0] threshold;
// logic valid_in;
// logic last;

// logic [$clog2(TOTAL_BITS+1)-1:0] popcount;
// logic valid_out;
// logic y;

// // DUT
// neuron_processor #(
//     .INPUT_WIDTH(PW),
//     .NEURON_COUNT(TOTAL_BITS)
// ) uut (
//     .clk(clk),
//     .rst(rst),
//     .in(in),
//     .weights(weights),
//     .threshold(threshold),
//     .valid_in(valid_in),
//     .last(last),
//     .popcount(popcount),
//     .valid_out(valid_out),
//     .y(y)
// );

// // clock
// initial clk = 0;
// always #5 clk = ~clk;

// // stimulus
// initial begin
//     // initialize
//     rst = 1;
//     valid_in = 0;
//     in = 0;
//     weights = 0;
//     threshold = 0;
//     last = 0;

//     #20;
//     rst = 0;

//     // --- NEURON 1 (1 beats) ---
//     #10;
//     valid_in = 1;
//     threshold = 7;
//     in = 8'b11111111;      // First 4 bits
//     weights = 8'b11111111;
//     last = 1;         

//     // --- NEURON 2 (1 beat) ---
//     #10;
//     threshold = 5;
//     in = 8'b00001111;      // First 4 bits
//     weights = 8'b10101010;
//     last = 1;

//     // --- NEURON 3 (2 beat) ---
//     #10;
//     threshold = 1;
//     in = 8'b11111111;      // First 4 bits
//     weights = 8'b00000000;
//     last = 1;

//     // Cleanup
//     #10;
//     valid_in = 0;
//     last = 0;
//     in = 0;

//     #100;
//     $finish;
// end

// always @(posedge clk) begin
//     if (valid_out) begin
//         $display("time=%0t popcount=%0d y=%b", $time, popcount, y);
//     end
// end

// endmodule

module tb_neuron();

parameter PW = 4;             
parameter TOTAL_BITS = 120;    
parameter TOTAL_CYCLES = TOTAL_BITS / PW; 

logic clk, rst, valid_in, last, valid_out, y;
logic [PW-1:0] in, weights;
logic [$clog2(TOTAL_BITS+1)-1:0] threshold, popcount;

// DUT
neuron_processor #(
    .INPUT_WIDTH(PW),
    .NEURON_COUNT(TOTAL_BITS)
) uut (.*);

initial clk = 0;
always #5 clk = ~clk;

initial begin
    rst = 1;
    valid_in = 0; last = 0; in = 0; weights = 0;
    threshold = 784; // Small threshold to ensure Y triggers
    #20 rst = 0;
    @(posedge clk);

    // --- NEURON 1: ALL MATCHES ---
    // Goal: Popcount should be exactly 784
    $display("\n[STIMULUS] Starting Neuron 1: Expecting Popcount 784");
    for (int i = 0; i < TOTAL_CYCLES; i++) begin
        valid_in = 1;
        in       = 4'hF; 
        weights  = 4'hF; // 1 XNOR 1 = 1 (8 matches per cycle)
        last     = (i == TOTAL_CYCLES - 1);
        @(posedge clk);
    end

    // --- NEURON 2: ZERO MATCHES ---
    // Goal: Popcount should be exactly 0
    $display("[STIMULUS] Starting Neuron 2: Expecting Popcount 0");
    for (int i = 0; i < TOTAL_CYCLES; i++) begin
        valid_in = 1;
        in       = 4'hF; 
        weights  = 4'h0; // 1 XNOR 0 = 0 (0 matches per cycle)
        last     = (i == TOTAL_CYCLES - 1);
        @(posedge clk);
    end

    valid_in = 0; last = 0;
    #200 $finish;
end

// Simple monitor to catch the results
always @(posedge clk) begin
    if (valid_out) begin
        $display(">>> [HARDWARE OUT] Time: %0t | Popcount: %0d | Y: %b", $time, popcount, y);
        if (popcount == 784) $display("    RESULT: MAX SUCCESS");
        else if (popcount == 0) $display("    RESULT: ZERO SUCCESS");
        else $display("    RESULT: ERROR! Expected 784 or 0 but got %0d", popcount);
    end
end

endmodule