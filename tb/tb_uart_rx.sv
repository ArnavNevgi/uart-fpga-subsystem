`timescale 1ns/1ps

import uart_pkg::*;

module tb_uart_rx;

  localparam int CLK_PERIOD_NS = 10;
  localparam int TEST_DIV      = 4;
  localparam int OVERSAMPLE_TB = 16;

  logic clk;
  logic rst_n;

  logic rx_enable;
  logic os_tick;
  logic rx_i;

  logic [7:0] rx_data;
  logic rx_valid;
  logic rx_busy;
  logic frame_error;

  int errors;

  baud_gen #(
    .DIV_WIDTH(16)
  ) u_baud_gen (
    .clk       (clk),
    .rst_n     (rst_n),
    .enable    (1'b1),
    .baud_div  (16'd4),
    .baud_tick (os_tick)
  );

  uart_rx #(
    .DATA_WIDTH(8),
    .OVERSAMPLE_RATE(16)
  ) dut (
    .clk         (clk),
    .rst_n       (rst_n),
    .rx_enable   (rx_enable),
    .os_tick     (os_tick),
    .rx_i        (rx_i),
    .rx_data     (rx_data),
    .rx_valid    (rx_valid),
    .rx_busy     (rx_busy),
    .frame_error (frame_error)
  );

  initial begin
    clk = 1'b0;
    forever #(CLK_PERIOD_NS/2) clk = ~clk;
  end

  task automatic wait_os_ticks(input int num_ticks);
    begin
      repeat (num_ticks) begin
        @(posedge os_tick);
      end
    end
  endtask

  task automatic reset_dut();
    begin
      rst_n     = 1'b0;
      rx_enable = 1'b0;
      rx_i      = 1'b1;
      errors    = 0;

      repeat (5) @(posedge clk);
      rst_n = 1'b1;
      repeat (5) @(posedge clk);
    end
  endtask

  task automatic drive_uart_byte(
    input logic [7:0] data,
    input logic       good_stop_bit
  );
    begin
      $display("Driving UART RX byte: 0x%02h good_stop_bit=%0b", data, good_stop_bit);

      // Idle before frame
      rx_i <= 1'b1;
      wait_os_ticks(OVERSAMPLE_TB);

      // Start bit
      rx_i <= 1'b0;
      wait_os_ticks(OVERSAMPLE_TB);

      // Data bits, LSB first
      for (int i = 0; i < 8; i++) begin
        rx_i <= data[i];
        wait_os_ticks(OVERSAMPLE_TB);
      end

      // Stop bit
      rx_i <= good_stop_bit;
      wait_os_ticks(OVERSAMPLE_TB);

      // Return to idle
      rx_i <= 1'b1;
      wait_os_ticks(OVERSAMPLE_TB);
    end
  endtask

    task automatic check_valid_byte(input logic [7:0] expected);
    begin
      // Make sure we do not accidentally reuse a previous rx_valid pulse
      wait (rx_valid === 1'b0);

      // Wait for the next new valid pulse
      wait (rx_valid === 1'b1);
      #1;

      if (rx_data !== expected) begin
        $display("[ERROR] RX data mismatch. expected=0x%02h actual=0x%02h time=%0t",
                expected, rx_data, $time);
        errors++;
      end else begin
        $display("[PASS] RX byte matched: 0x%02h time=%0t", rx_data, $time);
      end

      // Wait until rx_valid deasserts before allowing another check
      @(posedge clk);
      wait (rx_valid === 1'b0);
    end
endtask

  task automatic check_frame_error();
    begin
      wait (frame_error === 1'b1);
      #1;

      if (frame_error !== 1'b1) begin
        $display("[ERROR] frame_error did not assert");
        errors++;
      end else begin
        $display("[PASS] frame_error asserted correctly time=%0t", $time);
      end

      @(posedge clk);
    end
  endtask

  initial begin
    $display("============================================================");
    $display("PHASE 2 UART RX TEST START");
    $display("============================================================");

    reset_dut();

    if (rx_busy !== 1'b0) begin
      $display("[ERROR] RX busy after reset");
      errors++;
    end

    if (rx_valid !== 1'b0) begin
      $display("[ERROR] RX valid high after reset");
      errors++;
    end

    rx_enable = 1'b1;

    fork
      drive_uart_byte(8'hA5, 1'b1);
      check_valid_byte(8'hA5);
    join

    fork
      drive_uart_byte(8'h3C, 1'b1);
      check_valid_byte(8'h3C);
    join

    fork
      drive_uart_byte(8'h00, 1'b1);
      check_valid_byte(8'h00);
    join

    fork
      drive_uart_byte(8'hFF, 1'b1);
      check_valid_byte(8'hFF);
    join

    // Frame error test: bad stop bit
    fork
      drive_uart_byte(8'h55, 1'b0);
      check_frame_error();
    join

    // Back-to-back valid bytes
    $display("Testing back-to-back RX bytes");

    fork
      begin
        drive_uart_byte(8'h12, 1'b1);
        drive_uart_byte(8'h34, 1'b1);
      end
      begin
        check_valid_byte(8'h12);
        check_valid_byte(8'h34);
      end
    join

    $display("============================================================");
    if (errors == 0) begin
      $display("[PHASE 2 PASS] UART receiver with 16x oversampling verified.");
    end else begin
      $display("[PHASE 2 FAIL] errors=%0d", errors);
    end
    $display("============================================================");

    $finish;
  end

endmodule