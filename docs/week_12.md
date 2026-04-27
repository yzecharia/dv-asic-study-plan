# Week 11: Portfolio Project #1 — UART with Full UVM Testbench

## Why This Matters
This is your first GitHub portfolio piece. It demonstrates: RTL design, UVM verification, coverage-driven methodology, and professional documentation. This is what hiring managers click on.

## Goal
Take your UART RTL from Week 9 and wrap it in a complete UVM testbench. Push to GitHub with a professional README.

---

## Step-by-Step

### Step 1: Project Structure
Create a clean project structure:

```
uart-uvm-verification/
    rtl/
        uart_tx.sv
        uart_rx.sv
        baud_rate_gen.sv
        uart_top.sv
    tb/
        uart_pkg.sv           # package with all UVM classes
        uart_if.sv            # SV interface
        uart_seq_item.sv      # transaction
        uart_driver.sv        # drives TX interface
        uart_monitor.sv       # observes RX interface
        uart_agent.sv         # agent (active or passive)
        uart_scoreboard.sv    # reference model + checker
        uart_coverage.sv      # functional coverage
        uart_env.sv           # environment
        uart_base_test.sv     # base test
        uart_tests.sv         # all test classes
        uart_sequences.sv     # all sequences
        tb_top.sv             # top-level testbench module
    sim/
        Makefile              # compile & run commands
        run_regression.sh     # run all tests
    docs/
        architecture.png      # testbench block diagram
    README.md
```

### Step 2: UVM Components

**uart_seq_item:**
```
- rand bit [7:0] data
- rand int unsigned delay_between_bytes (0-100 clocks)
- rand bit inject_framing_error
- constraint: inject_framing_error dist {0 := 95, 1 := 5}
```

**uart_driver:**
- Gets transactions from sequencer
- Drives tx_start and tx_data on the interface
- Waits for tx_done before getting next item

**uart_monitor:**
- Watches rx_valid pulse
- Captures rx_data when valid
- Sends transaction to analysis port

**uart_scoreboard:**
- Receives TX transactions (what was sent)
- Receives RX transactions (what was received)
- Compares: rx_data must match tx_data
- Tracks pass/fail counts

**uart_coverage:**
- All 256 data byte values sent
- All 256 data byte values received
- Back-to-back transmissions
- Framing error injected and detected
- Different baud rates tested

**uart_sequences:**
```
- uart_single_byte_seq: send one specific byte
- uart_random_seq: send N random bytes
- uart_all_bytes_seq: send all 256 values
- uart_stress_seq: back-to-back with 0 delay
- uart_error_seq: inject framing errors
```

**uart_tests:**
```
- uart_directed_test: known patterns (0x00, 0xFF, 0x55, 0xAA)
- uart_random_test: 1000 random bytes
- uart_coverage_test: run until 100% coverage
- uart_stress_test: back-to-back at max speed
- uart_error_test: framing error injection and detection
```

### Step 3: Run Regression
Run all tests. For each test, record:
- Pass/fail
- Number of transactions
- Coverage achieved

Create a simple regression script that runs all tests and reports results.

### Step 4: Coverage Closure
If coverage is below 100%:
1. Identify uncovered bins
2. Write targeted sequences
3. Re-run until 100%

### Step 5: README
Write a professional README with:

```markdown
# UART with UVM Verification Environment

## Overview
Fully verified UART (TX + RX) IP core with a complete UVM testbench.

## Architecture
![Testbench Architecture](docs/architecture.png)

## Features
- Configurable baud rate (9600, 115200, etc.)
- 16x oversampling receiver
- Framing error detection
- Full UVM testbench with:
  - Constrained random verification
  - Coverage-driven methodology
  - Multiple test scenarios
  - Reference model scoreboard

## Results
| Test | Transactions | Result |
|------|-------------|--------|
| Directed | 10 | PASS |
| Random | 1000 | PASS |
| Stress | 5000 | PASS |
| Error | 500 | PASS |

Functional coverage: **100%**

## How to Run
```
make compile
make run TEST=uart_random_test
make regression  # run all tests
```

## Tools
- Simulator: [Questa/VCS/iverilog]
- SystemVerilog + UVM 2.0
```

### Step 6: Push to GitHub
```bash
cd uart-uvm-verification
git init
git add .
git commit -m "UART IP with full UVM verification environment"
git remote add origin https://github.com/YOUR_USERNAME/uart-uvm-verification.git
git push -u origin main
```

---

## Checklist
- [ ] Project structure created
- [ ] RTL ported from Week 9 (clean, well-commented)
- [ ] uart_seq_item implemented
- [ ] uart_driver implemented
- [ ] uart_monitor implemented
- [ ] uart_agent implemented (active + passive modes)
- [ ] uart_scoreboard implemented with reference model
- [ ] uart_coverage implemented
- [ ] uart_env implemented
- [ ] All 5 sequences implemented
- [ ] All 5 tests implemented
- [ ] tb_top connects DUT to interface and starts UVM
- [ ] All tests pass
- [ ] Coverage >95% (ideally 100%)
- [ ] README written with architecture diagram
- [ ] Pushed to GitHub
- [ ] **MILESTONE: First portfolio project live on GitHub!**
