# Week 10: UART Design & Verification

## Why This Matters

UART is the simplest serial protocol and the perfect first "real"
IP block to design and verify end-to-end. It's used everywhere —
debug ports, sensor interfaces, FPGA-to-PC links — and it's a
clean project to demonstrate your full RTL + verification skillset.

This is the RTL you'll wrap in a UVM testbench in W12 (your first
GitHub portfolio piece), so RTL quality matters.

## What to Study

### Reading — Verification

- **Spear & Tumbush ch.6 — Randomization**: constrained-random
  data for byte streams (used in HW2's random TB).
- **Spear & Tumbush ch.9 — Functional Coverage**: covergroups for
  byte values, framing-error injection, baud-rate combinations
  (used in HW3).
- **Spear & Tumbush ch.4 §4.9 — assertion intro** — for the small
  SVA bundle.
- **ChipVerify** — quick reference for SV interfaces / clocking
  blocks if you need it for the DUT TB harness.

### Reading — Design

- **Pong P. Chu *FPGA Prototyping* ch.7** ⭐ — UART is **ch.7** in
  Chu (not ch.8 — earlier versions of this doc had it wrong). Chu
  walks through baud-rate generator → RX FSM with oversampling →
  TX FSM → optional FIFO buffering. This is the canonical
  textbook treatment.
- **Pong Chu ch.4** — regular sequential circuits (counter, shift
  register, FIFO buffer); the building blocks Chu uses in ch.7.
- **Pong Chu ch.5** — FSM coding patterns; the coding style Chu
  uses for UART RX/TX.
- **Dally & Harting ch.16 — Datapath Sequential Logic**:
  registers, shift registers — the underlying primitives.
- **Sutherland *SV for Design* ch.10 — Interfaces**: bundle the
  UART signals (TX, RX, baud-tick, parity-error, ready) in a
  proper SV interface with `modport`s for `dut`/`tb`. (Note:
  ch.10 is interfaces — earlier drafts cited the wrong chapter.)
- **Sutherland *SV for Design* ch.8 — FSM modeling**: same FSM
  coding style as Chu, in modern SV.
- **Cliff Cummings** *"Coding And Scripting Techniques For FSM
  Designs"* — glitch-free FSM outputs (relevant to RX framing
  flag).

### Tool Setup

- xsim or iverilog. No new tools.

---

## Verification Homework

### Drills (per-Chu-section warmups)

- **Drill — Baud-rate generator timing TB (Chu §7.x baud-rate
  generator section)**
  *File:* `homework/verif/per_chapter/hw_uart_baud_tb/baud_tb.sv`
  Drive a known clock; measure cycles between successive
  `baud_tick`s. Assert that observed period equals the expected
  divisor for `BAUD_RATE = 9600`, `115200`, `921600`.

- **Drill — TX byte trace (Chu §7.x TX FSM section)**
  *File:* `homework/verif/per_chapter/hw_uart_tx_tb/tx_tb.sv`
  Drive `tx_data = 0x55`, pulse `tx_start`, sample `tx_serial` at
  each baud edge into an array, and check the array equals
  `[0, 1, 0, 1, 0, 1, 0, 1, 0, 1]` (start, LSB-first 0x55, stop).

- **Drill — RX false-start rejection (Chu §7.x RX FSM section)**
  *File:* `homework/verif/per_chapter/hw_uart_rx_tb/rx_tb.sv`
  Pull RX low for 1 sample period then back high. Assert that no
  byte is delivered, no `rx_valid` pulse.

- **Drill — Random byte stream (Spear ch.6)**
  *File:* `homework/verif/per_chapter/hw_uart_random/uart_random_tb.sv`
  Use a `class` with `rand byte data` and constraint to generate
  100 random bytes; drive each through TX, capture each at RX,
  scoreboard-check matches.

- **Drill — Coverage covergroup (Spear ch.9)**
  *File:* `homework/verif/per_chapter/hw_uart_coverage/uart_cov.sv`
  Covergroup with bins: every value of `data[7:0]` (256 bins),
  `back_to_back_send`, `framing_error_seen`. Sample on every
  TX/RX event.

- **Drill — UART SVA bundle (Spear §4.9)**
  *File:* `homework/verif/per_chapter/hw_uart_sva/uart_sva.sv`
  Three or four asserts: `tx_serial` is high in IDLE; `tx_busy`
  and `tx_done` never overlap; `rx_valid` pulses for exactly one
  cycle. Wired into the TB.

### Main HWs

#### HW1: TX→RX loopback regression
*Folder:* `homework/verif/connector/hw1_uart_loopback/`

Connect the TX serial output directly to the RX serial input.
Build a self-checking TB that:
- Runs a directed sweep: `0x00`, `0xFF`, `0x55`, `0xAA`, plus 6
  hand-picked patterns.
- Runs a constrained-random sweep (Spear ch.6): 1000 random
  bytes; scoreboard checks `rx_data == sent_data` and per-byte
  ordering.
- Runs a back-to-back stress sweep: pulse `tx_start` again the
  cycle after `tx_done`; verify zero data loss.

#### HW2: Coverage closure
*Folder:* `homework/verif/connector/hw2_uart_coverage/`

Wire the ch.9 covergroup from your drill into the loopback TB and
run until coverage = 100%. If a bin is missing, add a directed
sequence (e.g., a sequence that walks all 256 byte values, a
sequence that always sets `inject_framing_error = 1`). Final
report: covergroup hit table.

#### HW3: Framing-error injection
*Folder:* `homework/verif/connector/hw3_uart_framing/`

Add a `force` mechanism in the TB to corrupt the serial line at a
configurable position (during data, during stop). Verify that:
- For data corruption: receiver still produces a byte, possibly
  wrong; no framing error.
- For stop-bit corruption: receiver flags `rx_error = 1`.

### Stretch (optional)

- **Stretch — Parity bit (outside Chu ch.7 scope)**
  Chu's UART doesn't cover parity. Add an even/odd parity option
  to TX and RX, plus a covergroup bin for "parity error
  detected". Note this honestly as outside the chapter.

---

## Design Homework

### Drills (per-Chu-section warmups)

- **Drill — Baud-rate generator (Chu §7.x baud section)**
  *Folder:* `homework/design/per_chapter/hw_baud_rate_gen/`
  ```systemverilog
  module baud_rate_gen #(
      parameter CLK_FREQ   = 50_000_000,
      parameter BAUD_RATE  = 9600,
      parameter OVERSAMPLE = 16
  )(
      input  logic clk, rst_n,
      output logic baud_tick,    // 1 tick per bit period
      output logic sample_tick   // 16 ticks per bit period
  );
  ```
  `localparam DIVISOR = CLK_FREQ / (BAUD_RATE * OVERSAMPLE);`
  (Sutherland ch.5 / ch.9 — `localparam`).

- **Drill — UART TX FSM (Chu §7.x TX section, Chu ch.5 FSM)**
  *Folder:* `homework/design/per_chapter/hw_uart_tx/`
  3-block FSM (`always_ff` state register + `always_comb`
  next-state + `always_comb` outputs) per Sutherland ch.8.
  States: IDLE, START, DATA, STOP. Shift register from Dally ch.16.

- **Drill — UART RX FSM with oversampling (Chu §7.x RX section)**
  *Folder:* `homework/design/per_chapter/hw_uart_rx/`
  RX uses 16x oversampling; sample at the *middle* of each bit.
  States: IDLE, START, DATA, STOP. Detect false start (RX goes
  high before mid-start). Detect framing error (stop bit not
  high).

- **Drill — UART SV interface (Sutherland ch.10)**
  *Folder:* `homework/design/per_chapter/hw_uart_if/`
  ```systemverilog
  interface uart_if;
      logic tx_serial;
      logic rx_serial;
      logic tx_start;
      logic [7:0] tx_data;
      logic tx_busy, tx_done;
      logic [7:0] rx_data;
      logic rx_valid, rx_error;
      modport dut (...);
      modport tb  (...);
  endinterface
  ```

- **Drill — Small synchronous FIFO buffer (Chu ch.4 FIFO buffer
  section)**
  *Folder:* `homework/design/per_chapter/hw_uart_fifo_buffer/`
  Tiny depth-8 FIFO between user-side TX-data and the TX FSM. Chu
  ch.4 covers this directly (it's the canonical "regular
  sequential circuit" example).

### Main HWs

#### HW1: UART top integration
*Folder:* `homework/design/connector/hw1_uart_top/`

```systemverilog
module uart_top (
    input  logic       clk, rst_n,
    input  logic       tx_start,
    input  logic [7:0] tx_data,
    output logic       tx_busy, tx_done,
    output logic [7:0] rx_data,
    output logic       rx_valid, rx_error
);
    logic baud_tick, sample_tick;
    logic serial_line;          // TX → RX loopback
    // baud_rate_gen, uart_tx, uart_rx
endmodule
```

Use the SV interface from your drill to bundle the TB-facing
signals. Connect TX → RX internally (loopback). All four drill
modules wired in.

#### HW2: TX-with-FIFO variant
*Folder:* `homework/design/connector/hw2_uart_tx_with_fifo/`

Add the FIFO buffer drill in front of `uart_tx`. User pushes
bytes into the FIFO; TX FSM auto-pops and sends. This is how a
real UART IP buffers user writes vs serial throughput. Chu ch.7
discusses this style.

### Stretch (optional)

- **Stretch — Parameterizable data-bit count (5/6/7/8)**
  Most real UARTs let you pick 5..8 data bits. Chu's example is
  fixed-8; this generalizes it. A small `for`/`generate`
  refactor.

---

## Self-Check Questions

1. Why does UART use oversampling? Why 16× specifically?
2. How does the RX find the middle of each bit?
3. What happens if TX and RX clocks drift? At what drift rate
   does framing fail?
4. What's a framing error? What causes it?
5. How would you add parity? (Stretch — note Chu ch.7 doesn't
   cover it.)
6. What's the maximum reliable baud rate for a given clock
   frequency?

---

## Checklist

### Verification Track
- [ ] Read Spear ch.6 (randomization)
- [ ] Read Spear ch.9 (functional coverage)
- [ ] Read Spear ch.4 §4.9 (assertions intro)
- [ ] Drill: baud-rate generator timing TB
- [ ] Drill: TX byte trace
- [ ] Drill: RX false-start rejection
- [ ] Drill: random byte stream
- [ ] Drill: coverage covergroup
- [ ] Drill: UART SVA bundle
- [ ] HW1: loopback regression (directed + random + stress)
- [ ] HW2: coverage closure to 100%
- [ ] HW3: framing-error injection
- [ ] Can answer all self-check questions

### Design Track
- [ ] Read Pong Chu ch.4 (regular sequential circuits)
- [ ] Read Pong Chu ch.5 (FSM)
- [ ] Read Pong Chu ch.7 (UART) ⭐
- [ ] Read Dally ch.16 (datapath sequential)
- [ ] Read Sutherland ch.8 (FSM modeling)
- [ ] Read Sutherland ch.10 (interfaces)
- [ ] Read Cummings glitch-free FSM paper
- [ ] Drill: baud-rate generator
- [ ] Drill: UART TX FSM
- [ ] Drill: UART RX FSM (oversampling)
- [ ] Drill: UART SV interface
- [ ] Drill: small sync FIFO buffer
- [ ] HW1: UART top integration (loopback)
- [ ] HW2: TX-with-FIFO variant
- [ ] **RTL is clean and ready for the W12 UVM testbench.**
