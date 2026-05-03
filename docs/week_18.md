# Week 18: DSP II — 2D Image Convolution 🆕

> Phase 4 · Builds on W17 (1D FIR) + W7 (sync FIFO line buffers).
> Anchor for [[concepts/convolution_2d]].

## Why This Matters

A 3×3 streaming convolution engine is the unit cell of every imaging
pipeline (camera ISPs, computer vision accelerators, stencil
computations). The hardware design problem — assembling a 3×3 window
from a 1D pixel stream using row line-buffers — is general beyond
imaging: it appears in any convolutional operation over a 2D
sliding window.

## What to Study

### Reading — Verification

- **Spear ch.9 + ch.7** — covergroups for image-grid coordinates
  (corner, edge, interior pixels) and edge-padding mode.

### Reading — Design

- **Bailey *Design for Embedded Image Processing on FPGAs*, ch.7 —
  Window-based processing**. **TO VERIFY by Yuval**: not in local
  library; confirm acceptable as primary reference.
- **Xilinx XAPP933** *(alternative)* — free Xilinx app note on
  line-buffer architecture. Use if Bailey is unavailable.
- **Smith DSP guide** ch.24 — Linear image processing
  ([dspguide.com](https://www.dspguide.com)).

### Concept notes

- [[concepts/convolution_2d]] (anchor) · [[concepts/fir_filters]]
- [[concepts/sync_fifo]] · [[concepts/fixed_point_qformat]]

### Tool setup

```bash
pip3 install pillow numpy scipy   # PGM read + reference convolution
```

---

## Verification Homework

### Drill — line-buffer write/read pattern

*File:* `homework/verif/per_chapter/hw_line_buffer/lb_tb.sv`
Drive a single line-buffer (depth = image width) with a row of
pixels; verify they emerge after `width` cycles. Round-trip check.

### Connector — kernel sweep against scipy

*Folder:* `homework/verif/connector/hw_conv_golden/`
Drive a 64×64 grayscale PGM image (committed as test fixture in
`tb/fixtures/`) through the DUT. Reference =
`scipy.ndimage.convolve(image, kernel, mode='reflect')` (or
`'constant'` for zero pad). Pixel-level diff with Q1.15 tolerance.

Sweep three kernels per regression run:
- Sobel-x edge detector
- 3×3 Gaussian blur
- 3×3 sharpen (centre = 5, neighbours = -1)

### Big-picture — edge-mode coverage

*Folder:* `homework/verif/big_picture/hw_edge_modes/`
Add a parameter to the DUT for edge mode: `ZERO_PAD`, `REFLECT`,
`CLAMP`. Drive each mode through the same input image; cross
coverage on `(kernel_type × edge_mode × pixel_position)`.

---

## Design Homework

### Drill — single line buffer

*Folder:* `homework/design/per_chapter/hw_line_buffer/`
Sync FIFO of depth = configurable IMAGE_WIDTH. Streaming pixel
input, streaming pixel output `width` cycles later.

### Connector — 3×3 conv engine ⭐

*Folder:* `homework/design/connector/hw_conv_3x3/`

Architecture:

```
pixel_in →┐
          ├→ row[0]
          │
        row1 ←──── row[0] passed through line buffer 1 (FIFO depth = WIDTH)
          │
        row2 ←──── row1 passed through line buffer 2
          ↓
        ┌───────────────────┐
        │  3×3 window regs  │
        └───────────────────┘
          ↓
        9 multiplies + 8-input adder tree (qmac reuse)
          ↓
        round + saturate → pixel_out
```

Spec only — Yuval implements per Iron Rule.

### Big-picture — separable Gaussian (2× W17 reuse)

*Folder:* `homework/design/big_picture/hw_separable_gaussian/`
Implement the 3×3 Gaussian as **two passes of a 1D FIR** (the
W17 module), one horizontal pass into a temp line buffer + one
vertical pass. Compare LUT/FF count vs the monolithic 3×3 design.

---

## Self-Check Questions

1. Why does a 3×3 stencil need exactly two row buffers, not three?
2. Separable filter: when is it valid, and what's the count
   reduction (multiplies per output pixel)?
3. `mode='reflect'` vs `mode='constant'` (zero pad) — which gives
   you a clean Gaussian blur, and why?
4. At the bottom-right corner of the image, your sliding window
   walks off the edge. Walk through what your DUT does in each of
   the three edge modes, cycle by cycle.
5. Q1.15 coefficients × Q1.15 pixels — what accumulator width do you
   need to avoid overflow with a 9-tap kernel?

---

## Checklist

### Verification Track

- [ ] Read Bailey ch.7 OR Xilinx XAPP933 (TO VERIFY)
- [ ] Drill — line-buffer round-trip
- [ ] Connector — 3 kernels × scipy reference golden
- [ ] Big-picture — edge-mode coverage
- [ ] Iron Rule (a)/(b)/(c) ✓

### Design Track

- [ ] Drill — single line buffer
- [ ] Connector — 3×3 conv engine (monolithic)
- [ ] Big-picture — separable Gaussian (2× FIR)
- [ ] Yosys synth on both designs; LUT/FF compare
- [ ] Iron Rule (a)/(b)/(c) ✓

### Cross-cutting

- [ ] AI task — Waveform debug summary on edge-padding behaviour
- [ ] Power task — LinkedIn DSP-on-FPGA post with input/output diff
- [ ] `notes.md` updated

<!-- AUTO-SYNC: per-week views below — regenerate via tools/sync_week_docs.py; do not edit by hand below this line -->

## Daily-driver views

*Auto-mirrored from `week_18_dsp_image_conv/` — edit those files, then run `python3 tools/sync_week_docs.py` to refresh this section.*


---

### `README.md`

# Week 18 — Week 18: DSP II — 2D Image Convolution 🆕

> **Phase 4 — Portfolio + Advanced** · canonical syllabus: [`docs/week_18.md`](../docs/week_18.md) · ⬜ Not started

A 3×3 streaming convolution engine is the unit cell of every imaging
pipeline (camera ISPs, computer vision accelerators, stencil
computations). The hardware design problem — assembling a 3×3 window
from a 1D pixel stream using row line-buffers — is general beyond
imaging: it appears in any convolutional operation over a 2D
sliding window.

## Prerequisites

See [`docs/ROADMAP.md`](../docs/ROADMAP.md) §"Hard prerequisites" for
the dependency list. Refresh the relevant concept notes in
[`docs/concepts/`](../docs/concepts/) before starting.

## Estimated time split (24h total)

```
Reading        6h
Design         8h
Verification   8h
AI + Power     2h
```

(Adjust per week — UVM-heavy weeks shift hours into Verification;
RTL-heavy weeks shift into Design.)

## Portfolio value (what this week proves)

> Fill in 2–3 bullets when you start the week. The rule of thumb:
> what could you put on your CV after this week that you couldn't
> the week before?

## Iron-Rule deliverables

- [ ] **(a)** RTL committed and lint-clean.
- [ ] **(b)** Gold-TB PASS log captured to `sim/<topic>_pass.log`.
- [ ] **(c)** `verification_report.md` written.

## Daily-driver files

- [[learning_assignment]] · [[homework]] · [[checklist]] · [[notes]]

Canonical syllabus: [`docs/week_18.md`](../docs/week_18.md).

> ℹ️ This file was auto-generated by
> `tools/generate_week_daily_drivers.py`. Refine it by hand when
> you start the week — replace placeholders with concrete content.


---

### `learning_assignment.md`

# Week 18 — Learning Assignment

## Reading

The canonical reading list with chapter and page references lives at
[`docs/week_18.md`](../docs/week_18.md). When you start
the week, copy the **Reading — Verification** and **Reading — Design**
tables into this file with page-precise citations per `CLAUDE.md` §3.

## Concept notes to review/update

Browse [`docs/concepts/`](../docs/concepts/) and link to the relevant
notes here once you've identified them. Use `[[concepts/<slug>]]`
wikilinks so Obsidian's graph view shows the dependency.

## AI productivity task (this week)

**Type 5 — Waveform / debug summary (2D conv edge-padding behaviour)**

Use the matching template under [`docs/prompts/`](../docs/prompts/).
Time budget: 30 min. Output goes to `notes.md`.

## Power-skill task

LinkedIn — DSP-on-FPGA post with input/output image diff

Time budget: 30 min.

> ℹ️ Auto-generated stub. Replace with hand-crafted content when you
> start the week.


---

### `homework.md`

# Week 18 — Homework

The canonical homework list lives at
[`docs/week_18.md`](../docs/week_18.md). When you start
the week, port the **Drills**, **Main HWs**, and **Stretch** sections
here — but with explicit file paths, acceptance criteria, and run
commands using the `homework/` folder structure that already exists
in this repo.

## Per-chapter drills (TODO)

> Table: chapter → file path → 3-line spec → acceptance criteria.

## Connector exercise (TODO)

> Tie design + verif. Same DUT, both sides.

## Big-picture exercise (TODO)

> Mini-project within this week's scope only.

## Self-check questions (TODO)

> 5–8 questions answerable without looking. Answer keys at the
> bottom of this file once written.

## Run commands

```bash
cd week_18_*

# Native arm64 sim (Phase 1/2 default)
verilator --lint-only -Wall <rtl_file>.sv
iverilog -g2012 -o /tmp/sim <tb_file>.sv && vvp /tmp/sim

# UVM (Phase 3, when needed)
bash ../run_xsim.sh -L uvm <files>

# Yosys schematic
bash ../run_yosys_rtl.sh <rtl_file>.sv
```

> ℹ️ Auto-generated stub. Replace with concrete homework content
> when you start the week.


---

### `checklist.md`

# Week 18 — Checklist

## Reading

- [ ] Verification reading (per `learning_assignment.md`)
- [ ] Design reading (per `learning_assignment.md`)
- [ ] Concept notes reviewed/updated

## Per-chapter drills

- [ ] (fill in from canonical `docs/week_18.md`)

## Main HWs

- [ ] (fill in from canonical `docs/week_18.md`)

## Iron-Rule deliverables

- [ ] (a) RTL committed and lint-clean
- [ ] (b) Gold-TB PASS log captured to `sim/<topic>_pass.log`
- [ ] (c) `verification_report.md` written

## Cross-cutting weekly tasks

- [ ] **AI productivity task** — Type 5 — Waveform / debug summary (2D conv edge-padding behaviour)
- [ ] **Power-skill task** — LinkedIn — DSP-on-FPGA post with input/output image diff
- [ ] `notes.md` updated with at least 3 entries this week

> ℹ️ Auto-generated stub. Refine the day-by-day breakdown when you
> start the week.


---

### `notes.md`

# Week 18 — Notes

## Open questions

> (none yet — add as they come up while reading or coding)

## Aha moments

> (none yet)

## AI corrections

> Track any time AI confidently said something the book contradicted.

## Methodology lessons

> One paragraph per debug session worth remembering.

