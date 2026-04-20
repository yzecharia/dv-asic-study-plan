# Week 4: UVM Architecture & Components

## Why This Matters
UVM (Universal Verification Methodology) is the industry standard. Every DV job listing in Israel mentions UVM. It's a SystemVerilog class library that provides a reusable testbench structure. This week you learn the architecture — how all the pieces fit together.

## What to Study

### Reading
- **Salemi *The UVM Primer*** (primary — uses TinyALU as the running DUT):
  - **ch.1 Introduction** (quick read)
  - **ch.2-3 Conventional TB + SV Interfaces/BFM** (skim — you already know this)
  - **ch.4-8 OOP review** (skim fast — you have this from weeks 1-2)
  - **ch.9 The Factory Pattern** ⭐ (read carefully — core UVM abstraction)
  - **ch.10 An Object-Oriented Testbench** (bridges OOP → UVM)
  - **ch.11 UVM Tests** ⭐
  - **ch.12 UVM Components** ⭐
  - **ch.13 UVM Environments** ⭐
  - **ch.14 A New Paradigm**
- **Videos**: companion videos at [uvmprimer.com](http://uvmprimer.com), one per chapter
- **Rosenberg & Meade ch.1-4** (reference, optional): deeper treatment if you want industry-depth framing
- **Verification Academy UVM Cookbook** (free, online): topic-indexed recipes — bookmark and search when stuck

### Videos (Verification Academy)
- "UVM Basics" course — start from lesson 1
- "UVM Components" course
- From the **SystemVerilog OOP for UVM Verification** course (deferred from Weeks 1–2), NOW watch:
  - *What is the UVM Factory?*
  - *Using the UVM Factory*
  - *Using the UVM Configuration Database* (save for Week 5 when config_db is the main topic, but you can watch it now if you're curious)

### Quick Reference (ChipVerify.com)
- https://www.chipverify.com/uvm/uvm-introduction
- https://www.chipverify.com/uvm/uvm-testbench-architecture
- https://www.chipverify.com/uvm/uvm-component
- https://www.chipverify.com/uvm/uvm-factory

### Tool Setup
**IMPORTANT:** iverilog does NOT fully support UVM. For this week and all UVM work, use:
- **EDA Playground** (edaplayground.com) — free, browser-based, has Questa/VCS/Riviera
  - Select "UVM 1.2" or "UVM 2.0" from the libraries dropdown
  - Select a simulator (Aldec Riviera-PRO works well on free tier)
- Alternatively, try Verilator (you have it installed) but UVM support is limited

---

## Design Track: ALU & SV Interfaces

Starting from Week 4, your design work feeds directly into your UVM testbench. The ALU you build this week is the DUT you'll verify through Weeks 4-6.

### Reading (Design)
- **Dally & Harting ch.10**: "Arithmetic Circuits" — adders (ripple carry, carry select), subtractors, comparators, multipliers (shift-add). Core chapter for this week's ALU and multiplier HW.
- **Dally & Harting ch.12**: "Fast Arithmetic Circuits" — carry-lookahead adders, fast multipliers, barrel shifters. Explains the circuits behind your barrel shifter HW.
- **Dally & Harting ch.13**: "Arithmetic Examples" — worked design examples combining arithmetic blocks.
- **ChipVerify**: https://www.chipverify.com/systemverilog/systemverilog-interface
- **Cliff Cummings** *"Synthesis Coding Styles for Efficient Designs"* — how your RTL maps to actual hardware gates

### Design HW1: ALU DUT
Design the ALU that your UVM testbench will verify:

```systemverilog
module alu #(
    parameter WIDTH = 8
)(
    input  logic                clk,
    input  logic                rst_n,
    input  logic [WIDTH-1:0]    operand_a,
    input  logic [WIDTH-1:0]    operand_b,
    input  logic [2:0]          operation,   // ADD, SUB, AND, OR, XOR
    input  logic                valid_in,
    output logic [WIDTH:0]      result,      // extra bit for carry/overflow
    output logic                valid_out
);
```

Industry practices:
- Registered outputs (1-cycle latency) — more realistic than pure combinational
- Valid signal for handshaking
- Parameterized width

### Design HW2: SystemVerilog Interface for the ALU
Write the SV interface that connects DUT to testbench:

```systemverilog
interface alu_if (input logic clk, rst_n);
    logic [7:0]  operand_a, operand_b;
    logic [2:0]  operation;
    logic        valid_in;
    logic [8:0]  result;
    logic        valid_out;

    modport dut (input  operand_a, operand_b, operation, valid_in,
                 output result, valid_out);

    modport tb  (output operand_a, operand_b, operation, valid_in,
                 input  result, valid_out);

    clocking cb @(posedge clk);
        output operand_a, operand_b, operation, valid_in;
        input  result, valid_out;
    endclocking
endinterface
```

This interface is what your UVM driver and monitor will use via `virtual alu_if` handles passed through `uvm_config_db`.

### Design HW3: Sequential Shift-Add Multiplier
Design a multiplier that computes the product over multiple cycles — this is how real hardware multipliers work when area is constrained:

```systemverilog
module shift_add_multiplier #(
    parameter WIDTH = 8
)(
    input  logic                  clk, rst_n,
    input  logic                  start,
    input  logic [WIDTH-1:0]      multiplicand,
    input  logic [WIDTH-1:0]      multiplier,
    output logic [2*WIDTH-1:0]    product,
    output logic                  done,
    output logic                  busy
);
    // Algorithm:
    // 1. Load multiplier into shift register
    // 2. For each bit of multiplier:
    //    - If bit is 1, add shifted multiplicand to accumulator
    //    - Shift multiplicand left by 1
    //    - Shift multiplier right by 1
    // 3. After WIDTH cycles, product is ready
    //
    // Industry practice: use an FSM (IDLE -> COMPUTE -> DONE)
    // Bonus: add support for signed multiplication (Booth's algorithm)
endmodule
```

Write a testbench:
- Test corner cases: 0×N, 1×N, N×N, MAX×MAX
- Compare result against `*` operator for 100 random inputs
- Verify timing: exactly WIDTH clock cycles to compute

### Design HW4: Barrel Shifter
Design a single-cycle barrel shifter — used inside ALUs and floating-point units:

```systemverilog
module barrel_shifter #(
    parameter WIDTH = 32
)(
    input  logic [WIDTH-1:0]         data_in,
    input  logic [$clog2(WIDTH)-1:0] shift_amount,
    input  logic [1:0]               shift_type,  // 00=SLL, 01=SRL, 10=SRA
    output logic [WIDTH-1:0]         data_out
);
    // Implement using cascaded MUX layers (log2(WIDTH) stages)
    // Each stage shifts by 1, 2, 4, 8, 16 positions
    // SRA: fill with sign bit instead of zero
endmodule
```

This is the same structure used in your RISC-V ALU (Week 7). Write a testbench verifying all three shift types with various shift amounts.

---

## Homework

### HW1: Draw the UVM Architecture from Memory
Without looking at any reference, draw on paper (or in a drawing tool) the standard UVM testbench architecture:

```
uvm_test
  └── uvm_env
        ├── uvm_agent (active)
        │     ├── uvm_sequencer
        │     ├── uvm_driver
        │     └── uvm_monitor
        ├── uvm_agent (passive — monitor only)
        │     └── uvm_monitor
        ├── uvm_scoreboard
        └── uvm_coverage
```

Label each component with:
- What it does
- Which UVM base class it extends
- How it connects to others (TLM ports)

Then check against the book. Can you draw it perfectly?

### HW2: Build a Skeleton UVM Environment
Create a complete UVM testbench skeleton for an ALU. No actual DUT yet — just the structure.

On EDA Playground, create these files:

**Transaction (uvm_sequence_item):**
```systemverilog
class alu_transaction extends uvm_sequence_item;
    `uvm_object_utils(alu_transaction)

    rand bit [7:0] operand_a;
    rand bit [7:0] operand_b;
    rand enum {ADD, SUB, AND, OR, XOR} operation;
    bit [8:0] result;  // not rand — set by DUT/monitor

    function new(string name = "alu_transaction");
        super.new(name);
    endfunction

    // Implement: do_copy, do_compare, convert2string
endclass
```

**Driver, Monitor, Agent, Scoreboard, Env, Test:**
Create all these as empty shells with correct inheritance and phase methods:
- `alu_driver extends uvm_driver #(alu_transaction)` — has `run_phase` that calls `seq_item_port.get_next_item()`
- `alu_monitor extends uvm_monitor` — has analysis port
- `alu_agent extends uvm_agent` — builds driver + monitor + sequencer in `build_phase`, connects in `connect_phase`
- `alu_scoreboard extends uvm_scoreboard` — has `uvm_analysis_imp`, `write()` function
- `alu_env extends uvm_env` — builds agent + scoreboard
- `alu_test extends uvm_test` — builds env

Make sure it compiles and runs (prints UVM topology) even without a DUT.

### HW3: Implement uvm_sequence_item Properly
Take the `alu_transaction` from HW2 and fully implement all required methods:

```systemverilog
class alu_transaction extends uvm_sequence_item;
    `uvm_object_utils(alu_transaction)

    // ... fields ...

    // Implement these:
    virtual function void do_copy(uvm_object rhs);
        // Deep copy all fields
    endfunction

    virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
        // Compare all fields, return 1 if match
    endfunction

    virtual function string convert2string();
        // Return formatted string: "A=XX B=XX OP=ADD RESULT=XXX"
    endfunction

    virtual function void do_print(uvm_printer printer);
        // Pretty print using printer.print_field()
    endfunction
endclass
```

Write a small test that:
1. Creates two transactions with `type_id::create()`
2. Randomizes both
3. Copies one to the other with `copy()`
4. Compares them (should match)
5. Modifies one field and compares again (should not match)
6. Prints both using `print()`

### HW4: Factory Override Exercise
Demonstrate the UVM factory pattern:

```systemverilog
// Base driver — drives transactions slowly (1 per 10 clocks)
class slow_driver extends uvm_driver #(alu_transaction);
    `uvm_component_utils(slow_driver)
    // ...
    virtual task run_phase(uvm_phase phase);
        `uvm_info(get_type_name(), "SLOW driver running", UVM_LOW)
    endtask
endclass

// Fast driver — drives transactions every clock
class fast_driver extends slow_driver;
    `uvm_component_utils(fast_driver)
    // ...
    virtual task run_phase(uvm_phase phase);
        `uvm_info(get_type_name(), "FAST driver running", UVM_LOW)
    endtask
endclass
```

In the test:
```systemverilog
class fast_test extends uvm_test;
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // Factory override: replace slow_driver with fast_driver everywhere
        set_type_override_by_type(slow_driver::get_type(), fast_driver::get_type());
        env = alu_env::type_id::create("env", this);
    endfunction
endclass
```

Run and verify the override works — you should see "FAST driver running" even though the agent creates a `slow_driver`.

---

## Self-Check Questions
1. What's the difference between `uvm_object` and `uvm_component`?
2. Why use `type_id::create()` instead of `new()`?
3. What are the main UVM phases and in what order do they execute?
4. What is a TLM analysis port and why is it used instead of direct function calls?
5. What's the difference between an active agent and a passive agent?
6. What does `uvm_config_db` do? (preview for next week)

---

## Checklist

### Verification Track
- [ ] Read Salemi *UVM Primer* ch.9-14 (factory, OO TB, UVM tests/components/environments; skim ch.1-8 OOP review)
- [ ] Watched Verification Academy UVM Basics + Components
- [ ] Read ChipVerify UVM introduction, architecture, component, factory pages
- [ ] Set up EDA Playground account and ran a "Hello UVM" example
- [ ] Completed HW1 (Draw architecture from memory)
- [ ] Completed HW2 (Skeleton UVM environment)
- [ ] Completed HW3 (Full sequence_item implementation)
- [ ] Completed HW4 (Factory override exercise)
- [ ] Can answer all self-check questions

### Design Track
- [ ] Read Dally ch.10 (arithmetic circuits) and ch.12 (fast arithmetic / barrel shifter)
- [ ] Read about SV interfaces and modports
- [ ] Completed Design HW1 (ALU DUT with registered outputs)
- [ ] Completed Design HW2 (SV interface with modports + clocking block)
- [ ] Completed Design HW3 (Sequential shift-add multiplier)
- [ ] Completed Design HW4 (Barrel shifter)
