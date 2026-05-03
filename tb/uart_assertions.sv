`timescale 1ns/1ps

module uart_assertions #(
  parameter int DATA_WIDTH = 8
)(
  input logic clk,
  input logic rst_n,

  input logic tx_enable,
  input logic rx_enable,
  input logic loopback_enable,

  input logic uart_tx_o,
  input logic uart_rx_i,
  input logic uart_rx_muxed,

  input logic tx_busy,
  input logic tx_done,
  input logic tx_start_state,
  input logic tx_stop_state,

  input logic tx_fifo_wr_en,
  input logic tx_fifo_full,
  input logic tx_fifo_empty,

  input logic rx_fifo_rd_en,
  input logic rx_fifo_full,
  input logic rx_fifo_empty,

  input logic rx_valid,
  input logic rx_core_valid,
  input logic rx_stop_sample_event,
  input logic rx_stop_bit_sample,
  input logic frame_error,
  input logic overrun_error,

  input logic bus_valid,
  input logic bus_we,
  input logic [3:0] bus_addr,
  input logic bus_ready,

  input logic [31:0] bus_rdata,

  output logic [31:0] assertion_failures
);

  logic bus_valid_d1;
  logic bus_valid_d2;
  logic bus_valid_d3;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      bus_valid_d1 <= 1'b0;
      bus_valid_d2 <= 1'b0;
      bus_valid_d3 <= 1'b0;
      assertion_failures <= '0;
    end else begin
      bus_valid_d1 <= bus_valid;
      bus_valid_d2 <= bus_valid_d1;
      bus_valid_d3 <= bus_valid_d2;
    end
  end

  task automatic report_assertion_failure(input string message);
    begin
      assertion_failures++;
      $error("[ASSERT FAIL] %s", message);
    end
  endtask

  // ------------------------------------------------------------
  // No unknowns on key outputs after reset
  // bus_rdata is only meaningful during a bus response.
  // ------------------------------------------------------------

  always_ff @(posedge clk) begin
    if (rst_n) begin
      assert (!$isunknown(uart_tx_o))
        else report_assertion_failure("X/Z detected on uart_tx_o");
      assert (!$isunknown(uart_rx_i))
        else report_assertion_failure("X/Z detected on uart_rx_i");
      assert (!$isunknown(uart_rx_muxed))
        else report_assertion_failure("X/Z detected on uart_rx_muxed");
      assert (!$isunknown({tx_enable, rx_enable, loopback_enable}))
        else report_assertion_failure("X/Z detected on UART control outputs");
      assert (!$isunknown({tx_busy, tx_done, tx_start_state, tx_stop_state}))
        else report_assertion_failure("X/Z detected on TX status/state observations");
      assert (!$isunknown({tx_fifo_wr_en, tx_fifo_full, tx_fifo_empty}))
        else report_assertion_failure("X/Z detected on TX FIFO signals");
      assert (!$isunknown({rx_fifo_rd_en, rx_fifo_full, rx_fifo_empty}))
        else report_assertion_failure("X/Z detected on RX FIFO signals");
      assert (!$isunknown({rx_valid, rx_core_valid, frame_error, overrun_error}))
        else report_assertion_failure("X/Z detected on RX status/error signals");
      assert (!$isunknown(bus_ready))
        else report_assertion_failure("X/Z detected on bus_ready");

      if (bus_valid) begin
        assert (!$isunknown({bus_we, bus_addr}))
          else report_assertion_failure("X/Z detected on active bus request controls");
      end

      if (bus_ready) begin
        assert (!$isunknown(bus_rdata))
          else report_assertion_failure("X/Z detected on bus_rdata during bus_ready");
      end
    end
  end

  // ------------------------------------------------------------
  // UART TX idle line should be high when transmitter is not busy
  // ------------------------------------------------------------

  property tx_idle_high;
    @(posedge clk) disable iff (!rst_n)
      (!tx_busy) |-> (uart_tx_o == 1'b1);
  endproperty

  assert property (tx_idle_high)
    else report_assertion_failure("UART TX line not high while idle");

  property tx_start_bit_low;
    @(posedge clk) disable iff (!rst_n)
      $rose(tx_start_state) |=> (uart_tx_o == 1'b0);
  endproperty

  assert property (tx_start_bit_low)
    else report_assertion_failure("UART TX start bit did not drive low");

  property tx_stop_bit_high;
    @(posedge clk) disable iff (!rst_n)
      $rose(tx_stop_state) |=> (uart_tx_o == 1'b1);
  endproperty

  assert property (tx_stop_bit_high)
    else report_assertion_failure("UART TX stop bit did not drive high");

  // ------------------------------------------------------------
  // FIFO safety checks
  // ------------------------------------------------------------

  property no_write_when_tx_fifo_full;
    @(posedge clk) disable iff (!rst_n)
      tx_fifo_full |-> !tx_fifo_wr_en;
  endproperty

  assert property (no_write_when_tx_fifo_full)
    else report_assertion_failure("TX FIFO write attempted while full");

  property no_read_when_rx_fifo_empty;
    @(posedge clk) disable iff (!rst_n)
      rx_fifo_empty |-> !rx_fifo_rd_en;
  endproperty

  assert property (no_read_when_rx_fifo_empty)
    else report_assertion_failure("RX FIFO read attempted while empty");

  // ------------------------------------------------------------
  // RX valid is equivalent to RX FIFO not empty at top level
  // ------------------------------------------------------------

  property rx_valid_matches_fifo_not_empty;
    @(posedge clk) disable iff (!rst_n)
      rx_valid == !rx_fifo_empty;
  endproperty

  assert property (rx_valid_matches_fifo_not_empty)
    else report_assertion_failure("rx_valid does not match RX FIFO non-empty status");

  property rx_core_valid_after_valid_stop_bit;
    @(posedge clk) disable iff (!rst_n)
      rx_core_valid |-> $past(rx_stop_sample_event && rx_stop_bit_sample);
  endproperty

  assert property (rx_core_valid_after_valid_stop_bit)
    else report_assertion_failure("RX core valid asserted without a valid completed frame");

  property valid_stop_bit_generates_rx_core_valid;
    @(posedge clk) disable iff (!rst_n)
      (rx_stop_sample_event && rx_stop_bit_sample) |=> rx_core_valid;
  endproperty

  assert property (valid_stop_bit_generates_rx_core_valid)
    else report_assertion_failure("Valid UART stop bit did not produce rx_valid");

  property invalid_stop_bit_generates_frame_error;
    @(posedge clk) disable iff (!rst_n)
      (rx_stop_sample_event && !rx_stop_bit_sample) |=> frame_error;
  endproperty

  assert property (invalid_stop_bit_generates_frame_error)
    else report_assertion_failure("Invalid UART stop bit did not assert frame_error");

  property frame_error_caused_by_invalid_stop_bit;
    @(posedge clk) disable iff (!rst_n)
      $rose(frame_error) |-> $past(rx_stop_sample_event && !rx_stop_bit_sample);
  endproperty

  assert property (frame_error_caused_by_invalid_stop_bit)
    else report_assertion_failure("frame_error asserted without an invalid stop bit");

  // ------------------------------------------------------------
  // Loopback mux correctness
  // ------------------------------------------------------------

  property loopback_mux_correct;
    @(posedge clk) disable iff (!rst_n)
      loopback_enable |-> (uart_rx_muxed == uart_tx_o);
  endproperty

  assert property (loopback_mux_correct)
    else report_assertion_failure("Loopback mux is not routing TX to RX");

  property external_rx_mux_correct;
    @(posedge clk) disable iff (!rst_n)
      (!loopback_enable) |-> (uart_rx_muxed == uart_rx_i);
  endproperty

  assert property (external_rx_mux_correct)
    else report_assertion_failure("RX mux is not routing external RX input when loopback disabled");

  // ------------------------------------------------------------
  // Bus response sanity
  // ------------------------------------------------------------

  property bus_ready_has_recent_valid_transaction;
    @(posedge clk) disable iff (!rst_n)
      bus_ready |-> (bus_valid || bus_valid_d1 || bus_valid_d2 || bus_valid_d3);
  endproperty

  assert property (bus_ready_has_recent_valid_transaction)
    else report_assertion_failure("bus_ready asserted without a current or recent bus_valid transaction");

endmodule
