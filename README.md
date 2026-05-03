# FPGA-Based UART Communication Subsystem

## Overview

This project implements a reusable FPGA UART communication subsystem in SystemVerilog. It includes UART transmit/receive logic, 16x RX oversampling, TX/RX FIFOs, a memory-mapped register interface, internal loopback mode, frame/overrun error handling, assertions, functional coverage, randomized verification, and Vivado implementation evidence.

## Target

| Item | Value |
|---|---|
| FPGA | Xilinx Artix-7 `xc7a35tcpg236-1` |
| Clock | 100 MHz |
| UART format | 8N1 |
| Top module | `uart_top` |
| HDL | SystemVerilog |
| Simulation | QuestaSim / ModelSim |
| Implementation | Vivado |

## Key Features

UART transmitter
UART receiver with 16x oversampling
8N1 UART format: 8 data bits, no parity, 1 stop bit
Configurable baud divisor
TX FIFO buffering
RX FIFO buffering
FIFO full/empty status flags
RX overrun detection
Frame error detection
Simple memory-mapped register interface
Internal loopback mode
Self-checking SystemVerilog testbenches
Protocol assertions
Functional coverage
Randomized verification
Vivado synthesis and implementation flow
100 MHz timing analysis for Artix-7s

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
uart_tx_o ---> uart_rx_i internally

Detailed architecture notes: docs/architecture.md

## Register Map

| Address | Register | Description |
|---:|---|---|
| `0x00` | `DATA` | TX FIFO write / RX FIFO read |
| `0x04` | `STATUS` | FIFO, busy, valid, and error flags |
| `0x08` | `CONTROL` | TX/RX enable, loopback enable, clear errors |
| `0x0C` | `BAUD_DIV` | Baud divisor configuration |

TATUS flags include:

tx_busy
tx_fifo_full
tx_fifo_empty
rx_fifo_full
rx_fifo_empty
rx_valid
frame_error
overrun_error

CONTROL bits include:

tx_enable
rx_enable
loopback_enable
clear_errors

Detailed register documentation: docs/register_map.md

## Project Phases

| Phase | Description | Status |
|---:|---|---|
| 0 | Project setup, docs, register map, verification plan | Complete |
| 1 | Baud generator and UART TX | Complete |
| 2 | UART RX with 16x oversampling | Complete |
| 3A | Standalone synchronous FIFO | Complete |
| 3B | TX/RX FIFO subsystem integration | Complete |
| 4 | Register interface and top-level integration | Complete |
| 5 | Internal loopback mode | Complete |
| 6 | Assertions and functional coverage | Complete |
| 7 | Randomized verification | Complete |
| 8A | Vivado synthesis/implementation reports | Complete, board constraints pending |
| 9 | GitHub polish and resume documentation | Not started |

    ## Verification strategy

The design is verified using self-checking SystemVerilog testbenches.

Verification includes:

directed UART TX tests
directed UART RX tests
FIFO boundary tests
TX/RX FIFO integration tests
register-interface tests
loopback tests
protocol assertions
functional coverage
randomized verification
scoreboard-based checking
error injection

Assertions cover:

TX idle high
start bit low
stop bit high
RX valid only after a complete valid frame
FIFO full blocks writes
FIFO empty blocks reads
no unknown X/Z values on key outputs after reset
frame error on invalid stop bit
loopback mux correctness

Coverage includes:

TX byte values
RX byte values
FIFO full events
FIFO empty events
frame error event
overrun error event
loopback enable/disable
baud divisor bins
back-to-back transfers

Detailed verification plan: docs/verification_plan.md

| Phase | Description                                                        | Status   |
| ----: | ------------------------------------------------------------------ | -------- |
|     0 | Project setup, specification, register map, verification plan      | Complete |
|     1 | Baud generator and UART TX                                         | Complete |
|     2 | UART RX with 16x oversampling                                      | Complete |
|    3A | Standalone synchronous FIFO design and verification                | Complete |
|    3B | TX/RX FIFO integration and RX overrun verification                 | Complete |
|     4 | Register interface and top-level integration                       | Complete |
|     5 | Internal loopback mode                                             | Complete |
|     6 | Assertions and functional coverage                                 | Complete |
|     7 | Randomized verification                                            | Complete |
|     8 | Vivado synthesis/implementation reports; board constraints pending | Complete |
|     9 | Board Implementation                                               | Not complete |

## Vivado FPGA implementation

Xilinx Artix-7 xc7a35tcpg236-1
Clock: 100 MHz
Top module: uart_top

Results:
| Metric          | Result                               |
| --------------- | ------------------------------------ |
| LUTs            | 234 / 20,800, 1.13%                  |
| FFs / Registers | 489 / 41,600, 1.18%                  |
| BRAM            | 0 / 50, 0.00%                        |
| DSP             | 0 / 90, 0.00%                        |
| IO              | 75 / 106, 70.75%                     |
| WNS             | +5.318 ns                            |
| TNS             | 0.000 ns                             |
| WHS             | +0.154 ns                            |
| THS             | 0.000 ns                             |
| Routing         | 637 / 637 routable nets fully routed |

Timing result:

100 MHz timing met.

Generated reports:

fpga/reports/phase8_impl_utilization.rpt
fpga/reports/phase8_impl_timing_summary.rpt
fpga/reports/phase8_route_status.rpt
fpga/reports/phase8_drc.rpt

Documentation:

docs/fpga_implementation_report.md
docs/timing_summary.md
docs/utilization_summary.md

Post-implementation device view: docs/vivado/phase8_device_view.png


## Phase 7 Summary

```text
================ UART VERIFICATION SUMMARY ================
Directed tests      : PASS
Random tests        : PASS
Scoreboard errors   : 0
Assertions          : PASS
Functional coverage : 72.22%
============================================================
[PHASE 7 PASS] UART subsystem verification complete.
[PHASE 7 PASS] Self-checking verification complete.
```

Coverage report:

```text
sim/logs/phase7_coverage_report.txt
```


Timing is met at 100 MHz. DRC reports critical warnings for missing `PACKAGE_PIN`/`IOSTANDARD` assignments and a warning for missing `CFGBVS`/`CONFIG_VOLTAGE`. These are expected at this IP-style implementation stage and must be resolved before generating a board-ready bitstream.

## Known Limitations

This project is currently a software-only FPGA implementation and verification project.

The design has been synthesized and implemented in Vivado for the Xilinx Artix-7 xc7a35tcpg236-1, and timing/routing/utilization reports have been generated.

Board-specific pin constraints and hardware validation are not included because no physical FPGA board is currently available. As a result, board-clean bitstream generation and on-board UART testing are listed as future work.

The current uart_top exposes a parallel register interface at the top level. This is useful for verification and subsystem integration, but for board deployment a wrapper should be added to map the register interface to a practical board-facing interface such as AXI-Lite, switches/buttons/LEDs, or a small debug controller.

## Future Improvements

Add board-specific LOC and IOSTANDARD constraints.
Add CFGBVS and CONFIG_VOLTAGE properties for the selected board.
Add a board-level wrapper for practical hardware deployment.
Add an AXI-Lite wrapper around the register interface.
Generate a final board-clean bitstream after selecting an FPGA board.
Increase functional coverage beyond 72.22% using longer constrained-random regressions.
Add parity support.
Add configurable stop-bit support.
Add interrupt support for RX valid, TX empty, frame error, and overrun error.
Add UVM-based verification as an optional advanced extension.


