module data_in_manager#(
    parameter int INPUT_DATA_WIDTH  = 8,
    parameter int INPUT_BUS_WIDTH   = 64
)(
    input logic clk,
    input logic rst,

    // AXI streaming image input interface (consumer)
    input  logic                         data_in_valid,
    output logic                         data_in_ready,
    input  logic [  INPUT_BUS_WIDTH-1:0] data_in_data,
    input  logic [INPUT_BUS_WIDTH/8-1:0] data_in_keep,
    input  logic                         data_in_last,


    // output the data
    output logic [(INPUT_DATA_WIDTH*2)-1:0] img_data_out[INPUT_BUS_WIDTH/16], 
    // neurons accept 16 bits of data, so push out two pixels at a time, for 
    // the size of the bus, so 4 elements of  16 bits. 
    output logic [INPUT_BUS_WIDTH/16-1:0] img_data_out_valid, // /16 so it's 4 bits, one for each 16 bit chunk of the bus
    output logic                          img_data_out_last, // indicates the last bit of data being pushed out
    output logic                          img_data_out_error // if anything's wrong with the input stream, we want to be able to flag that to the neurons so they can handle it appropriately
);


    // struct to hold two pixels of data. readable syntax
    typedef struct packed {
        logic [INPUT_DATA_WIDTH-1:0] pixel1;
        logic [INPUT_DATA_WIDTH-1:0] pixel0;
    } data_t;

    data_t img_data_out_r[INPUT_BUS_WIDTH/16], img_data_out_next[INPUT_BUS_WIDTH/16];
    logic [INPUT_BUS_WIDTH/16-1:0] img_data_out_valid_r, img_data_out_valid_next;
    logic img_data_out_last_r, img_data_out_last_next;
    logic img_data_out_error_r, img_data_out_error_next;

    assign img_data_out = img_data_out_r;
    assign img_data_out_valid = img_data_out_valid_r;
    assign img_data_out_last = img_data_out_last_r;
    assign img_data_out_error = img_data_out_error_r;

    // states to track status of data_in stream receiver
    typedef enum {
        IDLE,
        RECEIVING
    } state_t;
    state_t curr_state, next_state;

    logic [INPUT_BUS_WIDTH-1:0] shift_out_data;
    logic [(INPUT_BUS_WIDTH/8)-1:0] shift_out_keep;
    logic shift_out_valid, shift_out_last;
    logic shift_out_ready;
    shift_reg #(
        .WIDTH(INPUT_BUS_WIDTH),
        .DEPTH(3) // just a number so stuff can be streamed in
    ) shift_reg_inst (
        .clk(clk),
        .rst(rst),
        .shift_in_valid(data_in_valid),
        .shift_in_keep(data_in_keep),
        .shift_in_data(data_in_data),
        .shift_in_last(data_in_last),
        .shift_in_ready(data_in_ready),
        .shift_out_valid(shift_out_valid),
        .shift_out_data(shift_out_data),
        .shift_out_keep(shift_out_keep),
        .shift_out_last(shift_out_last),
        .shift_out_ready(shift_out_ready) 
    );


    always_comb begin
        next_state = curr_state;
        shift_out_ready = 1'b0;
        img_data_out_next = img_data_out_r;
        img_data_out_valid_next = '0;
        img_data_out_last_next = 1'b0;
        img_data_out_error_next = img_data_out_error_r;
        case (curr_state)
            IDLE: begin
                next_state = IDLE;
                if (shift_out_valid) begin
                    shift_out_ready = 1'b1;
                    // read first beat since it's valid, so we'll have the first 8 pixels
                    for (int i = 0; i < INPUT_BUS_WIDTH/16; i++) begin
                        img_data_out_next[i].pixel0 = shift_out_data[i*16 +: 8];
                        img_data_out_next[i].pixel1 = shift_out_data[i*16+8 +: 8];
                        img_data_out_valid_next[i] = shift_out_keep[i*2] | shift_out_keep[i*2 + 1];
                    end
                    img_data_out_last_next = shift_out_last;
                    next_state = shift_out_last ? IDLE : RECEIVING;
                end
            end
            RECEIVING: begin
                if (shift_out_valid && !shift_out_last) begin
                    shift_out_ready = 1'b1;
                    for (int i = 0; i < INPUT_BUS_WIDTH/16; i++) begin
                        img_data_out_next[i].pixel0 = shift_out_data[i*16 +: 8];
                        img_data_out_next[i].pixel1 = shift_out_data[i*16+8 +: 8];
                        img_data_out_valid_next[i] = shift_out_keep[i*2] | shift_out_keep[i*2 + 1];
                    end
                    img_data_out_last_next = shift_out_last;
                    next_state = RECEIVING;
                end else if (shift_out_valid && shift_out_last) begin
                    shift_out_ready = 1'b1;
                    for (int i = 0; i < INPUT_BUS_WIDTH/16; i++) begin
                        img_data_out_next[i].pixel0 = shift_out_data[i*16 +: 8];
                        img_data_out_next[i].pixel1 = shift_out_data[i*16+8 +: 8];
                        img_data_out_valid_next[i] = shift_out_keep[i*2] | shift_out_keep[i*2 + 1];
                    end
                    img_data_out_last_next = shift_out_last;
                    next_state = IDLE;
                end else begin
                    next_state = RECEIVING;
                end
            end
        endcase
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            curr_state <= IDLE;
            img_data_out_r <= '{default:'0};
            img_data_out_valid_r <= '0;
            img_data_out_last_r <= 1'b0;
            img_data_out_error_r <= 1'b0;
        end else begin
            curr_state <= next_state;
            img_data_out_r <= img_data_out_next;
            img_data_out_valid_r <= img_data_out_valid_next;
            img_data_out_last_r <= img_data_out_last_next;
            img_data_out_error_r <= img_data_out_error_next;
        end
    end


    



endmodule

