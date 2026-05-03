`timescale 1ns/1ps

import uart_pkg::*;

module tb_uart_loopback;

  localparam int CLK_PERIOD_NS = 10;
  localparam int FIFO_DEPTH    = 16;
  localparam int TEST_BAUD_DIV = 4;

  logic clk;
  logic rst_n;

  logic        bus_valid;
  logic        bus_we;
  logic [3:0]  bus_addr;
  logic [31:0] bus_wdata;
  logic [31:0] bus_rdata;
  logic        bus_ready;

  logic uart_rx_i;
  logic uart_tx_o;

  int errors;

  uart_top #(
    .DATA_WIDTH(8),
    .REG_WIDTH(32),
    .FIFO_DEPTH(FIFO_DEPTH)
  ) dut (
    .clk        (clk),
    .rst_n      (rst_n),

    .bus_valid  (bus_valid),
    .bus_we     (bus_we),
    .bus_addr   (bus_addr),
    .bus_wdata  (bus_wdata),
    .bus_rdata  (bus_rdata),
    .bus_ready  (bus_ready),

    .uart_rx_i  (uart_rx_i),
    .uart_tx_o  (uart_tx_o)
  );

  initial begin
    clk = 1'b0;
    forever #(CLK_PERIOD_NS/2) clk = ~clk;
  end

  task automatic reset_dut();
    begin
      rst_n      = 1'b0;
      bus_valid  = 1'b0;
      bus_we     = 1'b0;
      bus_addr   = '0;
      bus_wdata  = '0;
      uart_rx_i  = 1'b1;
      errors     = 0;

      repeat (8) @(posedge clk);
      rst_n = 1'b1;
      repeat (5) @(posedge clk);
      #1;
    end
  endtask

  task automatic bus_write(
    input logic [3:0]  addr,
    input logic [31:0] data
  );
    begin
      @(negedge clk);
      bus_valid = 1'b1;
      bus_we    = 1'b1;
      bus_addr  = addr;
      bus_wdata = data;

      wait (bus_ready === 1'b1);

      @(negedge clk);
      bus_valid = 1'b0;
      bus_we    = 1'b0;
      bus_addr  = '0;
      bus_wdata = '0;

      #1;
    end
  endtask

  task automatic bus_read(
    input  logic [3:0]  addr,
    output logic [31:0] data
  );
    begin
      @(negedge clk);
      bus_valid = 1'b1;
      bus_we    = 1'b0;
      bus_addr  = addr;
      bus_wdata = '0;

      wait (bus_ready === 1'b1);

      @(negedge clk);
      data      = bus_rdata;
      bus_valid = 1'b0;
      bus_addr  = '0;

      #1;
    end
  endtask

  task automatic expect_bit(
    input logic [31:0] word,
    input int          bit_idx,
    input logic        expected,
    input string       name
  );
    begin
      if (word[bit_idx] !== expected) begin
        $display("[ERROR] %s expected=%0b actual=%0b word=0x%08h time=%0t",
                 name, expected, word[bit_idx], word, $time);
        errors++;
      end else begin
        $display("[PASS] %s=%0b time=%0t", name, word[bit_idx], $time);
      end
    end
  endtask

  task automatic expect_data(
    input logic [31:0] actual,
    input logic [7:0]  expected,
    input string       name
  );
    begin
      if (actual[7:0] !== expected) begin
        $display("[ERROR] %s expected=0x%02h actual=0x%02h time=%0t",
                 name, expected, actual[7:0], $time);
        errors++;
      end else begin
        $display("[PASS] %s=0x%02h time=%0t", name, actual[7:0], $time);
      end
    end
  endtask

  task automatic send_loopback_byte(input logic [7:0] data);
    int unsigned rx_count_before;
    begin
      $display("Sending loopback byte: 0x%02h", data);

      rx_count_before = dut.u_uart_fifo_subsystem.rx_fifo_count;
      bus_write(ADDR_DATA, {24'h0, data});

      wait (dut.u_uart_fifo_subsystem.rx_fifo_count > rx_count_before);
      repeat (10) @(posedge clk);
    end
  endtask

  logic [31:0] rdata;

  initial begin
    $display("============================================================");
    $display("PHASE 5 INTERNAL LOOPBACK TEST START");
    $display("============================================================");

    reset_dut();

    // ------------------------------------------------------------
    // Configure baud divisor
    // ------------------------------------------------------------

    $display("------------------------------------------------------------");
    $display("BAUD_DIV setup");
    $display("------------------------------------------------------------");

    bus_write(ADDR_BAUDDIV, 32'd4);
    bus_read(ADDR_BAUDDIV, rdata);
    expect_data(rdata, TEST_BAUD_DIV[7:0], "BAUD_DIV readback");

    // ------------------------------------------------------------
    // Enable TX, RX, and loopback
    // CONTROL bits:
    // bit 0 = tx_enable
    // bit 1 = rx_enable
    // bit 2 = loopback_enable
    // value = 0b111 = 0x7
    // ------------------------------------------------------------

    $display("------------------------------------------------------------");
    $display("Enable TX/RX loopback");
    $display("------------------------------------------------------------");

    bus_write(ADDR_CONTROL, 32'h0000_0007);
    bus_read(ADDR_CONTROL, rdata);

    expect_bit(rdata, CTRL_TX_ENABLE,       1'b1, "CONTROL.tx_enable");
    expect_bit(rdata, CTRL_RX_ENABLE,       1'b1, "CONTROL.rx_enable");
    expect_bit(rdata, CTRL_LOOPBACK_ENABLE, 1'b1, "CONTROL.loopback_enable");

    // External RX line is held idle high.
    // Any received byte must come from internal loopback, not external stimulus.
    uart_rx_i = 1'b1;

    // ------------------------------------------------------------
    // Single-byte loopback
    // ------------------------------------------------------------

    $display("------------------------------------------------------------");
    $display("Single-byte loopback test");
    $display("------------------------------------------------------------");

    send_loopback_byte(8'hA5);

    bus_read(ADDR_STATUS, rdata);
    expect_bit(rdata, STATUS_RX_VALID,      1'b1, "STATUS.rx_valid after loopback byte");
    expect_bit(rdata, STATUS_RX_FIFO_EMPTY, 1'b0, "STATUS.rx_fifo_empty after loopback byte");

    bus_read(ADDR_DATA, rdata);
    expect_data(rdata, 8'hA5, "Loopback DATA read");

    bus_read(ADDR_STATUS, rdata);
    expect_bit(rdata, STATUS_RX_FIFO_EMPTY, 1'b1, "STATUS.rx_fifo_empty after DATA read");

    // ------------------------------------------------------------
    // Multiple-byte loopback
    // ------------------------------------------------------------

    $display("------------------------------------------------------------");
    $display("Multiple-byte loopback test");
    $display("------------------------------------------------------------");

    send_loopback_byte(8'h3C);
    send_loopback_byte(8'h00);
    send_loopback_byte(8'hFF);

    bus_read(ADDR_STATUS, rdata);
    expect_bit(rdata, STATUS_RX_VALID,      1'b1, "STATUS.rx_valid after multiple loopback bytes");
    expect_bit(rdata, STATUS_RX_FIFO_EMPTY, 1'b0, "STATUS.rx_fifo_empty after multiple loopback bytes");

    bus_read(ADDR_DATA, rdata);
    expect_data(rdata, 8'h3C, "Loopback DATA read byte 1");

    bus_read(ADDR_DATA, rdata);
    expect_data(rdata, 8'h00, "Loopback DATA read byte 2");

    bus_read(ADDR_DATA, rdata);
    expect_data(rdata, 8'hFF, "Loopback DATA read byte 3");

    bus_read(ADDR_STATUS, rdata);
    expect_bit(rdata, STATUS_RX_FIFO_EMPTY, 1'b1, "STATUS.rx_fifo_empty after all loopback reads");

    // ------------------------------------------------------------
    // Loopback disabled negative check
    // ------------------------------------------------------------

    $display("------------------------------------------------------------");
    $display("Loopback disabled negative test");
    $display("------------------------------------------------------------");

    // Enable TX/RX, disable loopback: 0b011 = 0x3
    bus_write(ADDR_CONTROL, 32'h0000_0003);
    bus_read(ADDR_CONTROL, rdata);
    expect_bit(rdata, CTRL_LOOPBACK_ENABLE, 1'b0, "CONTROL.loopback_enable disabled");

    uart_rx_i = 1'b1;

    bus_write(ADDR_DATA, 32'h0000_005A);

    // Wait long enough for TX to complete.
    wait (dut.u_uart_fifo_subsystem.tx_fifo_empty === 1'b1);
    wait (dut.u_uart_fifo_subsystem.tx_busy === 1'b0);
    repeat (50) @(posedge clk);

    bus_read(ADDR_STATUS, rdata);
    expect_bit(rdata, STATUS_RX_FIFO_EMPTY, 1'b1, "RX FIFO remains empty when loopback disabled");

    $display("============================================================");
    if (errors == 0) begin
      $display("[PHASE 5 PASS] Internal loopback verified.");
    end else begin
      $display("[PHASE 5 FAIL] errors=%0d", errors);
    end
    $display("============================================================");

    $finish;
  end

endmodule
