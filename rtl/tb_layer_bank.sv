`timescale 1ns/1ps

module tb_layer_bank #(
    parameter int PW = 16,
    parameter int PN = 4,
    parameter int ADDR_W = 10,
    parameter NUM_TESTS = 1000
);

    logic                   rst;
    logic                   clk = 1'b0;

    logic [PW-1:0]          x;
    logic                   valid_in;
    logic                   last;

    logic                   cfg_we;
    logic                   cfg_is_weight;
    logic [$clog2(PN)-1:0]  cfg_np_sel;
    logic [ADDR_W-1:0]      cfg_addr;
    logic [PW-1:0]          cfg_data;

    logic [PN-1:0]          np_active;
    logic [PN-1:0]          y;
    logic [PN-1:0][PW-1:0]  popcount;
    logic [PN-1:0]          valid_out;

    int passed, failed;

    layer_bank #(
        .PW(PW),
        .PN(PN),
        .ADDR_W(ADDR_W)
    ) dut (
        .rst(rst),
        .clk(clk),
        .x(x),
        .valid_in(valid_in),
        .last(last),
        .np_active(np_active),
        .cfg_we(cfg_we),
        .cfg_is_weight(cfg_is_weight),
        .cfg_np_sel(cfg_np_sel),
        .cfg_addr(cfg_addr),
        .cfg_data(cfg_data),
        .y(y),
        .popcount(popcount),
        .valid_out(valid_out)
    );

    initial begin : generate_clock
        forever #5 clk <= ~clk;
    end

endmodule