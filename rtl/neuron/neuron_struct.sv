module neuron_struct #(
    parameter int PW = 8 // bits per beat
) (
    input logic [PW-1:0]         x,
    input logic [PW-1:0]         w,
    input logic [PW-1:0]         threshold,
    
    input logic                  clk,
    input logic                  rst,
    input logic                  acc_en,
    input logic                  last,

    output logic                 y,
    output logic [PW-1:0]        popcount
);

    logic [PW-1:0] popcount_r;
    logic [PW-1:0] accumulator_r;
    logic [PW-1:0] threshold_r;

    assign popcount = popcount_r;
    assign y = (popcount >= threshold_r) ? 1'b1 : 1'b0;

    always_ff @(posedge clk or posedge rst) begin
        if(rst) begin
            popcount_r <= '0;
            accumulator_r <= '0;
            threshold_r <= '0;
        end
        else begin
            if(acc_en) begin
                popcount_r <= ~(x ^ w);
                accumulator_r <= accumulator_r + popcount_r;
                threshold_r <= threshold;
            end
        end
    end

endmodule