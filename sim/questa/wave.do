quietly WaveActivateNextPane {} 0

add wave -divider "TB"
add wave -radix binary sim:/tb_uart_fifo_subsystem/clk
add wave -radix binary sim:/tb_uart_fifo_subsystem/rst_n
add wave -radix binary sim:/tb_uart_fifo_subsystem/tx_enable
add wave -radix binary sim:/tb_uart_fifo_subsystem/rx_enable
add wave -radix binary sim:/tb_uart_fifo_subsystem/clear_errors

add wave -divider "BAUD TICKS"
add wave -radix binary sim:/tb_uart_fifo_subsystem/baud_tick
add wave -radix binary sim:/tb_uart_fifo_subsystem/os_tick

add wave -divider "TX FIFO"
add wave -radix binary sim:/tb_uart_fifo_subsystem/tx_fifo_wr_en
add wave -radix hexadecimal sim:/tb_uart_fifo_subsystem/tx_fifo_wr_data
add wave -radix binary sim:/tb_uart_fifo_subsystem/tx_fifo_full
add wave -radix binary sim:/tb_uart_fifo_subsystem/tx_fifo_empty
add wave -radix unsigned sim:/tb_uart_fifo_subsystem/dut/tx_fifo_count

add wave -divider "UART TX"
add wave -radix binary sim:/tb_uart_fifo_subsystem/uart_tx_o
add wave -radix binary sim:/tb_uart_fifo_subsystem/tx_busy
add wave -radix binary sim:/tb_uart_fifo_subsystem/tx_done
add wave -radix symbolic sim:/tb_uart_fifo_subsystem/dut/tx_ctrl_state

add wave -divider "RX FIFO"
add wave -radix binary sim:/tb_uart_fifo_subsystem/rx_fifo_rd_en
add wave -radix hexadecimal sim:/tb_uart_fifo_subsystem/rx_fifo_rd_data
add wave -radix binary sim:/tb_uart_fifo_subsystem/rx_fifo_full
add wave -radix binary sim:/tb_uart_fifo_subsystem/rx_fifo_empty
add wave -radix unsigned sim:/tb_uart_fifo_subsystem/dut/rx_fifo_count

add wave -divider "UART RX"
add wave -radix binary sim:/tb_uart_fifo_subsystem/uart_rx_i
add wave -radix binary sim:/tb_uart_fifo_subsystem/rx_valid
add wave -radix binary sim:/tb_uart_fifo_subsystem/frame_error
add wave -radix binary sim:/tb_uart_fifo_subsystem/overrun_error
add wave -radix hexadecimal sim:/tb_uart_fifo_subsystem/dut/rx_core_data
add wave -radix binary sim:/tb_uart_fifo_subsystem/dut/rx_core_valid

run 0
wave zoom full