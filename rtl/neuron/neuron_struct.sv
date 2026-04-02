module neuron_struct #(
    parameter int PW = 8 // bits per beat
) (
    input logic [PW-1:0]         x,
    input logic [PW-1:0]         w,
    input logic [PW-1:0]         threshold,
    
    input logic                  clk,
    input logic                  rst,
    input logic                  acc_en,
    input logic                  acc_clr,

    output logic                 y,
    output logic [PW-1:0]        popcount
);

    logic [PW-1:0] accumulator_r;
    logic [PW-1:0] threshold_r;
    logic [PW-1:0] xnor_vals;
    logic [PW-1:0] beat_count;

    logic [PW-1:0] out_popcount_r;
    logic [PW-1:0] out_threshold_r;
    logic [PW-1:0] accum_next;

    assign beat_count = popcount_fn(xnor_vals);
    assign popcount = out_popcount_r;
    assign y = (out_popcount_r >= out_threshold_r) ? 1'b1 : 1'b0;
    assign xnor_vals = ~(x ^ w);
    assign accum_next = acc_en ? (accumulator_r + beat_count) : accumulator_r;

    function automatic logic [PW-1:0] popcount_fn(
        input logic [PW-1:0] v
    );
        int i;
        begin
            popcount_fn = '0;
            for (i = 0; i < PW; i++) begin
                if(v[i]) popcount_fn++;
            end
        end
    endfunction

    always_ff @(posedge clk or posedge rst) begin
        if(rst) begin
            accumulator_r <= '0;
            threshold_r <= '0;
            out_popcount_r <= '0;
            out_threshold_r<= '0;
        end
        else begin
            if(acc_clr) begin
                out_popcount_r  <= accum_next;
                out_threshold_r <= threshold_r;
            end
            if(acc_clr && acc_en) begin
                accumulator_r <= beat_count;
                threshold_r <= threshold;
            end
            else if (acc_clr) begin
                accumulator_r <= '0;
                threshold_r <= '0;
            end
            else if(acc_en) begin
                accumulator_r <= accumulator_r + beat_count;
                threshold_r <= threshold;
            end
        end
    end

endmodule