# Week 13 (Bonus): Advanced UVM — RAL + Multi-UVC + Register Verification

## Why This Matters
The 12-week core plan gets you a working junior DV foundation. This bonus week
closes two specific gaps that **academic DV courses cover explicitly** and that
**Israeli senior DV teams ask about in interviews**:

1. **UVM RAL (Register Abstraction Layer)** — modeling DUT registers as a
   first-class testbench object, with auto-generated read/write APIs that the
   sequences can use without hand-coding bus transactions every time.
2. **Multi-UVC integration** — wiring up a verification environment that
   contains agents from **multiple** independent UVCs (e.g., AXI + UART +
   register interface), all driven by a coordinated virtual sequence.

After this week you can claim "I have hands-on experience with RAL and
multi-agent UVM environments" — which most junior candidates can't.

## What to Study

### Reading
- **Salemi UVM Primer ch.16-18** (final RAL chapters in the book)
- **Verification Academy UVM Cookbook → "Register Layer"** ⭐ (free, the
  industry-standard reference)
- **ChipVerify**: search "UVM RAL" — quick syntax reference
- **Mentor whitepaper**: *"UVM Register Layer Quick Start"* (Google it; Mentor
  hosts it free)

### Videos (Verification Academy)
- "Register Modeling" course (3 short lessons)
- "UVM Multi-Domain Environments" (mentions multi-UVC patterns)

### Reference
- The `tools/ralgen.py` you already wrote in your `uvm_framework` repo
  generates a basic RAL model from `regs.json` — extend it (or hand-write a
  full one) for the homework below.

---

## Homework

### HW1: Hand-Written UVM RAL Block (no code generation)
Pick a small register set (4 registers max) and write a UVM RAL model **by
hand** — no `ralgen.py`. Goal: understand every line of the model.

Required classes:
- `my_ctrl_reg extends uvm_reg` with a few `uvm_reg_field`s (use `configure`)
- `my_status_reg extends uvm_reg` (read-only)
- `my_reg_block extends uvm_reg_block` containing both registers, with a
  `default_map` (`UVM_LITTLE_ENDIAN`, 4-byte addressing)

Required methods to exercise:
- `reg_block.CTRL.write(status, 32'h0001)`
- `reg_block.STATUS.read(status, val)`
- `reg_block.CTRL.set(0xCAFE); reg_block.CTRL.update(status);`
- `reg_block.CTRL.predict(...)` and `reg_block.CTRL.get_mirrored_value()`

### HW2: RAL Adapter — Plug Into Your Existing Driver
Write `my_reg_adapter extends uvm_reg_adapter`:
- `reg2bus()`: convert a `uvm_reg_bus_op` into your bus's transaction type
  (e.g., your `alu_transaction` or a new `apb_transaction`)
- `bus2reg()`: the reverse direction

Connect adapter to the existing sequencer:
```systemverilog
reg_block.default_map.set_sequencer(env.agt.sqr, env.adapter);
reg_block.default_map.set_auto_predict(1);
```

Verify: write a sequence that does `reg_block.CTRL.write(...)` and watch the
real bus transactions hit the DUT exactly as if you'd hand-coded them.

### HW3: Multi-UVC Environment
Take your existing `uvm_framework` repo. It already has **two independent
DUTs** (ALU + FIFO) with full UVCs each. Build a NEW env that contains BOTH
agents simultaneously:

```
multi_dut_env
   ├── alu_agent       (drives ALU DUT)
   ├── fifo_agent      (drives FIFO DUT)
   ├── alu_scoreboard
   ├── fifo_scoreboard
   └── virtual_sequencer  ← coordinates the two
```

Required:
- A new `top_multi.sv` that instantiates BOTH DUTs and BOTH interfaces
- A `multi_dut_env` (uvm_env) wiring up both agents
- A `virtual_sequencer extends uvm_sequencer` with handles to the alu and
  fifo sequencers
- A virtual sequence that issues 10 ALU ops and 10 FIFO ops **in parallel**
  (use `fork`/`join` inside the body)

This is the single most important "I can ship real verification" demo you can
put on your CV.

### HW4: Built-in RAL Sequences
The UVM RAL ships with pre-built test sequences. Run them all on your reg
model from HW1+HW2:
- `uvm_reg_hw_reset_seq` — confirms every register has the right reset value
- `uvm_reg_bit_bash_seq` — toggles every bit of every R/W register
- `uvm_reg_access_seq` — exercises the read/write/access policy of each field
- `uvm_mem_walk_seq` (if you add a memory) — walks every memory address

Each is one line in your test:
```systemverilog
seq = uvm_reg_hw_reset_seq::type_id::create("seq");
seq.model = reg_block;
seq.start(null);
```

These four sequences alone are what 90% of register verification looks like in
real chips. If you can run them on your own reg block you've covered the bulk
of what a register-verification interview would ask.

---

## Self-Check Questions
1. What's the difference between `set/get` (frontdoor) and `peek/poke`
   (backdoor) on a `uvm_reg`?
2. What does `set_auto_predict(1)` do, and when would you turn it off?
3. Why does `uvm_reg_adapter` exist — what specifically does it convert?
4. In a multi-UVC env, where do shared resources (clock, reset, config) live
   so all agents can access them?
5. What's a virtual sequencer and why isn't a regular sequencer good enough?
6. What's the bit-bash sequence checking for?

---

## Checklist
- [ ] Read Salemi ch.16-18 (RAL)
- [ ] Read VerificationAcademy "Register Layer" cookbook section
- [ ] Watched Register Modeling videos (3 lessons)
- [ ] Completed HW1 (Hand-written UVM RAL block)
- [ ] Completed HW2 (RAL adapter plugged into existing driver)
- [ ] Completed HW3 (Multi-UVC env with virtual sequencer)
- [ ] Completed HW4 (4 built-in RAL sequences run cleanly)
- [ ] Can answer all self-check questions
- [ ] **MILESTONE: You can verify register sets and multi-IP environments —
  the daily bread of mid-level DV engineers.**
