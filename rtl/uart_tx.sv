`timescale 1ns/1ps

import uart_pkg::*;

module uart_tx #(
  parameter int DATA_WIDTH = 8
)(
  input  logic                  clk,
  input  logic                  rst_n,

  input  logic                  tx_enable,
  input  logic                  baud_tick,

  input  logic                  tx_start,
  input  logic [DATA_WIDTH-1:0] tx_data,

  output logic                  tx_o,
  output logic                  tx_busy,
  output logic                  tx_done
);

  uart_tx_state_t state, next_state;

  logic [DATA_WIDTH-1:0] shifter;
  logic [$clog2(DATA_WIDTH)-1:0] bit_cnt;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state   <= TX_IDLE;
      shifter <= '0;
      bit_cnt <= '0;
      tx_o    <= 1'b1;
      tx_done <= 1'b0;
    end else begin
      tx_done <= 1'b0;

      case (state)
        TX_IDLE: begin
          tx_o    <= 1'b1;
          bit_cnt <= '0;

          if (tx_enable && tx_start) begin
            shifter <= tx_data;
            state   <= TX_START;
          end
        end

        TX_START: begin
          tx_o <= 1'b0;

          if (baud_tick) begin
            state <= TX_DATA;
          end
        end

        TX_DATA: begin
          tx_o <= shifter[0];

          if (baud_tick) begin
            shifter <= {1'b0, shifter[DATA_WIDTH-1:1]};

            if (bit_cnt == DATA_WIDTH-1) begin
              bit_cnt <= '0;
              state   <= TX_STOP;
            end else begin
              bit_cnt <= bit_cnt + 1'b1;
            end
          end
        end

        TX_STOP: begin
          tx_o <= 1'b1;

          if (baud_tick) begin
            tx_done <= 1'b1;
            state   <= TX_IDLE;
          end
        end

        default: begin
          state <= TX_IDLE;
          tx_o  <= 1'b1;
        end
      endcase
    end
  end

  assign tx_busy = (state != TX_IDLE);

endmodule
