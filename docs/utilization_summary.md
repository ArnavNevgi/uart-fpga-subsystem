# Utilization Summary

## Target

| Item | Value |
|---|---|
| FPGA | Xilinx Artix-7 `xc7a35tcpg236-1` |
| Top module | `uart_top` |
| Design state | Routed |
| Clock target | 100 MHz |

## Resource Utilization

| Resource | Used | Available | Utilization |
|---|---:|---:|---:|
| Slice LUTs | 234 | 20,800 | 1.13% |
| LUT as Logic | 234 | 20,800 | 1.13% |
| LUT as Memory | 0 | 9,600 | 0.00% |
| Slice registers | 489 | 41,600 | 1.18% |
| Slices | 136 | 8,150 | 1.67% |
| Block RAM tiles | 0 | 50 | 0.00% |
| RAMB36/FIFO | 0 | 50 | 0.00% |
| RAMB18 | 0 | 100 | 0.00% |
| DSPs | 0 | 90 | 0.00% |
| Bonded IOBs | 75 | 106 | 70.75% |
| BUFGCTRL | 1 | 32 | 3.13% |

## Primitive Summary

| Primitive | Count |
|---|---:|
| FDRE | 256 |
| FDCE | 226 |
| FDPE | 7 |
| LUT6 | 150 |
| LUT5 | 17 |
| LUT4 | 60 |
| LUT3 | 22 |
| LUT2 | 17 |
| LUT1 | 7 |
| CARRY4 | 6 |
| MUXF7 | 32 |
| MUXF8 | 16 |
| IBUF | 41 |
| OBUF | 34 |
| BUFG | 1 |

## Interpretation

The UART subsystem is lightweight for the Artix-7 35T:

- LUT usage is about 1.1%.
- Register usage is about 1.2%.
- No DSP blocks are used.
- No block RAM tiles are used; the small FIFOs synthesize into flip-flop/LUT logic.
- The design occupies only 136 slices.

The only high percentage is I/O utilization at 70.75%. This is because the top-level module exposes a 32-bit memory-mapped bus directly as FPGA pins. In a production board design, this would typically be wrapped by an internal bus fabric, processor subsystem, UART register bridge, or smaller board-facing interface.

## Conclusion

The implementation is very small relative to the `xc7a35tcpg236-1` fabric and has ample room for integration with a larger FPGA system. The next physical-design concern is not logic capacity; it is finalizing realistic board-level I/O constraints and deciding how the register bus should be exposed or wrapped.
