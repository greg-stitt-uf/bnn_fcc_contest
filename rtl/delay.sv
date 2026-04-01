module delay #(
    parameter int CYCLES = 4,
    parameter int WIDTH = 1
) (
    input  logic             clk,
    input  logic             rst,
    input  logic             en,
    input  logic [WIDTH-1:0] in,
    output logic [WIDTH-1:0] out
);

    initial begin
        if (CYCLES < 0) $fatal(1, "ERROR: Cycles must be >= 0.");
        if (WIDTH < 1) $fatal(1, "ERROR: Width must be positive.");
    end

    logic [WIDTH-1:0] regs[CYCLES+1];

    if (CYCLES == 0) begin : l_cycles_eq_0
        assign out = in;
    end else if (CYCLES > 0) begin : l_cycles_gt_0 
        for (genvar i = 0; i < CYCLES; i++) begin : reg_array
            register #(
                .WIDTH(WIDTH)
            ) reg_array (
                .clk,
                .rst,
                .en,
                .in (regs[i]),
                .out(regs[i+1])
            );
        end

        assign regs[0] = in;

        assign out = regs[CYCLES];
    end
endmodule

module register #(
    parameter int WIDTH
) (
    input  logic             clk,
    input  logic             rst,
    input  logic             en,
    input  logic [WIDTH-1:0] in,
    output logic [WIDTH-1:0] out
);

    always_ff @(posedge clk or posedge rst) begin
        if (rst) out <= '0;
        else if (en) out <= in;
    end

endmodule