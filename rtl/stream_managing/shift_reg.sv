module shift_reg #(
    parameter int WIDTH = 64,
    parameter int DEPTH = 3
)(
    input  logic                  clk,
    input  logic                  rst,
    input  logic                  shift_in_valid,
    input  logic [(WIDTH/8)-1:0]  shift_in_keep,
    input  logic [WIDTH-1:0]      shift_in_data,
    input  logic                  shift_in_last,
    output logic                  shift_in_ready,
    output logic                  shift_out_valid,
    output logic [WIDTH-1:0]      shift_out_data,
    output logic [(WIDTH/8-1):0]  shift_out_keep,
    output logic                  shift_out_last,
    input  logic                  shift_out_ready
);
    localparam int COUNT_W = $clog2(DEPTH+1);

    logic [WIDTH-1:0] fifo[DEPTH-1:0];
    logic [(WIDTH/8)-1:0] fifo_keep[DEPTH-1:0];
    logic fifo_last[DEPTH-1:0];
    logic [COUNT_W-1:0] count;
    logic [WIDTH-1:0] masked_in_data;
    logic push;
    logic pop;

    // handle keep signal to mask out invalid bytes in the input data
    always_comb begin
        masked_in_data = '0;
        for (int i = 0; i < WIDTH/8; i++) begin
            if (shift_in_keep[i]) begin
                masked_in_data[i*8 +: 8] = shift_in_data[i*8 +: 8];
            end else begin
                masked_in_data[i*8 +: 8] = '0;
            end
        end
    end

    assign shift_in_ready  = (count < COUNT_W'(DEPTH));
    assign shift_out_valid = (count > 0);
    assign push = shift_in_valid && shift_in_ready;
    assign pop  = shift_out_valid && shift_out_ready;

    always_comb begin
        shift_out_data = '0;
        shift_out_keep = '0;
        shift_out_last = 1'b0;
        if (count > 0) begin
            shift_out_data = fifo[count-1];
            shift_out_keep = fifo_keep[count-1];
            shift_out_last = fifo_last[count-1];
        end
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            count <= '0;
            for (int i = 0; i < DEPTH; i++) begin
                fifo[i] <= '0;
                fifo_keep[i] <= '0;
                fifo_last[i] <= 1'b0;
            end
        end else begin
            if (push) begin
                for (int i = DEPTH-1; i > 0; i--) begin
                    fifo[i] <= fifo[i-1];
                    fifo_keep[i] <= fifo_keep[i-1];
                    fifo_last[i] <= fifo_last[i-1];
                end
                fifo[0] <= masked_in_data;
                fifo_keep[0] <= shift_in_keep;
                fifo_last[0] <= shift_in_last;
            end

            case ({push, pop})
                2'b10: count <= count + 1'b1;
                2'b01: count <= count - 1'b1;
                default: count <= count;
            endcase
        end
    end

endmodule
