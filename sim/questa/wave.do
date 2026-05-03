quietly WaveActivateNextPane {} 0

add wave -divider "TB"
add wave -radix binary sim:/tb_uart_random/clk
add wave -radix binary sim:/tb_uart_random/rst_n
add wave -radix binary sim:/tb_uart_random/uart_rx_i
add wave -radix binary sim:/tb_uart_random/uart_tx_o

add wave -divider "BUS"
add wave -radix binary sim:/tb_uart_random/bus_valid
add wave -radix binary sim:/tb_uart_random/bus_we
add wave -radix hexadecimal sim:/tb_uart_random/bus_addr
add wave -radix hexadecimal sim:/tb_uart_random/bus_wdata
add wave -radix hexadecimal sim:/tb_uart_random/bus_rdata
add wave -radix binary sim:/tb_uart_random/bus_ready

add wave -divider "CONTROL"
add wave -radix binary sim:/tb_uart_random/dut/tx_enable
add wave -radix binary sim:/tb_uart_random/dut/rx_enable
add wave -radix binary sim:/tb_uart_random/dut/loopback_enable
add wave -radix binary sim:/tb_uart_random/dut/clear_errors
add wave -radix unsigned sim:/tb_uart_random/dut/baud_div

add wave -divider "TX FIFO"
add wave -radix binary sim:/tb_uart_random/dut/tx_fifo_wr_en
add wave -radix hexadecimal sim:/tb_uart_random/dut/tx_fifo_wr_data
add wave -radix binary sim:/tb_uart_random/dut/tx_fifo_full
add wave -radix binary sim:/tb_uart_random/dut/tx_fifo_empty
add wave -radix unsigned sim:/tb_uart_random/dut/u_uart_fifo_subsystem/tx_fifo_count

add wave -divider "RX FIFO"
add wave -radix binary sim:/tb_uart_random/dut/rx_fifo_rd_en
add wave -radix hexadecimal sim:/tb_uart_random/dut/rx_fifo_rd_data
add wave -radix binary sim:/tb_uart_random/dut/rx_fifo_full
add wave -radix binary sim:/tb_uart_random/dut/rx_fifo_empty
add wave -radix unsigned sim:/tb_uart_random/dut/u_uart_fifo_subsystem/rx_fifo_count

add wave -divider "UART STATUS"
add wave -radix binary sim:/tb_uart_random/dut/tx_busy
add wave -radix binary sim:/tb_uart_random/dut/tx_done
add wave -radix binary sim:/tb_uart_random/dut/rx_valid
add wave -radix binary sim:/tb_uart_random/dut/frame_error
add wave -radix binary sim:/tb_uart_random/dut/overrun_error

add wave -divider "ASSERTION OBSERVABILITY"
add wave -radix symbolic sim:/tb_uart_random/dut/u_uart_fifo_subsystem/u_uart_tx/state
add wave -radix symbolic sim:/tb_uart_random/dut/u_uart_fifo_subsystem/u_uart_rx/state
add wave -radix binary sim:/tb_uart_random/dut/u_uart_fifo_subsystem/rx_core_valid
add wave -radix binary sim:/tb_uart_random/dut/u_uart_fifo_subsystem/rx_core_busy
add wave -radix unsigned sim:/tb_uart_random/dut/u_uart_fifo_subsystem/u_uart_rx/sample_cnt
add wave -radix binary sim:/tb_uart_random/back_to_back_event

add wave -divider "SCOREBOARD"
add wave -radix decimal sim:/tb_uart_random/scoreboard_errors
add wave -radix decimal sim:/tb_uart_random/total_checks
add wave -radix decimal sim:/tb_uart_random/total_passes
add wave -radix decimal sim:/tb_uart_random/assertion_failures
add wave -radix decimal sim:/tb_uart_random/functional_coverage

run 0
wave zoom full
