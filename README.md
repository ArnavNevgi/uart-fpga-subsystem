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
|     3A| Standalone synchronous FIFO design and verification           | Complete    |
|     3B| TX/RX FIFO integration and overrun verification               | Complete    |
|     4 | Register interface and top-level integration                  | Complete    |
|     5 | Internal loopback mode                                        | Complete    |
|     6 | Assertions and functional coverage                            | Complete    |
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

Phase 2 — UART RX with 16x Oversampling

Verified UART receiver behavior using oversampled UART stimulus.

Validated:

start-bit detection
16x oversampling timing
LSB-first byte reconstruction
valid-frame receive
invalid stop-bit frame error
back-to-back receive sequence

Result:

[PHASE 2 PASS] UART receiver with 16x oversampling verified.

Phase 3A — Standalone Synchronous FIFO

Implemented and verified a parameterized synchronous FIFO for use in the UART TX and RX buffering paths.

Validated:

write until full
read until empty
FIFO full and empty flags
data ordering across fill/drain sequence
blocked overflow write
blocked underflow read
simultaneous read/write behavior

Result:

[PHASE 3A PASS] Standalone synchronous FIFO verified.

### Phase 3B — TX/RX FIFO Buffering Integration

Integrated the parameterized synchronous FIFO into the UART subsystem as separate TX and RX buffers.

Validated:
- TX FIFO write until full
- TX FIFO full and empty flags
- TX FIFO drain through UART TX path
- RX FIFO fill from UART RX back-to-back received bytes
- RX FIFO read until empty
- RX FIFO data ordering
- RX overrun detection when a valid byte arrives while RX FIFO is full

Result:

```text
[PHASE 3B PASS] TX/RX FIFO buffering and RX overrun verified.

### Phase 4 — Register-Controlled UART Top-Level Integration

Integrated the UART FIFO subsystem with a simple memory-mapped register interface.

Implemented registers:
- `DATA` register for TX FIFO writes and RX FIFO reads
- `STATUS` register for FIFO, valid, busy, frame error, and overrun flags
- `CONTROL` register for TX enable, RX enable, loopback enable, and error clear
- `BAUD_DIV` register for configurable baud divisor

Validated:
- `DATA` register TX FIFO write behavior
- `DATA` register RX FIFO read behavior
- `STATUS` register flag correctness
- `CONTROL` register enable behavior
- `BAUD_DIV` write/read behavior
- top-level UART TX FIFO drain
- top-level UART RX receive and register read path
- frame error visibility through `STATUS`

Resolved integration issue:
- Fixed registered FIFO read latency in the memory-mapped `DATA` read path by adding a read-capture state in the register FSM.

Result:

```text
[PHASE 4 PASS] Register-controlled UART top-level verified.

### Phase 5 — Internal Loopback Mode

Verified internal UART loopback mode through the memory-mapped register interface.

Validated:
- `CONTROL.loopback_enable` register bit
- internal routing from UART TX output into UART RX input
- loopback operation without external RX stimulus
- TX `DATA` register write followed by RX `DATA` register readback
- multiple-byte loopback sequence
- negative case where RX FIFO remains empty when loopback is disabled

Resolved:
- fixed TX FIFO controller latency by adding wait/capture states before launching UART TX
- fixed registered RX FIFO `DATA` read timing so `bus_ready` asserts only after `bus_rdata` is stable
- updated testbench bus read timing to sample stable read data after `bus_ready`

Result:

```text
[PHASE 5 PASS] Internal loopback verified.