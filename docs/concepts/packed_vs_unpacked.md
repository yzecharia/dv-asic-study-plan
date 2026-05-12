# Packed vs Unpacked — Layout, Ports, and When to Pick Each

**Category**: SV Language · **Used in**: every week from W2 onwards (any module that crosses ports with bundled signals, any memory model, any transaction type) · **Type**: authored

The packed/unpacked distinction is the single most important new concept in Sutherland ch.5 (pp. 101–117). It controls **how the simulator stores your variable in memory**, which determines whether you can treat it as a vector, pass it through a port, slice it with a part-select, or apply arithmetic to it. It applies to structures, unions, AND arrays — the rules are unified.

## The one-sentence rule

**Packed** = stored as one contiguous bit-vector with a fixed layout. **Unpacked** = stored as independent named slots whose memory layout is up to the simulator.

That single sentence drives everything that follows.

## Packed structs (Sutherland §5.1.3, pp. 101–104)

```systemverilog
struct packed {
    logic        valid;     // bit 40
    logic [ 7:0] tag;       // bits 39:32
    logic [31:0] data;      // bits 31:0
} d_word;
```

Layout: left-to-right declaration = MSB-to-LSB in the resulting vector. Total width = sum of member widths. **No padding.**

Consequences:
- `d_word[39:32]` is exactly the same bits as `d_word.tag` — you can use either.
- Arithmetic and shift operators work: `d_word << 2`, `d_word + 1`, comparisons.
- All members must be **integral** types (bit, logic, reg, byte, int, longint, packed sub-types). No `real`, no unpacked anything inside a packed.

## Unpacked structs (Sutherland §5.1.3, p. 101)

```systemverilog
struct {
    logic        valid;
    logic [ 7:0] tag;
    logic [31:0] data;
} d_word;
```

Layout: simulator-defined. Members are grouped under one name but stored independently — possibly with padding for alignment.

Consequences:
- Cannot use `d_word[N:M]` part-select.
- Cannot do arithmetic on the whole struct.
- Can hold `real`, other unpacked structs, unpacked arrays — anything.
- Can only assign as a whole struct (via `'{...}` expression) or per-member.

## The same rule for arrays (Sutherland §5.3.1–5.3.2, pp. 113–117)

```systemverilog
// Packed dimensions go BEFORE the name
logic [3:0][7:0] data;     // 32-bit packed array, contiguous bits

// Unpacked dimensions go AFTER the name
byte mem [0:4095];         // unpacked array of 4096 bytes — stored independently

// Mixed: packed sub-fields inside unpacked slots (RAM idiom)
logic [63:0] mem [0:4095]; // each slot is one packed 64-bit word
```

Layout for `logic [3:0][7:0] data;` — packed:
```
bit:  31      23      15       7       0
     | data[3]| data[2]| data[1]| data[0]|     ← contiguous, vector
```

Layout for `wire [7:0] table [3:0]` — unpacked: each `table[i]` is its own 8-bit slot, possibly padded out to 16 or 32 bits in actual simulator memory.

## Why this matters at module boundaries

Packed types behave like vectors → they pass through ports the way any wide signal does.

Unpacked types are passable too (SV extends Verilog here, Sutherland §5.3.10) BUT both sides of the port must have **identical layout, element type, dimension count, and dimension sizes**. The wire on the other side can't be a different shape with the same total bit count.

Practical implication:
- **Cross-module bundled signals → use packed structs.** Single port, one vector, ports/synth/lint all happy.
- **Memory models, BFM-side multi-word state → unpacked arrays.** You're indexing one element at a time, not slicing a vector.
- **Reference models in TBs, RAL fields → packed structs.** You'll want to read/write sub-fields by name AND by bit range.

## The four array-copy cases (Sutherland §5.3.6, pp. 123–124)

| From | To | Direct copy? | Why |
|---|---|---|---|
| packed | packed | ✅ | vector → vector, standard truncate/extend rules |
| unpacked | unpacked | ✅ if same layout & type | element-by-element copy |
| unpacked | packed | ❌ — need bit-stream cast | unpacked has no defined bit order |
| packed | unpacked | ❌ — need bit-stream cast | packed vector ≠ independent slots |

See [[bit_stream_casting]] for the cast mechanics.

## Decision tree

```
Need to bundle multiple signals into one port?
  └─ Yes → packed struct (typedef in a package)

Need a 1-D array where you access one element per cycle? (RAM, ROM, lookup table)
  └─ Yes → unpacked array

Need a 2-D vector with sub-field access?
  └─ Yes → multi-dim packed array

Need to mix real, abstract types, or store transactions?
  └─ unpacked struct / unpacked array

Need to pass arbitrary-typed bundles between modules?
  └─ packed where possible; unpacked only with matched layouts on both sides
```

## Gotchas

1. **`logic [32] x;` is a syntax error.** Packed dimensions must be ranges, not sizes. `logic [31:0] x` is correct.
2. **Packed dim before the name, unpacked dim after.** Easy to swap. `logic [3:0] a [7:0]` and `logic [7:0] a [3:0]` are different shapes.
3. **A packed struct containing `real` is illegal.** `real` is non-integral. Compiler error at elaboration.
4. **Synthesis tools accept both** packed and unpacked structures (Sutherland §5.1.6). Don't assume unpacked = simulation-only.
5. **You can pack a packed (nest them)** — `struct packed { logic [3:0][7:0] data; ... }` is legal. You cannot put unpacked anything inside a packed.

## Cross-links

- [[structure_expressions]] — `'{...}` syntax for assigning to either packed or unpacked
- [[bit_stream_casting]] — the cast you need when shapes don't match
- [[sv_unions]] — same packed/unpacked rules apply to unions
- [[foreach_loop]] — how iteration interacts with packed/unpacked dimension counts
- [[array_query_functions]] — `$bits` / `$size` / `$dimensions` operate on both kinds

## Reading

- Sutherland *SV for Design* 2e — §5.1.3 (pp. 101–104), §5.3.1–5.3.3 (pp. 113–118)
- IEEE 1800-2017 §7.4 — "Packed and unpacked arrays"
- IEEE 1800-2017 §7.2.1 — "Packed structures"
