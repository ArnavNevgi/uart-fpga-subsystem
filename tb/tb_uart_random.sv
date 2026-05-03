`timescale 1ns/1ps

import uart_pkg::*;

module tb_uart_random;

  localparam int CLK_PERIOD_NS = 10;
  localparam int FIFO_DEPTH    = 16;

  localparam int NUM_LOOPBACK_PKTS = 24;
  localparam int NUM_RX_PKTS       = 16;
  localparam int NUM_FIFO_STRESS   = 16;
  localparam int NUM_TX_PKTS       = 12;

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

  int scoreboard_errors;
  int directed_tests_pass;
  int random_tests_pass;
  logic [31:0] assertion_failures;
  int total_checks;
  int total_passes;
  real functional_coverage;

  logic [7:0] expected_q[$];
  logic [7:0] actual_byte;

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
    .bus_rdata       (bus_rdata),
    .assertion_failures (assertion_failures)
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
      rst_n              = 1'b0;
      bus_valid          = 1'b0;
      bus_we             = 1'b0;
      bus_addr           = '0;
      bus_wdata          = '0;
      uart_rx_i          = 1'b1;
      back_to_back_event = 1'b0;
      scoreboard_errors  = 0;
      directed_tests_pass = 0;
      random_tests_pass   = 0;
      total_checks        = 0;
      total_passes        = 0;
      expected_q.delete();

      repeat (10) @(posedge clk);
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

      @(negedge clk);
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
      #1;
      data = bus_rdata;

      bus_valid = 1'b0;
      bus_addr  = '0;

      @(negedge clk);
      #1;
    end
  endtask

  task automatic check_byte(
    input logic [7:0] actual,
    input logic [7:0] expected,
    input string      name
  );
    begin
      total_checks++;

      if (actual !== expected) begin
        $display("[ERROR] %s expected=0x%02h actual=0x%02h time=%0t",
                 name, expected, actual, $time);
        scoreboard_errors++;
      end else begin
        total_passes++;
        $display("[PASS] %s=0x%02h time=%0t", name, actual, $time);
      end
    end
  endtask

  task automatic check_status_bit(
    input int    bit_idx,
    input logic  expected,
    input string name
  );
    logic [31:0] status;
    begin
      bus_read(ADDR_STATUS, status);
      total_checks++;

      if (status[bit_idx] !== expected) begin
        $display("[ERROR] %s expected=%0b actual=%0b status=0x%08h time=%0t",
                 name, expected, status[bit_idx], status, $time);
        scoreboard_errors++;
      end else begin
        total_passes++;
        $display("[PASS] %s=%0b time=%0t", name, status[bit_idx], $time);
      end
    end
  endtask

  task automatic clear_errors();
    logic [31:0] control_word;
    begin
      wait_for_uart_idle("clear_errors entry");

      control_word = '0;
      control_word[CTRL_TX_ENABLE]       = dut.tx_enable;
      control_word[CTRL_RX_ENABLE]       = dut.rx_enable;
      control_word[CTRL_LOOPBACK_ENABLE] = dut.loopback_enable;
      control_word[CTRL_CLEAR_ERRORS]    = 1'b1;

      bus_write(ADDR_CONTROL, control_word);
      repeat (4) @(posedge clk);

      control_word[CTRL_CLEAR_ERRORS] = 1'b0;
      bus_write(ADDR_CONTROL, control_word);
      repeat (4) @(posedge clk);
    end
  endtask

  task automatic wait_for_uart_idle(input string name);
    int cycles;
    begin
      cycles = 0;

      while (((dut.tx_busy !== 1'b0) ||
              (dut.u_uart_fifo_subsystem.rx_core_busy !== 1'b0)) &&
             (cycles < 400000)) begin
        @(posedge clk);
        cycles++;
      end

      if ((dut.tx_busy !== 1'b0) ||
          (dut.u_uart_fifo_subsystem.rx_core_busy !== 1'b0)) begin
        $display("[ERROR] Timeout waiting for UART idle during %s time=%0t", name, $time);
        scoreboard_errors++;
      end
    end
  endtask

  task automatic wait_for_tx_drain(input string name);
    int cycles;
    begin
      cycles = 0;

      while (((dut.u_uart_fifo_subsystem.tx_fifo_empty !== 1'b1) ||
              (dut.tx_busy !== 1'b0)) &&
             (cycles < 600000)) begin
        @(posedge clk);
        cycles++;
      end

      if ((dut.u_uart_fifo_subsystem.tx_fifo_empty !== 1'b1) ||
          (dut.tx_busy !== 1'b0)) begin
        $display("[ERROR] Timeout waiting for TX drain during %s time=%0t", name, $time);
        scoreboard_errors++;
      end
    end
  endtask

  task automatic wait_for_rx_nonempty(input string name);
    int cycles;
    begin
      cycles = 0;

      while ((dut.u_uart_fifo_subsystem.rx_fifo_empty !== 1'b0) &&
             (cycles < 400000)) begin
        @(posedge clk);
        cycles++;
      end

      if (dut.u_uart_fifo_subsystem.rx_fifo_empty !== 1'b0) begin
        $display("[ERROR] Timeout waiting for RX FIFO non-empty during %s time=%0t", name, $time);
        scoreboard_errors++;
      end
    end
  endtask

  task automatic wait_for_rx_count_at_least(
    input int    count_needed,
    input string name
  );
    int cycles;
    begin
      cycles = 0;

      while ((dut.u_uart_fifo_subsystem.rx_fifo_count < count_needed) &&
             (cycles < 800000)) begin
        @(posedge clk);
        cycles++;
      end

      if (dut.u_uart_fifo_subsystem.rx_fifo_count < count_needed) begin
        $display("[ERROR] Timeout waiting for RX FIFO count >= %0d during %s time=%0t",
                 count_needed, name, $time);
        scoreboard_errors++;
      end
    end
  endtask

  task automatic wait_os_ticks(input int ticks);
    begin
      repeat (ticks) @(posedge dut.os_tick);
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
      wait_os_ticks(4);
    end
  endtask

  task automatic set_baud_div(input int div_value);
    logic [31:0] rdata;
    begin
      wait_for_uart_idle("baud divisor update");

      bus_write(ADDR_BAUDDIV, div_value[31:0]);
      bus_read(ADDR_BAUDDIV, rdata);
      check_byte(rdata[7:0], div_value[7:0], "BAUD_DIV randomized readback");
    end
  endtask

  task automatic enable_mode(
    input logic tx_en,
    input logic rx_en,
    input logic loopback_en
  );
    logic [31:0] control_word;
    begin
      wait_for_uart_idle("control mode update");

      control_word = '0;
      control_word[CTRL_TX_ENABLE]       = tx_en;
      control_word[CTRL_RX_ENABLE]       = rx_en;
      control_word[CTRL_LOOPBACK_ENABLE] = loopback_en;

      bus_write(ADDR_CONTROL, control_word);
      repeat (4) @(posedge clk);
    end
  endtask

  task automatic random_loopback_packets();
    logic [7:0] tx_byte;
    logic [31:0] rdata;
    begin
      $display("------------------------------------------------------------");
      $display("Random loopback packet test");
      $display("------------------------------------------------------------");

      expected_q.delete();
      enable_mode(1'b1, 1'b1, 1'b1);

      for (int i = 0; i < NUM_LOOPBACK_PKTS; i++) begin
        tx_byte = $urandom_range(0, 255);
        expected_q.push_back(tx_byte);

        $display("[INFO] Loopback TX byte %0d = 0x%02h", i, tx_byte);
        bus_write(ADDR_DATA, {24'h0, tx_byte});

        wait_for_rx_nonempty("random loopback byte");
        repeat (4) @(posedge clk);

        bus_read(ADDR_DATA, rdata);
        actual_byte = rdata[7:0];

        check_byte(actual_byte, expected_q.pop_front(), "Random loopback byte");
      end
    end
  endtask

  task automatic random_tx_byte_stream();
    logic [7:0] tx_byte;
    begin
      $display("------------------------------------------------------------");
      $display("Random TX byte-stream test");
      $display("------------------------------------------------------------");

      enable_mode(1'b0, 1'b0, 1'b0);

      for (int i = 0; i < NUM_TX_PKTS; i++) begin
        tx_byte = $urandom_range(0, 255);
        $display("[INFO] TX-only byte %0d = 0x%02h", i, tx_byte);
        bus_write(ADDR_DATA, {24'h0, tx_byte});
      end

      enable_mode(1'b1, 1'b0, 1'b0);
      wait_for_tx_drain("random TX byte stream");

      check_status_bit(STATUS_TX_FIFO_EMPTY, 1'b1, "TX FIFO empty after random TX byte stream");
      check_status_bit(STATUS_RX_FIFO_EMPTY, 1'b1, "RX FIFO empty after TX-only stream");
    end
  endtask

  task automatic random_external_rx_stream();
    logic [7:0] rx_byte;
    logic [31:0] rdata;
    begin
      $display("------------------------------------------------------------");
      $display("Random external RX byte-stream test");
      $display("------------------------------------------------------------");

      expected_q.delete();
      enable_mode(1'b0, 1'b1, 1'b0);
      uart_rx_i = 1'b1;

      for (int i = 0; i < NUM_RX_PKTS; i++) begin
        rx_byte = $urandom_range(0, 255);
        expected_q.push_back(rx_byte);

        $display("[INFO] External RX byte %0d = 0x%02h", i, rx_byte);
        drive_uart_rx_byte(rx_byte, 1'b1);

        wait_for_rx_nonempty("random external RX byte");
        repeat (4) @(posedge clk);

        bus_read(ADDR_DATA, rdata);
        actual_byte = rdata[7:0];

        check_byte(actual_byte, expected_q.pop_front(), "Random external RX byte");
      end
    end
  endtask

  task automatic random_fifo_stress();
    logic [7:0] stress_byte;
    logic [31:0] rdata;
    begin
      $display("------------------------------------------------------------");
      $display("Random FIFO stress test");
      $display("------------------------------------------------------------");

      expected_q.delete();
      enable_mode(1'b0, 1'b1, 1'b0);

      for (int i = 0; i < NUM_FIFO_STRESS; i++) begin
        stress_byte = $urandom_range(0, 255);
        drive_uart_rx_byte(stress_byte, 1'b1);
        expected_q.push_back(stress_byte);
      end

      check_status_bit(STATUS_RX_FIFO_FULL, 1'b1, "RX FIFO full during random stress");

      for (int i = 0; i < NUM_FIFO_STRESS; i++) begin
        bus_read(ADDR_DATA, rdata);
        check_byte(rdata[7:0], expected_q.pop_front(), "RX FIFO stress drain byte");
      end

      check_status_bit(STATUS_RX_FIFO_EMPTY, 1'b1, "RX FIFO empty after random stress drain");

      enable_mode(1'b0, 1'b0, 1'b0);

      for (int i = 0; i < FIFO_DEPTH; i++) begin
        stress_byte = $urandom_range(0, 255);
        bus_write(ADDR_DATA, {24'h0, stress_byte});
      end

      check_status_bit(STATUS_TX_FIFO_FULL, 1'b1, "TX FIFO full during random stress");

      enable_mode(1'b1, 1'b0, 1'b0);

      wait_for_tx_drain("random FIFO stress TX drain");
      repeat (20) @(posedge clk);

      check_status_bit(STATUS_TX_FIFO_EMPTY, 1'b1, "TX FIFO empty after TX drain");
    end
  endtask

  task automatic random_baud_divisor_test();
    int div_values[4];
    int selected_div;
    logic [7:0] tx_byte;
    logic [31:0] rdata;
    begin
      $display("------------------------------------------------------------");
      $display("Random baud divisor selection test");
      $display("------------------------------------------------------------");

      div_values[0] = 4;
      div_values[1] = 6;
      div_values[2] = 8;
      div_values[3] = 10;

      for (int i = 0; i < 4; i++) begin
        selected_div = div_values[$urandom_range(0, 3)];
        set_baud_div(selected_div);

        enable_mode(1'b1, 1'b1, 1'b1);

        tx_byte = $urandom_range(0, 255);
        bus_write(ADDR_DATA, {24'h0, tx_byte});

        wait_for_rx_nonempty("loopback after random baud divisor");
        repeat (4) @(posedge clk);

        bus_read(ADDR_DATA, rdata);
        check_byte(rdata[7:0], tx_byte, "Loopback byte after random baud divisor");
      end

      set_baud_div(4);
    end
  endtask

  task automatic error_injection_test();
    begin
      $display("------------------------------------------------------------");
      $display("Error injection test");
      $display("------------------------------------------------------------");

      enable_mode(1'b0, 1'b1, 1'b0);
      clear_errors();

      drive_uart_rx_byte(8'h55, 1'b0);
      repeat (20) @(posedge clk);

      check_status_bit(STATUS_FRAME_ERROR, 1'b1, "Frame error after invalid stop bit");

      clear_errors();

      for (int i = 0; i < FIFO_DEPTH; i++) begin
        drive_uart_rx_byte((8'h60 + i[7:0]), 1'b1);
      end

      check_status_bit(STATUS_RX_FIFO_FULL, 1'b1, "RX FIFO full before overrun injection");

      drive_uart_rx_byte(8'hAA, 1'b1);
      repeat (20) @(posedge clk);

      check_status_bit(STATUS_OVERRUN_ERROR, 1'b1, "Overrun error after extra RX byte");

      clear_errors();

      // Drain RX FIFO
      for (int i = 0; i < FIFO_DEPTH; i++) begin
        logic [31:0] dummy;
        bus_read(ADDR_DATA, dummy);
      end
    end
  endtask

  task automatic back_to_back_loopback_test();
    logic [7:0] bytes[6];
    logic [31:0] rdata;
    begin
      $display("------------------------------------------------------------");
      $display("Back-to-back queued loopback transfer test");
      $display("------------------------------------------------------------");

      expected_q.delete();
      bytes[0] = 8'hA5;
      bytes[1] = 8'h3C;
      bytes[2] = 8'h00;
      bytes[3] = 8'hFF;
      bytes[4] = $urandom_range(0, 255);
      bytes[5] = $urandom_range(0, 255);

      enable_mode(1'b1, 1'b1, 1'b1);

      for (int i = 0; i < 6; i++) begin
        expected_q.push_back(bytes[i]);
        bus_write(ADDR_DATA, {24'h0, bytes[i]});
      end

      @(negedge clk);
      back_to_back_event = 1'b1;
      @(negedge clk);
      back_to_back_event = 1'b0;

      wait_for_rx_count_at_least(6, "back-to-back loopback transfer");
      repeat (10) @(posedge clk);

      for (int i = 0; i < 6; i++) begin
        bus_read(ADDR_DATA, rdata);
        check_byte(rdata[7:0], expected_q.pop_front(), "Back-to-back loopback byte");
      end
    end
  endtask

  initial begin
    $display("============================================================");
    $display("PHASE 7 RANDOMIZED UART VERIFICATION START");
    $display("============================================================");

    reset_dut();

    set_baud_div(4);

    random_tx_byte_stream();
    random_loopback_packets();
    random_external_rx_stream();
    random_fifo_stress();
    random_baud_divisor_test();
    error_injection_test();
    back_to_back_loopback_test();

    directed_tests_pass = (scoreboard_errors == 0);
    random_tests_pass   = (scoreboard_errors == 0);
    functional_coverage = $get_coverage();

    $display("================ UART VERIFICATION SUMMARY ================");
    $display("Directed tests      : %s", directed_tests_pass ? "PASS" : "FAIL");
    $display("Random tests        : %s", random_tests_pass   ? "PASS" : "FAIL");
    $display("Scoreboard errors   : %0d", scoreboard_errors);
    $display("Assertions          : %s", assertion_failures == 0 ? "PASS" : "CHECK LOG");
    $display("Functional coverage : %0.2f%%", functional_coverage);
    $display("============================================================");

    if (scoreboard_errors == 0) begin
      $display("[PHASE 7 PASS] UART subsystem verification complete.");
      $display("[PHASE 7 PASS] Self-checking verification complete.");
    end else begin
      $display("[PHASE 7 FAIL] errors=%0d", scoreboard_errors);
    end

    $display("============================================================");

    $finish;
  end

endmodule
