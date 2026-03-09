module neuron_tb #(
    parameter int PW = 2,
    parameter int THRESH_W = 4
);

    logic [PW-1:0]         x;
    logic [PW-1:0]         w;
    logic [THRESH_W-1:0]   threshold;
    logic                  clk;
    logic                  rst;
    logic                  valid_in;
    logic                  last;
    logic                  valid_out;
    logic                  y;
    logic [THRESH_W-1:0]   popcount_out;

    int errors = 0;
    logic [THRESH_W-1:0] expected_popcount;
    logic expected_y;


    neuron #(
        .PW(PW),
        .THRESH_W(THRESH_W)
    ) dut (
        .x(x),
        .w(w),
        .threshold(threshold),
        .clk(clk),
        .rst(rst),
        .valid_in(valid_in),
        .last(last),
        .valid_out(valid_out),
        .y(y),
        .popcount_out(popcount_out)
    );

    // clock generator
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        rst = 1;
        valid_in = 0;
        last = 0;
        x = 0;
        w = 0;
        threshold = 0;
        repeat(3) @(posedge clk);
        rst = 0;
        @(posedge clk);

        expected_popcount = 2;
        expected_y = 1;

        // Test case 1
        valid_in = 1;
        last = 0;
        x = 2'b11;
        w = 2'b10;
        threshold = 4'd2;
        @(posedge clk);

        valid_in = 1;
        last = 1;
        x = 2'b01;
        w = 2'b11;
        threshold = 4'd2;
        @(posedge clk);

        valid_in = 0;
        last = 0;
        repeat(2) @(posedge clk);

        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("TEST FAILED with %0d errors", errors);
            
        $finish;

    end

    always @(posedge clk) begin
        if (valid_out) begin
            if (popcount_out !== expected_popcount) begin
                $error("Popcount mismatch! Got %0d Expected %0d", popcount_out, expected_popcount);
                errors++;
            end
            if (y !== expected_y) begin
                $error("Output y mismatch! Got %0b Expected %0b", y, expected_y);
                errors++;
            end
            else begin
                $display("PASS: popcount=%0d y=%0b at time %0t", popcount_out, y, $time);
            end
        end
    end

endmodule