# Master Progress Checklist

Update this file as you go. Show it to Claude anytime to pick up where you left off.

**Last updated:** 2026-04-20

---

## Phase 1: SystemVerilog for Verification (Weeks 1-3)

### Week 1 - SV OOP
- [x] Read Spear ch.1-2 (Data Types, OOP Basics)
- [x] Verification Academy: "SystemVerilog OOP" module
- [x] ChipVerify: Classes, Inheritance, Polymorphism pages
- [x] HW1: Packet class with randomize
- [x] HW2: Transaction class hierarchy (base + read/write)
- [x] HW3: Deep copy vs shallow copy exercise
- [x] HW4: Virtual methods exercise

### Week 2 - Constrained Random
- [x] Read Spear ch.4-6 (Randomization, Coverage intro)
- [x] Verification Academy: "Constrained Random" module
- [x] ChipVerify: rand, constraint, dist, solve...before pages
- [x] HW1: 10 constraint blocks with distribution prediction
- [x] HW2: Packet generator with complex constraints
- [x] HW3: Randomized FIFO transaction generator
- [x] HW4: Pre/post randomize hooks exercise

### Week 3 - Coverage & Assertions
- [x] Read Spear ch.9 (Functional Coverage) + Cummings SNUG-2009 SVA paper
- [x] Verification Academy: "Functional Coverage" + "SVA" modules
- [x] ChipVerify: covergroup, coverpoint, cross, SVA pages
- [x] HW1: Covergroup for FIFO states (full/empty/overflow/underflow)
- [x] HW2: Cross coverage exercise
- [x] HW3: 5 SVA assertions for handshake protocol
- [x] HW4: Assertion + coverage combined testbench for simple counter
- [x] Design: Read Dally ch.8 (combinational building blocks) and ch.14 (sequential logic)
- [x] Design HW3: Fixed-priority arbiter
- [x] Design HW4: Parameterized shift register

---

## Phase 2: UVM (Weeks 4-6)

### Week 4 - UVM Architecture
- [ ] Read Salemi *UVM Primer* ch.9-14 (Factory, OO TB, UVM tests/components/environments)
- [ ] Verification Academy: "UVM Basics" module
- [ ] ChipVerify: uvm_component, uvm_object, factory pages
- [ ] HW1: Draw UVM testbench architecture from memory
- [ ] HW2: Build skeleton UVM env (test/env/agent/driver/monitor)
- [ ] HW3: Implement uvm_sequence_item for ALU transaction
- [ ] HW4: Factory override exercise
- [ ] Design: Read Dally ch.10 (arithmetic) and ch.12 (fast arithmetic / barrel shifter)
- [ ] Design HW3: Sequential shift-add multiplier
- [ ] Design HW4: Barrel shifter

### Week 5 - Sequences & Config DB
- [ ] Read Salemi *UVM Primer* ch.15-18, 21-23 (analysis ports, transactions, agents, sequences)
- [ ] Verification Academy: "UVM Sequences" + "Config DB" modules
- [ ] ChipVerify: sequence, sequencer, config_db pages
- [ ] HW1: Write 3 sequences (directed, random, error injection)
- [ ] HW2: Virtual sequence for multi-agent coordination
- [ ] HW3: Config DB exercise (parameterize agent from test level)
- [ ] HW4: TLM FIFO connection between monitor and scoreboard
- [ ] Design: Read Dally ch.16 (datapath sequential), ch.24 (interconnect), ch.25 (memory systems)
- [ ] Design: Read Cummings async FIFO paper (theory)
- [ ] Design HW2: True dual-port RAM
- [ ] Design HW3: Round-robin arbiter
- [ ] Design HW4: Direct-mapped cache structure

### Week 6 - Full UVM Testbench
- [ ] Read Salemi *UVM Primer* ch.19-20, 24 + Rosenberg ch.8-10 (Scoreboard, Coverage, Reporting)
- [ ] Verification Academy: "UVM Scoreboard" + "Register Layer" modules
- [ ] EDA Playground: Run UVM examples with commercial simulator
- [ ] HW1: Build scoreboard with reference model for simple ALU
- [ ] HW2: Add functional coverage to ALU testbench
- [ ] HW3: Complete end-to-end UVM testbench for register file
- [ ] HW4: Run regression with multiple test cases, achieve 100% coverage
- [ ] Design: Read Dally ch.15 (timing), ch.28 (metastability), ch.29 (synchronizer design)
- [ ] Design: Read Cummings CDC paper (SNUG 2008)
- [ ] Design: Read Cummings async FIFO paper (SNUG 2002)
- [ ] Design HW1: Register file RTL (x0=0, write-first)
- [ ] Design HW2: 2-FF synchronizer + pulse synchronizer
- [ ] Design HW3: Asynchronous FIFO (gray code pointers)
- [ ] Design HW4: Timing analysis exercise (pen & paper)

---

## Phase 3: Computer Architecture (Weeks 7-8)

### Week 7 - RISC-V ISA & Single-Cycle
- [ ] Re-read Harris & Harris ch.6-7 (Architecture, Microarchitecture)
- [ ] Read RISC-V spec RV32I chapter (47 instructions)
- [ ] Watch MIT 6.004: Single-cycle processor lecture
- [ ] HW1: Write RV32I instruction decoder in SV
- [ ] HW2: Implement ALU with all RV32I operations
- [ ] HW3: Build single-cycle datapath (PC, RegFile, ALU, Memory)
- [ ] HW4: Write assembly test programs, simulate in your CPU

### Week 8 - Pipelining & Hazards
- [ ] Re-read Harris & Harris ch.7.5-7.8 (Pipelining)
- [ ] Watch MIT 6.004: Pipelining + Hazards lectures
- [ ] HW1: Add 5-stage pipeline registers to your CPU
- [ ] HW2: Implement forwarding unit (EX-EX, MEM-EX)
- [ ] HW3: Implement hazard detection unit (stalls for load-use)
- [ ] HW4: Implement branch handling (flush on misprediction)
- [ ] HW5: Write test programs that trigger each hazard type

---

## Phase 4: Protocols (Weeks 9-10)

### Week 9 - UART
- [ ] Read UART protocol spec (baud rate, framing, start/stop bits)
- [ ] Nandland: UART tutorial + reference implementation
- [ ] ChipVerify: UART design page
- [ ] HW1: Design baud rate generator module
- [ ] HW2: Design UART TX (parallel to serial + framing)
- [ ] HW3: Design UART RX (oversampling, start bit detection, shift register)
- [ ] HW4: Write directed SV testbench (TX to RX loopback)
- [ ] HW5: Add randomized testing (random data, random baud rates)

### Week 10 - SPI & AXI-Lite
- [ ] Read SPI spec (CPOL, CPHA, 4 modes, multi-slave)
- [ ] Read ARM AMBA AXI spec chapters 1-3
- [ ] Nandland: SPI tutorial
- [ ] HW1: Design SPI master (all 4 modes)
- [ ] HW2: Write SPI testbench with SPI slave model
- [ ] HW3: Read and summarize AXI-Lite read/write channel handshake
- [ ] HW4: Design AXI-Lite slave register bank (for future projects)

---

## Phase 5: Portfolio Projects (Weeks 11-12)

### Week 11 - UART + UVM Testbench (GitHub Project #1)
- [ ] Create GitHub repo: `uart-uvm-verification`
- [ ] RTL: UART TX + RX (clean, synthesizable)
- [ ] UVM: Full environment (agent, driver, monitor, scoreboard, coverage)
- [ ] UVM: At least 3 test cases (normal, edge cases, error injection)
- [ ] Coverage: Achieve >95% functional coverage
- [ ] README: Architecture diagram, how to run, coverage report
- [ ] Push to GitHub

### Week 12 - RISC-V + FIFO UVM (GitHub Projects #2 & #3)
- [ ] Create GitHub repo: `riscv-sv-cpu`
- [ ] Clean up RISC-V CPU code from weeks 7-8
- [ ] Add README with block diagram, supported instructions, test results
- [ ] Push to GitHub
- [ ] Create GitHub repo: `fifo-uvm-verification`
- [ ] RTL: Parameterized sync FIFO
- [ ] UVM: Full environment with coverage (empty, full, overflow, underflow, simultaneous R/W)
- [ ] README with architecture diagram
- [ ] Push to GitHub
- [ ] Update CV with all 3 project links

---

## Final Checklist - Portfolio Ready
- [ ] GitHub profile has 3 repos: uart-uvm, riscv-cpu, fifo-uvm
- [ ] Each repo has a professional README with diagrams
- [ ] CV updated with GitHub link and project descriptions
- [ ] LinkedIn updated with projects
- [ ] AutoApply bot config updated with new GitHub URL
