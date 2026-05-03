quietly WaveActivateNextPane {} 0

add wave -divider "TB"
add wave -radix binary sim:/tb_uart_loopback/clk
add wave -radix binary sim:/tb_uart_loopback/rst_n
add wave -radix binary sim:/tb_uart_loopback/uart_rx_i
add wave -radix binary sim:/tb_uart_loopback/uart_tx_o

add wave -divider "BUS INTERFACE"
add wave -radix binary sim:/tb_uart_loopback/bus_valid
add wave -radix binary sim:/tb_uart_loopback/bus_we
add wave -radix hexadecimal sim:/tb_uart_loopback/bus_addr
add wave -radix hexadecimal sim:/tb_uart_loopback/bus_wdata
add wave -radix hexadecimal sim:/tb_uart_loopback/bus_rdata
add wave -radix binary sim:/tb_uart_loopback/bus_ready

add wave -divider "CONTROL"
add wave -radix binary sim:/tb_uart_loopback/dut/tx_enable
add wave -radix binary sim:/tb_uart_loopback/dut/rx_enable
add wave -radix binary sim:/tb_uart_loopback/dut/loopback_enable
add wave -radix binary sim:/tb_uart_loopback/dut/clear_errors
add wave -radix unsigned sim:/tb_uart_loopback/dut/baud_div

add wave -divider "LOOPBACK PATH"
add wave -radix binary sim:/tb_uart_loopback/dut/uart_rx_muxed
add wave -radix binary sim:/tb_uart_loopback/dut/uart_tx_o

add wave -divider "TX PATH"
add wave -radix binary sim:/tb_uart_loopback/dut/tx_fifo_wr_en
add wave -radix hexadecimal sim:/tb_uart_loopback/dut/tx_fifo_wr_data
add wave -radix binary sim:/tb_uart_loopback/dut/tx_fifo_empty
add wave -radix binary sim:/tb_uart_loopback/dut/tx_fifo_full
add wave -radix binary sim:/tb_uart_loopback/dut/tx_busy
add wave -radix binary sim:/tb_uart_loopback/dut/u_uart_fifo_subsystem/tx_fifo_rd_en
add wave -radix hexadecimal sim:/tb_uart_loopback/dut/u_uart_fifo_subsystem/tx_fifo_rd_data
add wave -radix hexadecimal sim:/tb_uart_loopback/dut/u_uart_fifo_subsystem/tx_data_to_send
add wave -radix binary sim:/tb_uart_loopback/dut/u_uart_fifo_subsystem/tx_start
add wave -radix binary sim:/tb_uart_loopback/dut/u_uart_fifo_subsystem/tx_done
add wave -radix symbolic sim:/tb_uart_loopback/dut/u_uart_fifo_subsystem/tx_ctrl_state

add wave -divider "RX PATH"
add wave -radix binary sim:/tb_uart_loopback/dut/rx_fifo_rd_en
add wave -radix hexadecimal sim:/tb_uart_loopback/dut/rx_fifo_rd_data
add wave -radix binary sim:/tb_uart_loopback/dut/rx_fifo_empty
add wave -radix binary sim:/tb_uart_loopback/dut/rx_fifo_full
add wave -radix binary sim:/tb_uart_loopback/dut/rx_valid
add wave -radix hexadecimal sim:/tb_uart_loopback/dut/u_uart_fifo_subsystem/rx_core_data
add wave -radix binary sim:/tb_uart_loopback/dut/u_uart_fifo_subsystem/rx_core_valid
add wave -radix binary sim:/tb_uart_loopback/dut/u_uart_fifo_subsystem/rx_fifo_wr_en
add wave -radix unsigned sim:/tb_uart_loopback/dut/u_uart_fifo_subsystem/rx_fifo_count

add wave -divider "REGISTER DATA READ FSM"
add wave -radix symbolic sim:/tb_uart_loopback/dut/u_uart_regs/state
add wave -radix binary sim:/tb_uart_loopback/dut/u_uart_regs/rx_fifo_rd_en
add wave -radix hexadecimal sim:/tb_uart_loopback/dut/u_uart_regs/rx_fifo_rd_data
add wave -radix hexadecimal sim:/tb_uart_loopback/dut/u_uart_regs/bus_rdata

add wave -divider "ERROR FLAGS"
add wave -radix binary sim:/tb_uart_loopback/dut/frame_error
add wave -radix binary sim:/tb_uart_loopback/dut/overrun_error

run 0
wave zoom full
