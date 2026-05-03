# Phase 8 Timing Summary

## Target

| Item | Value |
|------|-------|
| FPGA | Xilinx Artix-7 `xc7a35tcpg236-1` |
| Top Module | `uart_top` |
| Clock | 100 MHz |
| Clock Period | 10.000 ns |
| Tool | Vivado |

## Timing Result

| Metric | Value |
|--------|-------|
| WNS | +5.318 ns |
| TNS | 0.000 ns |
| WHS | +0.154 ns |
| THS | 0.000 ns |

## Interpretation

The routed `uart_top` implementation meets timing for the 100 MHz target. Vivado reports positive setup slack with WNS = +5.318 ns and no setup timing violations.

Hold timing is also clean, with WHS = +0.154 ns and THS = 0.000 ns. The worst setup path is inside the oversampling baud generator/control logic, from `u_os_baud_gen/count_reg[1]/C` to `u_os_baud_gen/baud_tick_reg/D`, and still has substantial positive margin.

Phase 8 timing status: PASS.

## Report Reference

`fpga/reports/phase8_impl_timing_summary.rpt`
