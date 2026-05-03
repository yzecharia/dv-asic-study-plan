# Week 11: SPI Master & AXI-Lite Slave

## Why This Matters

SPI is the second most common serial protocol (flash, sensors,
ADCs, displays). AXI is **the** bus standard in ARM-based SoCs and
most modern ASICs. Knowing both makes you versatile for any
Israeli SoC team.

**Honest framing:** there is **no good textbook** for either of
these in your assigned set. SPI shows up in datasheets and online
tutorials; AXI is documented in the ARM AMBA spec. Cite them as
the primary references and mark drills/HWs as "outside textbook
curriculum" where they are. The relevant SV-syntax chapters from
Sutherland still apply (interfaces, structs, FSMs).

## What to Study

### Reading — Verification

- **Spear & Tumbush ch.6 — Randomization**: random SPI
  transactions, random AXI address/data with constraints.
- **Spear & Tumbush ch.9 — Functional Coverage**: covergroups for
  SPI modes, AXI address ranges, wstrb patterns.
- **Spear & Tumbush ch.4 §4.9 — assertion intro**: the bedrock for
  the AXI handshake assertions in HW3.
- (Outside curriculum) For the proper handshake-stability
  assertions, see Sutherland *SystemVerilog Assertions Handbook*
  or Cummings SNUG papers — Spear's coverage is too thin for the
  formal-style AXI properties.

### Reading — Design

- **SPI** — outside the assigned textbook curriculum. Use:
  - **Nandland SPI tutorial** —
    https://nandland.com/spi-serial-peripheral-interface/
  - **ChipVerify SPI** — quick reference.
  - Any vendor datasheet (e.g., Microchip 25LC256 EEPROM) for a
    real SPI command set.
- **AXI-Lite** — outside the assigned textbook curriculum. Use:
  - **ARM AMBA AXI Protocol Specification** (free PDF, IHI0022E) —
    read chapters 1-3 and the AXI4-Lite section. This is **the**
    spec.
  - **ChipVerify AXI tutorial** — friendlier on-ramp.
- **Sutherland *SV for Design* ch.10 — Interfaces** ⭐: bundle the
  SPI signals (SCLK/MOSI/MISO/CS) and the 5 AXI channels in
  proper SV interfaces with `master`/`slave`/`monitor` modports
  and a clocking block. This is exactly how real bus IPs are
  written.
- **Sutherland *SV for Design* ch.9 — Design Hierarchy**:
  parameterized modules + `generate`. AXI-Lite is naturally
  parameterized on `ADDR_WIDTH` and `DATA_WIDTH`. (Note:
  parameterization is ch.9, not ch.11 — earlier draft was wrong.)
- **Sutherland *SV for Design* ch.8 — FSM Modeling**: the SPI
  master FSM and the AXI write/read FSMs.
- **Dally & Harting ch.24 — Interconnect**: covers the
  valid/ready handshake pattern that every AXI channel uses. The
  textbook home for handshake protocols even though AXI itself
  isn't there.

### Tool Setup

- xsim or iverilog. No new tools.

---

## Verification Homework

### Drills (per-block warmups)

> SPI/AXI drills are mostly directed-test scaffolding because the
> protocols aren't in your textbooks. Use the spec / ChipVerify as
> primary references.

- **Drill — SPI Mode 0 trace check (Nandland / datasheet)**
  *File:* `homework/verif/per_chapter/hw_spi_mode0_tb/spi_mode0_tb.sv`
  Drive `start` with `tx_data = 0xA5`, capture MOSI on each rising
  SCLK, assert the captured bits equal `0xA5` MSB-first. Hold
  CS_n low across all 8 SCLK cycles.

- **Drill — SPI all-4-modes loopback (Nandland)**
  *File:* `homework/verif/per_chapter/hw_spi_all_modes/spi_modes_tb.sv`
  Loopback MISO ← MOSI inside the TB. Iterate over `mode = 0..3`,
  send `0x55`, assert RX = `0x55` for each. Demonstrates your
  master handles all 4 (CPOL, CPHA) combinations.

- **Drill — AXI write transaction (AMBA spec ch.A3)**
  *File:* `homework/verif/per_chapter/hw_axi_write_tb/axi_write_tb.sv`
  Drive AW + W simultaneously (`awvalid = wvalid = 1`); wait for
  `awready` and `wready`; wait for `bvalid`; assert `bresp ==
  OKAY`. Use BFM-style task helpers in the TB.

- **Drill — AXI read transaction (AMBA spec ch.A3)**
  *File:* `homework/verif/per_chapter/hw_axi_read_tb/axi_read_tb.sv`
  Drive AR; wait for `arready`; capture `rdata` on `rvalid`;
  assert `rresp == OKAY`. Check that `rdata` matches what was
  written.

- **Drill — AXI handshake SVA (AMBA spec §A3.1.1)**
  *File:* `homework/verif/per_chapter/hw_axi_handshake_sva/axi_sva.sv`
  The two canonical AXI handshake properties:
  - Once `valid` is asserted, it must stay high until handshake.
  - Once asserted, payload (`awaddr`, `wdata`, etc.) must hold
    stable until handshake.
  Light SVA syntax — Spear ch.4 §4.9 is just enough; for a
  rigorous treatment see the Sutherland SVA Handbook.

- **Drill — Random AXI sequence (Spear ch.6)**
  *File:* `homework/verif/per_chapter/hw_axi_random_tb/axi_random_tb.sv`
  Class with `rand bit [3:0] addr; rand bit [31:0] data; rand
  bit [3:0] wstrb;`. Generate 50 random writes followed by 50
  reads; scoreboard via SV associative array.

- **Drill — Coverage on AXI (Spear ch.9)**
  *File:* `homework/verif/per_chapter/hw_axi_coverage/axi_cov.sv`
  Covergroup: every register address × {written, read}, every
  `wstrb` pattern (16 bins), back-to-back-write event,
  write-then-read-same-address event.

### Main HWs

#### HW1: SPI master TB (all 4 modes, scoreboard)
*Folder:* `homework/verif/connector/hw1_spi_master_tb/`

Plain-SV TB (UVM lives in W12+). Wraps your `spi_master`
(DHW1) and a small `spi_slave_model` (DHW2). For each mode:
- 100 random bytes through master → slave.
- Slave returns 100 random response bytes → master.
- Scoreboard checks both directions.
- Covergroup hits all 4 modes × {0x00, 0xFF, mid-pattern}.

#### HW2: AXI-Lite slave register-bank TB
*Folder:* `homework/verif/connector/hw2_axi_lite_tb/`

Wraps your `axi_lite_slave` (DHW3). Tests:
- Directed: write 0xDEADBEEF → reg 0, read back, verify match.
- All-regs sweep: write each register with a unique pattern,
  read all back, verify.
- `wstrb` patterns: write only upper 2 bytes; verify only those
  bytes change.
- Read from unwritten register: returns reset value.
- AXI handshake SVA bundle from your drill is wired in.
- Coverage covergroup from drill drives 100% closure.

### Stretch (optional)

- **Stretch — AXI-Lite as UVM agent (preview of W12-W14)**
  Outside the textbook reading; pre-register the AXI agent shape
  for W14's multi-UVC env. One sequence_item, one driver, one
  monitor. Don't ship — just sketch.

---

## Design Homework

### Drills (per-block warmups)

- **Drill — SPI master FSM (Nandland)**
  *Folder:* `homework/design/per_chapter/hw_spi_master_fsm/`
  3-block FSM (Sutherland ch.8). States: IDLE, ACTIVE, DONE.
  Generates SCLK from a clock divider. Mode-aware sample/shift
  edges.

- **Drill — SPI shift register (Dally ch.16)**
  *Folder:* `homework/design/per_chapter/hw_spi_shift_reg/`
  8-bit shift register with parallel-load + serial-out (MOSI),
  serial-in (MISO) → parallel-out. Clocked by SCLK.

- **Drill — AXI handshake skeleton (Dally ch.24, AMBA spec)**
  *Folder:* `homework/design/per_chapter/hw_axi_handshake/`
  Tiny producer + consumer wired with valid/ready. Test
  back-pressure: drop `ready` mid-stream. (Dally ch.24 covers
  this generically; the AMBA spec adds the AXI-specific
  stability rules.)

- **Drill — AXI write FSM (AMBA spec)**
  *Folder:* `homework/design/per_chapter/hw_axi_write_fsm/`
  Slave-side write FSM: states IDLE, WAIT_AW_W, WRITE, RESP. Wait
  for both `awvalid` and `wvalid`, latch the address+data, drive
  `bvalid`.

- **Drill — AXI read FSM (AMBA spec)**
  *Folder:* `homework/design/per_chapter/hw_axi_read_fsm/`
  Slave-side read FSM: states IDLE, WAIT_AR, READ. Wait for
  `arvalid`, latch `araddr`, drive `rvalid` with `rdata`.

- **Drill — SV interfaces for SPI + AXI (Sutherland ch.10)**
  *Folder:* `homework/design/per_chapter/hw_spi_axi_if/`
  Two interfaces:
  ```systemverilog
  interface spi_if;
      logic sclk, mosi, miso, cs_n;
      modport master(...); modport slave(...);
  endinterface

  interface axi_lite_if #(parameter ADDR_W = 4, DATA_W = 32);
      // 5 channels with valid/ready
      modport master(...); modport slave(...); modport monitor(...);
      clocking cb @(posedge aclk); ... endclocking
  endinterface
  ```

### Main HWs

#### HW1: SPI Master — all 4 modes
*Folder:* `homework/design/connector/hw1_spi_master/`

```systemverilog
module spi_master #(
    parameter CLK_DIV    = 4,
    parameter DATA_WIDTH = 8
)(
    input  logic                  clk, rst_n,
    input  logic                  start,
    input  logic [1:0]            mode,
    input  logic [DATA_WIDTH-1:0] tx_data,
    output logic [DATA_WIDTH-1:0] rx_data,
    output logic                  busy, done,
    spi_if.master                 spi
);
```
Mode decoding:
- Mode 0: CPOL=0 CPHA=0 — sample rising, shift falling.
- Mode 1: CPOL=0 CPHA=1 — shift rising, sample falling.
- Mode 2: CPOL=1 CPHA=0 — sample falling, shift rising.
- Mode 3: CPOL=1 CPHA=1 — shift falling, sample rising.

Use your FSM + shift-register drills.

#### HW2: SPI slave model (TB-only)
*Folder:* `homework/design/connector/hw2_spi_slave_model/`

A simple SPI slave model used by the W11 verification HW. Echoes
MOSI → captured `rx_data`; emits `tx_data` on MISO. Mode-aware.
Lives in `tb/` of the SPI testbench, not a synthesizable IP.

#### HW3: AXI-Lite slave with 4 registers
*Folder:* `homework/design/connector/hw3_axi_lite_slave/`

```systemverilog
module axi_lite_slave #(
    parameter ADDR_WIDTH = 4,
    parameter DATA_WIDTH = 32
)(
    input  logic aclk, aresetn,
    axi_lite_if.slave bus
);
    logic [DATA_WIDTH-1:0] regs [0:3];
    // ... write FSM, read FSM
endmodule
```
4 registers at 0x0, 0x4, 0x8, 0xC. Honor `wstrb` (per-byte
write-enable). Use the AXI write/read FSM drills.

### Stretch (optional)

- **Stretch — Parameterize register count via `generate`
  (Sutherland ch.9)**
  Make `N_REGS` a parameter; use `generate for` to instantiate
  `N_REGS` registers and a parameterized address decoder.

- **Stretch — AXI-Lite read with back-pressure**
  Add an "wait state" mode where the slave delays `rvalid`
  for a configurable number of cycles. Useful for W12+ random
  testing.

---

## Self-Check Questions

1. Draw the timing diagram for SPI Mode 0 sending `0xA5`.
2. What's the maximum SPI clock frequency relative to the system
   clock?
3. In AXI, can `awvalid` and `wvalid` be asserted on the same
   cycle? Different cycles?
4. What's the difference between AXI4-Full and AXI4-Lite?
5. Why does AXI use separate read and write channels?
6. What does `wstrb` do? When would you use it?

---

## Checklist

### Verification Track
- [ ] Read Spear ch.6 (randomization)
- [ ] Read Spear ch.9 (functional coverage)
- [ ] Read Spear ch.4 §4.9 (assertion intro)
- [ ] Drill: SPI Mode 0 trace check
- [ ] Drill: SPI all-4-modes loopback
- [ ] Drill: AXI write transaction
- [ ] Drill: AXI read transaction
- [ ] Drill: AXI handshake SVA
- [ ] Drill: random AXI sequence
- [ ] Drill: AXI coverage covergroup
- [ ] HW1: SPI master TB (all 4 modes)
- [ ] HW2: AXI-Lite slave TB (with SVA + coverage closure)
- [ ] Can answer all self-check questions

### Design Track
- [ ] Skim Nandland SPI tutorial
- [ ] Read AMBA AXI spec ch.1-3 + AXI4-Lite section
- [ ] Read Sutherland ch.8 (FSM)
- [ ] Read Sutherland ch.9 (parameterization, generate)
- [ ] Read Sutherland ch.10 (interfaces)
- [ ] Read Dally ch.24 (interconnect / handshakes)
- [ ] Drill: SPI master FSM
- [ ] Drill: SPI shift register
- [ ] Drill: AXI handshake skeleton
- [ ] Drill: AXI write FSM
- [ ] Drill: AXI read FSM
- [ ] Drill: SV interfaces for SPI + AXI
- [ ] HW1: SPI master all 4 modes
- [ ] HW2: SPI slave model
- [ ] HW3: AXI-Lite slave with 4 registers + wstrb
