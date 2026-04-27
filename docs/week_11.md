# Week 10: SPI Master & AXI-Lite Basics

## Why This Matters
SPI is the second most common serial protocol (after UART) — used for flash, sensors, ADCs, display controllers. AXI is THE bus standard in ARM-based SoCs and most modern ASICs. Knowing both makes you versatile for any Israeli semiconductor company working on SoCs.

## What to Study

### SPI Protocol
- **Nandland SPI tutorial**: https://nandland.com/spi-serial-peripheral-interface/
- Google "SPI protocol tutorial" — key concepts:
  - 4 signals: SCLK, MOSI, MISO, CS (chip select)
  - 4 modes: CPOL (clock polarity) x CPHA (clock phase)
  - Mode 0 (CPOL=0, CPHA=0) is most common
  - Full duplex: data goes both ways simultaneously
  - Multi-slave: one CS per slave device
  - No acknowledgment — simpler than I2C

### AXI-Lite Protocol
- **ARM AMBA AXI Protocol Specification** (free PDF — Google "ARM IHI0022E")
  - Read chapters 1-3 only
  - Focus on AXI4-Lite (simplified version, no bursts)
- **ChipVerify AXI tutorial**: https://www.chipverify.com/axi/axi-protocol

### Reading (Design Best Practices)
- **Sutherland *SystemVerilog for Design* (2nd ed) ch.4-5**: SV interfaces and modports — bundle the SPI signals (SCLK/MOSI/MISO/CS) and the AXI-Lite 5 channels into proper interfaces with master/slave/monitor modports. This is exactly how real bus IPs are written.
- **Sutherland *SystemVerilog for Design* (2nd ed) ch.11**: parameterized modules — AXI-Lite is naturally parameterized on `ADDR_WIDTH` and `DATA_WIDTH`. Use `generate` to scale the register bank in HW3.
- **Sutherland *SystemVerilog for Design* (2nd ed) ch.13**: RTL synthesis guidelines — the SPI/AXI FSMs and handshake logic should follow these patterns to synthesize cleanly.
- Key concepts:
  - 5 channels: Write Address (AW), Write Data (W), Write Response (B), Read Address (AR), Read Data (R)
  - Valid/Ready handshake on every channel
  - AXI-Lite: single transfers only (no bursts), fixed data width

---

## Homework

### HW1: SPI Master — All 4 Modes
Design a configurable SPI master:

```systemverilog
module spi_master #(
    parameter CLK_DIV = 4,      // SCLK = clk / (2 * CLK_DIV)
    parameter DATA_WIDTH = 8
)(
    input  logic                  clk, rst_n,
    input  logic                  start,          // pulse to begin
    input  logic [1:0]            mode,           // SPI mode (0-3)
    input  logic [DATA_WIDTH-1:0] tx_data,        // data to send
    output logic [DATA_WIDTH-1:0] rx_data,        // data received
    output logic                  busy,
    output logic                  done,
    // SPI signals
    output logic                  sclk,
    output logic                  mosi,
    input  logic                  miso,
    output logic                  cs_n            // active low
);
    // Mode decoding:
    // Mode 0: CPOL=0 CPHA=0 — sample on rising edge, shift on falling
    // Mode 1: CPOL=0 CPHA=1 — shift on rising edge, sample on falling
    // Mode 2: CPOL=1 CPHA=0 — sample on falling edge, shift on rising
    // Mode 3: CPOL=1 CPHA=1 — shift on rising edge, sample on falling
endmodule
```

### HW2: SPI Testbench with Slave Model
Write a simple SPI slave model for testing:

```systemverilog
module spi_slave_model #(
    parameter DATA_WIDTH = 8
)(
    input  logic sclk, cs_n, mosi,
    output logic miso,
    input  logic [1:0] mode,
    input  logic [DATA_WIDTH-1:0] tx_data,  // data slave sends back
    output logic [DATA_WIDTH-1:0] rx_data,  // data slave received
    output logic                  rx_valid
);
    // Simple shift register that mirrors SPI protocol
endmodule
```

Testbench:
- **Loopback test**: SPI master sends data, slave receives it, slave sends response, master receives it
- **All 4 modes**: Test each SPI mode with the same data
- **Different data patterns**: 0x55, 0xAA, 0xFF, 0x00, random
- **Multiple back-to-back transfers**: CS stays low between bytes
- **Different clock dividers**: Test SPI at different speeds

### HW3: AXI-Lite Slave — Register Bank
Implement an AXI-Lite slave with 4 read/write registers:

```systemverilog
module axi_lite_slave #(
    parameter ADDR_WIDTH = 4,     // 16 bytes = 4 registers
    parameter DATA_WIDTH = 32
)(
    input  logic                    aclk, aresetn,

    // Write Address Channel
    input  logic [ADDR_WIDTH-1:0]   awaddr,
    input  logic                    awvalid,
    output logic                    awready,

    // Write Data Channel
    input  logic [DATA_WIDTH-1:0]   wdata,
    input  logic [DATA_WIDTH/8-1:0] wstrb,
    input  logic                    wvalid,
    output logic                    wready,

    // Write Response Channel
    output logic [1:0]              bresp,
    output logic                    bvalid,
    input  logic                    bready,

    // Read Address Channel
    input  logic [ADDR_WIDTH-1:0]   araddr,
    input  logic                    arvalid,
    output logic                    arready,

    // Read Data Channel
    output logic [DATA_WIDTH-1:0]   rdata,
    output logic [1:0]              rresp,
    output logic                    rvalid,
    input  logic                    rready
);
    // Internal: 4 registers, addressed at offsets 0x0, 0x4, 0x8, 0xC
    logic [DATA_WIDTH-1:0] regs [0:3];

    // Write logic: accept awaddr+wdata, write to register, respond on B channel
    // Read logic: accept araddr, return register value on R channel
    // Handshake: proper valid/ready protocol on every channel
endmodule
```

### HW4: AXI-Lite Testbench with Assertions
Write a testbench for the AXI-Lite slave:

**Directed tests:**
1. Write 0xDEADBEEF to register 0, read it back, verify match
2. Write to all 4 registers, read all 4 back
3. Write with byte strobes (wstrb): write only upper 2 bytes
4. Read from unwritten register (should be 0 after reset)

**Assertions (SVA):**
- AXI handshake: once `valid` is asserted, it stays high until `ready`
- Response: `bresp` and `rresp` are always OKAY (2'b00) for valid addresses
- No overlapping transactions: don't start new write before previous response
- `awvalid` and `wvalid` can be asserted in any order or simultaneously

**Coverage:**
- All 4 register addresses written and read
- Back-to-back writes
- Back-to-back reads
- Write immediately followed by read to same address
- All values of `wstrb`

---

## Self-Check Questions
1. Draw the timing diagram for SPI Mode 0 sending byte 0xA5.
2. What's the maximum SPI clock frequency relative to the system clock?
3. In AXI, can `awvalid` and `wvalid` be asserted on the same cycle? Different cycles?
4. What's the difference between AXI4-Full and AXI4-Lite?
5. Why does AXI use separate read and write channels?
6. What does `wstrb` do? When would you use it?

---

## Checklist
- [ ] Studied SPI protocol (Nandland + tutorial)
- [ ] Read AXI-Lite spec (ARM AMBA chapters 1-3)
- [ ] Read ChipVerify AXI tutorial
- [ ] Completed HW1 (SPI master — all 4 modes)
- [ ] Completed HW2 (SPI testbench with slave model)
- [ ] Completed HW3 (AXI-Lite slave register bank)
- [ ] Completed HW4 (AXI-Lite testbench with assertions + coverage)
- [ ] Can answer all self-check questions
