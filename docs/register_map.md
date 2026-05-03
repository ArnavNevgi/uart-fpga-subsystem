# UART FPGA Subsystem Register Map

## Address Map

| Address | Register | Access | Description |
|--------:|----------|--------|-------------|
| 0x00 | DATA | R/W | Write TX byte / read RX byte |
| 0x04 | STATUS | R | UART status flags |
| 0x08 | CONTROL | R/W | Enable, loopback, clear errors |
| 0x0C | BAUD_DIV | R/W | Configurable baud divisor |

---

## DATA Register — 0x00

### Write Behavior

Writing to DATA pushes an 8-bit byte into the TX FIFO if:

- TX is enabled
- TX FIFO is not full

Only bits `[7:0]` are used.

### Read Behavior

Reading DATA pops one byte from the RX FIFO if:

- RX FIFO is not empty

Only bits `[7:0]` contain valid RX data.

---

## STATUS Register — 0x04

| Bit | Name | Description |
|----:|------|-------------|
| 0 | tx_busy | UART transmitter is actively sending a frame |
| 1 | tx_fifo_full | TX FIFO cannot accept more data |
| 2 | tx_fifo_empty | TX FIFO has no data |
| 3 | rx_fifo_full | RX FIFO is full |
| 4 | rx_fifo_empty | RX FIFO has no data |
| 5 | rx_valid | At least one valid byte is available in RX FIFO |
| 6 | frame_error | RX stop bit was invalid |
| 7 | overrun_error | RX data arrived while RX FIFO was full |

Unused bits return 0.

---

## CONTROL Register — 0x08

| Bit | Name | Description |
|----:|------|-------------|
| 0 | tx_enable | Enables UART transmitter |
| 1 | rx_enable | Enables UART receiver |
| 2 | loopback_enable | Internally routes TX output to RX input |
| 3 | clear_errors | Clears frame and overrun error flags |

Unused bits are reserved.

---

## BAUD_DIV Register — 0x0C

Configures the baud tick divider.

For a 100 MHz clock and 16x RX oversampling:

```text
baud_div = clock_frequency / (baud_rate * 16)

Approximate values:

Baud Rate	Divisor
9600	    651
115200	    54