# Phase 8 Utilization Summary

## Target

| Item | Value |
|------|-------|
| FPGA | Xilinx Artix-7 `xc7a35tcpg236-1` |
| Top Module | `uart_top` |
| Clock | 100 MHz |
| Design State | Routed |

## Resource Utilization

| Resource | Used | Available | Utilization |
|----------|-----:|----------:|------------:|
| LUTs | 234 | 20,800 | 1.13% |
| FFs / Registers | 489 | 41,600 | 1.18% |
| BRAM | 0 | 50 | 0.00% |
| DSP | 0 | 90 | 0.00% |
| IO | 75 | 106 | 70.75% |

## Interpretation

The UART subsystem uses a very small amount of Artix-7 logic fabric. LUT usage is only 1.13%, register usage is only 1.18%, and the implementation uses no BRAM or DSP resources. This leaves substantial FPGA capacity available for integration with a larger subsystem.

The high IO utilization is expected for the current top-level because `uart_top` exposes a parallel register interface directly at the FPGA boundary. That interface is useful for verification and subsystem integration, but it is wider than a typical board-facing UART-only pinout.

For deployment, a board wrapper or AXI-Lite wrapper would reduce and organize the board-facing IO. The wrapper could keep the register interface internal while exposing only the physical UART pins, clock/reset, and the selected system-bus interface required by the target board.

## Report Reference

`fpga/reports/phase8_impl_utilization.rpt`
