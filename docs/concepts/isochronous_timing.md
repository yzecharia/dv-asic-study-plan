# Isochronous Timing

**Category**: Protocols · **Used in**: W11 (audio/display interfaces), W17-W18 (real-time DSP pipelines) · **Type**: authored

Some interfaces have a **hard real-time deadline**: a datum is not just
"valid eventually," it must be delivered inside a bounded window or the
output is wrong. An audio sample that arrives a millisecond late is a
click in the speaker; a pixel that arrives late is a torn frame.
Dally calls this discipline **isochronous timing** — "equal time,"
data delivered on a fixed, bounded cadence.

## Dally's teaching

Dally & Harting ch.22 §22.4, pp. 468-469 defines it directly: "Some
interfaces, such as an LCD display or an audio codec, require
isochronous timing. These devices have hard real-time constraints on
timing — requiring that each data element be delivered within a
bounded window of time to avoid missing a sample."

### The constraint — periodic-with-a-margin, expressed as FIFO depth

Dally's key move: an isochronous interface is **periodically-valid
plus slack**, and the slack is sized by a FIFO.

> "The timing constraint can be thought of as periodic timing with a
> margin — due to a FIFO. Sample `i` must be delivered between cycle
> `Ni − B` and cycle `Ni`, where `N` is the period and `B` is the size
> of the FIFO buffer."

```
   ideal delivery of sample i ──────────────► cycle  N·i
                                                  │
   acceptable window  ◄── B cycles of slack ──────┤
                                                  │
   earliest delivery ──────────────────────► cycle  N·i − B
```

Read it as: a strict periodically-valid interface (see
`[[interface_timing_taxonomy]]`) demands sample `i` at *exactly* cycle
`N·i`. Real producers have jitter, so you put a FIFO of depth `B`
between producer and consumer. The FIFO absorbs early arrivals; the
consumer drains it at the exact rate `N`. The producer's only
obligation is to keep the FIFO non-empty — deliver sample `i` no later
than `N·i` and no earlier than `N·i − B`. Make `B` too small and
jitter underruns the FIFO; the consumer starves and you miss a sample.

### Flow control inside an isochronous interface

"The interfaces themselves employ flow control — to allow some
variation in the timing — but they require that the flow-control
signals respond within the required timing interval."

This is the subtle part. The interface *does* carry `valid`/`ready`,
so the producer can be irregular cycle-to-cycle. But the flow control
is not a free pass: the consumer's `ready` (or `next`) **must be
serviced inside the window**. Flow control buys *jitter tolerance*, not
*latency tolerance* — the deadline is still hard.

### Worked example — the music player codec (§22.6.3)

Dally's isochronous example is the music player of Figure 21.5
(§22.6.3, pp. 474-475). "The event flow for the music player is driven
by the isochronous codec which requests a new `next` sample every
20.83 µs (48 kHz). This is an example of **pull timing**." The codec
asserts `next`; only the `valid` side of flow control runs (one-sided,
receiver-driven — see `[[ready_valid_handshake]]`).

The hard-real-time teeth: "The rest of the system has 2083 10 ns
(100 MHz) clocks to provide this sample before the next request. There
is **no FIFO to buffer samples** before the codec, so the system must
compute each sample in real time." With `B = 0` the margin collapses
to zero — the synthesizer pipeline (sine-wave FSM + harmonics FSM +
envelope FSM, Table 22.5) *must* finish a sample inside 2083 cycles,
every time. Dally also flags the arbitration hazard (p.469):
isochronous timing "can be challenging in a system that includes
arbitration for resources — the amount of time spent waiting for
arbitration must be bounded to prevent the worst-case delay from
exceeding the timing constraint." A late arbitration grant is a missed
sample.

## Industry-standard view

Isochronous is a named transfer class in real protocols — the word
itself is in the USB spec.

| Interface | Period `N` | Buffer / margin `B` | Failure mode |
|---|---|---|---|
| USB isochronous endpoint | 1 transfer per (micro)frame, 1/8 kHz | Endpoint double-buffer; no retransmission | Dropped frame = audio glitch |
| I2S / TDM audio | one sample per `WS` (LR-clock) period, 48/96/192 kHz | Codec FIFO sized for SoC jitter | FIFO underrun = click/pop |
| Display (HDMI/MIPI-DSI/LCD) | one pixel per pixel-clock, line/frame paced by HSYNC/VSYNC | Line buffer(s) | Underrun = torn / black line |
| CAN-FD / TSN time-triggered slot | fixed schedule slot | Slot-sized window | Missed slot = dropped frame |
| PCIe isochronous VC | bandwidth-reserved virtual channel | Reserved credits | Latency target missed |

Key industry points:

- **USB makes the contract explicit.** USB's four transfer types are
  Control, Bulk, Interrupt, and **Isochronous**. Isochronous endpoints
  get *guaranteed bandwidth and bounded latency but no error
  retry* — exactly Dally's "hard deadline, deliver in window or lose
  it." Bulk transfers are the opposite: best-effort, retried, no
  deadline.
- **I2S audio is Dally's music player in silicon.** `BCLK` and `WS`
  (word select / LR clock) pace samples isochronously; the codec's
  internal FIFO is Dally's buffer of depth `B`. SoC audio subsystems
  size that FIFO against DMA-arbitration jitter — under-size it and
  you get the underrun click every audio engineer knows.
- **Display controllers live and die on the line buffer.** The pixel
  clock is unforgiving — the framebuffer DMA must keep the line FIFO
  fed every scanline or the monitor shows a tear. The line buffer *is*
  Dally's margin `B`; sizing it is sizing slack against memory-bus
  contention.
- **Bounded arbitration is the design rule.** Anywhere an isochronous
  flow shares a resource (memory bus, NoC, interrupt path), the
  arbiter must give a **worst-case-bounded** grant latency — round
  robin with a guaranteed slot, TDMA, or QoS/credit reservation. A
  fair-but-unbounded arbiter (e.g. pure priority where a high-priority
  storm can starve the audio DMA) will eventually miss a deadline.
  This is the SoC-QoS problem: isochronous masters get a latency
  guarantee, bulk masters get the leftover bandwidth.

## When timing is isochronous — and how to size it

| Question | If yes → isochronous design |
|---|---|
| Does a late datum corrupt the output (click, tear)? | Yes — hard deadline |
| Is the consumption rate fixed and externally clocked? | Yes — period `N` is fixed |
| Can the producer jitter cycle-to-cycle? | Yes — size FIFO `B` to absorb it |
| Does the path cross a shared/arbitrated resource? | Yes — bound the worst-case grant latency |

Sizing rule: `B ≥` worst-case producer-side jitter (in periods),
including worst-case arbitration latency. If `B = 0` (Dally's music
player), the entire producing pipeline must be **worst-case** fast
enough — design and verify against the worst case, never the average.

## Reading

- Dally & Harting ch.22 §22.4 "Isochronous timing", pp. 468-469.
- Dally & Harting ch.22 §22.6.3 "Music player" (the `B = 0`
  isochronous codec, Table 22.5), pp. 474-475.
- USB 2.0 specification ch.5 §5.6 — isochronous transfers (guaranteed
  bandwidth, bounded latency, no retry).
- I2S / TDM audio interface specification — `BCLK`/`WS` sample pacing.

## Cross-links

- `[[interface_timing_taxonomy]]` — isochronous = periodically-valid
  with a margin.
- `[[ready_valid_handshake]]` — the pull-timing flow control used
  inside the isochronous window.
- `[[sync_fifo]]` — the buffer of depth `B` that provides the margin.
- `[[ppa_tradeoffs]]` — buffer depth vs area vs robustness.
