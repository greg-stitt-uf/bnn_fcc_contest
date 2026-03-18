module neuron_top #(
    parameter int PW = 8
)(
    input logic           clk,
    input logic           rst,
    input logic [PW-1:0]  x,

    input logic           last,
    input logic           valid_in,

    output logic          y,
    output logic [PW-1:0] popcount,
    output logic          valid_out
);

    logic           thres_read_en;
    logic [5:0]     thres_read_addr;
    logic           w_read_en;
    logic [5:0]     w_read_addr;

    neuron_top_cont #(
        .PW(PW)
    ) neuron_top_cont_inst (
        .clk(clk),
        .rst(rst),
        .thres_read_en(thres_read_en),
        .thres_read_addr(thres_read_addr),
        .w_read_en(w_read_en),
        .w_read_addr(w_read_addr),
        .last(last),
        .valid_in(valid_in)
    );

    neuron_top_struct #(
        .PW(PW)
    ) neuron_top_struct_inst (
        .clk(clk),
        .rst(rst),
        .x(x),
        .thres_read_en(thres_read_en),
        .thres_read_addr(thres_read_addr),
        .w_read_en(w_read_en),
        .w_read_addr(w_read_addr),
        .last(last),
        .valid_in(valid_in),
        .y(y),
        .popcount(popcount),
        .valid_out(valid_out)
    );

endmodule