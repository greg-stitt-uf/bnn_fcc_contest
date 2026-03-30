`timescale 1ns/1ps

module tb_bram_latency;

  localparam int PW = 16;

  logic                 clka, clkb;
  logic                 ena, wea;
  logic [9:0]           addra;
  logic [PW-1:0]        dina;

  logic                 enb, web;
  logic [9:0]           addrb;
  logic [PW-1:0]        doutb;

  // DUT: your Vivado-generated BRAM wrapper
  weight_bram dut (
    .clka(clka),
    .ena(ena),
    .wea(wea),
    .addra(addra),
    .dina(dina),

    .clkb(clkb),
    .enb(enb),
    .web(web),
    .addrb(addrb),
    .doutb(doutb)
  );

  // 100MHz clocks (10ns period)
  initial begin clka = 0; forever #5 clka = ~clka; end
  initial begin clkb = 0; forever #5 clkb = ~clkb; end

  task automatic writeA(input [5:0] a, input [PW-1:0] d);
    begin
      @(negedge clka);
      ena   = 1'b1;
      wea   = 1'b1;
      addra = a;
      dina  = d;
      @(negedge clka);
      ena   = 1'b0;
      wea   = 1'b0;
      addra = '0;
      dina  = '0;
    end
  endtask

  task automatic readB_and_trace(input [5:0] a);
    int cyc;
    logic [PW-1:0] prev;
    begin
      // Set up read
      @(negedge clkb);
      enb   = 1'b1;
      web   = 1'b0;
      addrb = a;

      // Watch doutb over several rising edges
      prev = doutb;
      for (cyc = 0; cyc < 4; cyc++) begin
        @(posedge clkb);
        $display("t=%0t  cyc=%0d  addrb=%0d  doutb=0x%0h", $time, cyc, addrb, doutb);
      end

      @(negedge clkb);
      enb   = 1'b0;
      addrb = '0;
    end
  endtask

  initial begin
    // init signals
    ena=0; wea=0; addra='0; dina='0;
    enb=0; web=0; addrb='0;

    // Wait a couple cycles
    repeat (2) @(posedge clka);

    // Write known data into a few addresses
    writeA(6'd0, 16'hA5A5);
    writeA(6'd1, 16'h1234);
    writeA(6'd2, 16'hBEEF);

    // Now read and trace when doutb updates
    $display("\n--- READ addr 0 ---");
    readB_and_trace(6'd0);

    $display("\n--- READ addr 1 ---");
    readB_and_trace(6'd1);

    $display("\n--- READ addr 2 ---");
    readB_and_trace(6'd2);

    $display("\nDone.");
    #20 $finish;
  end

endmodule