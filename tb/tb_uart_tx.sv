`timescale 1ns/1ps

import uart_pkg::*;

module tb_uart_tx;

  localparam int CLK_PERIOD_NS = 10;
  localparam int TEST_DIV      = 4;

  logic clk;
  logic rst_n;

  logic tx_enable;
  logic baud_tick;
  logic tx_start;
  logic [7:0] tx_data;

  logic tx_o;
  logic tx_busy;
  logic tx_done;

  int errors;

  baud_gen #(
    .DIV_WIDTH(16)
  ) u_baud_gen (
    .clk       (clk),
    .rst_n     (rst_n),
    .enable    (tx_busy),
    .baud_div  (16'(TEST_DIV)),
    .baud_tick (baud_tick)
  );

  uart_tx #(
    .DATA_WIDTH(8)
  ) dut (
    .clk       (clk),
    .rst_n     (rst_n),
    .tx_enable (tx_enable),
    .baud_tick (baud_tick),
    .tx_start  (tx_start),
    .tx_data   (tx_data),
    .tx_o      (tx_o),
    .tx_busy   (tx_busy),
    .tx_done   (tx_done)
  );

  initial begin
    clk = 1'b0;
    forever #(CLK_PERIOD_NS/2) clk = ~clk;
  end

  task automatic reset_dut();
    begin
      rst_n     = 1'b0;
      tx_enable = 1'b0;
      tx_start  = 1'b0;
      tx_data   = 8'h00;
      errors    = 0;

      repeat (5) @(posedge clk);
      rst_n = 1'b1;
      repeat (2) @(posedge clk);
    end
  endtask

  task automatic check_bit(input logic expected, input string bit_name);
    begin
      @(posedge baud_tick);
      #1;

      if (tx_o !== expected) begin
        $display("[ERROR] %s expected=%0b actual=%0b time=%0t",
                 bit_name, expected, tx_o, $time);
        errors++;
      end else begin
        $display("[PASS] %s = %0b time=%0t", bit_name, tx_o, $time);
      end
    end
  endtask

  task automatic send_and_check_byte(input logic [7:0] data);
    begin
      $display("------------------------------------------------------------");
      $display("Testing TX byte: 0x%02h", data);
      $display("------------------------------------------------------------");

      @(posedge clk);
      tx_data  <= data;
      tx_start <= 1'b1;
      @(posedge clk);
      tx_start <= 1'b0;

      wait (tx_busy === 1'b1);

      check_bit(1'b0, "START_BIT");

      for (int i = 0; i < 8; i++) begin
        check_bit(data[i], $sformatf("DATA_BIT_%0d", i));
      end

      check_bit(1'b1, "STOP_BIT");

      wait (tx_done === 1'b1);
      @(posedge clk);

      if (tx_busy !== 1'b0) begin
        $display("[ERROR] tx_busy did not deassert after transmission");
        errors++;
      end

      if (tx_o !== 1'b1) begin
        $display("[ERROR] tx_o not idle high after transmission");
        errors++;
      end

      repeat (3) @(posedge clk);
    end
  endtask

  initial begin
    $display("============================================================");
    $display("PHASE 1 UART TX TEST START");
    $display("============================================================");

    reset_dut();

    if (tx_o !== 1'b1) begin
      $display("[ERROR] TX line not high after reset");
      errors++;
    end

    tx_enable = 1'b1;

    send_and_check_byte(8'hA5);
    send_and_check_byte(8'h3C);
    send_and_check_byte(8'h00);
    send_and_check_byte(8'hFF);

    $display("============================================================");
    if (errors == 0) begin
      $display("[PHASE 1 PASS] UART transmitter verified.");
    end else begin
      $display("[PHASE 1 FAIL] errors=%0d", errors);
    end
    $display("============================================================");

    $finish;
  end

endmodule
