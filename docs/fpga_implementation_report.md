# FPGA Implementation Report

## Phase 8A Verdict

**[PHASE 8A PASS] Vivado synthesis/implementation reports generated; board-specific pin constraints pending.**

The UART subsystem was synthesized, placed, routed, and analyzed in Vivado for the Xilinx Artix-7 `xc7a35tcpg236-1` target. The routed implementation meets the 100 MHz timing constraint with positive setup and hold slack.

This is not yet a board-ready bitstream result. The current constraints include the 100 MHz clock but do not assign board-specific package pins, I/O standards, `CFGBVS`, or `CONFIG_VOLTAGE`.

## Target

| Item | Result |
|---|---:|
| Tool | Vivado 2025.2 |
| Device | `xc7a35tcpg236-1` |
| Top module | `uart_top` |
| Design state | Routed / Fully Routed |
| Clock constraint | 100 MHz, 10.000 ns period |

## Implementation Status

| Area | Status | Notes |
|---|---|---|
| Synthesis | PASS | Synthesis completed before implementation reports were generated. |
| Placement/routing | PASS | Route status reports 637/637 routable nets fully routed. |
| Timing | PASS | WNS = +5.318 ns, TNS = 0.000 ns. |
| DRC | WARN | Critical warnings are due to missing board pin and I/O-standard constraints. |
| Bitstream readiness | Pending board constraints | Vivado reports bitstream generation will fail until LOC and IOSTANDARD constraints are added. |

## Key Metrics

| Metric | Used | Available | Utilization |
|---|---:|---:|---:|
| Slice LUTs | 234 | 20,800 | 1.13% |
| Slice registers | 489 | 41,600 | 1.18% |
| Slices | 136 | 8,150 | 1.67% |
| Block RAM tiles | 0 | 50 | 0.00% |
| DSPs | 0 | 90 | 0.00% |
| Bonded IOBs | 75 | 106 | 70.75% |
| BUFGCTRL | 1 | 32 | 3.13% |

The logic footprint is very small for the Artix-7 35T device. The high I/O percentage comes from exposing the full 32-bit register bus at the FPGA top level. For a board-level design, this interface should normally be wrapped with a board-specific bus bridge or assigned to real pins only where appropriate.

## Timing Summary

| Metric | Result |
|---|---:|
| WNS | +5.318 ns |
| TNS | 0.000 ns |
| WHS | +0.154 ns |
| THS | 0.000 ns |
| Failing setup endpoints | 0 |
| Failing hold endpoints | 0 |

Vivado reports: **All user specified timing constraints are met.**

The worst setup path is inside the baud generator/control path from `u_os_baud_gen/count_reg[1]` to `u_os_baud_gen/baud_tick_reg`. The path has 4.367 ns data path delay and still has +5.318 ns slack against the 10 ns clock.

## Route Status

| Route Metric | Count |
|---|---:|
| Logical nets | 949 |
| Nets not needing routing | 312 |
| Routable nets | 637 |
| Fully routed nets | 637 |
| Nets with routing errors | 0 |

Routing completed cleanly.

## DRC Status

Vivado found three DRC checks:

| Rule | Severity | Meaning |
|---|---|---|
| NSTD-1 | Critical Warning | All 75 logical ports use default I/O standard. |
| UCIO-1 | Critical Warning | All 75 logical ports lack package pin LOC constraints. |
| CFGBVS-1 | Warning | Configuration bank voltage properties are not set. |

These are expected for the current IP-style implementation stage because the exact board pinout has not been added yet. They must be resolved before creating a board-ready bitstream.

## Next Steps

1. Choose the target Artix-7 board and board connector mapping.
2. Add `PACKAGE_PIN` and `IOSTANDARD` constraints for `clk`, `rst_n`, UART pins, and any exposed register interface pins.
3. Add `CFGBVS` and `CONFIG_VOLTAGE` properties appropriate for the board.
4. Re-run implementation and DRC.
5. Generate a final board-ready bitstream only after DRC is clean.
