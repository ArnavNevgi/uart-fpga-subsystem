`timescale 1ns/1ps

import uart_pkg::*;

module uart_regs #(
  parameter int DATA_WIDTH = 8,
  parameter int REG_WIDTH  = 32
)(
  input  logic                  clk,
  input  logic                  rst_n,

  // Simple memory-mapped bus interface
  input  logic                  bus_valid,
  input  logic                  bus_we,
  input  logic [3:0]            bus_addr,
  input  logic [REG_WIDTH-1:0]  bus_wdata,
  output logic [REG_WIDTH-1:0]  bus_rdata,
  output logic                  bus_ready,

  // TX FIFO interface
  output logic                  tx_fifo_wr_en,
  output logic [DATA_WIDTH-1:0] tx_fifo_wr_data,
  input  logic                  tx_fifo_full,
  input  logic                  tx_fifo_empty,

  // RX FIFO interface
  output logic                  rx_fifo_rd_en,
  input  logic [DATA_WIDTH-1:0] rx_fifo_rd_data,
  input  logic                  rx_fifo_full,
  input  logic                  rx_fifo_empty,

  // UART status inputs
  input  logic                  tx_busy,
  input  logic                  frame_error,
  input  logic                  overrun_error,

  // Control outputs
  output logic                  tx_enable,
  output logic                  rx_enable,
  output logic                  loopback_enable,
  output logic                  clear_errors,

  // Baud divisor output
  output logic [15:0]           baud_div
);

  logic [REG_WIDTH-1:0] control_reg;
  logic [REG_WIDTH-1:0] baud_div_reg;

  typedef enum logic [1:0] {
    REG_IDLE,
    REG_READ_DATA_WAIT,
    REG_READ_DATA_CAPTURE,
    REG_READ_DATA_RESP
  } reg_state_t;

  reg_state_t state;

  logic [REG_WIDTH-1:0] status_word;

  always_comb begin
    status_word = '0;

    status_word[STATUS_TX_BUSY]       = tx_busy;
    status_word[STATUS_TX_FIFO_FULL]  = tx_fifo_full;
    status_word[STATUS_TX_FIFO_EMPTY] = tx_fifo_empty;
    status_word[STATUS_RX_FIFO_FULL]  = rx_fifo_full;
    status_word[STATUS_RX_FIFO_EMPTY] = rx_fifo_empty;
    status_word[STATUS_RX_VALID]      = !rx_fifo_empty;
    status_word[STATUS_FRAME_ERROR]   = frame_error;
    status_word[STATUS_OVERRUN_ERROR] = overrun_error;
  end

  assign tx_enable       = control_reg[CTRL_TX_ENABLE];
  assign rx_enable       = control_reg[CTRL_RX_ENABLE];
  assign loopback_enable = control_reg[CTRL_LOOPBACK_ENABLE];
  assign baud_div        = baud_div_reg[15:0];

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state           <= REG_IDLE;
      bus_rdata       <= '0;
      bus_ready       <= 1'b0;
      tx_fifo_wr_en   <= 1'b0;
      tx_fifo_wr_data <= '0;
      rx_fifo_rd_en   <= 1'b0;
      control_reg     <= '0;
      baud_div_reg    <= BAUD_DIV_115200[REG_WIDTH-1:0];
      clear_errors    <= 1'b0;
    end else begin
      bus_ready     <= 1'b0;
      tx_fifo_wr_en <= 1'b0;
      rx_fifo_rd_en <= 1'b0;
      clear_errors  <= 1'b0;

      case (state)

        REG_IDLE: begin
          if (bus_valid) begin

            if (bus_we) begin
              case (bus_addr)

                ADDR_DATA: begin
                  if (!tx_fifo_full) begin
                    tx_fifo_wr_en   <= 1'b1;
                    tx_fifo_wr_data <= bus_wdata[DATA_WIDTH-1:0];
                  end

                  bus_ready <= 1'b1;
                end

                ADDR_CONTROL: begin
                  control_reg <= bus_wdata;

                  if (bus_wdata[CTRL_CLEAR_ERRORS]) begin
                    clear_errors <= 1'b1;
                  end

                  bus_ready <= 1'b1;
                end

                ADDR_BAUDDIV: begin
                  baud_div_reg <= bus_wdata;
                  bus_ready    <= 1'b1;
                end

                default: begin
                  bus_ready <= 1'b1;
                end

              endcase
            end else begin
              case (bus_addr)

                ADDR_DATA: begin
                  if (!rx_fifo_empty) begin
                    rx_fifo_rd_en <= 1'b1;
                    state         <= REG_READ_DATA_WAIT;
                  end else begin
                    bus_rdata <= '0;
                    bus_ready <= 1'b1;
                  end
                end

                ADDR_STATUS: begin
                  bus_rdata <= status_word;
                  bus_ready <= 1'b1;
                end

                ADDR_CONTROL: begin
                  bus_rdata <= control_reg;
                  bus_ready <= 1'b1;
                end

                ADDR_BAUDDIV: begin
                  bus_rdata <= baud_div_reg;
                  bus_ready <= 1'b1;
                end

                default: begin
                  bus_rdata <= '0;
                  bus_ready <= 1'b1;
                end

              endcase
            end
          end
        end

        REG_READ_DATA_WAIT: begin
          state <= REG_READ_DATA_CAPTURE;
        end

        REG_READ_DATA_CAPTURE: begin
          bus_rdata <= {{(REG_WIDTH-DATA_WIDTH){1'b0}}, rx_fifo_rd_data};
          state     <= REG_READ_DATA_RESP;
        end

        REG_READ_DATA_RESP: begin
          bus_ready <= 1'b1;
          state     <= REG_IDLE;
        end

        default: begin
          state <= REG_IDLE;
        end

      endcase
    end
  end

endmodule
