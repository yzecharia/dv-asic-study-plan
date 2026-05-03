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
