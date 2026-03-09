module neuron_old #(
    parameter int PW = 16, // bits per beat
    parameter int N_IN_BITS = 784 // total bits accumulated per neuron (layer dependent)
) (
    input logic [PW-1:0]         x,
    input logic [PW-1:0]         w,
    input logic [$clog2(N_IN_BITS+1)-1:0]   threshold, // has threshold
    
    input logic                  clk,
    input logic                  rst,
    input logic                  valid_in,
    input logic                  last,

    output logic                 valid_out,
    output logic                 y,
    output logic [$clog2(N_IN_BITS+1)-1:0]  popcount_out
);

logic [$clog2(N_IN_BITS+1)-1:0] popcount; // luh accumulator

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
            y <= ((popcount + pc) >= threshold) ? 1'b1 : 1'b0; // set y value based on threshold
            valid_out <= 1'b1; // set valid out
            popcount <= '0; // reset popcount
        end else begin
            popcount <= popcount + pc; // else update popcount signal
        end
    end
    
    if (rst) begin // reset logic
        popcount <= '0;
        valid_out <= 1'b0;
        y <= 1'b0;
        popcount_out <= '0;
    end
end

endmodule