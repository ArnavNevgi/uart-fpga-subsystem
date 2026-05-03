quietly WaveActivateNextPane {} 0

add wave -divider "TB"
add wave -radix binary sim:/tb_uart_tx/clk
add wave -radix binary sim:/tb_uart_tx/rst_n
add wave -radix binary sim:/tb_uart_tx/tx_enable
add wave -radix binary sim:/tb_uart_tx/tx_start
add wave -radix hexadecimal sim:/tb_uart_tx/tx_data

add wave -divider "UART TX OUTPUTS"
add wave -radix binary sim:/tb_uart_tx/tx_o
add wave -radix binary sim:/tb_uart_tx/tx_busy
add wave -radix binary sim:/tb_uart_tx/tx_done
add wave -radix binary sim:/tb_uart_tx/baud_tick

add wave -divider "UART TX INTERNAL"
add wave -radix symbolic sim:/tb_uart_tx/dut/state
add wave -radix hexadecimal sim:/tb_uart_tx/dut/shifter
add wave -radix unsigned sim:/tb_uart_tx/dut/bit_cnt

run 0
wave zoom full