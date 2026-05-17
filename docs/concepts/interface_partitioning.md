# Interface Partitioning and Selection

**Category**: Protocols · **Used in**: W11 (AXI-Lite channels), W12+ (portfolio bus design) · **Type**: authored

The timing discipline of an interface (always-valid, periodically-valid,
flow-controlled — see `[[interface_timing_taxonomy]]`) says *when* the
data is valid. **Partitioning** says *what the data is*: the data
portion of almost every real interface is not one opaque bus, it is a
set of named fields, and some of those fields are **selection fields**
that decide how the rest is interpreted.

## Dally's teaching

Dally & Harting ch.22 §22.2, p.465 observes that "the data portion of
an interface is often partitioned into a number of fields." Two
running examples:

- **Pong (§22.6.1).** The `model` subsystem's output is logically one
  bus but carries **five distinct state fields**: `mode`, `score`,
  `leftPadY`, `rightPadY`, and `ballPos`. One level down, the Ball FSM
  output is partitioned again — `ballPos` is itself `ballPos.X` and
  `ballPos.Y`. Partitioning is **hierarchical**: a field at one level
  decomposes into sub-fields at the next.
- **Microcode instruction (Figure 18.13).** A microcode instruction
  bus has a field whose value "determines how the rest of the
  instruction is interpreted." That field is a selection field.

### Selection fields — control and address

Dally names a "common interface technique": split the interface into
separate fields for **control**, **address**, and **data**. The
control and address fields are **selection fields**:

- The **control field selects the operation** to be performed. In a
  memory system the control field may specify `read`, `write`,
  `no-operation`, `refresh`, `set parameter`, etc.
- The **address field selects the location** or parameter that the
  operation reads, writes, or refreshes.
- The **data field** then carries (or receives) the data associated
  with the operation.

```
        ┌─────────┬─────────┬───────────────────────┐
  bus → │ control │ address │         data          │
        └────┬────┴────┬────┴───────────────────────┘
             │         │
   selects   │         └─ selects WHICH location/parameter
   the OP ───┘            (read/write target)
   (read / write / refresh / nop ...)
```

A selection field is interpreted *before* the data field, and it
changes the meaning of every other field. This is the structural
heart of every bus protocol: a transaction is `op × target × payload`,
and the first two are selection fields.

Dally closes §22.2 with the timing hook: "Both the data and selection
fields are sequenced using one of the timing conventions described in
Section 22.1." Partitioning (what) is orthogonal to timing (when) —
you choose a discipline from `[[interface_timing_taxonomy]]` and apply
it to the whole partitioned bundle.

## Industry-standard view

Every production bus protocol is interface partitioning made concrete.
The industry difference from Dally's single-bus picture is that mature
protocols give each field group **its own physically separate channel
with its own handshake**.

### AXI4 — partitioning taken to separate channels

AXI4 splits one logical "memory transaction" into **five independent
channels**, each a flow-controlled (`VALID`/`READY`) interface:

| AXI channel | Dally field role | Carries |
|---|---|---|
| AW (write address) | control + address | `AWADDR`, `AWLEN`, `AWSIZE`, `AWBURST`, `AWID` |
| W  (write data) | data | `WDATA`, `WSTRB`, `WLAST` |
| B  (write response) | response (a selection field in reverse) | `BRESP`, `BID` |
| AR (read address) | control + address | `ARADDR`, `ARLEN`, ... |
| R  (read data) | data + response | `RDATA`, `RRESP`, `RLAST` |

`AWADDR` is Dally's address field; the burst attributes
(`AWLEN`/`AWSIZE`/`AWBURST`) are the control field selecting *how* the
transfer runs; `WSTRB` is a sub-field selecting which byte lanes are
live. Separating address from data into distinct channels is what lets
AXI pipeline and reorder transactions — the control/address selection
can be issued cycles ahead of the data.

`[[axi_lite]]` is the cut-down version: still separate AW/W/B/AR/R
channels, no burst control field. APB collapses everything onto one
phase with `PADDR`/`PWRITE`/`PWDATA` — Dally's single partitioned bus,
verbatim.

### Instruction encoding — selection fields in an ISA

A RISC-V instruction word is a partitioned interface into the
datapath. `opcode` + `funct3` + `funct7` are the **control selection
field** (which operation); `rs1`/`rs2`/`rd` are **address selection
fields** (which register-file locations); the immediate is the **data
field**. The instruction *format* (R/I/S/B/U/J) is itself selected by
`opcode` — hierarchical partitioning, exactly Dally's Pong nesting.
See `[[riscv_basics]]`.

### Other mappings

- **DRAM command bus**: `RAS`/`CAS`/`WE` form the control field
  selecting ACTIVATE / READ / WRITE / PRECHARGE / REFRESH; bank +
  row/column pins are the address field.
- **SD/SPI flash commands**: an opcode byte (control) followed by
  address bytes followed by data bytes — a serialized partitioned
  interface (see `[[serial_packetized_interfaces]]`).

## When fields get their own channel vs share a bus

| Situation | Partitioning style |
|---|---|
| Lowest pin count, simple peripheral | One shared bus, fields multiplexed in time (APB, SPI command frame) |
| Need to pipeline address ahead of data | Separate address and data channels (AXI AW/AR vs W/R) |
| Need independent backpressure per field group | Separate channels, each with own `VALID`/`READY` |
| Response must flow opposite direction | Dedicated response channel (AXI B; `RRESP`) |

Rule: partition into fields always; give a field group its own physical
channel when you need to **decouple its timing** from the others —
that decoupling is exactly what buys pipelining and reordering.

## Reading

- Dally & Harting ch.22 §22.2 "Interface partitioning and selection",
  p.465.
- Dally & Harting ch.22 §22.6.1 "Pong" (hierarchical field
  partitioning of the model output), p.471.
- Dally & Harting ch.18 Figure 18.13 — microcode instruction with a
  selection field.
- ARM AMBA AXI specification (IHI0022E) ch.A — the five-channel
  partitioning of AXI4.

## Cross-links

- `[[interface_timing_taxonomy]]` — fields are sequenced by one of the
  three timing disciplines.
- `[[axi_lite]]` — separate address/data/response channels in practice.
- `[[serial_packetized_interfaces]]` — partitioned fields serialized
  over a narrow bus.
- `[[riscv_basics]]` — instruction-encoding fields as selection fields.
