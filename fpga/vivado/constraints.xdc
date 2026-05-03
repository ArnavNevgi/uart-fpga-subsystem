###############################################################################
# UART FPGA Subsystem Constraints
# Target FPGA: Xilinx Artix-7 xc7a35tcpg236-1
# Target Clock: 100 MHz
###############################################################################

# ---------------------------------------------------------------------------
# Clock constraint
# ---------------------------------------------------------------------------
# Top-level clock port: clk
# 100 MHz clock = 10 ns period

create_clock -name sys_clk -period 10.000 [get_ports clk]

# ---------------------------------------------------------------------------
# Input/output delay constraints
# ---------------------------------------------------------------------------
# This project is currently being implemented as an FPGA IP-style subsystem.
# Board-level pin constraints will be added later when the exact board/pinout
# is finalized.
#
# For board deployment, add LOC and IOSTANDARD constraints for:
# - clk
# - rst_n
# - uart_rx_i
# - uart_tx_o
# - bus_valid
# - bus_we
# - bus_addr
# - bus_wdata
# - bus_rdata
# - bus_ready
#
# Example style:
# set_property PACKAGE_PIN <PIN> [get_ports clk]
# set_property IOSTANDARD LVCMOS33 [get_ports clk]
###############################################################################