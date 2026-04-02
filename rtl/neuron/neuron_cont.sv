module neuron_cont # (
    parameter int PW = 8
)(
    input logic          valid_in,
    input logic          last,
    input logic          clk,
    input logic          rst,
    
    output logic         valid_out,
    output logic         acc_en,
    output logic         acc_clr
);

    assign acc_en = valid_in;

    logic last_r, last_r2;

    assign valid_out = last_r2; 
    assign acc_clr = last_r;

    always_ff @(posedge clk or posedge rst) begin
        if(rst) begin
            last_r <= 1'b0;
            last_r2 <= 1'b0;
        end
        else begin
            last_r <= last;
            last_r2 <= last_r;
        end
    end

endmodule