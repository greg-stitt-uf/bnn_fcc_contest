// Top-level neuron wrapper: comments added for clarity

module neuron_top #(
    parameter int PW = 16,            // PW: width of input vector and weight elements
    parameter int N_IN_BITS = 784,       // total bits accumulated per neuron (layer dependent)
    localparam int THRESH_W = $clog2(N_IN_BITS+1)
) (
    input logic                 clk, // system clock
    input logic                 rst, // synchronous reset (active high)

    input logic [PW-1:0]        x_in,           // input activation vector (not directly used, loaded via BRAM)

    // Inputs for threshold and weight ram writing
    input logic                 cfg_w_enw,      // write enable for weight BRAM (port A)
    input logic [PW-1:0]        cfg_w_dataw,    // data to write into weight BRAM
    input logic [5:0]           cfg_w_addrw,    // write address for weight BRAM

    input logic                 cfg_w_ent,      // write enable for threshold BRAM (port A)
    input logic [THRESH_W-1:0]  cfg_w_datat,    // data to write into threshold BRAM
    input logic [5:0]           cfg_w_addrt,    // write address for threshold BRAM

    input logic                 cfg_done,

    // Outputs of neuron processor
    output logic                valid_out,      // asserted when neuron output is valid
    output logic                y,              // neuron binary output (activation)
    output logic [THRESH_W-1:0] popcount_out    // population count result / internal sum
);

    // Internal registers hold the current input vector, weight vector, and threshold
    logic [PW-1:0]         x;          // input activation vector presented to neuron
    logic [PW-1:0]         w;          // weight vector read from BRAM (port B)
    logic [THRESH_W-1:0]   threshold;  // threshold value read from BRAM (port B)
    logic                  valid_in;   // valid signal indicating input is ready
    logic                  last;     // registered 'last' flag marking end of a read burst

    // Next-state signals for sequential update
    logic                  next_last;
    logic                  last1, last2; // two cycle delay for the last signal too

    // Counters tracking how many words were written into BRAMs (used to know read length)
    logic [5:0] write_count_w_r;
    logic [5:0] write_count_t_r;
    logic [5:0] next_write_count_w;
    logic [5:0] next_write_count_t;

    // Read addresses for BRAM port B (used during reading phase)
    logic [5:0] addr_weight_read_r;     // current read address for weights
    logic [5:0] addr_threshold_read_r;  // current read address for thresholds
    logic [5:0] next_addr_weight_read;
    logic [5:0] next_addr_threshold_read;

    // Flags to enable reading from BRAM (controls BRAM port B enb signals)
    logic reading_weights_r;      // high while reading weight BRAM
    logic reading_thresholds_r;   // high while reading threshold BRAM
    logic next_reading_weights;
    logic next_reading_thresholds;

    logic encycle1, encycle2;

    // Small state machine to coordinate write and read phases
    typedef enum logic [1:0] {
        IDLE,
        WRITING,
        READING
    } state_t;

    state_t state_r, next_state;

    assign x = x_in;

    assign valid_in = encycle2; // once data is actually being outputted by the BRAM

    assign last = last2;
    
    // Instantiate the neuron processing block. It consumes x, w, threshold and
    // produces valid_out, y and popcount_out. Comments clarify interface mapping.
    neuron #(
        .PW(PW),
        .N_IN_BITS(N_IN_BITS)
    ) neuron_inst (
        .x(x),                 // input activations (from BRAM read path)
        .w(w),                 // weights (from BRAM read path)
        .threshold(threshold), // threshold for activation decision
        .clk(clk),
        .rst(rst),
        .valid_in(valid_in), // indicates x/w/threshold are valid this cycle
        .last(last),         // indicates last element in a sequence
        .valid_out(valid_out),
        .y(y),
        .popcount_out(popcount_out)
    );

    // BRAM Instantiations:
    // - Port A (clka) used for writes via cfg_w_enw/cfg_w_dataw/cfg_w_addrw
    // - Port B (clkb) used for reads while reading_*_r is asserted; doutb drives w/16-bit data
    weight_bram weight_bram_inst (
        .clka(clk),
        .ena(cfg_w_enw),                  // enable for write port A
        .wea(cfg_w_enw),                  // write enable tied to ena
        .addra(cfg_w_addrw),         // write address (lower bits used)
        .dina(cfg_w_dataw),         // data in for write port
        .clkb(clk),
        .enb(reading_weights_r),          // enable for read port B while in READING
        .web(1'b0),                       // read-only on port B
        .addrb(addr_weight_read_r),       // read address for weights
        .doutb(w)                         // read data -> w
    );

    // Threshold BRAM: similar usage as weight BRAM
    threshold_bram threshold_bram_inst (
        .clka(clk),
        .ena(cfg_w_ent),
        .wea(cfg_w_ent),
        .addra(cfg_w_addrt),
        .dina(cfg_w_datat),
        .clkb(clk),
        .enb(reading_thresholds_r),
        .web(1'b0),
        .addrb(addr_threshold_read_r),
        .doutb(threshold)
    );    


    // Sequential register updates: on reset clear counters/flags and start in WRITING
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            write_count_w_r       <= '0;      // clear number of written weight words
            write_count_t_r       <= '0;      // clear number of written threshold words
            addr_weight_read_r    <= '0;      // reset read addresses
            addr_threshold_read_r <= '0;
            reading_weights_r     <= 1'b0;    // not reading after reset
            reading_thresholds_r  <= 1'b0;
            last2                 <= 1'b0;    // not last element
            encycle1              <= 1'b0;
            encycle2              <= 1'b0;
            last1                 <= 1'b0;
            state_r               <= WRITING; // enter WRITING so configuration writes possible
        end
        else begin
            // update registers from combinational next-state values
            write_count_w_r       <= next_write_count_w;
            write_count_t_r       <= next_write_count_t;
            addr_weight_read_r    <= next_addr_weight_read;
            addr_threshold_read_r <= next_addr_threshold_read;
            reading_weights_r     <= next_reading_weights;
            reading_thresholds_r  <= next_reading_thresholds;
            last1                 <= next_last;
            last2                 <= last1;
            state_r               <= next_state;
            encycle1              <= reading_weights_r;
            encycle2              <= encycle1;
        end   
    end

    // Combinational next-state logic: implements a simple three-state controller
    always_comb begin
        // defaults
        next_state = state_r;
        next_write_count_w = write_count_w_r;
        next_write_count_t = write_count_t_r;
        next_addr_weight_read = addr_weight_read_r;
        next_addr_threshold_read = addr_threshold_read_r;
        next_reading_weights = reading_weights_r;
        next_reading_thresholds = reading_thresholds_r;
        next_last = 1'b0;     // default: not last

        case(state_r)
            IDLE: begin
                // If any config write enable asserted, go to WRITING state
                if(cfg_w_enw || cfg_w_ent) next_state = WRITING;
            end
            WRITING: begin
                if (cfg_done)
                    next_state = READING;
                else begin
                    // while cfg write enables asserted, increment respective write counters
                    if(cfg_w_enw) next_write_count_w = write_count_w_r + 1;
                    if(cfg_w_ent) next_write_count_t = write_count_t_r + 1;
                end
            end
            READING: begin
                // start reading sequence: enable BRAM read ports and set addresses to zero
                if (!reading_weights_r && !reading_thresholds_r) begin
                    next_reading_weights     = 1'b1;
                    next_reading_thresholds  = 1'b1;
                    next_addr_weight_read    = 6'd0;
                    next_addr_threshold_read = 6'd0;
                    next_last = 1'b0;
                end
                else begin
                    // detect when we've reached the last element based on the write_count_w_r
                    if(write_count_w_r != 0 && addr_weight_read_r == (write_count_w_r - 1)) begin
                        next_last = 1'b1; // mark last element of the burst
                    end 
                    else begin
                        next_last = 1'b0;
                    end

                    if(next_last) begin
                        // finished reading: deassert reading flags and return to IDLE
                        next_reading_weights = 1'b0;
                        next_reading_thresholds = 1'b0;
                        next_state = IDLE;
                    end
                    else begin
                        // continue reading: increment read addresses for next beat
                        next_reading_weights = 1'b1;
                        next_reading_thresholds = 1'b1;
                        next_addr_weight_read = addr_weight_read_r + 1;
                        next_addr_threshold_read = addr_threshold_read_r + 1;
                    end
                end
            end

        endcase
    end

endmodule