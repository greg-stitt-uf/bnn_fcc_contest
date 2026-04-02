module data_in #(
    parameter int INPUT_BUS_WIDTH = 64
)(
    input logic clk,
    input logic rst,
    input  logic                         data_in_valid,
    output logic                         data_in_ready,
    input  logic [  INPUT_BUS_WIDTH-1:0] data_in_data,
    input  logic [INPUT_BUS_WIDTH/8-1:0] data_in_keep,
    input  logic                         data_in_last

);


    typedef enum {
        IDLE,
        RECEIVING
    } state_t;
    state_t curr_state, next_state;


    always_ff @(posedge clk) begin
        if (rst) begin
            curr_state <= IDLE;
        end else begin
            curr_state <= next_state;
        end
    end


    always_comb begin
        
    end

    


endmodule