package uart_pkg;

  // ------------------------------------------------------------
  // Global UART subsystem parameters
  // ------------------------------------------------------------
  parameter int CLK_FREQ_HZ     = 100_000_000;
  parameter int DATA_WIDTH      = 8;
  parameter int REG_WIDTH       = 32;
  parameter int FIFO_DEPTH      = 16;
  parameter int FIFO_ADDR_WIDTH = 4;

  // UART format: 8N1
  parameter int UART_DATA_BITS  = 8;
  parameter int UART_STOP_BITS  = 1;
  parameter int OVERSAMPLE      = 16;

  // Common baud divisors for 100 MHz clock
  // baud_tick divisor approx = CLK_FREQ_HZ / (BAUD_RATE * OVERSAMPLE)
  parameter int BAUD_DIV_9600   = 651;
  parameter int BAUD_DIV_115200 = 54;

  // ------------------------------------------------------------
  // Register map
  // ------------------------------------------------------------
  parameter logic [3:0] ADDR_DATA    = 4'h0;  // 0x00
  parameter logic [3:0] ADDR_STATUS  = 4'h4;  // 0x04
  parameter logic [3:0] ADDR_CONTROL = 4'h8;  // 0x08
  parameter logic [3:0] ADDR_BAUDDIV = 4'hC;  // 0x0C

  // ------------------------------------------------------------
  // STATUS register bit positions
  // ------------------------------------------------------------
  parameter int STATUS_TX_BUSY       = 0;
  parameter int STATUS_TX_FIFO_FULL  = 1;
  parameter int STATUS_TX_FIFO_EMPTY = 2;
  parameter int STATUS_RX_FIFO_FULL  = 3;
  parameter int STATUS_RX_FIFO_EMPTY = 4;
  parameter int STATUS_RX_VALID      = 5;
  parameter int STATUS_FRAME_ERROR   = 6;
  parameter int STATUS_OVERRUN_ERROR = 7;

  // ------------------------------------------------------------
  // CONTROL register bit positions
  // ------------------------------------------------------------
  parameter int CTRL_TX_ENABLE       = 0;
  parameter int CTRL_RX_ENABLE       = 1;
  parameter int CTRL_LOOPBACK_ENABLE = 2;
  parameter int CTRL_CLEAR_ERRORS    = 3;

  // ------------------------------------------------------------
  // UART TX FSM states
  // ------------------------------------------------------------
  typedef enum logic [1:0] {
    TX_IDLE,
    TX_START,
    TX_DATA,
    TX_STOP
  } uart_tx_state_t;

  // ------------------------------------------------------------
  // UART RX FSM states
  // ------------------------------------------------------------
  typedef enum logic [2:0] {
    RX_IDLE,
    RX_START,
    RX_DATA,
    RX_STOP,
    RX_DONE
  } uart_rx_state_t;

endpackage