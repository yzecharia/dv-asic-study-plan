# Week 3: Functional Coverage & SystemVerilog Assertions (SVA)

## Why This Matters
Constrained random generates stimuli, but how do you know you've tested enough? **Functional coverage** measures what you've exercised. **Assertions** catch protocol violations in real time. Together they answer: "Am I done?" and "Is it correct?"

Every DV interview asks about coverage and assertions. This is non-negotiable knowledge.

## What to Study

### Reading
- **Spear & Tumbush ch.9**: "Functional Coverage" — the core chapter this week
  - `covergroup`, `coverpoint`, `bins`
  - `cross` coverage
  - Coverage options: `at_least`, `auto_bin_max`
  - Coverage sampling: `@(posedge clk)`, `.sample()`
  - `illegal_bins`, `ignore_bins`, transition bins
- **SVA reference** (Spear doesn't really cover assertions — use one of these instead):
  - **Sutherland "SystemVerilog Assertions Handbook"** — the canonical SVA reference
  - OR **Cummings SNUG papers on SVA** (free PDFs — Google "Cliff Cummings SVA")
  - OR simply ChipVerify + Verification Academy assertion lessons (free, good enough for Week 3)
  - Topics to cover:
    - Immediate assertions: `assert`, `assert else`
    - Concurrent assertions: `assert property`
    - Sequences: `##N`, `[*N]`, `[*M:N]`, `throughout`
    - Properties: `|->` (overlapping), `|=>` (non-overlapping)
    - Sampled value functions: `$rose`, `$fell`, `$stable`, `$past`

### Videos (Verification Academy)
- "Functional Coverage" course — all lessons
- "SystemVerilog Assertions" course — all lessons

### Quick Reference (ChipVerify.com)
- https://www.chipverify.com/systemverilog/systemverilog-covergroup
- https://www.chipverify.com/systemverilog/systemverilog-coverpoint
- https://www.chipverify.com/systemverilog/systemverilog-cross-coverage
- https://www.chipverify.com/systemverilog/systemverilog-assertions
- https://www.chipverify.com/systemverilog/systemverilog-concurrent-assertions

---

## Design Track: FSM Design & Handshake Protocols

### Reading (Design)
- **Dally & Harting ch.8**: "Combinational Building Blocks" — encoders, decoders, priority logic, multiplexers, arbiters. This chapter covers the exact building blocks you'll design this week.
- **Dally & Harting ch.14**: "Sequential Logic" — flip-flops, registers, shift registers, counters. Fundamentals for all sequential design.
- **Cliff Cummings** *"State Machine Coding Styles for Synthesis"* — 1-block, 2-block, and 3-block FSM styles
- **ChipVerify FSM page**: https://www.chipverify.com/verilog/verilog-fsm
- **ChipVerify**: https://www.chipverify.com/verilog/verilog-priority-encoder — arbiter/encoder design patterns

### Design HW1: Traffic Light Controller FSM
Design a 3-state FSM for a traffic intersection:

```systemverilog
module traffic_light_fsm (
    input  logic clk, rst_n,
    input  logic sensor,           // car detected on side road
    output logic [2:0] main_light, // {R, Y, G}
    output logic [2:0] side_light  // {R, Y, G}
);
    typedef enum logic [1:0] {
        MAIN_GREEN,
        MAIN_YELLOW,
        SIDE_GREEN
    } state_t;
```

Industry practices:
- Use `typedef enum` with explicit encoding
- 2-block FSM style: one `always_ff` for state register, one `always_comb` for next-state + outputs
- Add a `default` case that goes to a safe state (both red)
- Use a timer counter for state durations

### Design HW2: Valid/Ready Handshake Module
Design a module that implements the valid/ready protocol (same as AXI). This becomes the DUT for your SVA homework (HW3 below):

```systemverilog
module handshake_sender (
    input  logic        clk, rst_n,
    input  logic        send,           // request to send
    input  logic [7:0]  data_in,
    output logic [7:0]  data_out,
    output logic        valid,
    input  logic        ready
);
    // Rules:
    // - Assert valid when data is available
    // - Hold valid high until ready is seen
    // - Data must be stable while valid && !ready
    // - After handshake (valid && ready), deassert valid for 1 cycle
```

This is the exact protocol used by AXI, so getting it right now saves you trouble in Week 10.

### Design HW3: Fixed-Priority Arbiter
Design a 4-input fixed-priority arbiter — a fundamental building block in bus systems and NoCs:

```systemverilog
module fixed_priority_arbiter #(
    parameter NUM_REQ = 4
)(
    input  logic                clk, rst_n,
    input  logic [NUM_REQ-1:0]  request,      // request lines
    output logic [NUM_REQ-1:0]  grant,         // one-hot grant
    output logic                grant_valid    // at least one grant active
);
    // Rules:
    // - Request 0 has highest priority, request N-1 has lowest
    // - Exactly one grant bit set per cycle (one-hot)
    // - Grant is combinational (no latency)
    // - If no requests, grant_valid is low
```

Write a testbench that:
1. Asserts all 4 requests simultaneously — verify grant goes to request 0
2. De-assert request 0 — grant moves to request 1
3. Test all priority orderings
4. Add SVA: grant is always one-hot or zero

### Design HW4: Parameterized Shift Register
Design a versatile shift register used in serial protocols, FIFOs, and DSP:

```systemverilog
module shift_register #(
    parameter WIDTH = 8,
    parameter DIRECTION = "LEFT"  // "LEFT" or "RIGHT"
)(
    input  logic             clk, rst_n,
    input  logic             shift_en,     // enable shifting
    input  logic             load,         // parallel load
    input  logic [WIDTH-1:0] data_in,      // parallel input
    input  logic             serial_in,    // serial input bit
    output logic [WIDTH-1:0] data_out,     // parallel output
    output logic             serial_out    // serial output bit
);
    // Features:
    // - Parallel load overrides shift
    // - serial_out is MSB (left shift) or LSB (right shift)
    // - serial_in feeds the vacated bit position
```

Write a testbench that:
1. Loads 0xA5, shifts left 8 times, captures serial output — should reconstruct 0xA5
2. Tests right-shift mode similarly
3. Verifies load overrides an in-progress shift

---

## Homework

### HW1: Covergroup for FIFO States
You're verifying a FIFO with signals: `full`, `empty`, `overflow`, `underflow`, `wr_en`, `rd_en`, `data_count[3:0]`.

Write a covergroup that covers:

```
covergroup fifo_cg @(posedge clk);
    // TODO: implement the coverpoints below.
    //
    // 1. coverpoint for data_count — bin the 0..15 range into meaningful states:
    //    empty / low / mid / high / full
    //
    // 2. coverpoint for operation — four cases built from wr_en & rd_en:
    //    write_only, read_only, both, idle
    //
    // 3. Cross coverage: data_count_level X operation
    //    (this catches: "did we test writing when FIFO is full?")
    //
    // 4. Transition coverage on data_count (fill-up and drain sequences)
    //
    // 5. coverpoint for error flags: overflow / underflow
endgroup
```

Write a testbench with a simple FIFO model (behavioral, not RTL). Drive random reads/writes for 10000 cycles. Print coverage report at end. Target: 100% on all coverpoints.

### HW2: Cross Coverage Deep Dive
Create a scenario with a memory controller:

```
// Signals: operation (READ/WRITE), address_region (LOW/MID/HIGH), burst_size (1/4/8/16)
// You need to verify every combination — 2 x 3 x 4 = 24 bins.
//
// TODO: write a covergroup `mem_cg` that samples @(posedge clk) and contains:
//   - a coverpoint for each signal (with the bins above)
//   - a single `cross` covering all three
```

Write a testbench that:
1. Drives random transactions until cross coverage hits 100%
2. Prints how many transactions it took
3. Uses `ignore_bins` to exclude illegal combinations (e.g., burst_size 16 to LOW region)

### HW3: SVA Assertions for Handshake Protocol
Write assertions for a valid/ready handshake protocol (like AXI):

Rules:
- Once `valid` is asserted, it must stay high until `ready` is asserted
- `data` must be stable while `valid` is high and `ready` is low
- A transaction completes when both `valid` and `ready` are high
- After a transaction, `valid` must go low for at least 1 cycle (cool-down)
- `ready` can be asserted independently of `valid`

```
// Write these 5 assertions (names are suggestions, feel free to rename):
// 1. valid_must_hold:    valid stays high until ready
// 2. data_stable:        data doesn't change while waiting
// 3. handshake_complete: transaction happens when both high (use cover property)
// 4. cool_down:          valid drops after transaction
// 5. no_unknown:         valid and ready are never X or Z
//
// TODO: implement each as `assert property (...)` or `cover property (...)`.
// Remember: wrap with `disable iff (!rst_n)` to ignore reset cycles.
```

Write a testbench that:
1. Drives correct handshakes — all assertions pass
2. Intentionally violates each rule one at a time — observe assertion failures
3. Uses `$assertoff` / `$asserton` to show how to selectively disable assertions

### HW4: Combined Coverage + Assertions Testbench
Build a testbench for a simple up/down counter (you can write the RTL yourself):

RTL: 4-bit counter with `up`, `down`, `load`, `data_in[3:0]`, `count_out[3:0]`

Verification:
1. **Assertions:**
   - Counter never exceeds 15 or goes below 0
   - When `load` is high, `count_out` equals `data_in` next cycle
   - `up` and `down` should not both be high simultaneously
   - Counter increments by 1 when `up` is high
   - Counter decrements by 1 when `down` is high

2. **Coverage:**
   - All values of `count_out` (0-15) have been reached
   - All transitions: 0->1, 1->2, ..., 14->15, 15->14, ..., 1->0
   - Load operation from every possible `data_in` value
   - Cross: direction (up/down/load/idle) X count_out region (low/mid/high)

Run until 100% coverage. Print final coverage report.

---

## Self-Check Questions
1. What's the difference between code coverage and functional coverage? Which is more important for signoff?
2. What does `cross` coverage give you that individual coverpoints don't?
3. What's the difference between `|->` and `|=>` in SVA?
4. When would you use `cover property` instead of `assert property`?
5. What are `illegal_bins` and `ignore_bins`? When would you use each?
6. How do you handle coverage for very large state spaces (e.g., 32-bit address)?

---

## Checklist

### Verification Track
- [x] Read Spear ch.9 (Functional Coverage)
- [x] Read an SVA reference (Cummings SNUG-2009 "SVA Design Tricks and Bind Files" — ch.1-4)
- [ ] Watched Verification Academy coverage + SVA modules
- [x] Read ChipVerify covergroup, assertions, concurrent assertions pages
- [x] Completed HW1 (FIFO coverage)
- [x] Completed HW2 (Cross coverage)
- [x] Completed HW3 (SVA handshake assertions)
- [ ] Completed HW4 (Combined coverage + assertions testbench)
- [ ] Can answer all self-check questions

### Design Track
- [x] Read Cummings FSM coding styles paper
- [x] Completed Design HW1 (Traffic light FSM)
- [x] Completed Design HW2 (Valid/ready handshake module)
- [x] Read Dally ch.8 (combinational building blocks) and ch.14 (sequential logic)
- [x] Completed Design HW3 (Fixed-priority arbiter)
- [x] Completed Design HW4 (Parameterized shift register)
- [x] Used handshake module as DUT for SVA homework (HW3)
