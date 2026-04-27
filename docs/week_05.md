# Week 5: UVM Communication — TLM, Analysis Ports, Reporting

## Why This Matters

In week 4 you built the static UVM hierarchy (test → env → components). This
week you make the components **talk to each other** using TLM (Transaction
Level Modeling). You'll learn the pattern that decouples a monitor from its
subscribers (scoreboard, coverage, checker) — fundamental to every modern
UVM testbench.

This is also where `uvm_config_db` shows up properly, and where UVM's
reporting macros replace `$display`.

## What to Study (Salemi ch.15-19)

### Reading — Verification

- **Salemi *The UVM Primer***:
  - **ch.15 Talking to Multiple Objects** — TLM concept: ports, exports, imps
  - **ch.16 Using Analysis Ports in a Testbench** ⭐ — `uvm_analysis_port`, `uvm_analysis_imp`, broadcast pattern
  - **ch.17 Interthread Communication** — mailboxes, semaphores; UVM equivalents
  - **ch.18 Put and Get Ports in Action** — blocking/non-blocking TLM ports
  - **ch.19 UVM Reporting** ⭐ — `\`uvm_info`, `\`uvm_warning`, `\`uvm_error`, `\`uvm_fatal`, verbosity, `+UVM_VERBOSITY=`
- **Verification Academy**: UVM Cookbook → "Analysis Components" + "Reporting" sections
- **ChipVerify**: [uvm-tlm](https://www.chipverify.com/uvm/uvm-tlm), [uvm-analysis-port](https://www.chipverify.com/uvm/uvm-analysis-port), [uvm-analysis-imp](https://www.chipverify.com/uvm/uvm-analysis-imp), [uvm-config-db](https://www.chipverify.com/uvm/uvm-config-db)

### Reading — Design

- **Dally & Harting ch.16** — datapath sequential logic
- **Dally & Harting ch.24** — interconnect (handshake protocols, valid/ready)
- **Sutherland *SV for Design* ch.7** — packed/unpacked types, structs
- **Cliff Cummings** — *"Async FIFO Design"* paper (theory only this week)

### Tool Setup

- xsim with `-L uvm` (same as week 4)
- For reporting verbosity tests: `-testplusarg UVM_VERBOSITY=UVM_HIGH`

---

## Verification Homework

### Per-chapter

- **HW ch.15 — TLM concepts**
  *File:* `homework/verif/per_chapter/hw_ch15_tlm_basics/tlm_demo.sv`
  Build two `uvm_component` classes that communicate through a basic
  `uvm_blocking_put_port` / `uvm_blocking_put_imp` pair. Producer sends 10
  items; consumer prints them. No analysis ports yet.

- **HW ch.16 — Analysis port broadcast**
  *File:* `homework/verif/per_chapter/hw_ch16_analysis_ports/broadcast_demo.sv`
  One source component with a `uvm_analysis_port` writes 5 transactions.
  Two subscribers receive each one (use `uvm_analysis_imp`). Demonstrate
  the 1-to-many broadcast pattern.

- **HW ch.17 — Interthread communication**
  *File:* `homework/verif/per_chapter/hw_ch17_interthread/mailbox_demo.sv`
  Recreate Spear's mailbox example, then translate it to a
  `tlm_fifo`-based UVM equivalent.

- **HW ch.18 — Put and get ports**
  *File:* `homework/verif/per_chapter/hw_ch18_put_get/put_get_demo.sv`
  Producer/consumer using `uvm_blocking_put` and `uvm_blocking_get`.
  Try both blocking and non-blocking variants.

- **HW ch.19 — UVM reporting**
  *File:* `homework/verif/per_chapter/hw_ch19_reporting/report_demo.sv`
  Print at all 4 severities (info/warning/error/fatal) with different
  verbosity levels. Run with `+UVM_VERBOSITY=UVM_HIGH` and observe what
  filters in/out.

### Connector

- **Connector HW — Full analysis path on the ALU TB**
  *Folder:* `homework/verif/connector/`
  Take your week-4 connector TB (Salemi-ch.13 style, no sequences) and
  add a real **monitor → analysis_port → scoreboard + coverage** path.
  The monitor passively samples the bus and broadcasts; both subscribers
  receive every transaction. Replaces the direct `bfm.A`/`bfm.B` access
  the scoreboard had before.

### Big picture

- **Big-picture HW — config_db driven test**
  *Folder:* `homework/verif/big_picture/config_db_test/`
  Use `uvm_config_db` to pass: (a) the virtual interface, (b) the number
  of transactions, and (c) an `is_active` flag for the agent. Run two
  tests with different config values without recompiling.

- **Big-picture HW — UVM reporting macros throughout**
  *Folder:* `homework/verif/big_picture/uvm_reporting_polish/`
  Replace every `$display` in your connector TB with `\`uvm_info` /
  `\`uvm_error`. Show how verbosity filtering works.

---

## Design Homework

### Per-chapter

- **HW Dally ch.16 — Datapath shift register**
  *Folder:* `homework/design/per_chapter/hw_dally_ch16_shift_register/`
  Parameterized shift register with serial-in/serial-out and parallel-load.

- **HW Dally ch.24 — Valid/ready handshake**
  *Folder:* `homework/design/per_chapter/hw_dally_ch24_handshake/`
  Build a producer/consumer pair using a valid/ready handshake. Test
  back-pressure: consumer drops `ready` mid-stream.

- **HW Sutherland ch.7 — Packed structs**
  *Folder:* `homework/design/per_chapter/hw_sutherland_ch7_structs/`
  Build a small RTL block whose port is a packed `struct`. Use the
  struct to bundle 5+ signals cleanly.

### Connector

- **Connector HW — True dual-port RAM**
  *Folder:* `homework/design/connector/dual_port_ram/`
  Parameterized DPRAM (port A + port B, both can read & write
  independently). Combines sequential logic + handshake + struct port.

### Big picture

- **Big-picture HW — Round-robin arbiter**
  *Folder:* `homework/design/big_picture/round_robin_arbiter/`
  4-input round-robin arbiter with rotating priority mask. Test fairness.

---

## Self-Check Questions

1. What is a `uvm_analysis_port` and why use it instead of direct method calls?
2. What's the difference between `analysis_port`, `analysis_imp`, and `analysis_export`?
3. When would you use `tlm_fifo` instead of analysis ports?
4. What does `uvm_config_db::set` / `get` do? Why use it instead of constructor args?
5. What are the 4 severity levels in UVM reporting?
6. How does `+UVM_VERBOSITY=UVM_HIGH` change which messages print?

---

## Checklist

### Verification Track
- [ ] Read Salemi ch.15 (talking to multiple objects)
- [ ] Read Salemi ch.16 (analysis ports)
- [ ] Read Salemi ch.17 (interthread communication)
- [ ] Read Salemi ch.18 (put and get ports)
- [ ] Read Salemi ch.19 (UVM reporting)
- [ ] Read Verification Academy "Analysis Components" + "Reporting"
- [ ] Per-chapter HWs (5)
- [ ] Connector HW (full analysis path)
- [ ] Big-picture HW: config_db driven test
- [ ] Big-picture HW: UVM reporting macros polish
- [ ] Can answer all self-check questions

### Design Track
- [ ] Read Dally ch.16 (datapath sequential)
- [ ] Read Dally ch.24 (interconnect)
- [ ] Read Sutherland ch.7 (packed types)
- [ ] Per-chapter HW: shift register
- [ ] Per-chapter HW: valid/ready handshake
- [ ] Per-chapter HW: packed struct port
- [ ] Connector HW: dual-port RAM
- [ ] Big-picture HW: round-robin arbiter
