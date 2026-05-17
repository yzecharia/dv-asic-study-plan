# Interface Timing Taxonomy

**Category**: Protocols · **Used in**: W5 (TLM ports), W11 (AXI/SPI), W17 (FIR streaming) · **Type**: authored

Every interface between two modules answers one question: **when is
the datum on the wires valid, and how does the receiver know?** Dally
gives three answers, and they only make sense in contrast. Pick the
weakest discipline the system can tolerate — each step up the ladder
buys robustness at the cost of wires and latency.

## Dally's teaching — three timing disciplines

Dally & Harting ch.22 §22.1, pp. 461-464 defines interface timing as
"a convention for sequencing the transfer of data." To move a datum
from source `S` to destination `D` you must know two things: when `S`
has produced the datum and placed it on the pins, and when `D` is
ready to sample it. The three disciplines answer those two questions
with progressively more signalling.

### 1. Always-valid (§22.1.1, pp. 461-462)

The signal is **always** valid. No sequencing signals, no flow
control. The wire continuously carries the current value of some
state variable. Dally's example is a temperature sensor that
constantly outputs an 8-bit digital reading — you can sample it at the
clock rate, at twice the clock rate (duplicating values), or at half
the rate (dropping values), and the output still represents the
current temperature. The Pong game (§22.6.1, p.471) is built almost
entirely from always-valid signals: `mode`, `ballPos`, `leftPadY`,
`rightPadY`, `score` each always carry the current value of a state
variable, sampled by whichever FSM needs them.

A **static** (or **constant**) signal is the special case of an
always-valid signal whose value cannot change during the period of
interest (e.g. between system resets). It needs no synchronization at
all when crossing clock domains — see `[[two_ff_synchronizer]]` for
why a stable signal is the easy CDC case.

### 2. Periodically-valid (§22.1.2, p.462)

The signal carries a fresh, distinct datum **every N cycles** — `N` is
the period. There is **no flow control**, and crucially each value
**cannot be dropped or duplicated**: every value represents a distinct
event, token, or task. Dally's example is the `nextKey` output of the
DES cracker's key generator (§21.3.2): a new key appears every `N`
cycles and each key is a separate decryption task — drop one and you
skip a key; duplicate one and you waste work re-trying the same key.

The distinction between always-valid and periodically-valid "becomes
apparent when crossing clock domains": an always-valid signal can be
moved across domains freely (drop/duplicate is harmless), but a
periodically-valid signal needs proper synchronization because every
value matters. Dally notes periodically-valid interfaces "tend to be
brittle and in most cases should be avoided" — changing `N` forces a
redesign of every module on the interface.

### 3. Flow-controlled (§22.1.3, pp. 463-464)

Explicit `valid`/`ready` sequencing. The sender asserts `valid` when a
datum is present; the receiver asserts `ready` when it can accept one;
the transfer happens only when **both** are high. Dally also notes
**one-sided flow control**: if one module is always ready (the music
player's codec is always ready for `next`), `ready` is omitted and
only `valid` runs — `pull timing` when the receiver pulls (only
`ready`/`next` runs), `push timing` when the sender pushes (only
`valid` runs).

This is the deep dive — see `[[ready_valid_handshake]]` for the three
correctness rules, the SV idiom, the skid buffer, and the SVA bundle.
Do not duplicate it here.

## Industry-standard view

The three disciplines map cleanly onto interfaces you will meet in
production silicon.

| Dally discipline | Industry interface | Mechanism |
|---|---|---|
| Always-valid | Status / config registers; always-driven control; APB `PRDATA` when selected; combinational FSM outputs | Wire continuously holds current state; reader samples whenever |
| Periodically-valid | Source-synchronous parallel buses; DDR data with `DQS` strobe; I2S audio frame; LVDS video sampled on the forwarded clock | Sender forwards a clock/strobe; receiver samples on it, no backpressure |
| Flow-controlled | AXI4 / AXI4-Stream `VALID`/`READY`; FIFO `wr_en`+`full` / `rd_en`+`empty`; pipeline coupling with backpressure | Both ends gate the transfer; either can stall |

A few sharp points:

- **Always-valid is not "no protocol" — it is a protocol with a
  contract**: the producer guarantees the wire is meaningful every
  cycle, so the consumer never has to ask. Status registers, a
  free-running counter, a thermocouple ADC output: same idea.
- **Periodically-valid is exactly what source-synchronous DDR is.**
  `DQS` does not carry flow control — the SoC's memory controller
  *must* have a sample buffer ready every burst beat. Drop a beat and
  you have lost data with no recovery. This is why Dally calls these
  interfaces brittle: the entire system is timing-coupled.
- **Flow-controlled is the default for any non-trivial on-chip
  transfer.** Dally's own summary (p.476) says it: "For most
  non-trivial digital systems the event flow is driven from a
  key-interface and events are synchronized between modules with a
  ready/valid interface." AXI made `VALID`/`READY` the industry lingua
  franca precisely because it composes — you can drop a register slice
  or a FIFO anywhere on the path without changing the protocol.

## When to use which

```
                 fresh datum      receiver can     wires
                 every cycle?     stall sender?
always-valid     value is held    n/a (no xfer)    data only
periodically-V   yes, every N     NO               data (+ strobe)
flow-controlled  only on hs       YES (ready)      data + valid + ready
```

Decision rule: use the **weakest** discipline that the system
tolerates. If the value is continuous state that a stale sample does
not corrupt, use always-valid — it is free. If you have a guaranteed
rate and a guaranteed-fast receiver (audio, video, source-synchronous
memory), periodically-valid saves the `ready` wire. The moment either
side can stall, or the rate is data-dependent, you need full
flow control — anything less silently drops data.

## Reading

- Dally & Harting ch.22 §22.1 "Interface timing", pp. 461-464.
- Dally & Harting ch.22 §22.1.1 "Always valid timing", pp. 461-462.
- Dally & Harting ch.22 §22.1.2 "Periodically valid signals", p.462.
- Dally & Harting ch.22 §22.1.3 "Flow control", pp. 463-464.
- Dally & Harting ch.22 §22.6.1 "Pong" (always-valid worked example),
  p.471.
- Dally & Harting ch.22 Summary, p.476.
- ARM AMBA AXI specification (IHI0022E) — `VALID`/`READY` as the
  industry flow-control standard.

## Cross-links

- `[[ready_valid_handshake]]` — the flow-controlled discipline in full.
- `[[interface_partitioning]]` — how the data field of any of these is
  split into control/address/data.
- `[[serial_packetized_interfaces]]` · `[[isochronous_timing]]`
  · `[[two_ff_synchronizer]]` · `[[axi_lite]]`
