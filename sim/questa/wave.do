quietly WaveActivateNextPane {} 0

add wave -divider "TB"
add wave -radix binary sim:/tb_uart_top/clk
add wave -radix binary sim:/tb_uart_top/rst_n
add wave -radix binary sim:/tb_uart_top/uart_rx_i
add wave -radix binary sim:/tb_uart_top/uart_tx_o

add wave -divider "BUS INTERFACE"
add wave -radix binary sim:/tb_uart_top/bus_valid
add wave -radix binary sim:/tb_uart_top/bus_we
add wave -radix hexadecimal sim:/tb_uart_top/bus_addr
add wave -radix hexadecimal sim:/tb_uart_top/bus_wdata
add wave -radix hexadecimal sim:/tb_uart_top/bus_rdata
add wave -radix binary sim:/tb_uart_top/bus_ready

add wave -divider "CONTROL"
add wave -radix binary sim:/tb_uart_top/dut/tx_enable
add wave -radix binary sim:/tb_uart_top/dut/rx_enable
add wave -radix binary sim:/tb_uart_top/dut/loopback_enable
add wave -radix binary sim:/tb_uart_top/dut/clear_errors
add wave -radix unsigned sim:/tb_uart_top/dut/baud_div

add wave -divider "TICKS"
add wave -radix binary sim:/tb_uart_top/dut/os_tick
add wave -radix binary sim:/tb_uart_top/dut/baud_tick
add wave -radix unsigned sim:/tb_uart_top/dut/tx_tick_count

add wave -divider "TX FIFO"
add wave -radix binary sim:/tb_uart_top/dut/tx_fifo_wr_en
add wave -radix hexadecimal sim:/tb_uart_top/dut/tx_fifo_wr_data
add wave -radix binary sim:/tb_uart_top/dut/tx_fifo_full
add wave -radix binary sim:/tb_uart_top/dut/tx_fifo_empty

add wave -divider "RX FIFO"
add wave -radix binary sim:/tb_uart_top/dut/rx_fifo_rd_en
add wave -radix hexadecimal sim:/tb_uart_top/dut/rx_fifo_rd_data
add wave -radix binary sim:/tb_uart_top/dut/rx_fifo_full
add wave -radix binary sim:/tb_uart_top/dut/rx_fifo_empty

add wave -divider "UART STATUS"
add wave -radix binary sim:/tb_uart_top/dut/tx_busy
add wave -radix binary sim:/tb_uart_top/dut/rx_valid
add wave -radix binary sim:/tb_uart_top/dut/frame_error
add wave -radix binary sim:/tb_uart_top/dut/overrun_error

run 0
wave zoom full