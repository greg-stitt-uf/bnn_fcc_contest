`timescale 1ns/1ps

module tb_layer_bank #(
    parameter int PW = 16,
    parameter int PN = 4,
    parameter int ADDR_W = 10,
    parameter NUM_TESTS = 1000
);

    localparam int DEPTH = (1 << ADDR_W);

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

    logic [PW-1:0] w_bram_data [0:PN-1][0:DEPTH-1];
    logic [PW-1:0] t_bram_data [0:PN-1][0:DEPTH-1];

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

    initial begin : initialization
        $timeformat(-9, 0, " ns");

        rst <= 1'b1;
        x <= '0;
        valid_in <= 1'b0;
        last <= 1'b0;

        repeat (5) @(posedge clk);
        @(negedge clk);
        rst <= 1'b0;
    end

    initial begin : load_bram_data
        int unsigned depth = (1 << ADDR_W);

        @(negedge rst);

        for(int unsigned neuron = 0; neuron < PN; neuron++) begin

            //Weight Loading
            for(int unsigned addr = 0; addr < depth; addr++) begin
                logic [PW-1:0] w_data;
                w_data = $urandom;
                cfg_we <= 1'b1;
                cfg_is_weight <= 1'b1;
                cfg_np_sel <= neuron;
                cfg_addr <= addr;
                cfg_data <= w_data;
                w_bram_data[neuron][addr] = w_data;
                @(posedge clk);
            end

            //Threshold Loading
            for(int unsigned addr = 0; addr < depth; addr++) begin
                logic [PW-1:0] t_data;
                t_data = $urandom_range(0, 16'h00AA);;
                cfg_we <= 1'b1;
                cfg_is_weight <= 1'b0;
                cfg_np_sel <= neuron;
                cfg_addr <= addr;
                cfg_data <= t_data;
                t_bram_data[neuron][addr] = t_data;
                @(posedge clk);
            end
        end

        cfg_we <= 1'b0;
        @(posedge clk);
    end

endmodule