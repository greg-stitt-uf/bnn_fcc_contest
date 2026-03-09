module neuron_top #(
    parameter int PW = 8
)(
    input logic           clk,
    input logic           rst,
    input logic [PW-1:0]  x,

    output logic          y,
    output logic [PW-1:0] popcount,
    output logic          valid_out
);

    logic [PW-1:0]  w;
    logic [PW-1:0]  threshold;
    logic           valid_in;
    logic           last;

    neuron #(
        .PW(PW)
    ) neuron_inst (
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

endmodule