`timescale 1ns/1ps

import uart_pkg::*;

module tb_uart_fifo_subsystem;

  localparam int CLK_PERIOD_NS = 10;
  localparam int DATA_WIDTH    = 8;
  localparam int FIFO_DEPTH    = 16;
  localparam int OS_DIV        = 4;
  localparam int BAUD_DIV      = ((OS_DIV + 1) * 16) - 1;

  logic clk;
  logic rst_n;

  logic tx_enable;
  logic rx_enable;
  logic clear_errors;

  logic baud_tick;
  logic os_tick;

  logic tx_fifo_wr_en;
  logic [7:0] tx_fifo_wr_data;
  logic tx_fifo_full;
  logic tx_fifo_empty;

  logic rx_fifo_rd_en;
  logic [7:0] rx_fifo_rd_data;
  logic rx_fifo_full;
  logic rx_fifo_empty;

  logic uart_rx_i;
  logic uart_tx_o;

  logic tx_busy;
  logic tx_done;
  logic rx_valid;
  logic frame_error;
  logic overrun_error;

  int errors;

  baud_gen #(
    .DIV_WIDTH(16)
  ) u_os_baud_gen (
    .clk       (clk),
    .rst_n     (rst_n),
    .enable    (1'b1),
    .baud_div  (16'd4),
    .baud_tick (os_tick)
  );

  baud_gen #(
    .DIV_WIDTH(16)
  ) u_tx_baud_gen (
    .clk       (clk),
    .rst_n     (rst_n),
    .enable    (1'b1),
    .baud_div  (16'd79),
    .baud_tick (baud_tick)
  );

  uart_fifo_subsystem #(
    .DATA_WIDTH(DATA_WIDTH),
    .FIFO_DEPTH(FIFO_DEPTH)
  ) dut (
    .clk             (clk),
    .rst_n           (rst_n),
    .tx_enable       (tx_enable),
    .rx_enable       (rx_enable),
    .clear_errors    (clear_errors),
    .baud_tick       (baud_tick),
    .os_tick         (os_tick),

    .tx_fifo_wr_en   (tx_fifo_wr_en),
    .tx_fifo_wr_data (tx_fifo_wr_data),
    .tx_fifo_full    (tx_fifo_full),
    .tx_fifo_empty   (tx_fifo_empty),

    .rx_fifo_rd_en   (rx_fifo_rd_en),
    .rx_fifo_rd_data (rx_fifo_rd_data),
    .rx_fifo_full    (rx_fifo_full),
    .rx_fifo_empty   (rx_fifo_empty),

    .uart_rx_i       (uart_rx_i),
    .uart_tx_o       (uart_tx_o),

    .tx_busy         (tx_busy),
    .tx_done         (tx_done),
    .rx_valid        (rx_valid),
    .frame_error     (frame_error),
    .overrun_error   (overrun_error)
  );

  initial begin
    clk = 1'b0;
    forever #(CLK_PERIOD_NS/2) clk = ~clk;
  end

  task automatic reset_dut();
    begin
      rst_n           = 1'b0;
      tx_enable       = 1'b0;
      rx_enable       = 1'b0;
      clear_errors    = 1'b0;
      tx_fifo_wr_en   = 1'b0;
      tx_fifo_wr_data = 8'h00;
      rx_fifo_rd_en   = 1'b0;
      uart_rx_i       = 1'b1;
      errors          = 0;

      repeat (8) @(posedge clk);
      rst_n = 1'b1;
      repeat (5) @(posedge clk);
      #1;
    end
  endtask

  task automatic expect_flag(
    input logic actual,
    input logic expected,
    input string name
  );
    begin
      #1;
      if (actual !== expected) begin
        $display("[ERROR] %s expected=%0b actual=%0b time=%0t",
                 name, expected, actual, $time);
        errors++;
      end else begin
        $display("[PASS] %s=%0b time=%0t", name, actual, $time);
      end
    end
  endtask

  task automatic tx_fifo_write(input logic [7:0] data);
    begin
      @(negedge clk);
      tx_fifo_wr_en   = 1'b1;
      tx_fifo_wr_data = data;

      @(negedge clk);
      tx_fifo_wr_en   = 1'b0;
      tx_fifo_wr_data = 8'h00;

      #1;
    end
  endtask

  task automatic rx_fifo_read(output logic [7:0] data);
    begin
      @(negedge clk);
      rx_fifo_rd_en = 1'b1;

      @(negedge clk);
      rx_fifo_rd_en = 1'b0;

      #1;
      data = rx_fifo_rd_data;
    end
  endtask

  task automatic wait_os_ticks(input int ticks);
    begin
      repeat (ticks) begin
        @(posedge os_tick);
      end
      #1;
    end
  endtask

  task automatic drive_uart_rx_byte(
    input logic [7:0] data,
    input logic       good_stop_bit
  );
    begin
      // Start bit
      uart_rx_i = 1'b0;
      wait_os_ticks(16);

      // Data bits LSB first
      for (int i = 0; i < 8; i++) begin
        uart_rx_i = data[i];
        wait_os_ticks(16);
      end

      // Stop bit
      uart_rx_i = good_stop_bit;
      wait_os_ticks(16);

      // Idle after frame
      uart_rx_i = 1'b1;
      wait_os_ticks(2);
    end
  endtask

  task automatic expect_read_data(
    input logic [7:0] actual,
    input logic [7:0] expected,
    input string name
  );
    begin
      if (actual !== expected) begin
        $display("[ERROR] %s expected=0x%02h actual=0x%02h time=%0t",
                 name, expected, actual, $time);
        errors++;
      end else begin
        $display("[PASS] %s=0x%02h time=%0t", name, actual, $time);
      end
    end
  endtask

  task automatic clear_error_flags();
    begin
      @(negedge clk);
      clear_errors = 1'b1;
      @(negedge clk);
      clear_errors = 1'b0;
      #1;
    end
  endtask

  logic [7:0] rdata;

  initial begin
    $display("============================================================");
    $display("PHASE 3B UART FIFO SUBSYSTEM TEST START");
    $display("============================================================");

    reset_dut();

    expect_flag(tx_fifo_empty, 1'b1, "TX FIFO empty after reset");
    expect_flag(tx_fifo_full,  1'b0, "TX FIFO full after reset");
    expect_flag(rx_fifo_empty, 1'b1, "RX FIFO empty after reset");
    expect_flag(rx_fifo_full,  1'b0, "RX FIFO full after reset");
    expect_flag(overrun_error, 1'b0, "Overrun clear after reset");

    // ------------------------------------------------------------
    // TX FIFO fill test
    // ------------------------------------------------------------

    $display("------------------------------------------------------------");
    $display("TX FIFO fill and full-flag test");
    $display("------------------------------------------------------------");

    tx_enable = 1'b0;

    for (int i = 0; i < FIFO_DEPTH; i++) begin
      tx_fifo_write(i[7:0]);
    end

    expect_flag(tx_fifo_full,  1'b1, "TX FIFO full after 16 writes");
    expect_flag(tx_fifo_empty, 1'b0, "TX FIFO not empty after 16 writes");

    tx_fifo_write(8'hEE);
    expect_flag(tx_fifo_full, 1'b1, "TX FIFO remains full after overflow attempt");

    // ------------------------------------------------------------
    // TX FIFO drain through UART TX
    // ------------------------------------------------------------

    $display("------------------------------------------------------------");
    $display("TX FIFO drain through UART TX test");
    $display("------------------------------------------------------------");

    tx_enable = 1'b1;

    wait (tx_fifo_empty === 1'b1);
    repeat (10) @(posedge clk);
    #1;

    expect_flag(tx_fifo_empty, 1'b1, "TX FIFO empty after UART TX drain");
    expect_flag(tx_fifo_full,  1'b0, "TX FIFO not full after UART TX drain");

    // ------------------------------------------------------------
    // RX FIFO back-to-back receive fill test
    // ------------------------------------------------------------

    $display("------------------------------------------------------------");
    $display("RX FIFO back-to-back receive fill test");
    $display("------------------------------------------------------------");

    rx_enable = 1'b1;
    uart_rx_i = 1'b1;
    wait_os_ticks(16);

    for (int i = 0; i < FIFO_DEPTH; i++) begin
      drive_uart_rx_byte((8'h80 + i[7:0]), 1'b1);
    end

    repeat (10) @(posedge clk);
    #1;

    expect_flag(rx_fifo_full,  1'b1, "RX FIFO full after 16 received bytes");
    expect_flag(rx_fifo_empty, 1'b0, "RX FIFO not empty after received bytes");

    $display("------------------------------------------------------------");
    $display("RX FIFO read-until-empty and data-order test");
    $display("------------------------------------------------------------");

    for (int i = 0; i < FIFO_DEPTH; i++) begin
      rx_fifo_read(rdata);
      expect_read_data(rdata, (8'h80 + i[7:0]), "RX FIFO read data");
    end

    expect_flag(rx_fifo_empty, 1'b1, "RX FIFO empty after drain");
    expect_flag(rx_fifo_full,  1'b0, "RX FIFO not full after drain");

    // ------------------------------------------------------------
    // RX overrun test
    // ------------------------------------------------------------

    $display("------------------------------------------------------------");
    $display("RX overrun test");
    $display("------------------------------------------------------------");

    clear_error_flags();
    expect_flag(overrun_error, 1'b0, "Overrun cleared before test");

    for (int i = 0; i < FIFO_DEPTH; i++) begin
      drive_uart_rx_byte((8'h40 + i[7:0]), 1'b1);
    end

    repeat (10) @(posedge clk);
    #1;
    expect_flag(rx_fifo_full, 1'b1, "RX FIFO full before overrun byte");

    drive_uart_rx_byte(8'hAA, 1'b1);

    repeat (10) @(posedge clk);
    #1;
    expect_flag(overrun_error, 1'b1, "Overrun asserted after extra RX byte");

    // Drain RX FIFO after overrun
    for (int i = 0; i < FIFO_DEPTH; i++) begin
      rx_fifo_read(rdata);
      expect_read_data(rdata, (8'h40 + i[7:0]), "RX FIFO post-overrun data");
    end

    expect_flag(rx_fifo_empty, 1'b1, "RX FIFO empty after post-overrun drain");

    $display("============================================================");
    if (errors == 0) begin
      $display("[PHASE 3B PASS] TX/RX FIFO buffering and RX overrun verified.");
    end else begin
      $display("[PHASE 3B FAIL] errors=%0d", errors);
    end
    $display("============================================================");

    $finish;
  end

endmodule