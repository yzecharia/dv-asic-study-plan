# Week 2: Constrained Random Verification

## Why This Matters
Directed tests only cover cases you think of. Constrained random verification generates thousands of valid-but-unexpected scenarios automatically. This is how real DV teams find bugs — it's the core methodology behind UVM.

## What to Study

### Reading
- **Spear & Tumbush ch.8 §§ 8.6–8.10**: "Advanced OOP (remaining)" — the rest of the Ch 8 topics that we deferred from Week 1:
  - §8.6 Abstract / virtual classes
  - §8.7 `$cast` (downcasting base handles to derived)
  - §8.8 Parameterized classes (`class Foo #(type T = int)`)
  - §8.9 Static members with inheritance
  - §8.10 Callbacks (preview — comes back in UVM)
- **Spear & Tumbush ch.6**: "Randomization" — the main chapter this week:
  - `rand` and `randc` modifiers
  - `constraint` blocks: `inside`, `dist`, relational
  - `solve...before` ordering
  - `pre_randomize()` and `post_randomize()` hooks
  - Inline constraints with `randomize() with {}`
  - `constraint_mode()` and `rand_mode()` to toggle constraints
  - Random stability and seeding
- **Spear & Tumbush ch.7** (optional, light read): "Threads & IPC" — fork/join, mailboxes, semaphores. You'll lean on this in Week 4+ for UVM.

### Videos (Verification Academy)
- "Constrained Random Verification" course
- From the **SystemVerilog OOP for UVM Verification** course, watch the two lessons deferred from Week 1:
  - *Design Patterns and Parameterized Classes*
  - *Design Patterns Examples*

### Quick Reference (ChipVerify.com)
- https://www.chipverify.com/systemverilog/systemverilog-randomization
- https://www.chipverify.com/systemverilog/systemverilog-constraints
- https://www.chipverify.com/systemverilog/systemverilog-constraint-examples
- https://www.chipverify.com/systemverilog/systemverilog-solve-before

---

## Design Track: Combinational & Sequential Building Blocks

This week you start writing **industry-style RTL** alongside verification. These modules become DUTs for your verification exercises.

### Reading (Design)
- **Pong Chu ch.4-5** (review): Sequential circuits, FSMs — you've read these, skim for SystemVerilog syntax differences
- **Cliff Cummings SNUG papers** (free PDFs — Google these):
  - *"Synthesizable Finite State Machine Design Techniques Using the New SystemVerilog 3.0 Enhancements"* — the industry-standard FSM coding style paper
  - *"Nonblocking Assignments in Verilog Synthesis, Coding Styles That Kill"* — essential for understanding `<=` vs `=`

### Design HW1: Parameterized Up/Down Counter
Write a clean, industry-style counter:

```systemverilog
module counter #(
    parameter WIDTH = 4
)(
    input  logic             clk,
    input  logic             rst_n,      // active-low async reset
    input  logic             en,
    input  logic             load,
    input  logic             up_down,    // 1=up, 0=down
    input  logic [WIDTH-1:0] data_in,
    output logic [WIDTH-1:0] count_out,
    output logic             wrap        // pulses on overflow/underflow
);
```

Industry practices to follow:
- Use `always_ff` for sequential, `always_comb` for combinational
- Active-low async reset with `negedge rst_n`
- Parameterize everything that might change
- No latches — every `if` has an `else` in combinational blocks

You'll use this counter as the DUT in Week 3's coverage/assertion homework.

### Design HW2: Simple Synchronous FIFO (Preview)
Write a basic synchronous FIFO — you'll build a full UVM testbench for it in Week 12:

```systemverilog
module sync_fifo #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH      = 8
)(
    input  logic                    clk, rst_n,
    input  logic                    wr_en, rd_en,
    input  logic [DATA_WIDTH-1:0]   wr_data,
    output logic [DATA_WIDTH-1:0]   rd_data,
    output logic                    full, empty,
    output logic [$clog2(DEPTH):0]  count
);
```

Key design decisions:
- Circular buffer with read/write pointers
- Use `$clog2(DEPTH)` for pointer widths
- Handle simultaneous read+write correctly
- Full/empty detection from pointers or count

Write a simple directed testbench (not UVM yet) that fills and drains the FIFO.

---

## Homework

### HW1: 10 Constraint Exercises
For each exercise, write the class, randomize it 1000 times, and print a histogram (use an associative array to count occurrences). Verify the distribution matches your prediction.

```
// Exercise 1: value is between 10 and 50
class Ex1;
    rand bit [7:0] value;
    constraint c_range { value inside {[10:50]}; }
endclass

// Exercise 2: value is one of {1, 2, 4, 8, 16, 32}
// Exercise 3: value is even and between 0-100
// Exercise 4: 80% chance value < 10, 20% chance value >= 10 (use dist)
// Exercise 5: addr is aligned to 4 bytes (addr % 4 == 0)
// Exercise 6: if (mode == READ) data must be 0; if (mode == WRITE) data must be non-zero
// Exercise 7: array size is between 1 and 10, each element is unique
// Exercise 8: randc — cycle through all values 0-7 before repeating
// Exercise 9: two variables: x + y == 100, both positive
// Exercise 10: solve x before y — demonstrate how it changes distribution
```

### HW2: Packet Generator with Complex Constraints
Build on Week 1's Packet class. Add these constraints:

```
class ConstrainedPacket extends Packet;
    rand enum {SMALL, MEDIUM, LARGE} size_category;
    rand bit [7:0] payload[];  // dynamic array

    // Constraints:
    // 1. If size_category == SMALL: payload.size() inside {[1:4]}
    //    If MEDIUM: payload.size() inside {[5:16]}
    //    If LARGE: payload.size() inside {[17:64]}
    // 2. src_addr != dst_addr (no loopback)
    // 3. If dst_addr == 8'hFF (broadcast): size_category must be SMALL
    // 4. Distribution: 50% SMALL, 30% MEDIUM, 20% LARGE
endclass
```

Write a testbench that:
1. Generates 100 packets, verifies all constraints hold
2. Uses `constraint_mode(0)` to disable the size distribution, regenerate, show the difference
3. Uses inline constraint: `pkt.randomize() with { dst_addr == 8'hFF; };` — verify size is forced to SMALL

### HW3: Randomized FIFO Transaction Generator
Create a verification-ready transaction generator for a FIFO:

```
class FifoTransaction;
    rand enum {PUSH, POP, PUSH_AND_POP, IDLE} operation;
    rand bit [31:0] write_data;
    rand int unsigned delay;  // cycles between transactions

    // Constraints:
    // 1. delay inside {[0:5]} — keep it fast
    // 2. Distribution: 40% PUSH, 30% POP, 20% PUSH_AND_POP, 10% IDLE
    // 3. write_data is relevant only for PUSH and PUSH_AND_POP
endclass

class FifoTransactionGenerator;
    int unsigned num_transactions;
    FifoTransaction txn_queue[$];

    function new(int unsigned n);
        num_transactions = n;
    endfunction

    // Method: generate() — create num_transactions random FifoTransactions
    // Method: display_all() — print all transactions
    // Method: get_stats() — print: how many PUSH, POP, etc.
endclass
```

Write a testbench that generates 1000 transactions and prints the statistics. Verify the distribution roughly matches the constraint weights.

### HW4: Pre/Post Randomize Hooks
Create a class where `post_randomize()` computes a CRC from the randomized data:

```
class CrcPacket;
    rand bit [7:0] header;
    rand bit [7:0] payload[4];
    bit [7:0] crc;  // NOT rand — computed after randomization

    function void post_randomize();
        // Compute CRC as XOR of header and all payload bytes
        crc = header;
        foreach (payload[i]) crc ^= payload[i];
    endfunction
endclass
```

Write a testbench that:
1. Randomizes 20 packets
2. Verifies CRC is always correct (recompute and compare)
3. Shows that CRC is different each time (not stuck at 0)

---

## Self-Check Questions
1. What's the difference between `rand` and `randc`?
2. What does `solve x before y` actually do to the distribution?
3. How does `constraint_mode()` work? When would you use it?
4. What happens if your constraints are contradictory? How do you debug it?
5. Why is `post_randomize()` useful for verification?
6. What's the difference between `dist` with `:=` vs `:/`?

### Answers

1. **`rand` vs `randc`**: `rand` is uniformly random — consecutive calls may repeat values. `randc` (cyclic) produces a random permutation of the value space — every value appears exactly once before any repeats. Use `randc` to guarantee hitting all values quickly (e.g., small enum state spaces); use `rand` for most cases. `randc` is expensive for large state spaces because the solver tracks history.

2. **`solve x before y`**: Without it, the constraint solver treats all variables equally — every legal `(x, y)` combination gets equal probability. With `solve x before y`, the solver first picks `x` uniformly, **then** picks `y` uniformly from values allowed by `x`. This biases the distribution toward values of `x` with fewer valid partners. Example: `x ∈ {0, 1}`, constraint says `y < x`. Without `solve`: only (1, 0) is legal → P(x=1) = 100%. With `solve x before y`: x picked first uniformly → P(x=0) = 50% but then y has no valid value → backtrack → P(x=1) = 100%. The effect becomes interesting with non-degenerate constraints.

3. **`constraint_mode()`**: Enables/disables a named constraint block at runtime. `obj.constraint_mode(0)` disables all constraints; `obj.my_cons.constraint_mode(0)` disables one. Use to relax or tighten the random space for different test phases without rewriting classes. E.g., during stress testing, disable a normal-range constraint to test boundary behavior.

4. **Contradictory constraints**: `randomize()` returns `0` (failure); variable values are undefined. Debug by: disabling constraints one at a time with `constraint_mode(0)` to isolate the conflict; using `rand_mode(0)` on variables to see which one is unsolvable; checking solver output (most simulators have constraint debug flags). Production testbenches always wrap with `if (!obj.randomize()) $fatal("constraint failure");`.

5. **`post_randomize()` utility**: Called automatically after each successful `randomize()`. Use it to: compute derived fields (e.g., CRC from packet payload), apply transformations constraints can't express, log randomized values for debugging, or enforce relationships between fields that would be awkward as constraints. Keeps all stimulus-related logic inside the class.

6. **`dist` with `:=` vs `:/`**: `:=` assigns the weight to **each** value in the range; `:/` **divides** the weight equally among the values in the range.

   - `x dist {[0:9] := 10, 10 := 1}` → each of `0..9` gets weight 10 (total 100), value 10 gets weight 1. P(x=0) = 10/101.
   - `x dist {[0:9] :/ 10, 10 := 1}` → weight 10 divided among `0..9` (each gets 1), value 10 gets 1. P(x=0) = 1/11.

   Use `:=` when you want probability per-value; `:/` when you want fixed total probability for a range regardless of width.

---

## Checklist

### Verification Track
- [x] Read Spear ch.8 §§ 8.6–8.10 (abstract classes, $cast, callbacks, parameterized classes, static members)
- [x] Read Spear ch.6 (Randomization)
- [x] Skimmed Spear ch.7 (Threads & IPC)
- [x] Watched Verification Academy constrained random module
- [x] Watched VA "Design Patterns" OOP lessons
- [x] Read ChipVerify randomization + constraints pages
- [x] Completed HW1 (10 constraint exercises)
- [x] Completed HW2 (Packet generator with complex constraints)
- [x] Completed HW3 (FIFO transaction generator)
- [x] Completed HW4 (Pre/post randomize hooks)
- [x] Can answer all self-check questions

### Design Track
- [x] Reviewed Pong Chu ch.4-5 (sequential circuits, FSMs)
- [x] Read Cliff Cummings FSM paper
- [x] Read Cliff Cummings nonblocking assignments paper
- [x] Completed Design HW1 (Parameterized counter)
- [x] Completed Design HW2 (Synchronous FIFO)
