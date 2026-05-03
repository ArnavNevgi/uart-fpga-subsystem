`timescale 1ns/1ps

import uart_pkg::*;

module uart_fifo_subsystem #(
  parameter int DATA_WIDTH      = 8,
  parameter int FIFO_DEPTH      = 16,
  parameter int FIFO_ADDR_WIDTH = $clog2(FIFO_DEPTH)
)(
  input  logic                  clk,
  input  logic                  rst_n,

  input  logic                  tx_enable,
  input  logic                  rx_enable,
  input  logic                  clear_errors,

  input  logic                  baud_tick,
  input  logic                  os_tick,

  input  logic                  tx_fifo_wr_en,
  input  logic [DATA_WIDTH-1:0] tx_fifo_wr_data,
  output logic                  tx_fifo_full,
  output logic                  tx_fifo_empty,

  input  logic                  rx_fifo_rd_en,
  output logic [DATA_WIDTH-1:0] rx_fifo_rd_data,
  output logic                  rx_fifo_full,
  output logic                  rx_fifo_empty,

  input  logic                  uart_rx_i,
  output logic                  uart_tx_o,

  output logic                  tx_busy,
  output logic                  tx_done,
  output logic                  rx_valid,
  output logic                  frame_error,
  output logic                  overrun_error
);

  // ------------------------------------------------------------
  // TX FIFO
  // ------------------------------------------------------------

  logic                  tx_fifo_rd_en;
  logic [DATA_WIDTH-1:0] tx_fifo_rd_data;
  logic [FIFO_ADDR_WIDTH:0] tx_fifo_count;

  sync_fifo #(
    .DATA_WIDTH(DATA_WIDTH),
    .DEPTH(FIFO_DEPTH),
    .ADDR_WIDTH(FIFO_ADDR_WIDTH)
  ) u_tx_fifo (
    .clk     (clk),
    .rst_n   (rst_n),
    .wr_en   (tx_fifo_wr_en),
    .wr_data (tx_fifo_wr_data),
    .full    (tx_fifo_full),
    .rd_en   (tx_fifo_rd_en),
    .rd_data (tx_fifo_rd_data),
    .empty   (tx_fifo_empty),
    .count   (tx_fifo_count)
  );

  // ------------------------------------------------------------
  // UART TX
  // ------------------------------------------------------------

  logic                  tx_start;
  logic [DATA_WIDTH-1:0] tx_data_to_send;

  uart_tx #(
    .DATA_WIDTH(DATA_WIDTH)
  ) u_uart_tx (
    .clk       (clk),
    .rst_n     (rst_n),
    .tx_enable (tx_enable),
    .baud_tick (baud_tick),
    .tx_start  (tx_start),
    .tx_data   (tx_data_to_send),
    .tx_o      (uart_tx_o),
    .tx_busy   (tx_busy),
    .tx_done   (tx_done)
  );

  typedef enum logic [1:0] {
    TXC_IDLE,
    TXC_READ_FIFO,
    TXC_START_TX,
    TXC_WAIT_DONE
  } tx_ctrl_state_t;

  tx_ctrl_state_t tx_ctrl_state;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx_ctrl_state  <= TXC_IDLE;
      tx_fifo_rd_en  <= 1'b0;
      tx_start       <= 1'b0;
      tx_data_to_send <= '0;
    end else begin
      tx_fifo_rd_en <= 1'b0;
      tx_start      <= 1'b0;

      case (tx_ctrl_state)

        TXC_IDLE: begin
          if (tx_enable && !tx_fifo_empty && !tx_busy) begin
            tx_fifo_rd_en <= 1'b1;
            tx_ctrl_state <= TXC_READ_FIFO;
          end
        end

        TXC_READ_FIFO: begin
          tx_data_to_send <= tx_fifo_rd_data;
          tx_ctrl_state   <= TXC_START_TX;
        end

        TXC_START_TX: begin
          tx_start      <= 1'b1;
          tx_ctrl_state <= TXC_WAIT_DONE;
        end

        TXC_WAIT_DONE: begin
          if (tx_done) begin
            tx_ctrl_state <= TXC_IDLE;
          end
        end

        default: begin
          tx_ctrl_state <= TXC_IDLE;
        end

      endcase
    end
  end

  // ------------------------------------------------------------
  // UART RX
  // ------------------------------------------------------------

  logic [DATA_WIDTH-1:0] rx_core_data;
  logic                  rx_core_valid;
  logic                  rx_core_busy;
  logic                  rx_fifo_wr_en;
  logic [FIFO_ADDR_WIDTH:0] rx_fifo_count;

  uart_rx #(
    .DATA_WIDTH(DATA_WIDTH),
    .OVERSAMPLE_RATE(16)
  ) u_uart_rx (
    .clk         (clk),
    .rst_n       (rst_n),
    .rx_enable   (rx_enable),
    .os_tick     (os_tick),
    .rx_i        (uart_rx_i),
    .rx_data     (rx_core_data),
    .rx_valid    (rx_core_valid),
    .rx_busy     (rx_core_busy),
    .frame_error (frame_error)
  );

  assign rx_fifo_wr_en = rx_core_valid && !rx_fifo_full;

  sync_fifo #(
    .DATA_WIDTH(DATA_WIDTH),
    .DEPTH(FIFO_DEPTH),
    .ADDR_WIDTH(FIFO_ADDR_WIDTH)
  ) u_rx_fifo (
    .clk     (clk),
    .rst_n   (rst_n),
    .wr_en   (rx_fifo_wr_en),
    .wr_data (rx_core_data),
    .full    (rx_fifo_full),
    .rd_en   (rx_fifo_rd_en),
    .rd_data (rx_fifo_rd_data),
    .empty   (rx_fifo_empty),
    .count   (rx_fifo_count)
  );

  assign rx_valid = !rx_fifo_empty;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      overrun_error <= 1'b0;
    end else begin
      if (clear_errors) begin
        overrun_error <= 1'b0;
      end else if (rx_core_valid && rx_fifo_full) begin
        overrun_error <= 1'b1;
      end
    end
  end

endmodule