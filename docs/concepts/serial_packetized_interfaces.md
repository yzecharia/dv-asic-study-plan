# Serial and Packetized Interfaces

**Category**: Protocols · **Used in**: W11 (SPI/UART), W12+ (portfolio), W19 (Ethernet-style framing) · **Type**: authored

A wide datum does not need a wide bus. If the interface has a low duty
factor — it is idle most of the time — you can **serialize**: send the
datum a slice per cycle over a narrow interface across several cycles.
The cost is latency and the need for **framing** so the receiver knows
where a transfer starts and ends.

## Dally's teaching

Dally & Harting ch.22 §22.3, pp. 465-468 motivates serialization by
duty factor: "When an interface must transfer a wide datum with a low
duty factor, it may be advantageous to serialize the datum,
transferring it over many cycles, one part per cycle over a narrower
interface."

The worked example: a 64-bit block sent once every four cycles can go
over a **16-bit** interface — `a[15:0]` on cycle 1, `a[31:16]` on
cycle 2, `a[47:32]` on cycle 3, `a[63:48]` on cycle 4 (Figure 22.5).
One quarter of the wires, four times the cycles.

### Framing — knowing where a transfer starts

"With a serialized interface, there must be a convention for the
sending and receiving module to determine which cycle a transfer
starts on. This can be done using either flow control or periodically
valid timing."

Figure 22.5 uses a **`frame` signal** — a `valid` signal that marks
the **first cycle** of each transfer (a form of push timing, receiver
assumed always ready). Dally is precise about *nested timing* here
(Figure 22.6, a memory/IO interface): two levels of timing on one
interface.

- **Frame-level timing** governs *when a transfer begins*. With
  one-way flow control, `frame` is a `valid` signal at transfer
  granularity — the transmitter need not wait, but a transfer need not
  start every `N` cycles and need not be aligned to a multiple of the
  word count.
- **Cycle-level timing** governs the *subsequent words within* a
  transfer. In the Figure 22.5 example the words after the first run
  with periodic timing (`N = 1`, no flow control).

A single `valid` signal can serve both levels — high at the frame
level for the first word, then high at the cycle level for the rest.
With two-way flow control, a single `ready` covers both levels.

### Packetized transfers

"Serialized interfaces can be thought of as being **packetized**. Each
item transmitted is a **packet** of information containing many fields
and possibly of variable length." Two consequences Dally calls out
explicitly:

- The packet is serialized for transmission over an interface "of a
  given width and deserialized on the far side. The width of the
  packet's fields have no relation to the width of the interface."
- "The information transmitted in a given cycle may include all or
  part of several fields, and a given field may span multiple
  cycles." Field boundaries and cycle boundaries are independent — the
  interface partitioning of `[[interface_partitioning]]` (control /
  address / data fields) is sequenced *across* cycles. Figure 22.6
  shows exactly this: a memory transaction with `control` on cycle 1,
  `address` on cycle 2, then `data` on the remaining cycles.

### Serialize-vs-parallel decision and the deserializer

"The decision to serialize an interface or leave it parallel is based
on cost and performance." Dally's rule of thumb (pp. 467): **on-chip**,
where extra wires are cheap, "it is almost always better to leave an
interface wide"; **off-chip**, where chip pins and system-level
signals are expensive, "interfaces are often serialized to keep the
duty factor of each pin close to unity."

**Example 22.2** (pp. 466-468) is the canonical illustration: a
**deserializer** that converts a 1-bit-wide input stream into an
8-bit-wide output, with **push flow control**. Bits 0..7 arrive one
per cycle; the output is not valid until all eight have been received.
Dally's design keeps three pieces of state — a one-hot `en_out` shift
that tracks which bit is being written, the data flip-flops, and a
`vout` flag asserted the cycle after the eighth bit lands. Each input
bit is steered (LSB first) into its D-flip-flop. Example 22.3 then
gives the **timing table** for this same deserializer — see
`[[timing_tables]]`.

```
  1-bit serial in        deserializer            8-bit parallel out
  ─────────────────►   ┌──────────────┐   ───────────────────────►
   b0 b1 ... b7         │ one-hot en   │   valid only after b7
   (one per cycle)      │ 8 D-flops    │   (vout high next cycle)
                        └──────────────┘
```

## Industry-standard view

Serialization is one of the most pervasive ideas in real hardware —
nearly every off-chip link is serialized to keep pin count down.

| Interface | Width | Framing mechanism |
|---|---|---|
| UART | 1 data wire | Start bit (frame open) + stop bit (frame close); no clock — receiver oversamples |
| SPI | 1 wire/direction (MOSI/MISO) | `SS`/`CS` low = frame active; `SCLK` is the forwarded clock |
| I2C | 1 data wire (SDA) | START / STOP conditions delimit the packet; address byte first |
| AXI4-Stream | `TDATA` bus | `TLAST` marks the final beat of a packet; `TVALID`/`TREADY` flow control per beat |
| Ethernet (MAC) | 8/64-bit datapath | Preamble + SFD open the frame; inter-frame gap + FCS close it |
| PCIe / SerDes | 1 differential lane | 8b/10b or 128b/130b block framing; comma symbols for alignment |

Mapping back to Dally's two-level timing:

- **AXI4-Stream is Dally's nested timing, verbatim.** `TVALID`/`TREADY`
  is the cycle-level flow control on every beat; `TLAST` is the
  frame-level delimiter marking the end of a packet. A packet is a
  variable-length burst of beats — Dally's "variable length" packet.
- **UART start/stop bits are explicit framing.** UART has no separate
  `frame` wire, so the start bit *is* the frame-open signal and the
  receiver resynchronizes its sample point on every start edge.
- **SPI `CS` is the `frame` signal of Figure 22.5** — asserted for the
  whole transfer, while `SCLK` carries the cycle-level (periodically
  valid, `N = 1`) timing.
- **Ethernet/PCIe framing** adds alignment: the receiver must first
  find the byte/symbol boundary (preamble, comma symbols) before
  framing means anything — the off-chip cost Dally warns about.

The serialize-vs-parallel rule still holds in 2020s silicon: on-chip
NoCs run wide (128/256/512-bit AXI), off-chip links serialize hard
(PCIe, DDR command bus, MIPI) because package pins dominate cost.

See `[[spi_protocol]]` and `[[uart_protocol]]` for the bit-level
sequencing of two serialized off-chip interfaces; `[[sync_fifo]]` for
the buffer that absorbs rate mismatch between a serial link and a wide
internal datapath.

## When to serialize

| Situation | Choice |
|---|---|
| On-chip, wires cheap, latency matters | Keep parallel (wide AXI) |
| Off-chip, pins expensive, duty factor low | Serialize (SPI, UART, SerDes) |
| Variable-length messages | Packetize with a `TLAST`-style frame delimiter |
| Fixed-size transfers, receiver always ready | One-way framing — `frame`/`valid` only, push timing |
| Either end can stall | Two-way flow control at the cycle level (`TVALID`/`TREADY`) |

## Reading

- Dally & Harting ch.22 §22.3 "Serial and packetized interfaces",
  pp. 465-468.
- Dally & Harting ch.22 Example 22.2 "Deserializer", pp. 466-468
  (Figures 22.7-22.8).
- ARM AMBA AXI-Stream protocol spec (IHI0051) — `TLAST` packet
  framing.
- nandland.com — UART and SPI bit-level framing tutorials.

## Cross-links

- `[[interface_partitioning]]` — the fields that get serialized across
  cycles.
- `[[interface_timing_taxonomy]]` — frame-level vs cycle-level timing
  disciplines.
- `[[timing_tables]]` — Example 22.3 tabulates this deserializer.
- `[[spi_protocol]]` · `[[uart_protocol]]` · `[[sync_fifo]]`
