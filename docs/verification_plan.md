# UART FPGA Subsystem Verification Plan

## Verification Methodology

This project uses a self-checking SystemVerilog testbench, not UVM.

The goal is to show strong digital verification fundamentals without overcomplicating the project.

---

## Testbench Components

Planned components:

- clock/reset generation
- register read/write tasks
- UART transmit stimulus
- UART receive monitor
- scoreboard
- directed tests
- randomized byte-stream tests
- assertions
- functional coverage

---

## Directed Tests

| Test | Purpose |
|------|---------|
| TX single byte | Check UART TX frame correctness |
| TX multiple bytes | Check repeated transmission |
| RX single byte | Check receive path |
| RX back-to-back bytes | Check continuous reception |
| FIFO full | Check full flag and blocked writes |
| FIFO empty | Check empty flag and blocked reads |
| RX overrun | Check overrun error behavior |
| Frame error | Check bad stop-bit detection |
| Loopback | Check internal TX-to-RX routing |
| Baud divisor | Check different baud settings |

---

## Assertions

Planned assertions:

- TX line must be high when idle
- Start bit must be low
- Stop bit must be high
- TX data must remain stable during a bit period
- RX valid must only assert after a complete valid frame
- Frame error must assert on invalid stop bit
- FIFO full must block writes
- FIFO empty must block reads
- No unknown X values on key outputs after reset
- Register writes must only affect valid registers
- Loopback mode must connect TX path to RX path

---

## Functional Coverage

Planned coverage:

- TX byte values
- RX byte values
- FIFO full event
- FIFO empty event
- frame error event
- overrun error event
- loopback enabled/disabled
- baud divisor categories
- back-to-back transfers
- transfer type vs error type cross coverage

---

## Final Pass Criteria

The project is considered verification-complete when:

```text
Directed tests      : PASS
Random tests        : PASS
Scoreboard errors   : 0
Assertions          : PASS
Functional coverage : target achieved

# Final Verification Result

The integrated UART subsystem completed randomized self-checking verification.

Final summary:

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