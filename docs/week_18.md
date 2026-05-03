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
