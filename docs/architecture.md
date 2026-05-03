# UART FPGA Subsystem Architecture

## Project Scope

This project implements an FPGA-targeted UART communication subsystem in SystemVerilog.

It is not a basic UART. The subsystem includes:

- UART transmitter
- UART receiver with 16x oversampling
- Baud-rate generator
- TX FIFO
- RX FIFO
- Simple memory-mapped register interface
- Internal loopback mode
- Frame error detection
- RX overrun detection
- Status and control registers
- Self-checking SystemVerilog verification
- Vivado synthesis, implementation, timing, and utilization reporting

---

## Target

| Item | Value |
|------|-------|
| FPGA | Xilinx Artix-7 xc7a35tcpg236-1 |
| Tool | Vivado |
| Simulation | QuestaSim / ModelSim |
| Clock | 100 MHz |
| UART Format | 8N1 |
| Data Bits | 8 |
| Stop Bits | 1 |
| Parity | None |
| Oversampling | 16x |
| FIFO Depth | 16 entries |

---

## Block Diagram

```text
Host register interface
        |
        v
+--------------------------+
|      UART REGISTERS      |
| DATA / STATUS / CONTROL  |
| BAUD_DIV                 |
+------------+-------------+
             |
             v
+------------+-------------+
|       Control Logic      |
+-----+--------------+-----+
      |              |
      v              v
+----------+    +----------+
| TX FIFO  |    | RX FIFO  |
+----+-----+    +-----+----+
     |                ^
     v                |
+----------+    +----------+
| UART TX  |    | UART RX  |
| FSM      |    | FSM      |
+----+-----+    +-----+----+
     |                ^
     v                |
 uart_tx_o        uart_rx_i

Loopback mode:
uart_tx_internal ---> uart_rx_internal

UART Frame Format
Idle line: High

Start bit: 0
Data bits: 8 bits, LSB first
Stop bit : 1

Frame:
START D0 D1 D2 D3 D4 D5 D6 D7 STOP
  0    x  x  x  x  x  x  x  x   1