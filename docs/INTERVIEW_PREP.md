# Interview Prep — Junior RTL / DV Question Bank

Categorised question pool you'll work through during W14 / W19 / W20
mock interviews. Each category cross-links to the week and concept
note that covers the answer foundationally — so when you don't know
something, you go back to the source rather than guessing.

---

## 1. Combinational logic

| # | Question | Source |
|---|---|---|
| 1 | Draw a 4-to-1 mux from 2-to-1 muxes. | `[[concepts/multiplexers_decoders]]` · Harris ch.2 |
| 2 | Why is a one-hot decoder safer for state encoding than binary? | `[[concepts/fsm_encoding_styles]]` · Cummings FSM SNUG-2003 |
| 3 | Carry-lookahead adder vs ripple-carry — when does each win? | `[[concepts/adders_carry_chain]]` · Dally ch.10 |
| 4 | Write Boolean for `Y = A·B + ¬A·C` using only NAND. | `[[concepts/boolean_algebra]]` |
| 5 | When does a Karnaugh map fail to give you the optimal expression? | `[[concepts/karnaugh_maps]]` |

## 2. Sequential logic & timing

| # | Question | Source |
|---|---|---|
| 1 | Setup vs hold violation — which one can you fix by slowing the clock? Why? | `[[concepts/setup_hold_metastability]]` · Harris ch.3 |
| 2 | Async vs sync reset — when do you use which? | `[[concepts/clocking_resets]]` · Sutherland Design |
| 3 | Why is a master-slave D-FF immune to certain glitches? | `[[concepts/flip_flops_latches]]` · Dally ch.14 |
| 4 | Latch vs flip-flop — what gives you a latch unintentionally in SV? | `always_comb` missing assignment · Sutherland RTL Modeling |
| 5 | Setup time = X ns, clock-to-Q = Y ns, combinational = Z ns. What is Fmax? | Static-timing reasoning · Cummings SNUG-2008 |

## 3. FSMs

| # | Question | Source |
|---|---|---|
| 1 | One-block vs two-block vs three-block FSM — what's each good for? | `[[concepts/fsm_encoding_styles]]` · W3 |
| 2 | Moore vs Mealy — when does a Mealy bite you? | `[[concepts/fsm_moore_mealy]]` |
| 3 | One-hot vs binary state encoding — synthesis trade-offs. | Cummings FSM SNUG-2003 |
| 4 | Glitch-free FSM outputs — registered vs combinational, and why. | Cummings FSM-outputs SNUG-2010 · W10 |

## 4. FIFOs

| # | Question | Source |
|---|---|---|
| 1 | Sync FIFO empty/full detection — what does the count compare to? | `[[concepts/sync_fifo]]` · W2 |
| 2 | Async FIFO — why gray-code pointers? | `[[concepts/async_fifo]]` · Cummings SNUG-2002 |
| 3 | Almost-full / almost-empty thresholds — where do you put them and why? | W7 |
| 4 | What happens if you try to use a single binary counter across two clock domains? | `[[concepts/multibit_handshake_cdc]]` |

## 5. CDC

| # | Question | Source |
|---|---|---|
| 1 | Why a 2-FF synchroniser? Why not 1? Why not 3? | `[[concepts/two_ff_synchronizer]]` · Cummings CDC SNUG-2008 |
| 2 | MTBF — what's a back-of-envelope number for a 100 MHz target with 2-FF sync? | `[[concepts/metastability_mtbf]]` · W19 |
| 3 | Multi-bit signal across CDC — handshake vs gray-code FIFO, when to use which. | `[[concepts/multibit_handshake_cdc]]` |
| 4 | Pulse synchroniser — explain the toggle-FF technique. | Cummings SNUG-2008 |
| 5 | Reset synchronisation — why async-assert / sync-deassert? | Sutherland Design clocking ch. |

## 6. UVM

| # | Question | Source |
|---|---|---|
| 1 | Walk through `build_phase` → `connect_phase` → `run_phase` order. | `[[concepts/uvm_phases]]` · Salemi ch.12 |
| 2 | Factory pattern — what does `set_type_override_by_type` do at construction time? | `[[concepts/uvm_factory_config_db]]` · Salemi ch.9, ch.14 |
| 3 | `uvm_config_db` — what's the wildcard precedence rule? | Verification Academy UVM Cookbook |
| 4 | Sequence vs sequencer — who arbitrates between competing sequences? | `[[concepts/uvm_sequences_sequencers]]` · Salemi ch.20–22 |
| 5 | Scoreboard with analysis port + analysis FIFO — why both? | `[[concepts/uvm_scoreboard]]` · Rosenberg ch.6 |
| 6 | Functional coverage in UVM — where do you place the `covergroup`? | `[[concepts/coverage_functional_vs_code]]` · Spear ch.9 |
| 7 | RAL backdoor vs frontdoor — when do you backdoor? | `[[concepts/uvm_ral]]` · Rosenberg RAL ch. |
| 8 | Multi-UVC env — what coordinates parallel sequences across UVCs? | virtual sequencer · W14 |

## 7. SVA

| # | Question | Source |
|---|---|---|
| 1 | `|->` vs `|=>` — what's the cycle difference? | `[[concepts/sva_assertions]]` · Cummings SNUG-2009 |
| 2 | `$rose`, `$fell`, `$stable`, `$past` — give an example of each. | Cummings SNUG-2009 |
| 3 | Bind file — why? When? | Cummings SVA Design Tricks SNUG-2009 |
| 4 | Cover property vs assert property — what does each give you? | Spear ch.9 |
| 5 | Liveness vs safety property — give one of each for an async FIFO. | W7 |

## 8. Protocols

| # | Question | Source |
|---|---|---|
| 1 | UART framing — start bit, stop bit, parity. How does the RX recover the clock? | `[[concepts/uart_protocol]]` · Chu ch.7 |
| 2 | SPI four modes — what are CPOL and CPHA, and how do they affect sample edges? | `[[concepts/spi_protocol]]` · Nandland tutorial |
| 3 | AXI-Lite handshake — what's the rule about `AWVALID` and `AWREADY`? | `[[concepts/axi_lite]]` · ARM AMBA spec |
| 4 | Ready/valid — can ready depend on valid in the same cycle? Why does this matter for timing? | `[[concepts/ready_valid_handshake]]` |
| 5 | AXI write strobes (`WSTRB`) — what do they let you do? | ARM AMBA spec |

## 9. RISC-V / CPU architecture

| # | Question | Source |
|---|---|---|
| 1 | RAW / WAR / WAW — which can occur in a single-issue in-order pipeline? | `[[concepts/riscv_basics]]` · Harris ch.7 |
| 2 | Forwarding (bypassing) — where does it physically happen in a 5-stage pipeline? | Harris ch.7 §7.5 |
| 3 | Load-use hazard — why one stall bubble is unavoidable. | Harris ch.7 §7.6 |
| 4 | Branch prediction in a single-cycle CPU — trick question, why? | (because there's no pipeline to flush) |
| 5 | Sign extension for `lb` vs `lbu` — where in your datapath does this happen? | RISC-V ISA spec V20191213 |

## 10. Synthesis & timing

| # | Question | Source |
|---|---|---|
| 1 | Setup-time-violating path — name 3 things you'd try to fix it. | `[[concepts/timing_constraints_sdc]]` |
| 2 | Why is `reg` (Verilog) not necessarily a flip-flop? | Sutherland RTL Modeling |
| 3 | Synthesis pragma `full_case parallel_case` — what does each do, and why is it dangerous? | Cummings SNUG-1999 |
| 4 | False path vs multi-cycle path — give an example of each. | Xilinx UG949 |
| 5 | Clock skew vs jitter — definitions and effect on timing. | `[[concepts/static_timing_analysis]]` |

## 11. Debug / methodology

| # | Question | Source |
|---|---|---|
| 1 | Tell me about a bug you debugged for >2 hours. (STAR) | `docs/POWER_SKILLS.md` §STAR |
| 2 | How do you decide if a bug is in your DUT or your testbench? | (waveform + scoreboard reasoning) |
| 3 | Walk me through coverage closure on a simple FIFO. | W7 + W12 |
| 4 | Functional vs code vs assertion coverage — what does each catch that the others miss? | Spear ch.9 |

## 12. Behavioural (STAR)

| # | Question | Source |
|---|---|---|
| 1 | Tell me about a time you disagreed with a teammate technically. | (your story) |
| 2 | Tell me about a project that didn't go as planned. | (your story) |
| 3 | What's a recent thing you taught yourself? Walk me through it. | This curriculum 😉 |
| 4 | When have you cut scope on a project? Why and how? | (your story) |
| 5 | Tell me about a time you missed an edge case. What did you change in your process? | (one of your STAR stories from `POWER_SKILLS.md`) |

---

## Stretch / post-graduation topics

These don't appear in the core 20 weeks but may come up in interviews
once you're past graduation:

- **AXI4 (full burst)** — beyond AXI-Lite. Read ARM AMBA spec ch.A.
- **Formal verification** — SymbiYosys (open) or commercial Jasper.
- **Low-power design** — UPF, clock gating, power domains.
- **Memory subsystem** — cache coherence (MESI), DRAM controllers.
- **PCIe / DDR / HBM** — high-speed serial protocols.
- **Custom-instruction extensions** for RISC-V.

When asked about something off-list, the right answer is "I haven't
worked with X directly, but here's how I'd approach learning it
based on Y from my plan."

---

## Self-mock procedure

See [`docs/POWER_SKILLS.md`](POWER_SKILLS.md) §5. Pick 5 questions
from the relevant category. Time yourself. Record. Listen back.

Cadence: W14 (UVM mock), W19 (CDC mock), W20 (full portfolio mock).
