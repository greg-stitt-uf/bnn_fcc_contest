module output_neuron #(
    parameter int PW = 8,
    parameter int N_IN_BITS = 784,       // total bits accumulated per neuron (layer dependent)
    localparam int THRESH_W = $clog2(N_IN_BITS+1)
) (
    input logic [PW-1:0]         x,
    input logic [PW-1:0]         w,
    // NO THRESHOLD FOR OUTPUT NEURON

    input logic                  clk,
    input logic                  rst,
    input logic                  valid_in,
    input logic                  last,

    output logic                 valid_out,
    output logic [THRESH_W-1:0]  popcount_out
);

logic [THRESH_W-1:0] popcount; // luh accumulator

logic [PW-1:0] xnored; // xnored bits
logic [$clog2(PW+1)-1:0] pc; // popcount of each beat

int i;

always_comb begin
    xnored = x ~^ w; // xnor bits
    pc = '0; // reset temp popcount
    for(i = 0; i < PW; i++) begin
        pc += xnored[i]; // compute new popcount
    end
end

always_ff @(posedge clk or posedge rst) begin
    
    valid_out <= 1'b0; // default 0

    if(valid_in) begin // if input valid
        if(last) begin // if last beat
            popcount_out <= popcount + pc;
            valid_out <= 1'b1; // set valid out
            popcount <= '0; // reset popcount
        end else begin
            popcount <= popcount + pc; // else update popcount signal
        end
    end
    if (rst) begin // reset logic
        popcount <= '0;
        valid_out <= 1'b0;
        popcount_out <= '0;
    end
end

endmodule