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

## Features

- UART transmitter and receiver
- 16x RX oversampling
- Configurable baud divisor
- TX and RX FIFO buffering
- Memory-mapped `DATA`, `STATUS`, `CONTROL`, and `BAUD_DIV` registers
- Internal loopback mode
- Frame error and RX overrun detection
- Self-checking directed and randomized testbenches
- Protocol assertions and functional coverage
- Vivado synthesis, implementation, timing, utilization, route, and DRC reports

## Register Map

| Address | Register | Description |
|---:|---|---|
| `0x00` | `DATA` | TX FIFO write / RX FIFO read |
| `0x04` | `STATUS` | FIFO, busy, valid, and error flags |
| `0x08` | `CONTROL` | TX/RX enable, loopback enable, clear errors |
| `0x0C` | `BAUD_DIV` | Baud divisor configuration |

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

## Verification Summary

Directed and randomized verification cover:

- TX byte streams
- RX byte streams
- loopback packets
- FIFO full/empty stress
- baud divisor changes
- frame error injection
- RX overrun injection
- back-to-back transfers
- scoreboard checking
- assertion-clean regression
- functional coverage reporting

Phase 7 final summary:

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

## Phase 8A Vivado Implementation

Vivado implementation reports were generated for the Artix-7 `xc7a35tcpg236-1` target with a 100 MHz clock constraint.

```text
[PHASE 8A PASS] Vivado synthesis/implementation reports generated; board-specific constraints pending.
```

Implementation result:

| Result | Status |
|---|---|
| Synthesis | PASS |
| Implementation routing | PASS |
| Timing | PASS |
| DRC | WARN |
| Bitstream-ready | Pending board pin constraints |

Key implementation numbers:

| Metric | Result |
|---|---:|
| LUTs | 234 / 20,800 (1.13%) |
| Flip-flops/registers | 489 / 41,600 (1.18%) |
| BRAM tiles | 0 / 50 (0.00%) |
| DSPs | 0 / 90 (0.00%) |
| IOBs | 75 / 106 (70.75%) |
| WNS | +5.318 ns |
| TNS | 0.000 ns |
| WHS | +0.154 ns |
| THS | 0.000 ns |

Timing is met at 100 MHz. DRC reports critical warnings for missing `PACKAGE_PIN`/`IOSTANDARD` assignments and a warning for missing `CFGBVS`/`CONFIG_VOLTAGE`. These are expected at this IP-style implementation stage and must be resolved before generating a board-ready bitstream.

## Vivado Reports

- `fpga/reports/phase8_impl_utilization.rpt`
- `fpga/reports/phase8_impl_timing_summary.rpt`
- `fpga/reports/phase8_route_status.rpt`
- `fpga/reports/phase8_drc.rpt`

## Documentation

- `docs/architecture.md`
- `docs/register_map.md`
- `docs/verification_plan.md`
- `docs/fpga_implementation_report.md`
- `docs/timing_summary.md`
- `docs/utilization_summary.md`

## Next Steps

- Add board-specific package pin and I/O-standard constraints.
- Add `CFGBVS` and `CONFIG_VOLTAGE` properties for the selected board.
- Re-run implementation and DRC.
- Generate a final bitstream only after board-level constraints are complete.
