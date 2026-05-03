`timescale 1ns/1ps

import uart_pkg::*;

module tb_uart_top;

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
      #1;
      data = bus_rdata;

      @(negedge clk);
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

  task automatic wait_os_ticks(input int ticks);
    begin
      repeat (ticks) begin
        @(posedge dut.os_tick);
      end
      #1;
    end
  endtask

  task automatic drive_uart_rx_byte(
    input logic [7:0] data,
    input logic       good_stop_bit
  );
    begin
      uart_rx_i = 1'b1;
      wait_os_ticks(16);

      uart_rx_i = 1'b0;
      wait_os_ticks(16);

      for (int i = 0; i < 8; i++) begin
        uart_rx_i = data[i];
        wait_os_ticks(16);
      end

      uart_rx_i = good_stop_bit;
      wait_os_ticks(16);

      uart_rx_i = 1'b1;
      wait_os_ticks(2);
    end
  endtask

  logic [31:0] rdata;

  initial begin
    $display("============================================================");
    $display("PHASE 4 UART TOP REGISTER INTERFACE TEST START");
    $display("============================================================");

    reset_dut();

    // ------------------------------------------------------------
    // BAUD_DIV register test
    // ------------------------------------------------------------

    $display("------------------------------------------------------------");
    $display("BAUD_DIV register test");
    $display("------------------------------------------------------------");

    bus_write(ADDR_BAUDDIV, 32'(TEST_BAUD_DIV));
    bus_read(ADDR_BAUDDIV, rdata);
    expect_data(rdata, TEST_BAUD_DIV[7:0], "BAUD_DIV readback");

    // ------------------------------------------------------------
    // CONTROL register test
    // tx_enable=0, rx_enable=1, loopback=0
    // ------------------------------------------------------------

    $display("------------------------------------------------------------");
    $display("CONTROL register test");
    $display("------------------------------------------------------------");

    bus_write(ADDR_CONTROL, 32'h0000_0002);
    bus_read(ADDR_CONTROL, rdata);

    expect_bit(rdata, CTRL_TX_ENABLE,       1'b0, "CONTROL.tx_enable");
    expect_bit(rdata, CTRL_RX_ENABLE,       1'b1, "CONTROL.rx_enable");
    expect_bit(rdata, CTRL_LOOPBACK_ENABLE, 1'b0, "CONTROL.loopback_enable");

    // ------------------------------------------------------------
    // STATUS after reset/config
    // ------------------------------------------------------------

    $display("------------------------------------------------------------");
    $display("STATUS register initial flag test");
    $display("------------------------------------------------------------");

    bus_read(ADDR_STATUS, rdata);

    expect_bit(rdata, STATUS_TX_FIFO_EMPTY, 1'b1, "STATUS.tx_fifo_empty");
    expect_bit(rdata, STATUS_TX_FIFO_FULL,  1'b0, "STATUS.tx_fifo_full");
    expect_bit(rdata, STATUS_RX_FIFO_EMPTY, 1'b1, "STATUS.rx_fifo_empty");
    expect_bit(rdata, STATUS_RX_FIFO_FULL,  1'b0, "STATUS.rx_fifo_full");

    // ------------------------------------------------------------
    // DATA write to TX FIFO with TX disabled
    // ------------------------------------------------------------

    $display("------------------------------------------------------------");
    $display("DATA register TX FIFO fill test");
    $display("------------------------------------------------------------");

    for (int i = 0; i < FIFO_DEPTH; i++) begin
      bus_write(ADDR_DATA, {24'h0, i[7:0]});
    end

    bus_read(ADDR_STATUS, rdata);
    expect_bit(rdata, STATUS_TX_FIFO_FULL,  1'b1, "STATUS.tx_fifo_full after DATA writes");
    expect_bit(rdata, STATUS_TX_FIFO_EMPTY, 1'b0, "STATUS.tx_fifo_empty after DATA writes");

    // Overflow attempt should not crash or change full flag
    bus_write(ADDR_DATA, 32'h0000_00EE);
    bus_read(ADDR_STATUS, rdata);
    expect_bit(rdata, STATUS_TX_FIFO_FULL, 1'b1, "STATUS.tx_fifo_full after overflow attempt");

    // Enable TX and wait for TX FIFO drain
    bus_write(ADDR_CONTROL, 32'h0000_0003);

    wait (dut.u_uart_fifo_subsystem.tx_fifo_empty === 1'b1);
    repeat (20) @(posedge clk);

    bus_read(ADDR_STATUS, rdata);
    expect_bit(rdata, STATUS_TX_FIFO_EMPTY, 1'b1, "STATUS.tx_fifo_empty after TX drain");
    expect_bit(rdata, STATUS_TX_FIFO_FULL,  1'b0, "STATUS.tx_fifo_full after TX drain");

    // ------------------------------------------------------------
    // RX DATA read path
    // ------------------------------------------------------------

    $display("------------------------------------------------------------");
    $display("RX DATA register read test");
    $display("------------------------------------------------------------");

    drive_uart_rx_byte(8'hA5, 1'b1);
    drive_uart_rx_byte(8'h3C, 1'b1);

    repeat (20) @(posedge clk);

    bus_read(ADDR_STATUS, rdata);
    expect_bit(rdata, STATUS_RX_VALID,      1'b1, "STATUS.rx_valid after RX bytes");
    expect_bit(rdata, STATUS_RX_FIFO_EMPTY, 1'b0, "STATUS.rx_fifo_empty after RX bytes");

    bus_read(ADDR_DATA, rdata);
    expect_data(rdata, 8'hA5, "DATA read first RX byte");

    bus_read(ADDR_DATA, rdata);
    expect_data(rdata, 8'h3C, "DATA read second RX byte");

    bus_read(ADDR_STATUS, rdata);
    expect_bit(rdata, STATUS_RX_FIFO_EMPTY, 1'b1, "STATUS.rx_fifo_empty after RX reads");

    // ------------------------------------------------------------
    // Frame error and clear_errors
    // ------------------------------------------------------------

    $display("------------------------------------------------------------");
    $display("Frame error and clear_errors test");
    $display("------------------------------------------------------------");

    drive_uart_rx_byte(8'h55, 1'b0);
    repeat (20) @(posedge clk);

    bus_read(ADDR_STATUS, rdata);
    expect_bit(rdata, STATUS_FRAME_ERROR, 1'b1, "STATUS.frame_error after bad stop bit");

    bus_write(ADDR_CONTROL, 32'h0000_000B); // tx=1, rx=1, clear_errors=1
    repeat (5) @(posedge clk);

    bus_write(ADDR_CONTROL, 32'h0000_0003); // tx=1, rx=1, clear_errors=0
    repeat (5) @(posedge clk);

    bus_read(ADDR_STATUS, rdata);
    expect_bit(rdata, STATUS_OVERRUN_ERROR, 1'b0, "STATUS.overrun_error clear check");

    $display("============================================================");
    if (errors == 0) begin
      $display("[PHASE 4 PASS] Register-controlled UART top-level verified.");
    end else begin
      $display("[PHASE 4 FAIL] errors=%0d", errors);
    end
    $display("============================================================");

    $finish;
  end

endmodule