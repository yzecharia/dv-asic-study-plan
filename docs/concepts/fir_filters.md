# FIR Filters

**Category**: DSP · **Used in**: W17 (anchor), W18 · **Type**: authored

A Finite Impulse Response filter computes `y[n] = Σ h[k] · x[n-k]` for
`k = 0..N-1`. It's a sliding multiply-accumulate over the last N
samples. Symmetric coefficients halve the multiplier count; pipelined
implementation pays one extra cycle of latency for full throughput.

## Direct-form structure

```
x[n] →[D]→[D]→[D]→  ...
       │   │   │
       h0  h1  h2 ...    (multiply)
       │   │   │
       └→ sum →─────→ y[n]
```

`D` is a 1-cycle delay (a flop). Each tap is a multiply-accumulate.

## Symmetric optimisation

For symmetric coefficients (`h[k] = h[N-1-k]`), pre-add the matching
input samples before multiplying — halves the number of multipliers
for an N-tap filter:

```
y[n] = h0(x[n] + x[n-N+1]) + h1(x[n-1] + x[n-N+2]) + ...
```

## SV skeleton (Yuval implements in W17, do not commit a full
solution from this file)

```systemverilog
module fir_8tap_sym #(
    parameter int W = 16,                  // sample width (Q1.15)
    parameter logic signed [W-1:0] H [4] = '{default: '0}
) (
    input  logic                  clk, rst_n,
    input  logic                  in_valid,
    output logic                  in_ready,
    input  logic signed [W-1:0]   in_data,
    output logic                  out_valid,
    input  logic                  out_ready,
    output logic signed [W-1:0]   out_data
);
    // 8-stage shift register; symmetric pre-adds; 4 multipliers; tree-add.
    // Yuval to implement per W17 HW spec.
endmodule
```

## Verification (W17)

- Golden vectors from `scipy.signal.lfilter` saved as hex via
  `np.savetxt('golden.hex', y.astype(np.int16).view(np.uint16),
  fmt='%04x')`.
- TB drives `x[n]` from `input.hex`; reads expected `y[n]` from
  `golden.hex`; checks per-sample with Q1.15 tolerance.
- Coverage: impulse, step, sinusoid at multiple frequencies,
  saturation events.

## Frequency response

For an interview answer: an N-tap FIR has linear phase (constant
group delay = `(N-1)/2`) iff coefficients are symmetric. The
magnitude response is whatever `np.fft.fft(h)` produces — a
low-pass / band-pass / high-pass shape depending on the coefficient
design (windowed-sinc, Parks-McClellan, etc.).

## Reading

- Smith *Scientist & Engineer's Guide to DSP* (free online),
  ch.14 (intro to digital filters), ch.15 (moving average filters),
  ch.16 (windowed-sinc filters) — dspguide.com.
- Dally & Harting ch.12 (pipelined arithmetic) for the pipeline
  scaffold.

## Cross-links

- `[[fixed_point_qformat]]`
- `[[multipliers]]`
- `[[ready_valid_handshake]]` — streaming interface.
- `[[convolution_2d]]` — 2D conv = separable 1D FIRs (W18).
