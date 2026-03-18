module neuron_top_struct #(
    parameter int PW = 8
)(
    input logic           clk,
    input logic           rst,
    input logic [PW-1:0]  x,

    input logic           thres_read_en,
    input logic [5:0]     thres_read_addr,

    input logic           w_read_en,
    input logic [5:0]     w_read_addr,

    input logic           last,
    input logic           valid_in,

    output logic          y,
    output logic [PW-1:0] popcount,
    output logic          valid_out
);

    logic [PW-1:0]  w;
    logic [PW-1:0]  threshold;

    // Pipeline inputs to match 2-cycle BRAM latency
    logic [PW-1:0]  x_r, x_r2;
    logic           valid_in_r, valid_in_r2;
    logic           last_r, last_r2;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            x_r <= '0;
            valid_in_r <= 1'b0;
            last_r <= 1'b0;
            x_r2 <= '0;
            valid_in_r2 <= 1'b0;
            last_r2 <= 1'b0;
        end else begin
            x_r <= x;
            valid_in_r <= valid_in;
            last_r <= last;
            x_r2 <= x_r;
            valid_in_r2 <= valid_in_r;
            last_r2 <= last_r;
        end
    end

    neuron #(
        .PW(PW)
    ) neuron_inst (
        .clk(clk),
        .rst(rst),
        .x(x_r2),
        .w(w),
        .threshold(threshold),
        .valid_in(valid_in_r2),
        .last(last_r2),
        .y(y),
        .popcount(popcount),
        .valid_out(valid_out)
    );

    weight_bram weight_bram_inst ( // may have to regenerate these brams since I used 16 width bits instead of 8.... depends on what we do with PW
        .clka(clk),
        .ena(1'b0),               
        .wea(1'b0),             
        .addra('0),        
        .dina('0),      
        .clkb(clk),
        .enb(w_read_en),        
        .web(1'b0),                  
        .addrb(w_read_addr),       
        .doutb(w)                    
    );

    threshold_bram threshold_bram_inst (
        .clka(clk),
        .ena(1'b0),
        .wea(1'b0),
        .addra('0),
        .dina('0),
        .clkb(clk),
        .enb(thres_read_en),
        .web(1'b0),
        .addrb(thres_read_addr),
        .doutb(threshold)
    );

endmodule