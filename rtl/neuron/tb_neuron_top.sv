module tb_neuron_top #(
    parameter int PW = 8,
    parameter NUM_TESTS = 1000,
    parameter int MIN_BEATS = 1,
    parameter int MAX_BEATS = 5,
    parameter int MIN_CYCLES_BETWEEN_TESTS = 1,
    parameter int MAX_CYCLES_BETWEEN_TESTS = 5
);

    logic           clk;
    logic           rst;

    logic [PW-1:0]  x;

    logic           last;
    logic           valid_in;

    logic          y;
    logic [PW-1:0] popcount;
    logic          valid_out;

    neuron_top #(
        .PW(PW)
    ) neuron_top_inst (
        .clk(clk),
        .rst(rst),
        .x(x),
        .last(last),
        .valid_in(valid_in),
        .y(y),
        .popcount(popcount),
        .valid_out(valid_out)
    );

    // Add test logic here (e.g., stimulus generation, assertions)

endmodule