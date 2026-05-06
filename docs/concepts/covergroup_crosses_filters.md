# Covergroup Crosses & Bin Filters (`cross`, `ignore_bins`, `illegal_bins`, `binsof`)

**Category**: SystemVerilog · **Used in**: W3 (anchor), W4+ (every UVM week with functional coverage), W7, W12, W14, W17, W18, W20 · **Type**: authored

Single coverpoints tell you **breadth** ("did we hit every op? every address corner?"); crosses tell you **depth** ("did we hit ADD with both operands at max?"). Combination bugs hide in the cross. This note covers cross syntax, the bin-explosion problem, and the four mechanisms (`ignore_bins`, `illegal_bins`, `binsof`, `intersect`) you use to keep crosses tractable.

## Why crosses matter

Two coverpoints, both at 100% individually, can still hide combination holes:

```systemverilog
coverpoint op             // 100% — every op was hit
coverpoint addr_corner    // 100% — every addr corner was hit
```

Doesn't mean **`WRITE` to address `0xFFFFFFFF`** was ever exercised — that combination might be the boundary case where the FIFO overflows. The cross tracks combinations:

```systemverilog
cross cp_op, cp_addr_corner    // tracks the Cartesian product
```

Now you can see that "WRITE × max_addr" was never hit. **Combination bugs** (overflow on WRITE only when addr is at the boundary, READ-after-WRITE corruption only when size = 32-bit, etc.) are exactly what crosses catch.

## Basic cross syntax

```systemverilog
covergroup cg_mem @(posedge clk iff valid);
    cp_op: coverpoint op {
        bins read  = {READ};
        bins write = {WRITE};
    }
    cp_addr: coverpoint addr {
        bins zero = {32'h0000_0000};
        bins max  = {32'hFFFF_FFFF};
        bins mid  = default;            // catch-all for everything else
    }
    cp_size: coverpoint size {
        bins b8  = {3'd0};
        bins b16 = {3'd1};
        bins b32 = {3'd2};
    }

    cross_op_addr_size: cross cp_op, cp_addr, cp_size;
endgroup
```

The cross creates **all combinations** by default: 2 × 3 × 3 = **18 cross bins**, named like `<read,zero,b8>`, `<write,max,b32>`, etc.

## The bin-explosion problem

Crosses multiply quickly. Add a fourth coverpoint with 4 bins → 18 × 4 = 72 bins. Five coverpoints with reasonable bin counts can produce 200+ cross bins. **Most of those bins are uninteresting.** You'll never close them all by random stimulus, and many shouldn't be closed at all.

Three filters keep crosses honest:

| Filter | Purpose | Counts toward goal? |
|---|---|---|
| `ignore_bins` | exclude **reachable but unimportant** combinations | No — removed from coverage % |
| `illegal_bins` | exclude **unreachable** combinations; flag if hit | No — but errors if hit |
| `binsof / intersect` | **select** a subset of cross bins to keep / name | Yes — the kept subset |

## `ignore_bins` — drop reachable-but-boring combinations

Pattern: "this combination is legal and might happen, but isn't a meaningful scenario." The bin is **removed from the cross**, so it doesn't count toward the goal *and* doesn't matter if it's never hit.

```systemverilog
cross_op_addr_size: cross cp_op, cp_addr, cp_size {
    ignore_bins zero_addr_with_b32_only =
        binsof(cp_addr.zero) && binsof(cp_size.b32);
}
```

Reads: "ignore the combinations where addr is zero AND size is 32-bit." Maybe you decide that "zero address with 32-bit size" is a meaningless corner.

The cross now has **18 − (matching combinations)** bins to close.

## `illegal_bins` — combinations that **must not happen**

Pattern: "this combination is forbidden by the spec; if it ever fires, the test should error."

```systemverilog
cross_op_addr_size: cross cp_op, cp_addr, cp_size {
    illegal_bins write_to_zero_8bit =
        binsof(cp_op.write) && binsof(cp_addr.zero) && binsof(cp_size.b8);
}
```

If a sample ever lands in this bin, the simulator emits a coverage error (severity depends on tool, but typically reported in the coverage summary). Use this for protocol violations the DUT shouldn't generate.

`illegal_bins` is the **assertion-like** flavor of filtering — "this should never be hit." `ignore_bins` is the **suppression** flavor — "this might be hit, but I don't care."

## `binsof()` and `intersect` — selecting specific cross bins

This is the powerful one — letting you **carve out specific named bins** from the cross instead of every Cartesian combination:

```systemverilog
cross_op_addr_size: cross cp_op, cp_addr, cp_size {
    bins read_corners = (binsof(cp_op.read) && (binsof(cp_addr.zero) || binsof(cp_addr.max)));
    bins write_max    = (binsof(cp_op.write) && binsof(cp_addr.max));
    bins multi_size   = binsof(cp_size) intersect {3'd1, 3'd2};   // any size that's b16 or b32
}
```

Only the **named bins above** count toward coverage; the rest of the Cartesian product is implicitly ignored. This is how you go from "track 200 bins" to "track 6 bins that actually matter."

| Operator | Meaning |
|---|---|
| `binsof(cp.bin_name)` | "select samples where coverpoint cp's bin `bin_name` was hit" |
| `binsof(cp) intersect { values }` | "select samples where cp's value is one of the listed values" |
| `&&` | logical AND across coverpoints (intersection of bins) |
| `\|\|` | logical OR within or across coverpoints (union of bins) |

**Read order:** when you see `binsof(cp_op.read) && binsof(cp_addr.max)`, it means "this cross bin records when **op was read AND addr was max** in the same sample."

## Auto-bin vs manual `binsof` — when to switch

| Approach | When to use |
|---|---|
| `cross cp_a, cp_b;` (no body) | small product (≤ 20 bins), every combination is interesting |
| `cross cp_a, cp_b { bins x = (binsof(...) && binsof(...)); }` | large product, only specific combinations matter |
| `cross cp_a, cp_b { ignore_bins ...; illegal_bins ...; }` | most combinations matter, a few don't / shouldn't |

Default to auto-bin until you see the bin count get out of hand, then add filters. Don't pre-filter speculatively — you'll mask real holes.

## Worked example — memory protocol coverage

```systemverilog
covergroup cg_mem @(posedge clk iff valid);
    cp_op: coverpoint op {
        bins read  = {READ};
        bins write = {WRITE};
    }
    cp_addr: coverpoint addr {
        bins zero  = {32'h0000_0000};
        bins low   = {[32'h0000_0001:32'h0000_FFFF]};
        bins high  = {[32'hFFFF_0000:32'hFFFF_FFFE]};
        bins max   = {32'hFFFF_FFFF};
    }
    cp_size: coverpoint size {
        bins b8  = {3'd0};
        bins b16 = {3'd1};
        bins b32 = {3'd2};
    }

    cross_op_addr_size: cross cp_op, cp_addr, cp_size {
        // Named bins for the combinations that matter
        bins read_boundary  = (binsof(cp_op.read)  && (binsof(cp_addr.zero) || binsof(cp_addr.max)));
        bins write_boundary = (binsof(cp_op.write) && (binsof(cp_addr.zero) || binsof(cp_addr.max)));
        bins all_sizes_max  = (binsof(cp_addr.max));            // any op × any size at max addr

        // Suppress the ~12 mid-range combinations that aren't interesting
        ignore_bins not_at_boundary =
            (binsof(cp_addr.low) || binsof(cp_addr.high));

        // Forbidden by spec: 32-bit access at the very top address (would overflow)
        illegal_bins write_b32_overflow =
            binsof(cp_op.write) && binsof(cp_addr.max) && binsof(cp_size.b32);
    }
endgroup
```

This cross declares **3 named bins to close** (`read_boundary`, `write_boundary`, `all_sizes_max`), **ignores** the boring middle-address combinations, and **flags** an illegal combination — all in 10 lines. Compare to letting the auto-bin produce 24 (2 × 4 × 3) bins, of which only 3 are meaningful.

## Common gotchas

- **Forgetting `ignore_bins` updates coverage %.** If you have 24 auto-bins and `ignore_bins` removes 18, your goal is **6 bins** — not 24. The reported % is against the kept set.
- **`illegal_bins` doesn't fail the sim by default.** It records as an error in the coverage report; it doesn't `$fatal`. Pair with an SVA assertion if you want hard failure.
- **`binsof(cp_a)` without naming a specific bin.** Means "any sample with cp_a's value falling into any of cp_a's bins" — i.e., basically all samples. Useful with `intersect { values }` but rarely useful alone.
- **Mixing `&&` and `||` without parens.** SV evaluates left-to-right within precedence rules; if you mean `(A && B) || C`, write the parentheses. Don't trust the operator precedence to do what you want.
- **Naming a cross bin with `=` instead of `:`.** Cross bin syntax is `bins <name> = (expression);`. Coverpoint bin syntax has both `=` (range/list) and `: ` (when used with `iff` or transitions). Crosses use `=`.
- **Bin name collisions.** Two cross bins with the same name → the second silently overrides the first. Use distinct names.
- **`cross_<x>: cross cp_a, cp_b` vs `cross cp_a, cp_b`.** The `<name>:` label is the cross's own coverpoint name; without it, the cross gets an auto-generated name based on the coverpoints it includes. Always name your crosses — saves debugging "what's `cp_a__x__cp_b` in the report?".
- **Sampling on a stale value.** Crosses sample whatever is in the coverpoint expressions at the moment `cg.sample()` (or the auto-event) fires. If you assigned a class member after the sample event, the cross sees the OLD value.

## Coverage-closure methodology with crosses

1. **Write the auto-bin cross first.** See the bin count.
2. **Run random tests.** Look at the holes report.
3. **For each hole, decide:**
   - "Is this important?" → leave it; the test isn't exercising it. Add a directed seq.
   - "Is this reachable but boring?" → `ignore_bins`.
   - "Is this *forbidden*?" → `illegal_bins` (and ideally an SVA `assert property`).
4. **Re-run.** Closure target is **100% on the kept set**, not 100% on the auto-bin set.
5. **Document `ignore_bins`** in a comment — future-you (or the next reviewer) will ask "why did we suppress this?" The why isn't obvious from the code alone.

## Reading

- Spear *SV for Verification* (3e) ch.9 — covergroups, including crosses, ignore/illegal bins, binsof/intersect.
- IEEE 1800-2017 §19.5 (coverage groups) and §19.7 (cross coverage).
- Verification Academy — coverage cookbook: https://verificationacademy.com/cookbook/coverage

## Cross-links

- `[[coverage_functional_vs_code]]` — the higher-level "why functional coverage matters" framing this note's syntax fits into.
- `[[uvm_subscriber_coverage]]` — where the covergroup typically lives in a UVM env.
- `[[sva_assertions]]` — pair `illegal_bins` with `assert property` for hard failures on forbidden combinations.
