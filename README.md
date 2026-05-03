# FPGA-Based UART Communication Subsystem

## Overview

This project implements an FPGA-targeted UART communication subsystem in SystemVerilog.

The design is built as a small reusable FPGA IP block, not as a minimal UART example. It includes configurable baud generation, UART TX/RX logic, 16x RX oversampling, TX/RX FIFO buffering, a simple memory-mapped register interface, loopback mode, frame error detection, overrun detection, self-checking verification, and Vivado implementation evidence.

---

## Target

| Item | Value |
|------|-------|
| FPGA | Xilinx Artix-7 xc7a35tcpg236-1 |
| Tool | Vivado |
| Simulation | QuestaSim / ModelSim |
| Clock | 100 MHz |
| UART Format | 8N1 |
| Baud Rates | 9600, 115200 |
| Language | SystemVerilog |

---

## Features

- UART transmitter
- UART receiver
- 16x RX oversampling
- Configurable baud divisor
- TX FIFO
- RX FIFO
- DATA register
- STATUS register
- CONTROL register
- BAUD_DIV register
- Internal loopback mode
- Frame error detection
- RX overrun detection
- Self-checking SystemVerilog testbench
- Assertions
- Functional coverage
- Vivado synthesis and implementation flow

---

## Architecture

```text
Host register interface
        |
        v
 UART register block
        |
        +------> Baud generator
        |
        +------> TX FIFO ---> UART TX FSM ---> uart_tx_o
        |
        +------> RX FIFO <--- UART RX FSM <--- uart_rx_i
        |
        +------> Status/control/error logic
        |
        +------> Internal loopback mux

Register Map

Address	Register	Description
0x00	DATA	    TX write / RX read
0x04	STATUS	    Status and error flags
0x08	CONTROL	    Enable, loopback, clear errors
0x0C	BAUD_DIV	Baud divisor configuration


Project Phases

| Phase | Description                                                   | Status      |
| ----: | ------------------------------------------------------------- | ----------- |
|     0 | Project setup, specification, register map, verification plan | Complete    |
|     1 | Baud generator and UART TX                                    | Complete    |
|     2 | UART RX with 16x oversampling                                 | Complete    |
|     3 | TX/RX FIFO integration                                        | Not started |
|     4 | Register interface and top-level integration                  | Not started |
|     5 | Internal loopback mode                                        | Not started |
|     6 | Assertions and functional coverage                            | Not started |
|     7 | Randomized verification                                       | Not started |
|     8 | Vivado synthesis, implementation, timing, utilization         | Not started |
|     9 | GitHub polish and resume documentation                        | Not started |


## Phase 1 Simulation Result

The UART transmitter was verified using a self-checking SystemVerilog testbench.

Validated behavior:

- TX idle line remains high after reset
- Start bit is transmitted low
- 8 data bits are transmitted LSB-first
- Stop bit is transmitted high
- `tx_busy` asserts during frame transmission
- `tx_done` asserts after frame completion
- Multiple byte values were verified: `0xA5`, `0x3C`, `0x00`, `0xFF`

Result:

```text
[PHASE 1 PASS] UART transmitter verified.