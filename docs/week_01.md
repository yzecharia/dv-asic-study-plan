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
