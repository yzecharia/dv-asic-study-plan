# 2D Image Convolution

**Category**: DSP · **Used in**: W18 (anchor) · **Type**: authored

A 2D convolution applies a small kernel `K[m, n]` to a window
around each input pixel, producing an output pixel. For a 3×3
kernel:

```
y[i, j] = ΣΣ K[m, n] · x[i-1+m, j-1+n]   for m,n ∈ {0, 1, 2}
```

The hardware challenge: producing the 3×3 window from a streaming
pixel input requires storing the previous **two rows** in line
buffers.

## Architecture

```
pixel_in →┐
          ├→ row[0] (current row)
          │
        row1 ←──── row[0] passed through line buffer 1
          │
        row2 ←──── row1 passed through line buffer 2
          ↓
        ┌───────────────────┐
        │  3×3 window       │
        │  [a][b][c]        │   (a, b, c = current, prev, prev-prev pixel
        │  [d][e][f]        │    of each row, shifted as new pixels stream in)
        │  [g][h][i]        │
        └───────────────────┘
          ↓
        9 multiplies + 8-input adder tree
          ↓
        y[i, j]
```

Each line buffer is a sync FIFO of depth = image width × 1 pixel.

## Separable filters (often a win)

If the kernel is **separable** (`K = K_v ⊗ K_h`, e.g. a 3×3 Gaussian
blur), 2D conv can be computed as two 1D FIRs:

```
y_temp[i, j] = Σ K_h[n] · x[i, j-1+n]
y[i, j]      = Σ K_v[m] · y_temp[i-1+m, j]
```

This reduces 9 multiplies per pixel to 6 — and lets you reuse the
W17 FIR module twice.

## Edge handling

What happens at the image boundary where the 3×3 window has no
left/right/top/bottom neighbour? Three choices:

| Mode | Behaviour | Quality |
|---|---|---|
| **Zero pad** | treat off-image pixels as 0 | dark fringe at edges |
| **Mirror** | reflect across the boundary | best for low-frequency kernels (Gaussian) |
| **Clamp** | hold the edge pixel value | cheap; OK for most |

W18 verifies all three modes via functional coverage.

## Verification (W18)

- TB reads a 64×64 grayscale PGM (`P5` format) committed as a test
  fixture.
- Golden = `scipy.ndimage.convolve(image, kernel, mode='reflect')`
  (or `'constant'` for zero pad).
- Pixel-level diff with Q1.15 tolerance (~1 LSB acceptable due to
  rounding).
- Coverage: kernel type (Sobel-x, Sobel-y, Gaussian, sharpen) ×
  edge mode × image-size combinations.

## Reading

- Bailey *Design for Embedded Image Processing on FPGAs*, ch.7
  (windowed processing).
- Xilinx XAPP933 — alternative reference (free).
- Smith DSP ch.24 (linear image processing) — free online.

## Cross-links

- `[[fir_filters]]` — 1D building block.
- `[[sync_fifo]]` — line buffers are sync FIFOs.
- `[[fixed_point_qformat]]` — Q1.15 throughout.
