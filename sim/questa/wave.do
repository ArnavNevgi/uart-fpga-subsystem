quietly WaveActivateNextPane {} 0

add wave -divider "TB"
add wave -radix binary sim:/tb_uart_rx/clk
add wave -radix binary sim:/tb_uart_rx/rst_n
add wave -radix binary sim:/tb_uart_rx/rx_enable
add wave -radix binary sim:/tb_uart_rx/rx_i
add wave -radix binary sim:/tb_uart_rx/os_tick

add wave -divider "UART RX OUTPUTS"
add wave -radix hexadecimal sim:/tb_uart_rx/rx_data
add wave -radix binary sim:/tb_uart_rx/rx_valid
add wave -radix binary sim:/tb_uart_rx/rx_busy
add wave -radix binary sim:/tb_uart_rx/frame_error

add wave -divider "UART RX INTERNAL"
add wave -radix symbolic sim:/tb_uart_rx/dut/state
add wave -radix unsigned sim:/tb_uart_rx/dut/sample_cnt
add wave -radix unsigned sim:/tb_uart_rx/dut/bit_cnt
add wave -radix hexadecimal sim:/tb_uart_rx/dut/data_reg

run 0
wave zoom full