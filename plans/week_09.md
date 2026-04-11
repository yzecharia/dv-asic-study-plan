# Week 9: UART Design & Verification

## Why This Matters
UART is the simplest serial protocol and the perfect first "real" IP block to design and verify. It's used everywhere — debug ports, sensor interfaces, FPGA-to-PC communication. More importantly, it's a clean project to demonstrate your full RTL + verification skillset.

## What to Study

### Reading
- **UART Protocol**: Google "UART protocol tutorial" — any good one covers:
  - Start bit (low), 8 data bits (LSB first), optional parity, stop bit (high)
  - Baud rate: bit period = 1/baud_rate (e.g., 9600 baud = 104.17us per bit)
  - Oversampling (typically 16x) for reliable RX sampling
  - No clock line — sender and receiver must agree on baud rate
- **Nandland UART tutorial**: https://nandland.com/uart-serial-port-module/
- **Pong P. Chu ch.7** (you have this book): UART section

### Reference Implementations (study, don't copy)
- Nandland UART Verilog code
- OpenCores UART implementations

---

## Homework

### HW1: Baud Rate Generator
Design a configurable baud rate generator:

```systemverilog
module baud_rate_gen #(
    parameter CLK_FREQ  = 50_000_000,  // 50 MHz system clock
    parameter BAUD_RATE = 9600,
    parameter OVERSAMPLE = 16          // 16x oversampling
)(
    input  logic clk, rst_n,
    output logic baud_tick,            // 1 tick per bit period (for TX)
    output logic sample_tick           // 16 ticks per bit period (for RX)
);
    // Compute divisor: CLK_FREQ / (BAUD_RATE * OVERSAMPLE)
    // Use a counter that generates a tick when it reaches the divisor
endmodule
```

Testbench:
- Verify `sample_tick` frequency = BAUD_RATE * 16
- Verify `baud_tick` frequency = BAUD_RATE
- Test with different BAUD_RATE parameters (9600, 115200, 921600)

### HW2: UART Transmitter
Design the TX module:

```systemverilog
module uart_tx (
    input  logic       clk, rst_n,
    input  logic       baud_tick,      // from baud rate generator
    input  logic       tx_start,       // pulse to begin transmission
    input  logic [7:0] tx_data,        // data to send
    output logic       tx_serial,      // serial output line
    output logic       tx_busy,        // high while transmitting
    output logic       tx_done         // pulse when done
);
    // State machine:
    // IDLE:  tx_serial = 1 (idle high), wait for tx_start
    // START: tx_serial = 0 (start bit), wait 1 bit period
    // DATA:  shift out 8 bits LSB first, 1 bit per baud_tick
    // STOP:  tx_serial = 1 (stop bit), wait 1 bit period
    // -> back to IDLE
endmodule
```

Testbench:
- Send byte 0x55 (alternating bits — easy to verify visually)
- Send byte 0x00 and 0xFF (edge cases)
- Send byte 0xA3 and verify serial output bit-by-bit
- Verify timing matches baud rate

### HW3: UART Receiver
Design the RX module with 16x oversampling:

```systemverilog
module uart_rx (
    input  logic       clk, rst_n,
    input  logic       sample_tick,    // 16x oversampling tick
    input  logic       rx_serial,      // serial input line
    output logic [7:0] rx_data,        // received data
    output logic       rx_valid,       // pulse when data is ready
    output logic       rx_error        // framing error (bad stop bit)
);
    // State machine:
    // IDLE:  wait for falling edge on rx_serial (start bit)
    // START: sample at middle of start bit (count 8 sample_ticks)
    //        if rx_serial != 0, false start — go back to IDLE
    // DATA:  sample 8 bits at middle of each bit (every 16 sample_ticks)
    // STOP:  check stop bit is high, else framing error
    // -> back to IDLE
endmodule
```

Testbench:
- Drive a known serial stream manually and verify rx_data matches
- Test framing error: drive stop bit as 0
- Test false start: drive start bit briefly then go high

### HW4: TX-to-RX Loopback Test
Connect TX output directly to RX input:

```systemverilog
module uart_top (
    input  logic       clk, rst_n,
    input  logic       tx_start,
    input  logic [7:0] tx_data,
    output logic [7:0] rx_data,
    output logic       rx_valid,
    output logic       tx_busy
);
    logic serial_line;
    // Instantiate baud_gen, uart_tx, uart_rx
    // Connect tx_serial -> rx_serial
endmodule
```

Testbench:
- **Directed test**: Send 10 known bytes, verify each is received correctly
- **Random test**: Send 1000 random bytes, compare TX data to RX data
- **Back-to-back**: Send bytes with minimal gap, verify no data loss
- **Error test**: Temporarily corrupt the serial line mid-transmission

### HW5: Add Assertions & Coverage
Add to your testbench:

**Assertions:**
- `tx_serial` is high during IDLE
- Start bit is exactly 1 bit period wide
- Data bits are stable for exactly 1 bit period each
- Stop bit is high
- `tx_busy` and `tx_done` never overlap
- `rx_valid` only pulses for 1 clock cycle

**Coverage:**
- All 256 possible data byte values transmitted and received
- Back-to-back transmissions (tx_start while tx_busy was just cleared)
- Framing error occurred and was detected

---

## Self-Check Questions
1. Why does UART use oversampling? Why 16x specifically?
2. How does the receiver find the middle of each bit?
3. What happens if TX and RX have slightly different baud rates (clock drift)?
4. What's a framing error? What causes it?
5. How would you add parity checking? (optional extension)
6. What's the maximum reliable baud rate for a given clock frequency?

---

## Checklist
- [ ] Studied UART protocol (read tutorial + Nandland)
- [ ] Completed HW1 (Baud rate generator)
- [ ] Completed HW2 (UART TX)
- [ ] Completed HW3 (UART RX)
- [ ] Completed HW4 (Loopback test — directed + random)
- [ ] Completed HW5 (Assertions + coverage)
- [ ] Can answer all self-check questions
- [ ] **RTL is clean and ready for UVM testbench in Week 11**
