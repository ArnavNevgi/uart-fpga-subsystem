`timescale 1ns/1ps

import uart_pkg::*;

module tb_uart_loopback;

  localparam int CLK_PERIOD_NS = 10;
  localparam int FIFO_DEPTH    = 16;
  localparam int TEST_BAUD_DIV = 4;
  localparam logic [3:0] TB_ADDR_DATA = ADDR_DATA;
  localparam logic [1:0] TB_TX_START  = TX_START;
  localparam logic [1:0] TB_TX_STOP   = TX_STOP;
  localparam logic [2:0] TB_RX_STOP   = RX_STOP;

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

  logic back_to_back_event;

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

    uart_assertions u_uart_assertions (
    .clk             (clk),
    .rst_n           (rst_n),

    .tx_enable       (dut.tx_enable),
    .rx_enable       (dut.rx_enable),
    .loopback_enable (dut.loopback_enable),

    .uart_tx_o       (uart_tx_o),
    .uart_rx_i       (uart_rx_i),
    .uart_rx_muxed   (dut.uart_rx_muxed),

    .tx_busy         (dut.tx_busy),
    .tx_done         (dut.tx_done),
    .tx_start_state  (dut.u_uart_fifo_subsystem.u_uart_tx.state == TB_TX_START),
    .tx_stop_state   (dut.u_uart_fifo_subsystem.u_uart_tx.state == TB_TX_STOP),

    .tx_fifo_wr_en   (dut.tx_fifo_wr_en),
    .tx_fifo_full    (dut.tx_fifo_full),
    .tx_fifo_empty   (dut.tx_fifo_empty),

    .rx_fifo_rd_en   (dut.rx_fifo_rd_en),
    .rx_fifo_full    (dut.rx_fifo_full),
    .rx_fifo_empty   (dut.rx_fifo_empty),

    .rx_valid        (dut.rx_valid),
    .rx_core_valid   (dut.u_uart_fifo_subsystem.rx_core_valid),
    .rx_stop_sample_event (
      (dut.u_uart_fifo_subsystem.u_uart_rx.state == TB_RX_STOP) &&
      dut.os_tick &&
      (dut.u_uart_fifo_subsystem.u_uart_rx.sample_cnt == 4'd15)
    ),
    .rx_stop_bit_sample (dut.uart_rx_muxed),
    .frame_error     (dut.frame_error),
    .overrun_error   (dut.overrun_error),

    .bus_valid       (bus_valid),
    .bus_we          (bus_we),
    .bus_addr        (bus_addr),
    .bus_ready       (bus_ready),
    .bus_rdata       (bus_rdata)
  );

  uart_coverage u_uart_coverage (
    .clk             (clk),
    .rst_n           (rst_n),

    .tx_data_sample  (bus_wdata[7:0]),
    .tx_data_event   (bus_valid && bus_we && bus_ready && (bus_addr == TB_ADDR_DATA)),

    .rx_data_sample  (bus_rdata[7:0]),
    .rx_data_event   (bus_valid && !bus_we && bus_ready && (bus_addr == TB_ADDR_DATA)),

    .tx_fifo_full    (dut.tx_fifo_full),
    .tx_fifo_empty   (dut.tx_fifo_empty),
    .rx_fifo_full    (dut.rx_fifo_full),
    .rx_fifo_empty   (dut.rx_fifo_empty),

    .frame_error     (dut.frame_error),
    .overrun_error   (dut.overrun_error),
    .loopback_enable (dut.loopback_enable),
    .back_to_back_event (back_to_back_event),

    .baud_div        (dut.baud_div)
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
      back_to_back_event = 1'b0;
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

  task automatic wait_for_rx_count_gt(
    input int unsigned count_before,
    input string       name
  );
    int cycles;
    begin
      cycles = 0;

      while ((dut.u_uart_fifo_subsystem.rx_fifo_count <= count_before) &&
             (cycles < 200000)) begin
        @(posedge clk);
        cycles++;
      end

      if (dut.u_uart_fifo_subsystem.rx_fifo_count <= count_before) begin
        $display("[ERROR] Timeout waiting for %s time=%0t", name, $time);
        errors++;
      end
    end
  endtask

  task automatic wait_for_tx_drain(input string name);
    int cycles;
    begin
      cycles = 0;

      while (((dut.u_uart_fifo_subsystem.tx_fifo_empty !== 1'b1) ||
              (dut.u_uart_fifo_subsystem.tx_busy !== 1'b0)) &&
             (cycles < 400000)) begin
        @(posedge clk);
        cycles++;
      end

      if ((dut.u_uart_fifo_subsystem.tx_fifo_empty !== 1'b1) ||
          (dut.u_uart_fifo_subsystem.tx_busy !== 1'b0)) begin
        $display("[ERROR] Timeout waiting for %s time=%0t", name, $time);
        errors++;
      end
    end
  endtask

  task automatic wait_for_overrun(input string name);
    int cycles;
    begin
      cycles = 0;

      while ((dut.overrun_error !== 1'b1) && (cycles < 200000)) begin
        @(posedge clk);
        cycles++;
      end

      if (dut.overrun_error !== 1'b1) begin
        $display("[ERROR] Timeout waiting for %s time=%0t", name, $time);
        errors++;
      end
    end
  endtask

  task automatic send_loopback_byte(input logic [7:0] data);
    int unsigned rx_count_before;
    begin
      $display("Sending loopback byte: 0x%02h", data);

      rx_count_before = dut.u_uart_fifo_subsystem.rx_fifo_count;
      bus_write(ADDR_DATA, {24'h0, data});

      wait_for_rx_count_gt(rx_count_before, "loopback RX FIFO count increment");

      if (rx_count_before > 0) begin
        @(negedge clk);
        back_to_back_event = 1'b1;
        @(negedge clk);
        back_to_back_event = 1'b0;
      end

      repeat (10) @(posedge clk);
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
    wait_for_tx_drain("loopback disabled TX drain");
    repeat (50) @(posedge clk);

    bus_read(ADDR_STATUS, rdata);
    expect_bit(rdata, STATUS_RX_FIFO_EMPTY, 1'b1, "RX FIFO remains empty when loopback disabled");

    // ------------------------------------------------------------
    // Small Phase 6 directed coverage hit: external RX frame error
    // ------------------------------------------------------------

    $display("------------------------------------------------------------");
    $display("External RX frame error coverage test");
    $display("------------------------------------------------------------");

    drive_uart_rx_byte(8'h55, 1'b0);
    repeat (20) @(posedge clk);

    bus_read(ADDR_STATUS, rdata);
    expect_bit(rdata, STATUS_FRAME_ERROR, 1'b1, "STATUS.frame_error after external bad stop bit");

    // ------------------------------------------------------------
    // Small Phase 6 directed coverage hit: TX FIFO full
    // ------------------------------------------------------------

    $display("------------------------------------------------------------");
    $display("TX FIFO full coverage test");
    $display("------------------------------------------------------------");

    bus_write(ADDR_CONTROL, 32'h0000_0000);

    for (int i = 0; i < FIFO_DEPTH; i++) begin
      bus_write(ADDR_DATA, {24'h0, i[7:0]});
    end

    bus_read(ADDR_STATUS, rdata);
    expect_bit(rdata, STATUS_TX_FIFO_FULL, 1'b1, "STATUS.tx_fifo_full after directed fill");

    bus_write(ADDR_DATA, 32'h0000_00EE);

    bus_write(ADDR_CONTROL, 32'h0000_0001);
    wait_for_tx_drain("directed TX FIFO drain");
    repeat (20) @(posedge clk);

    bus_read(ADDR_STATUS, rdata);
    expect_bit(rdata, STATUS_TX_FIFO_EMPTY, 1'b1, "STATUS.tx_fifo_empty after directed drain");

    // ------------------------------------------------------------
    // Small Phase 6 directed coverage hit: RX FIFO full and overrun
    // ------------------------------------------------------------

    $display("------------------------------------------------------------");
    $display("RX FIFO full and overrun coverage test");
    $display("------------------------------------------------------------");

    bus_write(ADDR_CONTROL, 32'h0000_000F);
    bus_write(ADDR_CONTROL, 32'h0000_0007);

    for (int i = 0; i < FIFO_DEPTH; i++) begin
      send_loopback_byte(i[7:0]);
    end

    bus_read(ADDR_STATUS, rdata);
    expect_bit(rdata, STATUS_RX_FIFO_FULL, 1'b1, "STATUS.rx_fifo_full after directed fill");

    bus_write(ADDR_DATA, 32'h0000_00EE);
    wait_for_overrun("directed RX FIFO overrun");

    bus_read(ADDR_STATUS, rdata);
    expect_bit(rdata, STATUS_OVERRUN_ERROR, 1'b1, "STATUS.overrun_error after extra RX byte");

    $display("============================================================");
    if (errors == 0) begin
      $display("[PHASE 5 PASS] Internal loopback verified.");
      $display("[PHASE 6 PASS] Assertions and functional coverage added.");
    end else begin
      $display("[PHASE 5 FAIL] errors=%0d", errors);
    end
    $display("============================================================");

    $finish;
  end

endmodule
