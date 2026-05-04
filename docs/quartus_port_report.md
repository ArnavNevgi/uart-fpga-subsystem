# Quartus Prime Cross-Vendor Port Report

## Overview

This document summarizes the Intel Quartus Prime port of the existing SystemVerilog UART FPGA subsystem.

The goal of this phase was to validate cross-vendor RTL portability by compiling the same UART RTL in Intel Quartus Prime after the original Vivado Artix-7 implementation flow.

The design was not rewritten for Intel FPGA. The existing synthesizable RTL was reused.

---

## Design Under Test

Project:

```text
FPGA UART IP Core with FIFOs and Timing Closure

Top-level entity:

uart_top

Synthesizable RTL files used:

rtl/uart_pkg.sv
rtl/baud_gen.sv
rtl/uart_tx.sv
rtl/uart_rx.sv
rtl/sync_fifo.sv
rtl/uart_fifo_subsystem.sv
rtl/uart_regs.sv
rtl/uart_top.sv

Verification-only files were not included in Quartus synthesis:

tb/
sim/
tb/uart_assertions.sv
tb/uart_coverage.sv
tb/tb_uart_random.sv

Quartus Target

| Item             | Value                      |
| ---------------- | -------------------------- |
| Tool             | Quartus Prime Lite Edition |
| Version          | 25.1std.0 Build 1129       |
| FPGA Family      | Cyclone V                  |
| Device           | `5CGXFC7C7F23C8`           |
| Top-level Entity | `uart_top`                 |
| Timing Model     | Final                      |
| Clock Target     | 100 MHz                    |
| Clock Period     | 10.000 ns                  |

Flow Result

| Stage                    | Result     |
| ------------------------ | ---------- |
| Analysis & Synthesis     | PASS       |
| Fitter / Place-and-Route | PASS       |
| Timing Analyzer          | PASS       |
| Full Compilation         | Successful |
| Errors                   | 0          |
| Warnings                 | 10         |

Resource Utilization

| Resource          | Used | Available | Utilization |
| ----------------- | ---: | --------: | ----------: |
| ALMs              |  181 |    56,480 |         <1% |
| Registers         |  312 |         — |           — |
| Pins              |   75 |       268 |         28% |
| Block Memory Bits |  256 | 7,024,640 |         <1% |
| M10K Blocks       |    2 |       686 |         <1% |
| DSP Blocks        |    0 |       156 |          0% |
| PLLs              |    0 |        13 |          0% |

	0	13	0%

The design uses a very small fraction of the Cyclone V logic fabric. Pin usage is relatively high because the current top-level exposes a parallel memory-mapped register interface directly at the top level

Timing Result

Slow 1100mV 85C Model

| Timing Metric             |    Result |
| ------------------------- | --------: |
| Setup Slack               | +4.215 ns |
| Setup TNS                 |  0.000 ns |
| Hold Slack                | +0.390 ns |
| Hold TNS                  |  0.000 ns |
| Minimum Pulse Width Slack | +3.424 ns |
| Minimum Pulse Width TNS   |  0.000 ns |
The design meets the 100 MHz target in Quartus for the selected Intel Cyclone V device. Setup timing, hold timing, and minimum pulse width checks all have positive slack.

Cross-Vendor Portability Result

The same UART RTL was successfully compiled through Quartus Analysis & Synthesis, Fitter, and Timing Analyzer for an Intel Cyclone V target.

| Vendor Flow         | Target                     | Result |
| ------------------- | -------------------------- | ------ |
| Xilinx Vivado       | Artix-7 `xc7a35tcpg236-1`  | PASS   |
| Intel Quartus Prime | Cyclone V `5CGXFC7C7F23C8` | PASS   |


Vivado result:

100 MHz timing met with WNS +5.318 ns

Quartus result:

100 MHz timing met with setup slack +4.215 ns