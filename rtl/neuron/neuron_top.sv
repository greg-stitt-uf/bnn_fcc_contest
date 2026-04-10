module neuron_top #(
    parameter int PW = 16,
    parameter int ADDR_W = 10,
    parameter int INPUTS_PER_NEURON = 784
)(
    input logic           clk,
    input logic           rst,
    input logic [PW-1:0]  x,

    input logic           valid_in,

    input logic           cfg_done,

    input  logic         cfg_w_we,
    input  logic [ADDR_W-1:0]   cfg_w_addr,
    input  logic [PW-1:0] cfg_w_data,

    input  logic         cfg_t_we,
    input  logic [ADDR_W-1:0]   cfg_t_addr,
    input  logic [PW-1:0] cfg_t_data,

    output logic          y,
    output logic [PW-1:0] popcount,
    output logic          valid_out
);

    logic                  thres_read_en;
    logic [ADDR_W-1:0]     thres_read_addr;
    logic                  w_read_en;
    logic [ADDR_W-1:0]     w_read_addr;
    logic                  last;

    neuron_top_cont #(
        .PW(PW),
        .ADDR_W(ADDR_W),
        .INPUTS_PER_NEURON(INPUTS_PER_NEURON)
    ) neuron_top_cont_inst (
        .clk(clk),
        .rst(rst),
        .cfg_done(cfg_done),
        .thres_read_en(thres_read_en),
        .thres_read_addr(thres_read_addr),
        .w_read_en(w_read_en),
        .w_read_addr(w_read_addr),
        .last(last),
        .valid_in(valid_in)
    );

    neuron_top_struct #(
        .PW(PW),
        .ADDR_W(ADDR_W)
    ) neuron_top_struct_inst (
        .clk(clk),
        .rst(rst),
        .x(x),

        .cfg_w_we(cfg_w_we),
        .cfg_w_addr(cfg_w_addr),
        .cfg_w_data(cfg_w_data),

        .cfg_t_we(cfg_t_we),
        .cfg_t_addr(cfg_t_addr),
        .cfg_t_data(cfg_t_data),

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