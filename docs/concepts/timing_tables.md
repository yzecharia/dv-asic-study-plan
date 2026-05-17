# Timing Tables

**Category**: Methodology · **Used in**: W5+ (TB debug), W11 (protocol bring-up), W12+ (portfolio docs) · **Type**: authored

A timing diagram shows you a few signals over a few cycles. The moment
you need *many* cycles or *non-binary* signals, the waveform stops
helping — squiggly lines blur together. Dally's answer is the
**timing table**: the same information transposed into a table, one
row per cycle, one column per signal. It is a *visualization and
specification* tool, not a circuit.

## Dally's teaching

Dally & Harting ch.22 §22.5, pp. 469-471 introduces the timing table
as the heavyweight alternative to the timing diagram used since
ch.14.

> "In situations where we want to visualize more than a few cycles, or
> where some signals are not binary, the waveforms don't help, and we
> often need to see many more cycles. ... While the data are the same
> whether horizontal or vertical, it is easier to interpret as a
> table."

The convention (Table 22.1, the Huffman encoder of §19.4.1 encoding
the string "THE"; and Table 22.2 / Example 22.3, the deserializer of
Example 22.2):

- **Time advances down the rows** — one row per `cycle`.
- **Each signal is a column.** Multi-bit values are written as
  numbers, not waveforms — that is the whole point.
- **Stacking successive values of a register one above the other
  makes a shift visible** — a left-shift literally reads down the
  column.
- Reset / don't-care entries are shown explicitly (`×` for unknown,
  `1` in `rst` for the reset cycle).

```
  cycle │ rst irdy in  char load count value oval out
  ──────┼───────────────────────────────────────────
    0   │  1   ×   ×    ×    ×    ×     ×    ×    ×
    1   │      1   14   ×              ×
    3   │              14        001000000  1    0
    4   │  1   08  14        2  010000000   1    1
  ──────┴───────────────────────────────────────────
   one row per cycle · multi-bit signals as numbers
```

### §22.5.1 Event flow (p.470)

A timing table makes the **event flow** of a digital system clear. The
event flow is "the sequence of events that through cause and effect
drive the system forward." For Dally's Huffman encoder the event flow
is driven *entirely off the counter*: when the counter reaches 2 the
encoder asserts `irdy` to load another input character; when the
counter reaches 1, `load` is asserted and the counter and shift
register are loaded on the next cycle with the bit string. You can
**trace cause and effect by reading down the table** — a value in one
column on cycle `i` triggers a column change on cycle `i+1`. Dally's
deserializer table (Table 22.2) reads the same way: "On a cycle when
`irdy` is asserted, `char` takes the value of `in` in the next row.
Similarly, in a cycle when `load` is asserted, `count` and `value` are
updated in the next row." A timing table is, in effect, an executed
trace of the FSM.

### §22.5.2 Pipelining and anticipatory timing (p.471)

The deeper use: a timing table exposes **anticipatory timing** in a
pipeline. Dally's Huffman encoder is a pipeline (ch.23); each input
passes through pipeline stages. Because there is a **two-cycle delay**
from input to output, "the control logic must *anticipate* the end of
the current character's bit string and assert `irdy` two cycles in
advance — when the value in the counter is 2 — to load the next
character into the input register. One cycle in advance — when the
count is 1 — it asserts the `load` signal."

The control signal must fire **ahead of** the event it is preparing
for, by exactly the pipeline depth. The timing table is what makes
that lead time visible: you see `irdy` go high two rows above the row
where the new character is actually needed. "This anticipatory timing
becomes more interesting when the pipeline is longer and when the
minimum length of an output string is 1." Anticipatory timing is the
mirror image of the latency a pipeline adds — see
`[[fsm_moore_mealy]]` and `[[static_timing_analysis]]` for the latency
side; here the table is the *design aid* that lets you place the
control assertion at the right row.

The DES cracker (§22.6.2, Tables 22.3-22.4) and music player
(§22.6.3, Table 22.5) are Dally's other worked timing tables — the DES
cracker's Table 22.3 shows the deterministic 16-cycle-per-block
schedule, and Table 22.4 shows the *speculative* variant where
`start_DES` for the next block is asserted before the plaintext check
of the current block resolves. Speculation is anticipatory timing
pushed to its limit: act on the predicted outcome, then "cancel the
speculative work by reasserting `start_DES`" if the prediction was
wrong.

## Industry-standard view

Dally's timing table is the formalization of two things every silicon
engineer already uses: the **datasheet timing diagram/specification**
and the **simulation trace**.

### 1. Datasheet timing specifications

Every component datasheet specifies its interface with a timing
diagram *plus a parameter table* — `tSU`, `tHOLD`, `tCO`, `tPD`, min /
typ / max, each with a symbol and a number. The waveform shows the
*shape*; the table carries the *numbers*. Dally's timing table is the
cycle-accurate digital cousin: instead of nanosecond parameters it
tabulates per-cycle signal values. A protocol bring-up document at any
shop uses exactly this form — "on cycle N assert `ARVALID`, on cycle
N+k expect `RVALID`."

### 2. Waveform viewers and simulation traces

A simulation trace in GTKWave / Verdi *is* a timing table rendered as
a waveform — `time` down (or across), signals as rows. When a waveform
gets unreadable (a 4096-entry burst, a wide bus changing every cycle),
engineers do precisely Dally's move: dump the trace as a **text/CSV
table** and read it as rows. VCD-to-CSV, `$monitor`/`$strobe` logging,
and SystemVerilog testbench transcripts all produce timing tables.

### 3. Expected-value tables in verification

In UVM / constrained-random verification, the **scoreboard reference
model** is often specified as a timing table: cycle, stimulus,
expected response. Directed-test stimulus and golden-response files
are timing tables on disk. See `[[uvm_scoreboard]]` — the predictor's
contract is "given this input on cycle `i`, expect this output on
cycle `i+latency`," which is anticipatory timing read in reverse.

### 4. Anticipatory timing in real pipelines

Dally's anticipatory timing is daily reality in pipelined RTL:

- **Read-enable lead.** A synchronous-read RAM has 1-cycle read
  latency, so the address/`rd_en` must be asserted one cycle *before*
  the data is consumed.
- **AXI burst control.** `ARLEN`/`AWLEN` are presented with the
  address, cycles ahead of the data beats they govern — the control
  field anticipates the data (see `[[interface_partitioning]]`).
- **Branch prediction / prefetch.** A processor front-end fetches and
  predicts *ahead* of execution by the pipeline depth — the same
  "assert the control N cycles early" pattern, with a misprediction
  flush as Dally's "cancel the speculative work."
- **Credit return.** Credit-based flow control returns credits ahead
  of buffer space actually freeing, to hide the round-trip latency.

| Tool | Best for |
|---|---|
| Timing diagram (waveform) | A few signals, a few cycles, binary — protocol shape, handshake edges |
| Timing table | Many cycles, multi-bit signals, shift/counter behavior, event-flow tracing |
| Datasheet parameter table | Analog/physical timing — `tSU`/`tHOLD`/`tCO` numbers |
| Sim trace dump (CSV/log) | Long bursts, regression diffs, scoreboard expected vs actual |

## When to reach for a timing table

Use a **waveform** to communicate the *shape* of a handshake or a
reset sequence — a few signals over a few cycles. Switch to a **timing
table** when (a) the run is long (the Huffman encoder over a whole
string, a multi-block DES decrypt), (b) signals are multi-bit (`count`,
`value`, `char` as numbers), or (c) you are reasoning about
**event flow / anticipatory timing** and need to see a control signal
lead its effect by a fixed number of rows. For pipeline design
specifically, the table is the tool that places each control
assertion at the correct lead distance.

## Reading

- Dally & Harting ch.22 §22.5 "Timing tables", pp. 469-471.
- Dally & Harting ch.22 §22.5.1 "Event flow", p.470.
- Dally & Harting ch.22 §22.5.2 "Pipelining and anticipatory timing",
  p.471.
- Dally & Harting ch.22 Example 22.3 "Deserializer timing table"
  (Table 22.2), p.470.
- Dally & Harting ch.22 §22.6.2-22.6.3 (DES cracker Tables 22.3-22.4,
  music player Table 22.5), pp. 472-475.
- Dally & Harting ch.23 — pipelines, the source of the two-cycle
  delay that forces anticipatory timing.

## Cross-links

- `[[serial_packetized_interfaces]]` — Example 22.2's deserializer,
  tabulated in Example 22.3.
- `[[fsm_moore_mealy]]` — event flow is an executed FSM trace.
- `[[static_timing_analysis]]` — the latency side of pipeline timing.
- `[[uvm_scoreboard]]` — expected-value tables as the predictor
  contract.
- `[[interface_partitioning]]` — control fields presented ahead of
  data (anticipatory timing on a bus).
