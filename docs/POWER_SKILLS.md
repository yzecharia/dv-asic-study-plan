# Power Skills — Career-Readiness Tasks Woven Weekly

The technical curriculum is necessary but not sufficient for landing
a junior RTL/DV role at NVIDIA-tier shops. Recruiters skim LinkedIn
in 7 seconds. Hiring managers ask STAR-format behavioral questions in
the first interview. You walk into the room with a 90-second
elevator pitch whether you wrote one or not — better to write it.

Each week's `checklist.md` ends with a 30-minute task drawn from the
sections below. Do the task even if it feels low-priority — these
compound.

---

## 1. STAR stories

The interview format every behavioral question expects:
**S**ituation, **T**ask, **A**ction, **R**esult.

### Template

```
Situation:  Brief context. Where, when, what was happening.
            (1-2 sentences. No company internals if you don't have permission.)
Task:       What you were specifically asked or expected to do.
            (1 sentence. Keep "I" not "we".)
Action:     What YOU did. Be specific — tools, decisions, why.
            (3-5 sentences. The interviewer wants to hear *how you think*.)
Result:     The outcome. Quantify if possible.
            (1-2 sentences. Acknowledge what didn't work too.)
```

### Example — UVM debug story (filled in)

```
Situation:  In W4 of my self-study plan I built a UVM testbench for a
            TinyALU using Salemi's UVM Primer factory pattern. After
            my first compile, the test ran but produced no UVM_INFO
            output and exited cleanly with 0 phase objections.
Task:       Figure out why no test sequence was actually running.
Action:     I added a UVM_INFO at start_of_simulation_phase to
            confirm the env was constructed. It wasn't — the
            uvm_config_db lookup in my env's build_phase had a typo
            in the field path ("alu_seq_cfg" vs "alu_seq_config").
            Used uvm_config_db::dump() to print the actual config DB
            contents and saw the mismatch. Fixed the path, added a
            self-check assertion that fails if config retrieval
            returns 0.
Result:     Test ran end-to-end. The lesson — uvm_config_db lookups
            fail silently — got a permanent assertion guard in my
            env builder. I now wrap every config_db get with a
            `if (!uvm_config_db::get(...)) `uvm_fatal(...)`.
```

### Story bank to draft (target: 8 stories by W20)

Keep one Markdown file per story under `docs/star_stories/` (folder
not committed yet — create when you write the first story).

| # | Topic | Source week | Status |
|---|---|---|---|
| 1 | UVM bug — config_db silent failure | W4 | ⬜ template above |
| 2 | CRV constraint solver picked the wrong distribution | W2 | ⬜ |
| 3 | FSM glitch caught by SVA | W3 | ⬜ |
| 4 | Async FIFO empty/full edge case | W7 | ⬜ |
| 5 | RISC-V pipeline hazard you missed first | W9 | ⬜ |
| 6 | UART framing error you only caught with random injection | W10 | ⬜ |
| 7 | RAL backdoor vs frontdoor write trade-off | W14 | ⬜ |
| 8 | CDC metastability you debugged via MTBF reasoning | W19 | ⬜ |

Each story rehearsed for 30 sec / 2 min / 5 min versions.

---

## 2. LinkedIn

### Headline patterns (try at least 3, A/B over a month)

```
Pattern A — role-targeted, technical
"Junior Design Verification Engineer | SystemVerilog · UVM · RISC-V | Building a 20-week portfolio in the open"

Pattern B — outcome-focused
"Verifying RTL the way I'd want it verified | UVM · SVA · CDC | github.com/yzecharia"

Pattern C — story-driven (riskier, only if your About section delivers)
"From HDLBits to NVIDIA-tier — autodidact studying RTL/DV in public, 1 commit at a time"
```

### About section structure (300-500 chars)

```
Paragraph 1 — what you're studying and why (current role / goal)
Paragraph 2 — concrete portfolio (3 repos, 1 sentence each, link)
Paragraph 3 — what kind of role you want next (be specific:
              "Junior DV at a chip company, hybrid in [city]")
```

### Featured section (3 items only — recruiter scans this first)

1. UART-UVM repo (W12 deliverable).
2. RISC-V CPU repo (W13 deliverable).
3. Capstone repo or W19 CDC handshake demo (W19/W20 deliverable).

### Weekly LinkedIn task rotation

| Wk | Task |
|---|---|
| W2 | Iterate headline — pick pattern A. |
| W6 | Update About section to mention current phase (UVM). |
| W10 | Post one project highlight (your UART RTL, with waveform). |
| W14 | Update Featured to include W12-13 portfolio repos. |
| W18 | Post one DSP-on-FPGA highlight. |
| W20 | Final About refresh with capstone link + "open to opportunities" toggle on. |

---

## 3. Elevator pitch

90 seconds. Practise out loud. Record yourself. Listen back.

### Structure

```
Hook         (10s) — one specific thing that catches attention.
                     Not "I'm a junior" — say "I built a UVM testbench
                     for a UART that injects framing errors via
                     constrained random."
Background   (20s) — academic + autodidact path, current focus.
Portfolio    (30s) — name 2 repos, what each demonstrates.
What's next  (20s) — what role you want, what you want to learn.
Close        (10s) — invite a question.
```

### Example (filled in, 90 seconds)

```
"Hi — I'm Yuval. Most recently I built a UVM testbench for a UART
that uses constrained random to inject framing errors and
verifies the receiver responds with the right error flag. That's
one of three repos I've published this year as part of a 20-week
self-study plan I built to bridge HDLBits-level Verilog into
NVIDIA-tier RTL/DV interview-ready. The other two are a
parameterized async FIFO with full SVA coverage and a 5-stage
RISC-V CPU with hazard handling. I'm looking for a junior DV role
at a chip company where I can grow under a senior verification
lead. Happy to walk through any of the projects if you'd like."
```

Record three versions: 30 / 60 / 90 seconds. Re-record after each
phase milestone (W7, W11, W13, W20).

---

## 4. Resume

### Bullet patterns

Each bullet: **Action verb · what you did · technical detail · outcome.**

#### Examples

```
✅ Designed an 8-tap symmetric FIR filter in SystemVerilog with Q1.15
   coefficients and valid/ready handshake; verified against
   scipy.signal golden vectors with functional coverage on impulse,
   step, and saturation cases.

✅ Built a UVM environment with 5 sequences and 3 tests on a
   parameterized synchronous FIFO; closed functional coverage to
   100% across full/empty boundary cases and concurrent read/write
   transactions.

✅ Implemented a 5-stage pipelined RV32I CPU subset with
   forwarding and hazard detection; verified using a self-checking
   directed test suite and a constrained-random ALU regression
   against a Python reference model.
```

#### Anti-patterns to avoid

```
❌ "Worked on UVM testbenches"   — what did you build, what did it prove?
❌ "Used Verilog and Python"     — every other resume says this.
❌ "Strong communicator"         — show, don't tell.
```

### Weekly resume task rotation

| Wk | Task |
|---|---|
| W3 | Add Phase 1 bullet — "Built constrained-random TBs for sync FIFO and FSMs with cross-coverage." |
| W7 | Add Phase 2 bullet — "Built UVM env with scoreboard for register file." |
| W11 | Add Phase 3 bullet — "Implemented UART, SPI master, AXI-Lite slave with self-checking TBs." |
| W15 | Add synthesis bullet — "Synthesised UART-UVM and FIR designs with Yosys, reported LUT/FF/Fmax." |
| W19 | Add CDC bullet — "Designed and verified multi-bit handshake CDC with formal-style SVA bundle." |

---

## 5. Mock interview practice

### Cadence

- **W14** — first mock: focus on UVM (RAL, factory, sequences).
- **W19** — second mock: focus on CDC + design depth.
- **W20** — third mock: full portfolio walkthrough.

Question bank in [`docs/INTERVIEW_PREP.md`](INTERVIEW_PREP.md).

### Self-mock procedure

1. Pick 5 questions from `INTERVIEW_PREP.md`.
2. Set a timer; answer aloud, recording yourself.
3. Listen back at 1.5×; note where you rambled or hesitated.
4. Rewrite the answer in `notes.md`. Practise once more.

If you have a friend in the industry, ask for a 30-min mock — but
only after you've done at least one self-mock for that question set.

---

## 6. Public-speaking practice

You will present your portfolio in interviews. Practise:

- Recording a 2-minute screen-share of you running a sim and
  narrating what you see (W12, W18).
- Explaining a waveform to a non-DV friend (parents count) — if they
  can follow, an interviewer can.
- Posting one technical thread per phase milestone (LinkedIn, X, or a
  blog) — the act of publishing exposes weak phrasing.

---

## 7. Time and task management

The weekly time budget (per `week_NN_*/README.md`):

```
Reading       6h
Design        8h
Verification  8h
AI + Power    2h
================
Total         24h / week (≈3.5h/day)
```

Hold this budget by:

- **Day-1 plan**: open `checklist.md`, mark which day you'll tackle
  each item.
- **End-of-day commit**: even if just notes. Visible streak →
  motivation.
- **End-of-week review**: 10 minutes Friday — what got cut, what
  carries over, what's the next AI task.

Skip a day, don't skip the week. Skip a week (sometimes life
happens), don't skip the phase.
