module layer_bank #(
    parameter int PW = 16,
    parameter int PN = 4,
    parameter int ADDR_W = 10
)(
    input logic rst,
    input logic clk,

    input  logic [PW-1:0]          x,
    input  logic                   valid_in,
    input  logic                   last,

    input  logic [PN-1:0]          np_active,

    input  logic                   cfg_we,
    input  logic                   cfg_is_weight,
    input  logic [$clog2(PN)-1:0]  cfg_np_sel,
    input  logic [ADDR_W-1:0]      cfg_addr,
    input  logic [PW-1:0]          cfg_data,

    output logic [PN-1:0]          y,
    output logic [PN-1:0][PW-1:0]  popcount,
    output logic [PN-1:0]          valid_out
);

    logic [PN-1:0] cfg_w_we_np;
    logic [PN-1:0] cfg_t_we_np;

    logic [PN-1:0] w_written;
    logic [PN-1:0] t_written;
    logic [PN-1:0] cfg_done_np;

    genvar i;
    
    always_comb begin
        cfg_w_we_np = '0;
        cfg_t_we_np = '0;

        if (cfg_we) begin
            if (cfg_is_weight) begin
                cfg_w_we_np[cfg_np_sel] = 1'b1;
            end
            else begin
                cfg_t_we_np[cfg_np_sel] = 1'b1;
            end
        end
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            w_written <= '0;
            t_written <= '0;
        end
        else begin
            if (cfg_we) begin
                if (cfg_is_weight) begin
                    w_written[cfg_np_sel] <= 1'b1;
                end
                else begin
                    t_written[cfg_np_sel] <= 1'b1;
                end
            end
        end
    end

    assign cfg_done_np = w_written & t_written;

    generate
        for (i = 0; i < PN; i++) begin : GEN_NP
            neuron_top #(
                .PW(PW)
            ) u_neuron_top (
                .clk        (clk),
                .rst        (rst),

                .x          (x),
                .valid_in   (valid_in & np_active[i]),
                .last       (last & np_active[i]),

                .cfg_done   (cfg_done_np[i]),
                .cfg_w_we   (cfg_w_we_np[i]),
                .cfg_w_addr (cfg_addr),
                .cfg_w_data (cfg_data),

                .cfg_t_we   (cfg_t_we_np[i]),
                .cfg_t_addr (cfg_addr),
                .cfg_t_data (cfg_data),

                .y          (y[i]),
                .popcount   (popcount[i]),
                .valid_out  (valid_out[i])
            );
        end
    endgenerate

endmodule