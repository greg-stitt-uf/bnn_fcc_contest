module neuron_top_struct #(
    parameter int PW = 8,
    parameter int ADDR_W = 10
)(
    input logic           clk,
    input logic           rst,
    input logic [PW-1:0]  x,

    input logic           thres_read_en,
    input logic [ADDR_W-1:0]     thres_read_addr,

    input logic           w_read_en,
    input logic [ADDR_W-1:0]     w_read_addr,

    input  logic          cfg_w_we,
    input  logic [ADDR_W-1:0]    cfg_w_addr,
    input  logic [PW-1:0] cfg_w_data,

    input  logic          cfg_t_we,
    input  logic [ADDR_W-1:0]    cfg_t_addr,
    input  logic [PW-1:0] cfg_t_data,

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

    //instantiation instructions
    // Opened Vivado and loaded the project
    // Navigated to IP Catalog in the Flow Navigator
    // Searched for and selected Block Memory Generator
    // Added the IP to the project
    // Configured Memory Type as True Dual-Port RAM
    // Set Data Width to 16 bits
    // Set Memory Depth to 64 entries
    // Set Address Width to 6 bits
    // Enabled Single Clock Operation for both ports
    // Enabled EN (Enable) pins for memory access
    // Set Write Mode to WRITE_FIRST
    // Enabled Output Registering
    // Configured Read Latency = 1 cycle (plus 1 cycle from output register ? total 2 cycles)
    // Enabled Memory Initialization File
    // Loaded .mem file (e.g., weight_bram.mem / threshold_bram.mem)
    // Generated the IP and output products
    // Instantiated the generated BRAM module in SystemVerilog
    // Connected clk, en, addr, and dout signals in the design
    // Ensured .mem files were included in the simulation directory for proper initialization
    weight_bram weight_bram_inst (
        .clka(clk),
        .ena(1'b1),
        .wea(cfg_w_we),
        .addra(cfg_w_addr),
        .dina(cfg_w_data),
        .douta(),   

        .clkb(clk),
        .enb(w_read_en),        
        .web(1'b0),                  
        .addrb(w_read_addr),   
        .dinb('0),    
        .doutb(w)                    
    );

    threshold_bram threshold_bram_inst (
        .clka(clk),
        .ena(1'b1),
        .wea(cfg_t_we),
        .addra(cfg_t_addr),
        .dina(cfg_t_data),
        .douta(),

        .clkb(clk),
        .enb(thres_read_en),
        .web(1'b0),
        .addrb(thres_read_addr),
        .dinb('0),
        .doutb(threshold)
    );

endmodule