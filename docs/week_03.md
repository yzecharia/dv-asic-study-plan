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
- **Cliff Cummings** *"State Machine Coding Styles for Synthesis"* — 1-block, 2-block, and 3-block FSM styles
- **ChipVerify FSM page**: https://www.chipverify.com/verilog/verilog-fsm

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

---

## Homework

### HW1: Covergroup for FIFO States
You're verifying a FIFO with signals: `full`, `empty`, `overflow`, `underflow`, `wr_en`, `rd_en`, `data_count[3:0]`.

Write a covergroup that covers:

```
covergroup fifo_cg @(posedge clk);
    // 1. coverpoint for data_count with bins:
    //    - bin "empty_state": data_count == 0
    //    - bin "low":  data_count inside {[1:4]}
    //    - bin "mid":  data_count inside {[5:10]}
    //    - bin "high": data_count inside {[11:14]}
    //    - bin "full_state": data_count == 15
    //
    // 2. coverpoint for operation:
    //    - bin "write_only": wr_en && !rd_en
    //    - bin "read_only":  !wr_en && rd_en
    //    - bin "both":       wr_en && rd_en
    //    - bin "idle":       !wr_en && !rd_en
    //
    // 3. Cross coverage: data_count_level X operation
    //    (this catches: "did we test writing when FIFO is full?")
    //
    // 4. Transition coverage on data_count:
    //    - bins "fill_up":   (0 => 1), (1 => 2), ..., (14 => 15)
    //    - bins "drain":     (15 => 14), ..., (1 => 0)
    //
    // 5. coverpoint for error flags:
    //    - overflow occurred
    //    - underflow occurred
endgroup
```

Write a testbench with a simple FIFO model (behavioral, not RTL). Drive random reads/writes for 10000 cycles. Print coverage report at end. Target: 100% on all coverpoints.

### HW2: Cross Coverage Deep Dive
Create a scenario with a memory controller:

```
// Signals: operation (READ/WRITE), address_region (LOW/MID/HIGH), burst_size (1/4/8/16)
// Cross all three: you need to verify every combination was tested
// That's 2 x 3 x 4 = 24 bins

covergroup mem_cg @(posedge clk);
    cp_op:     coverpoint operation { bins read = {READ}; bins write = {WRITE}; }
    cp_region: coverpoint addr_region { bins low = {LOW}; bins mid = {MID}; bins high = {HIGH}; }
    cp_burst:  coverpoint burst_size { bins b1 = {1}; bins b4 = {4}; bins b8 = {8}; bins b16 = {16}; }
    cx_all:    cross cp_op, cp_region, cp_burst;
endgroup
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
// Write these 5 assertions:
// 1. valid_must_hold: valid stays high until ready
//    assert property (@(posedge clk) $rose(valid) |-> valid throughout (ready [->1]));
//
// 2. data_stable: data doesn't change while waiting
//    assert property (@(posedge clk) (valid && !ready) |=> $stable(data));
//
// 3. handshake_complete: transaction happens when both high
//    (cover property to observe this)
//
// 4. cool_down: valid drops after transaction
//    assert property (@(posedge clk) (valid && ready) |=> !valid);
//
// 5. no_unknown: valid and ready are never X or Z
//    assert property (@(posedge clk) !$isunknown({valid, ready, data}));
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
- [ ] Read Spear ch.9 (Functional Coverage)
- [ ] Read an SVA reference (Sutherland handbook OR Cummings papers OR VA+ChipVerify assertion lessons)
- [ ] Watched Verification Academy coverage + SVA modules
- [ ] Read ChipVerify covergroup, assertions, concurrent assertions pages
- [ ] Completed HW1 (FIFO coverage)
- [ ] Completed HW2 (Cross coverage)
- [ ] Completed HW3 (SVA handshake assertions)
- [ ] Completed HW4 (Combined coverage + assertions testbench)
- [ ] Can answer all self-check questions

### Design Track
- [x] Read Cummings FSM coding styles paper
- [x] Completed Design HW1 (Traffic light FSM)
- [ ] Completed Design HW2 (Valid/ready handshake module)
- [ ] Used handshake module as DUT for SVA homework (HW3)
