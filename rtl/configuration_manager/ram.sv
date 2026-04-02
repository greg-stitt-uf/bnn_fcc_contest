module ram #(
    parameter int DATA_WIDTH = ram_pkg::DATA_WIDTH,
    parameter int ADDR_WIDTH = ram_pkg::ADDR_WIDTH
) (
    input  logic                  clk,
    input  logic                  rst,
    input  logic                  wr_en,
    input  logic                  rd_en, // always 1
    input  logic [ADDR_WIDTH-1:0] addr,
    input  logic [DATA_WIDTH-1:0] wr_data,
    output logic [DATA_WIDTH-1:0] rd_data
);
    logic [DATA_WIDTH-1:0] mem[2**ADDR_WIDTH];
    // DATA_WIDTH=8, ADDR_WIDTH = 2
    /*
        mem[0] = 0..0; for DATA_WIDTH bits
        mem[1] = 0..0;
        .
        .
        .
        mem[ADDR_WIDTH-1] = 0..0;
        Total size = 2**ADDR_WIDTH
    */

    always_ff @(posedge clk) begin
        if (wr_en) mem[addr] <= wr_data;
        if (rd_en) rd_data <= mem[addr];
        if (rst) begin
            // clear memory
            for (int i = 0; i < ADDR_WIDTH; i++) begin
                mem[i] = '0;
            end
        end
    end

endmodule