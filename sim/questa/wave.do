quietly WaveActivateNextPane {} 0

add wave -divider "TB"
add wave -radix binary sim:/tb_sync_fifo/clk
add wave -radix binary sim:/tb_sync_fifo/rst_n

add wave -divider "FIFO WRITE SIDE"
add wave -radix binary sim:/tb_sync_fifo/wr_en
add wave -radix hexadecimal sim:/tb_sync_fifo/wr_data
add wave -radix binary sim:/tb_sync_fifo/full

add wave -divider "FIFO READ SIDE"
add wave -radix binary sim:/tb_sync_fifo/rd_en
add wave -radix hexadecimal sim:/tb_sync_fifo/rd_data
add wave -radix binary sim:/tb_sync_fifo/empty

add wave -divider "FIFO INTERNAL"
add wave -radix unsigned sim:/tb_sync_fifo/count
add wave -radix unsigned sim:/tb_sync_fifo/dut/wr_ptr
add wave -radix unsigned sim:/tb_sync_fifo/dut/rd_ptr
add wave -radix hexadecimal sim:/tb_sync_fifo/dut/mem

run 0
wave zoom full