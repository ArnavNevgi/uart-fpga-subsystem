`timescale 1ns/1ps

import uart_pkg::*;

module uart_rx #(
  parameter int DATA_WIDTH = 8,
  parameter int OVERSAMPLE_RATE = 16
)(
  input  logic                  clk,
  input  logic                  rst_n,

  input  logic                  rx_enable,
  input  logic                  os_tick,
  input  logic                  rx_i,

  output logic [DATA_WIDTH-1:0] rx_data,
  output logic                  rx_valid,
  output logic                  rx_busy,
  output logic                  frame_error
);

  uart_rx_state_t state;

  logic [DATA_WIDTH-1:0] data_reg;
  logic [$clog2(DATA_WIDTH)-1:0] bit_cnt;
  logic [$clog2(OVERSAMPLE_RATE)-1:0] sample_cnt;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state       <= RX_IDLE;
      data_reg    <= '0;
      rx_data     <= '0;
      bit_cnt     <= '0;
      sample_cnt  <= '0;
      rx_valid    <= 1'b0;
      frame_error <= 1'b0;
    end else begin
      rx_valid <= 1'b0;

      case (state)

        RX_IDLE: begin
          bit_cnt    <= '0;
          sample_cnt <= '0;

          if (rx_enable && (rx_i == 1'b0)) begin
            state <= RX_START;
          end
        end

        RX_START: begin
          if (os_tick) begin
            if (sample_cnt == (OVERSAMPLE_RATE/2 - 1)) begin
              if (rx_i == 1'b0) begin
                sample_cnt <= '0;
                state      <= RX_DATA;
              end else begin
                sample_cnt <= '0;
                state      <= RX_IDLE;
              end
            end else begin
              sample_cnt <= sample_cnt + 1'b1;
            end
          end
        end

        RX_DATA: begin
          if (os_tick) begin
            if (sample_cnt == (OVERSAMPLE_RATE - 1)) begin
              data_reg[bit_cnt] <= rx_i;
              sample_cnt        <= '0;

              if (bit_cnt == DATA_WIDTH-1) begin
                bit_cnt <= '0;
                state   <= RX_STOP;
              end else begin
                bit_cnt <= bit_cnt + 1'b1;
              end
            end else begin
              sample_cnt <= sample_cnt + 1'b1;
            end
          end
        end

        RX_STOP: begin
          if (os_tick) begin
            if (sample_cnt == (OVERSAMPLE_RATE - 1)) begin
              sample_cnt <= '0;

              if (rx_i == 1'b1) begin
                rx_data     <= data_reg;
                rx_valid    <= 1'b1;
                frame_error <= 1'b0;
              end else begin
                frame_error <= 1'b1;
              end

              state <= RX_IDLE;
            end else begin
              sample_cnt <= sample_cnt + 1'b1;
            end
          end
        end

        default: begin
          state <= RX_IDLE;
        end

      endcase
    end
  end

  assign rx_busy = (state != RX_IDLE);

endmodule