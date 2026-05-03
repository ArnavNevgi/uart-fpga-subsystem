`timescale 1ns/1ps

module uart_coverage (
  input logic clk,
  input logic rst_n,

  input logic [7:0] tx_data_sample,
  input logic       tx_data_event,

  input logic [7:0] rx_data_sample,
  input logic       rx_data_event,

  input logic tx_fifo_full,
  input logic tx_fifo_empty,
  input logic rx_fifo_full,
  input logic rx_fifo_empty,

  input logic frame_error,
  input logic overrun_error,
  input logic loopback_enable,
  input logic back_to_back_event,

  input logic [15:0] baud_div
);

  covergroup uart_cg @(posedge clk);
    option.per_instance = 1;

    cp_tx_byte: coverpoint tx_data_sample iff (rst_n && tx_data_event) {
      bins zero      = {8'h00};
      bins all_ones  = {8'hFF};
      bins pattern_a = {8'hA5};
      bins pattern_b = {8'h3C};
      bins low_vals  = {[8'h01:8'h3F]};
      bins mid_vals  = {[8'h40:8'hBF]};
      bins high_vals = {[8'hC0:8'hFE]};
    }

    cp_rx_byte: coverpoint rx_data_sample iff (rst_n && rx_data_event) {
      bins zero      = {8'h00};
      bins all_ones  = {8'hFF};
      bins pattern_a = {8'hA5};
      bins pattern_b = {8'h3C};
      bins low_vals  = {[8'h01:8'h3F]};
      bins mid_vals  = {[8'h40:8'hBF]};
      bins high_vals = {[8'hC0:8'hFE]};
    }

    cp_tx_fifo_full: coverpoint tx_fifo_full iff (rst_n) {
      bins seen_full = {1'b1};
    }

    cp_tx_fifo_empty: coverpoint tx_fifo_empty iff (rst_n) {
      bins seen_empty = {1'b1};
    }

    cp_rx_fifo_full: coverpoint rx_fifo_full iff (rst_n) {
      bins seen_full = {1'b1};
    }

    cp_rx_fifo_empty: coverpoint rx_fifo_empty iff (rst_n) {
      bins seen_empty = {1'b1};
    }

    cp_frame_error: coverpoint frame_error iff (rst_n) {
      bins seen_frame_error = {1'b1};
    }

    cp_overrun_error: coverpoint overrun_error iff (rst_n) {
      bins seen_overrun_error = {1'b1};
    }

    cp_loopback: coverpoint loopback_enable iff (rst_n) {
      bins disabled = {1'b0};
      bins enabled  = {1'b1};
    }

    cp_back_to_back: coverpoint back_to_back_event iff (rst_n) {
      bins seen_back_to_back = {1'b1};
    }

    cp_baud_div: coverpoint baud_div iff (rst_n) {
      bins fast_sim = {[16'd1:16'd10]};
      bins mid      = {[16'd11:16'd100]};
      bins slow     = {[16'd101:16'd1000]};
    }

    cross_loopback_rx: cross cp_loopback, cp_rx_byte;

  endgroup

  uart_cg cg_inst = new();

endmodule
