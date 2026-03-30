module neuron_top_cont # (
    parameter int PW = 8
)(
    input logic            clk,
    input logic            rst,

    output logic           thres_read_en,
    output logic [9:0]     thres_read_addr,

    output logic           w_read_en,
    output logic [9:0]     w_read_addr,

    input logic            last,
    input logic            valid_in
);

    logic first_read_happened;

    always_ff @(posedge clk or posedge rst) begin
        if(rst) begin
            thres_read_en <= 1'b0;
            thres_read_addr <= '0;
            w_read_en <= 1'b0;
            w_read_addr <= '0;
            first_read_happened = 1'b0;
        end
        else begin
            thres_read_en <= 1'b0;
            w_read_en     <= 1'b0;
            
            if(!first_read_happened) begin
                thres_read_en <= 1'b1;
                w_read_en <= 1'b1;
                first_read_happened = 1'b1;
            end
            else if(valid_in) begin
                thres_read_en <= 1'b1;
                w_read_en <= 1'b1;
                w_read_addr <= w_read_addr + 1;
                if(last) begin
                    thres_read_addr <= thres_read_addr + 1;
                end
            end
        end
    end

endmodule