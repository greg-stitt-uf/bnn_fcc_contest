module neuron #(
    parameter int PW = 8
)(
    input logic           clk,
    input logic           rst,
    input logic [PW-1:0]  x,
    input logic [PW-1:0]  w,
    input logic [PW-1:0]  threshold,
    input logic           valid_in,
    input logic           last,


    output logic          y,
    output logic [PW-1:0] popcount,
    output logic          valid_out
);

    logic acc_en;
    logic acc_clr;

    neuron_struct #(
        .PW(PW)
    ) neuron_struct_inst (
        .x(x),
        .w(w),
        .threshold(threshold),
        .clk(clk),
        .rst(rst),
        .acc_en(acc_en),
        .acc_clr(acc_clr),
        .y(y),
        .popcount(popcount)
    );

    neuron_cont #(
        .PW(PW)
    ) neuron_cont_inst (
        .valid_in(valid_in),
        .last(last),
        .clk(clk),
        .rst(rst),
        .valid_out(valid_out),
        .acc_en(acc_en),
        .acc_clr(acc_clr)
    );

endmodule