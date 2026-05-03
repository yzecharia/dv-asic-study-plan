# Week 1: SystemVerilog OOP - Classes, Inheritance, Polymorphism

## Why This Matters
In verification, everything is built with classes. A UART transaction, a test sequence, a scoreboard — they're all SV classes. You can't write UVM without understanding OOP first.

## What to Study

### Reading
- **Spear & Tumbush ch.1**: "Verification Guidelines" — skim for context
- **Spear & Tumbush ch.2**: "Data Types" — focus on `enum`, `struct`, `union`, `typedef`, `string`, queues `[$]`, dynamic arrays `[]`, associative arrays `[string]`
- **Spear & Tumbush ch.5**: "Basic OOP" — foundation chapter, read carefully:
  - Class declaration, `new()` constructor
  - Properties and methods
  - `this` keyword
  - Static properties/methods
  - Shallow vs deep copy
  - Wrapping classes in a `package`
- **Spear & Tumbush ch.8 §§ 8.1–8.5**: "Advanced OOP — inheritance & polymorphism". Ch 5 alone is **not** enough for UVM; you need the first half of Ch 8 too:
  - §8.1 Inheritance with `extends`
  - §8.2 `super` keyword (fields + `super.new()`)
  - §8.3 Polymorphism with `virtual` methods
  - §8.4 Constructors in derived classes
  - §8.5 Copying extended objects
- **Defer to Week 2** (still Ch 8, but heavier): §8.6 abstract/virtual classes, §8.7 `$cast`, §8.8 parameterized classes, §8.9 static members with inheritance, §8.10 callbacks.

### Videos (Verification Academy — free signup)
From the **SystemVerilog OOP for UVM Verification** course, watch these 6 lessons in order (skip the rest until Week 4):
1. Introduction to Classes in SystemVerilog
2. Class Basics
3. Class Properties and Methods
4. Static Properties, Methods and Lists
5. **Inheritance**
6. **Polymorphism**

Skip for now (Week 2+): *Design Patterns and Parameterized Classes*, *Design Patterns Examples*.
Skip until Week 4 (UVM starts): *What is the UVM Factory?*, *Using the UVM Factory*, *Using the UVM Configuration Database*.

Focus on: why verification uses OOP, how classes model transactions, why `virtual` methods are the single most important OOP concept for UVM.

### Quick Reference (ChipVerify.com)
- https://www.chipverify.com/systemverilog/systemverilog-class
- https://www.chipverify.com/systemverilog/systemverilog-inheritance
- https://www.chipverify.com/systemverilog/systemverilog-polymorphism
- https://www.chipverify.com/systemverilog/systemverilog-virtual-methods

---

## Homework

### HW1: Packet Transaction Class
Create a file `hw1_packet.sv` and build a `Packet` class:

```
class Packet;
    // Properties:
    //   - rand bit [7:0] src_addr
    //   - rand bit [7:0] dst_addr
    //   - rand bit [31:0] data
    //   - rand bit [3:0] length
    //   - bit [15:0] crc
    //
    // Methods:
    //   - new() constructor with default values
    //   - function void calc_crc() — compute CRC from data (can be simple XOR)
    //   - function void display() — print all fields with $display
    //   - function Packet copy() — return a deep copy of this packet
    //   - function bit compare(Packet other) — compare two packets field by field
endclass
```

Write a testbench (`hw1_packet_tb.sv`) that:
1. Creates a Packet, randomizes it, displays it
2. Creates a copy, modifies the copy, shows original is unchanged (deep copy works)
3. Compares original and copy (should not match)

### HW2: Transaction Class Hierarchy
Create a base class and two child classes:

```
class Transaction;
    rand bit [7:0] addr;
    rand bit [31:0] data;
    virtual function void display();
    virtual function string get_type();
endclass

class ReadTransaction extends Transaction;
    // Adds: rand int unsigned latency;
    // Override display() to print "READ addr=X latency=Y"
    // Override get_type() to return "READ"
endclass

class WriteTransaction extends Transaction;
    // Adds: rand bit [3:0] byte_enable;
    // Override display() to print "WRITE addr=X data=Y be=Z"
    // Override get_type() to return "WRITE"
endclass
```

Write a testbench that:
1. Creates an array: `Transaction txn_queue[$];`
2. Pushes 5 random ReadTransactions and 5 random WriteTransactions into the queue
3. Loops through the queue, calls `display()` on each — polymorphism should print the correct type
4. Uses `$cast` to downcast a Transaction handle back to ReadTransaction and access `latency`

### HW3: Deep Copy vs Shallow Copy
Write a short testbench that demonstrates the problem with shallow copy:

1. Create a class `Outer` that contains a handle to class `Inner`
2. Do a shallow copy (just assign the handle): `Outer b = a;` — modify `b.inner.value`, show that `a.inner.value` also changed
3. Implement a proper `deep_copy()` method that creates a new Inner object
4. Show that after deep copy, modifying b doesn't affect a

This is critical for verification — scoreboard copies must be deep copies!

### HW4: Virtual Methods
Demonstrate why `virtual` matters:

1. Create `BaseDriver` with a NON-virtual method `drive()`
2. Create `UartDriver extends BaseDriver` that overrides `drive()`
3. Declare a handle: `BaseDriver d = new UartDriver();`
4. Call `d.drive()` — observe it calls BaseDriver's version (wrong!)
5. Now make `drive()` virtual, repeat — observe it calls UartDriver's version (correct!)

Write a clear `$display` in each method so the output makes the difference obvious.

---

## Self-Check Questions (answer without looking)
1. What's the difference between `virtual` and non-virtual methods?
2. What does `$cast` do and when do you need it?
3. Why do verification engineers prefer dynamic arrays and queues over fixed arrays?
4. What happens if you assign one class handle to another without deep copy?
5. What are static class members used for? Give an example.

### Answers

1. **`virtual` vs non-virtual methods**: Non-virtual methods are resolved at compile time based on the handle's declared type (static dispatch). Virtual methods are resolved at runtime based on the actual object type (dynamic dispatch). Virtual enables polymorphism — a base-class handle pointing to a derived object calls the derived class's override. Essential for UVM, where the factory creates objects accessed through base-class handles.

2. **`$cast`**: Performs a runtime downcast — converting a base-class handle to a derived-class handle, with a runtime check that the object actually IS that derived type. Returns 1 on success, 0 on type mismatch. Use `if ($cast(target, source))` when you pull a base-class item from a queue (e.g., a scoreboard) and need derived-class fields/methods.

3. **Dynamic arrays/queues over fixed**: A testbench rarely knows the size up front — number of transactions, test duration, etc. Dynamic arrays (`[]`) size at runtime. Queues (`[$]`) additionally support efficient push/pop/insert, making them ideal for scoreboards and reference models. Fixed arrays waste memory for the worst case and force rewrites when spec grows.

4. **Assigning class handles without deep copy**: Both handles point to the **same object** — any modification through one is visible through the other. That's a reference copy, not a duplicate. For an independent copy, use a user-defined `copy()` method that clones all fields. Common bug: writing `tx2 = tx1` expecting a duplicate, then mutating `tx2` and corrupting `tx1`.

5. **Static class members**: Shared across all instances of the class — one storage per class, not per object. Used for class-wide counters, unique IDs, or singleton patterns. Example: a `static int next_id = 0;` that each constructor increments gives every transaction a unique ID without passing an ID generator around.

---

## Checklist
- [x] Read Spear ch.1, ch.2, ch.5
- [x] Read Spear ch.8 §§ 8.1–8.5 (inheritance, super, virtual, constructors, copying)
- [x] Watched the 6 Verification Academy OOP lessons (Intro → Polymorphism)
- [x] Read ChipVerify class/inheritance/polymorphism pages
- [x] Completed HW1 (Packet class)
- [x] Completed HW2 (Transaction hierarchy)
- [x] Completed HW3 (Deep vs shallow copy)
- [x] Completed HW4 (Virtual methods)
- [x] Can answer all self-check questions

<!-- AUTO-SYNC: per-week views below — regenerate via tools/sync_week_docs.py; do not edit by hand below this line -->

## Daily-driver views

*Auto-mirrored from `week_01_sv_oop/` — edit those files, then run `python3 tools/sync_week_docs.py` to refresh this section.*


---

### `README.md`

# Week 1 — SystemVerilog OOP

> **Phase 1 — SV Fundamentals** · Spear ch.2 + ch.5 + ch.8 §1–5 · ✅ Done

The OOP foundation under everything that follows. Every UVM
transaction, sequence, scoreboard, and test is just a SystemVerilog
class. If polymorphism doesn't feel natural after this week, you'll
fight UVM in W4.

## Prerequisites

- HDLBits-level Verilog (assumed background per `CLAUDE.md` §6).
- No previous OOP experience required — Spear ch.5 starts from zero.

## Estimated time split (24h total)

```
Reading        8h   Spear ch.2 + ch.5 + ch.8 §1–5; Verification Academy lessons 1–6
Verification  10h   HW1 (Packet) + HW2 (Transaction hierarchy) + HW3 (deep copy) + HW4 (virtual methods)
Design         4h   none — Phase 1 is verif-only by design
AI + Power     2h   AI: verify SV terminology against Spear ch.5; Power: write LinkedIn headline draft
```

## Portfolio value (what this week proves)

- You can model a transaction as a class with `rand` fields,
  constraints, `display`, `copy`, and `compare` methods.
- You understand the inheritance hierarchy that UVM relies on
  (`uvm_object` → `uvm_transaction` → `uvm_sequence_item` →
  user transaction).
- You know when to use `virtual` methods — and what breaks without
  them when polymorphism is required.

## Iron-Rule deliverables

- [x] **(a)** RTL committed — n/a (Phase-1 verif-only).
- [x] **(b)** Gold-TB PASS log — all 4 HWs run clean.
- [x] **(c)** `verification_report.md` — Phase-1 retrospective.

## Daily-driver files

- [[learning_assignment]] · [[homework]] · [[checklist]] · [[notes]]

Canonical syllabus: [`docs/week_01.md`](../docs/week_01.md).


---

### `learning_assignment.md`

# Week 1 — Learning Assignment

## Reading

| Source | Chapter / Section | Why |
|---|---|---|
| Spear & Tumbush *SV for Verification* (3e) | ch.1 (skim) | Verification guidelines context. |
| Spear & Tumbush | ch.2 §2.1–2.10 | Data types — `enum`, `struct`, `union`, `typedef`, `string`, queues, dynamic & associative arrays. |
| Spear & Tumbush | **ch.5** (full) | Basic OOP — class, `new()`, `this`, static, shallow vs deep copy, packages. |
| Spear & Tumbush | ch.8 §8.1–§8.5 | Inheritance + polymorphism. The first half of ch.8 is **mandatory** for UVM; §8.6+ deferred to W2. |

Concept notes to read/update:
- [[concepts/boolean_algebra]] — refresher (5 min skim).
- (none specific to OOP yet — write [[concepts/uvm_factory_config_db]]
  notes during W4 from the OOP foundation built here.)

Cheatsheets to skim:
- `cheatsheets/oop_basics.sv` (your own, symlinked from W1 examples)
- `cheatsheets/data_types.sv`

## Verification Academy (free signup) — 6 lessons

From the **SystemVerilog OOP for UVM Verification** course:

1. Introduction to Classes in SystemVerilog
2. Class Basics
3. Class Properties and Methods
4. Static Properties, Methods and Lists
5. Inheritance
6. Polymorphism

## ChipVerify quick refs

- chipverify.com/systemverilog/systemverilog-class
- chipverify.com/systemverilog/systemverilog-inheritance
- chipverify.com/systemverilog/systemverilog-polymorphism
- chipverify.com/systemverilog/systemverilog-virtual-methods

## AI productivity task (Type 1 — Verify)

Per `docs/AI_LEARNING_GUIDE.md` §2.1: paste any AI explanation of
"shallow vs deep copy in SystemVerilog" into the
[`prompts/verify-explanation.md`](../docs/prompts/verify-explanation.md)
template. Cross-check claim by claim against Spear ch.5.

Time budget: 30 min. Output goes to `notes.md` under
`## AI corrections` if AI got anything wrong.

## Power-skill task

Per `docs/POWER_SKILLS.md` §2: write your **first** LinkedIn headline
using Pattern A:

```
Junior Design Verification Engineer | SystemVerilog · UVM · RISC-V |
Building a 20-week portfolio in the open
```

Update LinkedIn → save. Note in `notes.md` how many profile views
you had this week as a baseline for later iterations.

Time budget: 30 min.


---

### `homework.md`

# Week 1 — Homework

All four HWs are ✅ DONE in this repo. Files preserved verbatim from
the StudyPlan beta. Use this doc as a reference for what each HW
proved.

## HW1 — Packet Transaction Class ✅

Files: `tb/HomeWork/HW1/hw1_packet.sv`, `hw1_packet_tb.sv`.

Spec: `Packet` class with `rand bit [7:0] src_addr`, `dst_addr`,
`rand bit [31:0] data`, `rand bit [3:0] length`, computed
`bit [15:0] crc`. Methods: `new`, `display`, `compute_crc`,
`post_randomize`. TB instantiates 5 random packets and prints them.

Acceptance: PASS log captured.

## HW2 — Transaction Hierarchy + Polymorphism ✅

Files: `tb/HomeWork/HW2/hw2_transaction.sv`,
`hw2_read_transaction.sv`, `hw2_write_transaction.sv`, `hw2_tb.sv`.

Spec: base `Transaction` class with virtual `display()` and
`get_type()`. Subclasses `ReadTransaction` and `WriteTransaction`
override both. TB stores all transactions in a base-class array,
loops, calls `display()` — polymorphic dispatch.

Acceptance: prints distinct subclass output through base-class handle.

## HW3 — Deep vs Shallow Copy ✅

File: `tb/HomeWork/HW3/hw3.sv`.

Spec: a `Container` class holding a handle to a `Header` class. Show
that `c2 = c1` shares the `Header` instance (shallow), then write a
`do_copy` method that allocates a new `Header` and confirms changes
to `c2.header` no longer affect `c1`.

## HW4 — Virtual Methods + `$cast` ✅

File: `tb/HomeWork/HW4/hw4_tb.sv`.

Spec: same hierarchy as HW2; `$cast` from base handle into a derived
handle and vice versa. Show `$cast` returning 0 on illegal downcast.

## Per-chapter drills (smaller exercises) ✅

Folders: `tb/ch2_questions/`, `tb/ch5_questions/`, `tb/ch8/`. ~15 small
files demonstrating data types, OOP basics, inheritance, polymorphism.

## Run commands

```bash
cd week_01_sv_oop
iverilog -g2012 -o /tmp/hw1 tb/HomeWork/HW1/hw1_packet_tb.sv
vvp /tmp/hw1

iverilog -g2012 -o /tmp/hw2 tb/HomeWork/HW2/hw2_tb.sv tb/HomeWork/HW2/hw2_transaction.sv \
  tb/HomeWork/HW2/hw2_read_transaction.sv tb/HomeWork/HW2/hw2_write_transaction.sv
vvp /tmp/hw2
```

## Self-check questions (answers in `notes.md`)

1. Why does the array of `Transaction` handles in HW2 dispatch to the
   *subclass* `display()` method instead of the base?
2. What's the difference between a `local` property and a `protected`
   property?
3. When does `$cast` return 0?
4. What's the difference between calling `super.new(...)` from a
   derived constructor vs calling `new(...)` from the base directly?
5. Why is the `Header` field in HW3 shared by default in `c2 = c1`?

## Stretch (optional)

- Add a `compare(Transaction other)` virtual method to HW2's base
  class; subclasses compare their type-specific fields.
- Add a `pack/unpack` pair to HW1's Packet (preview of what UVM
  `do_pack` will do later).


---

### `checklist.md`

# Week 1 — Checklist

✅ Week complete (all items ticked from beta).

## Reading

- [x] Spear ch.1 (skim)
- [x] Spear ch.2 (data types)
- [x] Spear ch.5 (basic OOP)
- [x] Spear ch.8 §8.1–§8.5 (inheritance + polymorphism)
- [x] Verification Academy OOP-for-UVM lessons 1–6
- [x] ChipVerify class / inheritance / polymorphism / virtual-methods
      pages

## Per-chapter drills

- [x] ch.2 data-type drills (queues, dyn arrays, assoc arrays)
- [x] ch.5 OOP drills (class basics, methods, static)
- [x] ch.8 §1–5 drills (inheritance, polymorphism, virtual methods)

## Homework

- [x] HW1 — Packet transaction class
- [x] HW2 — Transaction hierarchy + polymorphism
- [x] HW3 — Deep vs shallow copy
- [x] HW4 — Virtual methods + `$cast`

## Iron-Rule deliverables

- [x] (a) RTL committed — n/a (verif-only week)
- [x] (b) Gold-TB PASS log captured — all 4 HWs PASS
- [x] (c) `verification_report.md` — Phase-1 retrospective

## Cross-cutting

- [x] **AI productivity task** — Verify shallow vs deep copy
      explanation against Spear ch.5
- [x] **Power-skill task** — LinkedIn headline draft (Pattern A)
- [x] `notes.md` updated


---

### `notes.md`

# Week 1 — Notes

## Aha moments

> Add yours.

## AI corrections

> Add when AI gets something wrong.

## Carryover into Week 2

- §8.6 (`$cast`), §8.7 (parameterised classes), §8.8 (callbacks)
  deferred from this week.
- HW2 hierarchy is the seed for the W2 ConstrainedPacket — same
  classes, add `rand` constraints.

