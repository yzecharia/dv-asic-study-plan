# Carry-Lookahead Adder (CLA)

**Category**: Combinational · **Used in**: W4 (anchor — ch.12 drill: cla4 + lcu4 + cla16), W8 (RV32I ALU), W11 (address adders), W16 (Q-format MAC accumulator) · **Type**: authored

CLAs trade extra logic for log-depth carry propagation. A 16-bit CLA
computes its carry chain in roughly `log4(16) = 2` block delays
instead of the 16 ripple delays a chained full-adder pays. The
implementation looks simple at the 4-bit primitive level but requires
careful **hierarchical** structure to scale beyond 4–8 bits without
gate fan-in exploding.

## The fan-in trap — why hierarchy

A flat N-bit lookahead expresses each carry as a sum of products:

```
c[k+1] = g[k]
       | p[k]·g[k-1]
       | p[k]·p[k-1]·g[k-2]
       | ...
       | p[k]·p[k-1]·…·p[0]·cin
```

For `N = 4` this is 5 product terms each with ≤ 5 inputs — easy. For
`N = 16` you get a 17-input AND gate inside a 17-input OR. Modern
silicon libraries cap useful fan-in at ~6–8; beyond that the
synthesis tool unrolls into multi-stage gates and **all the speedup
disappears**.

**Solution**: build a 4-bit CLA primitive, then stack four of them
behind a *Lookahead Carry Unit* (LCU). The LCU computes inter-block
carries in O(log4) depth using **block-level** generate/propagate
descriptors. Same trick recurses: four 16-bit CLAs + 1 LCU = 64-bit
CLA. The same `lcu4` module is reused at every level.

---

## Bit-level algebra (the cla4 primitive)

Per bit `i`:

| Signal | Equation | Meaning |
|---|---|---|
| `g[i]` | `a[i] & b[i]` | bit generates a carry regardless of cin |
| `p[i]` | `a[i] ^ b[i]` | bit propagates an incoming carry |
| `c[i+1]` | `g[i] \| (p[i] & c[i])` | carry out of column i |
| `s[i]` | `p[i] ^ c[i]` | sum bit i |

Use **`g = AND`, `p = XOR`** — not `p = OR`. The OR form works
algebraically but breaks the clean derivation `s = p ^ c`. Junior
mistake: implementing `g = a | b`; the adder will accidentally
generate carries that don't exist (a corner first surfaced in W4 ch.10
ripple-carry drill).

Unrolled for a 4-bit block:

```
c[1] = g[0] | p[0]·cin
c[2] = g[1] | p[1]·g[0]              | p[1]·p[0]·cin
c[3] = g[2] | p[2]·g[1] | p[2]·p[1]·g[0] | p[2]·p[1]·p[0]·cin
cout = g[3] | p[3]·g[2] | p[3]·p[2]·g[1] | p[3]·p[2]·p[1]·g[0]
                                          | p[3]·p[2]·p[1]·p[0]·cin
```

Each carry is a single-stage AND-OR computed in parallel from the
input g/p values. **The speedup over ripple is that no carry waits on
any other carry** — they're all peers, computed simultaneously.

---

## Block-level recursion (the deep insight)

The cla4 exposes two **block descriptors** that summarise its
behaviour to the level above:

- **BG (block-generate)** — *"this 4-bit block produces a carry-out
  regardless of cin"*
  ```
  BG = g[3] | p[3]·g[2] | p[3]·p[2]·g[1] | p[3]·p[2]·p[1]·g[0]
  ```
- **BP (block-propagate)** — *"this 4-bit block transparently forwards
  any cin to its top"*
  ```
  BP = p[3] & p[2] & p[1] & p[0]     // = &p in SV reduction syntax
  ```

The actual block carry-out, given a specific cin:

```
block_cout = BG | (BP & cin)
```

**This relation has the exact same shape as the bit-level recurrence
`c[i+1] = g[i] | (p[i] & c[i])`.** A 4-bit block, when described by
its BG/BP, behaves *identically to a single "fat bit"* to the level
above. That's the recursive symmetry — same algebra at every level
of hierarchy.

Equivalently, **`BG = block_cout` when cin = 0**. This is the trick
that lets a verification testbench reuse the same golden-recurrence
function for both `carry_out` and `BG`-grp checks: just call it twice
with different cin values.

---

## Hierarchical architecture (cla16 = 4× cla4 + 1× lcu4)

```
                                    cin (top-level)
                                     │
                                     ▼
   bits [3:0]            bits [7:4]            bits [11:8]           bits [15:12]
 ┌────────────┐        ┌────────────┐        ┌────────────┐        ┌────────────┐
 │  cla4 b0   │        │  cla4 b1   │        │  cla4 b2   │        │  cla4 b3   │
 │ .ci ◄─cin  │        │ .ci ◄─c[1] │        │ .ci ◄─c[2] │        │ .ci ◄─c[3] │
 │ .s   .bg   │        │ .s   .bg   │        │ .s   .bg   │        │ .s   .bg   │
 │   .co (n/c)│        │      .bp   │        │      .bp   │        │      .bp   │
 │      .bp   │        │   .co (n/c)│        │   .co (n/c)│        │   .co (n/c)│
 └──┬──────┬──┘        └──┬──────┬──┘        └──┬──────┬──┘        └──┬──────┬──┘
    │      │              │      │              │      │              │      │
   s[3:0] BG[0]/BP[0]   s[7:4] BG[1]/BP[1]    s[11:8] BG[2]/BP[2]  s[15:12] BG[3]/BP[3]
                              │                       │                     │
                              └───────────────┬───────┴─────────────────────┘
                                              ▼
                  ┌─────────────────────────────────────────────────────┐
                  │                       lcu4                          │
                  │   in:  BG[3:0], BP[3:0], cin                        │
                  │   out: c[3:1] (carries into b1, b2, b3)             │
                  │        carry_out  →  cla16 cout                     │
                  │        BG_grp, BP_grp  →  hierarchy hooks for cla64 │
                  └─────────────────────────────────────────────────────┘
```

Same pattern at every level:

| Module | Built from | Exposes |
|---|---|---|
| `cla4` | 4 bits | `BG`, `BP` |
| `cla16` | 4× `cla4` + 1× `lcu4` | `BG_grp`, `BP_grp` (look like `BG`, `BP` one level up) |
| `cla64` | 4× `cla16` + 1× `lcu4` | `BG_grp_64`, `BP_grp_64` |
| `cla256` | 4× `cla64` + 1× `lcu4` | … |

**The same `lcu4` module is reused at every level.** That's the
symmetry. There is no separate `lcu16` or `lcu64` — block descriptors
hide the inner structure perfectly.

> **Don't try to parameterise CLA with a `WIDTH` parameter and a
> single `generate` loop.** The flat lookahead expression's fan-in
> blows up. The "parameterisation" of CLA is hierarchical: separate
> wrappers per width, all reusing the same primitives.

---

## Lookahead Carry Unit (lcu4) equations

Given 4 BG/BP block descriptors and a cin, the LCU produces:

```
c[1] = BG[0] | BP[0]·cin
c[2] = BG[1] | BP[1]·BG[0] | BP[1]·BP[0]·cin
c[3] = BG[2] | BP[2]·BG[1] | BP[2]·BP[1]·BG[0] | BP[2]·BP[1]·BP[0]·cin

BG_grp = BG[3] | BP[3]·BG[2] | BP[3]·BP[2]·BG[1] | BP[3]·BP[2]·BP[1]·BG[0]
BP_grp = BP[3] · BP[2] · BP[1] · BP[0]                  // = &BP in SV

carry_out = BG_grp | (BP_grp · cin)                     // SAME shape as c[i+1] one level up
```

Notice the last line — `carry_out` is just `BG_grp | BP_grp·cin`
applied to a "fat bit." Compute `BG_grp` and `BP_grp` first, derive
`carry_out` from them in one line. **Don't write out the full 5-term
expansion for `carry_out` longhand** — every typo in those 16 ANDs
is a real bug, and you have a 1-line equivalent.

---

## Verification approach

The pattern for any optimised arithmetic circuit:

> Golden = the slow-but-obvious algorithm written procedurally in
> the testbench. DUT = the fast-but-tricky optimised version.

For CLA specifically:

| Module | Golden | Stimulus |
|---|---|---|
| `cla4` | SV `+` operator on `a, b, ci` | 8 directed corners + 1000 random |
| `cla16` | SV `+` operator on full operands | 8 directed corners + 1000 random |
| `lcu4` | 4-iteration ripple recurrence in a function | exhaustive 16×16×2 = 512 vectors |

The LCU has only `2^9 = 512` input combinations — exhaustive is cheap
and gives airtight proof. For 16-bit operand-level adders,
exhaustive is `2^33 ≈ 8.6 G` — use directed + random instead.

For `BG_grp` checks specifically: call the recurrence golden with
`cin = 0` and take the carry-out bit. `BG_grp == carry_out @ cin=0`
by definition, so this gives an independent check without rewriting
the formula.

### Standard directed corners for any CLA TB

- `0x0…0 + 0x0…0 + 0` — sanity zero
- `0x0…0 + 0x0…0 + 1` — cin-only
- `0xF…F + 0x0…1 + 0` — full-carry-chain (would catch a g/p bug
  immediately)
- `0xF…F + 0xF…F + 1` — max sum
- `0x80…0 + 0x80…0 + 0` — top-bit-only generate
- `0x55…5 + 0xAA…A + 0` — every-bit propagate, none generate
- `0x7F…F + 0x0…1 + 0` — carry stops at MSB

For cla16, add `0x0FFF + 0x0001 + 0` (full-chain through 12 bits) —
exercises every inter-block carry the LCU computes.

---

## PPA quick reference

| Adder structure | Critical path (gate delays) | Area cost vs ripple |
|---|---|---|
| Ripple-carry 16-bit | ~16 | 1× |
| CLA 16-bit (4× cla4 + lcu4) | ~3 | 2× |
| Carry-select 16-bit | ~6 | 2.5× |
| CLA 64-bit (3-level hierarchy) | ~5 | 3× |

Modern FPGAs internally use dedicated carry-select chains in the LUT
fabric. Hand-coded CLA rarely beats the synthesizer's default `+` on
FPGA targets — but for **ASIC** datapaths where you control gate
selection and floorplan, explicit CLA hierarchy gives predictable
log-depth carry timing that synthesisers can't always rediscover.

## Reading

- Dally & Harting *Digital Design: A Systems Approach* ch.12 (fast
  arithmetic) — primary reference for hierarchical CLA.
- Harris & Harris *Digital Design and Computer Architecture: RISC-V*
  ch.5 §5.2 — adder structures comparison.
- Sutherland *RTL Modeling with SystemVerilog* — operators chapter,
  synthesis behaviour of `+`.
- Cummings *Synthesis Coding Styles for Efficient Designs* SNUG-2012.

## Cross-links

- `[[adders_carry_chain]]` — high-level adder taxonomy (this note is
  the deep dive on CLA).
- `[[multipliers]]` — Wallace/Dadda trees use CLA-style structures
  for the final-add stage.
- `[[signed_arithmetic]]` — same hardware, different sign-extension
  rules.
- `[[ppa_tradeoffs]]` — when CLA wins vs ripple vs carry-select.
- `[[fsm_encoding_styles]]` — separate theme but same lesson:
  hierarchical decomposition beats flat parameterisation.
