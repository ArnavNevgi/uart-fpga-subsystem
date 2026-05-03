`timescale 1ns/1ps

import uart_pkg::*;

module uart_top #(
  parameter int DATA_WIDTH      = 8,
  parameter int REG_WIDTH       = 32,
  parameter int FIFO_DEPTH      = 16,
  parameter int FIFO_ADDR_WIDTH = $clog2(FIFO_DEPTH)
)(
  input  logic                 clk,
  input  logic                 rst_n,

  // Simple memory-mapped register interface
  input  logic                 bus_valid,
  input  logic                 bus_we,
  input  logic [3:0]           bus_addr,
  input  logic [REG_WIDTH-1:0] bus_wdata,
  output logic [REG_WIDTH-1:0] bus_rdata,
  output logic                 bus_ready,

  input  logic                 uart_rx_i,
  output logic                 uart_tx_o
);

  logic tx_enable;
  logic rx_enable;
  logic loopback_enable;
  logic clear_errors;

  logic [15:0] baud_div;

  logic os_tick;
  logic baud_tick;

  logic tx_fifo_wr_en;
  logic [DATA_WIDTH-1:0] tx_fifo_wr_data;
  logic tx_fifo_full;
  logic tx_fifo_empty;

  logic rx_fifo_rd_en;
  logic [DATA_WIDTH-1:0] rx_fifo_rd_data;
  logic rx_fifo_full;
  logic rx_fifo_empty;

  logic tx_busy;
  logic tx_done;
  logic rx_valid;
  logic frame_error;
  logic overrun_error;

  logic uart_rx_muxed;

  assign uart_rx_muxed = loopback_enable ? uart_tx_o : uart_rx_i;

  // ------------------------------------------------------------
  // Oversampling tick generator
  // BAUD_DIV represents the 16x oversampling divisor.
  // ------------------------------------------------------------

  baud_gen #(
    .DIV_WIDTH(16)
  ) u_os_baud_gen (
    .clk       (clk),
    .rst_n     (rst_n),
    .enable    (tx_enable || rx_enable),
    .baud_div  (baud_div),
    .baud_tick (os_tick)
  );

  // ------------------------------------------------------------
  // Generate 1x UART TX baud tick from 16x oversampling tick
  // ------------------------------------------------------------

  logic [3:0] tx_tick_count;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx_tick_count <= '0;
      baud_tick     <= 1'b0;
    end else begin
      baud_tick <= 1'b0;

      if (tx_enable) begin
        if (os_tick) begin
          if (tx_tick_count == 4'd15) begin
            tx_tick_count <= '0;
            baud_tick     <= 1'b1;
          end else begin
            tx_tick_count <= tx_tick_count + 1'b1;
          end
        end
      end else begin
        tx_tick_count <= '0;
      end
    end
  end

  // ------------------------------------------------------------
  // Register block
  // ------------------------------------------------------------

  uart_regs #(
    .DATA_WIDTH(DATA_WIDTH),
    .REG_WIDTH(REG_WIDTH)
  ) u_uart_regs (
    .clk             (clk),
    .rst_n           (rst_n),

    .bus_valid       (bus_valid),
    .bus_we          (bus_we),
    .bus_addr        (bus_addr),
    .bus_wdata       (bus_wdata),
    .bus_rdata       (bus_rdata),
    .bus_ready       (bus_ready),

    .tx_fifo_wr_en   (tx_fifo_wr_en),
    .tx_fifo_wr_data (tx_fifo_wr_data),
    .tx_fifo_full    (tx_fifo_full),
    .tx_fifo_empty   (tx_fifo_empty),

    .rx_fifo_rd_en   (rx_fifo_rd_en),
    .rx_fifo_rd_data (rx_fifo_rd_data),
    .rx_fifo_full    (rx_fifo_full),
    .rx_fifo_empty   (rx_fifo_empty),

    .tx_busy         (tx_busy),
    .frame_error     (frame_error),
    .overrun_error   (overrun_error),

    .tx_enable       (tx_enable),
    .rx_enable       (rx_enable),
    .loopback_enable (loopback_enable),
    .clear_errors    (clear_errors),

    .baud_div        (baud_div)
  );

  // ------------------------------------------------------------
  // UART FIFO subsystem
  // ------------------------------------------------------------

  uart_fifo_subsystem #(
    .DATA_WIDTH(DATA_WIDTH),
    .FIFO_DEPTH(FIFO_DEPTH),
    .FIFO_ADDR_WIDTH(FIFO_ADDR_WIDTH)
  ) u_uart_fifo_subsystem (
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

    .uart_rx_i       (uart_rx_muxed),
    .uart_tx_o       (uart_tx_o),

    .tx_busy         (tx_busy),
    .tx_done         (tx_done),
    .rx_valid        (rx_valid),
    .frame_error     (frame_error),
    .overrun_error   (overrun_error)
  );

endmodule