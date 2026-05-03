# Timing Summary

## Result

The routed `uart_top` implementation meets the 100 MHz timing constraint on the Artix-7 `xc7a35tcpg236-1`.

| Metric | Result |
|---|---:|
| Clock | `sys_clk` |
| Period | 10.000 ns |
| Frequency | 100.000 MHz |
| WNS | +5.318 ns |
| TNS | 0.000 ns |
| WHS | +0.154 ns |
| THS | 0.000 ns |
| Setup failing endpoints | 0 |
| Hold failing endpoints | 0 |
| Pulse-width failing endpoints | 0 |

Vivado reports: **All user specified timing constraints are met.**

## Worst Setup Path

| Field | Value |
|---|---|
| Slack | +5.318 ns |
| Source | `u_os_baud_gen/count_reg[1]/C` |
| Destination | `u_os_baud_gen/baud_tick_reg/D` |
| Path group | `sys_clk` |
| Path type | Setup, max delay, slow process corner |
| Data path delay | 4.367 ns |
| Logic delay | 1.748 ns |
| Route delay | 2.619 ns |
| Logic levels | 4 |

The worst setup path is in the baud generator/control logic. It has more than 5 ns of positive slack at 100 MHz, so there is substantial timing margin.

## Worst Hold Path

| Field | Value |
|---|---|
| Slack | +0.154 ns |
| Source | `u_uart_regs/baud_div_reg_reg[20]/C` |
| Destination | `u_uart_regs/bus_rdata_reg[20]/D` |
| Path group | `sys_clk` |
| Path type | Hold, min delay, fast process corner |
| Data path delay | 0.259 ns |
| Logic levels | 1 |

Hold timing is also met, with no failing endpoints.

## Methodology Notes

Vivado reports 74 timing methodology warnings for missing input/output delay constraints:

- 40 input ports have no input delay.
- 34 output ports have no output delay.

This is expected at the current IP-style implementation stage because only the internal 100 MHz clock constraint has been added. Board-level timing constraints should be added once the subsystem is connected to a real board interface or wrapper.

## Conclusion

Timing closure for the internal UART subsystem is clean at 100 MHz. The remaining timing work is board-integration work: add realistic input/output delays and physical pin constraints for the final board target.
