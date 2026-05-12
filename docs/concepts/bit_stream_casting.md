# Bit-Stream Casting — Converting Between Incompatible Array/Struct Layouts

**Category**: SV Language · **Used in**: testbenches converting between packed and unpacked representations, instruction-register models with mixed array dimensions · **Type**: authored

Sutherland §5.3.7 (pp. 124–125) introduces a SystemVerilog-only operation that lets you copy values between arrays/structs whose **layouts don't match** but whose **total bit count does**. The mechanism is conceptually simple — flatten the source to a stream of bits, re-pack into the destination — but the syntax is unusual and the failure modes are silent.

## When you need it

Three of the four array-copy cases require bit-stream casting (see [[packed_vs_unpacked]]):

| From | To | Direct copy? |
|---|---|---|
| packed → packed | ✅ | (vector rules: truncate/zero-extend) |
| unpacked → unpacked, same layout | ✅ | (element-by-element) |
| unpacked → unpacked, different layout | ❌ | needs bit-stream cast |
| unpacked → packed | ❌ | needs bit-stream cast |
| packed → unpacked | ❌ | needs bit-stream cast |
| structure → array, or array → structure | ❌ | needs bit-stream cast |
| dynamic ↔ static sized array | ❌ | needs bit-stream cast |

In short: any time you're moving bits between two containers of different *shape* but identical *total bit count*, you need the cast.

## The syntax

```systemverilog
typedef int data_t [3:0][7:0];          // unpacked type (target)

data_t a;                                // unpacked array, shape [3:0][7:0]
int    b [1:0][3:0][3:0];                // unpacked array, different shape

a = data_t'(b);                          // ← bit-stream cast
```

Three things to notice:
1. **The destination must be a named type via `typedef`.** You can't cast to an anonymous on-the-spot type.
2. **The cast operator is `Type'(expression)`** — apostrophe-parenthesis, same as other SV static casts.
3. **The cast is unidirectional** by syntax — you cast TO the destination type by naming it.

## What the cast actually does

1. Walk through the source in *declaration order* (leftmost dimension outer, rightmost inner), packing every bit into one long stream.
2. Walk through the destination in *declaration order*, pulling bits off the stream and assigning them to each element.

Worked example:

```systemverilog
typedef bit [3:0] nybble_t;
typedef nybble_t  array_a_t [0:3];      // 4 nybbles = 16 bits

bit [15:0] vec;                          // packed 16-bit vector
array_a_t  arr;                          // unpacked array of 4 nybbles

// vec = 16'hA53C  (1010_0101_0011_1100)
arr = array_a_t'(vec);
// arr[0] = 4'hA, arr[1] = 4'h5, arr[2] = 4'h3, arr[3] = 4'hC
```

The leftmost bits of the source bit-stream become the *first* (lowest-index) element of the destination.

## The total-bit-count rule

```systemverilog
typedef int data_t [3:0][7:0];           // 4×8 ints = 32 ints × 32 bits = 1024 bits
int        b [1:0][3:0][3:0];             // 2×4×4 ints = 32 ints × 32 bits = 1024 bits ✓

a = data_t'(b);                           // legal — same total bits
```

If `$bits(source) != $bits(destination_type)`, the cast is illegal — most simulators error at elaboration. Some emit only a warning, so don't rely on the tool to catch it. Sanity-check with `$bits`:

```systemverilog
initial $display("source=%0d dest=%0d", $bits(b), $bits(data_t));
```

## Bit-stream cast vs. concatenation

These two operations *look* similar but are not the same:

```systemverilog
// Concatenation — explicit, packs in the order you write
vec = {arr[0], arr[1], arr[2], arr[3]};

// Bit-stream cast — implicit, packs in declaration order (which is element 0 first)
vec = bit_vec_t'(arr);
```

If your dimensions are simple, the two produce the same result. If your dimensions are multi-dimensional or include packed sub-types, the bit-stream walk follows the **dimension ordering rule from Sutherland §5.3.8** (unpacked first left-to-right, then packed left-to-right), which may not match the concatenation order you'd write by hand.

## The dynamic-array escape valve

Bit-stream casting is one of the few legal ways to convert between **fixed-size** and **dynamic** arrays:

```systemverilog
typedef int dyn_t [];                    // dynamic
typedef int fixed_t [0:9];

fixed_t f;
dyn_t   d;

d = dyn_t'(f);                           // d.size() = 10 after cast
f = fixed_t'(d);                         // only legal if d.size()*$bits(int) == $bits(fixed_t)
```

This is useful in TBs that bridge between fixed-shape RTL signals and variable-length verification artifacts (transaction queues, scoreboard payloads).

## Synthesis

**Synthesizable** (Sutherland §5.3.13, p. 129) — provided neither side is a dynamic, associative, or sparse array. The cast is "free" in synthesis: it produces wire renaming, not gates. The bit-walk order matters for correctness, not for cost.

## Gotchas

1. **Silent shape mismatches.** If `$bits(src) != $bits(dst)`, some simulators warn instead of erroring. The simulation then produces truncated or zero-extended garbage. Always sanity-check `$bits` if you're not sure.
2. **The destination must be a typedef.** `int a [...] = int [3:0][7:0]'(b);` — you cannot inline the destination type. Compiler error.
3. **Cast direction is not symmetric in syntax.** `a = data_t'(b)` works; you don't write `b = src_t'(a)` unless `src_t` is also a typedef.
4. **Bit-ordering surprises with nested types.** A `typedef struct packed { ... } inner_t; typedef inner_t outer_t [N];` — the cast walks structure members in declaration order, then array elements in index order. Easy to predict; hard to remember when the layout is dense.
5. **No padding / no realignment.** The bit-stream is exactly $bits wide. No simulator-added padding between elements, even if the destination is unpacked.

## When to NOT use bit-stream cast

If you're trying to *interpret* the same bits two ways, use a **packed union** ([[sv_unions]]) instead. Unions are zero-copy and stay in sync; bit-stream cast makes an independent snapshot at the moment of assignment.

## Cross-links

- [[packed_vs_unpacked]] — the cases that require this cast
- [[sv_unions]] — the alternative when you want two simultaneous views
- [[array_query_functions]] — `$bits()` for sanity-checking shape compatibility
- [[structure_expressions]] — alternative for explicit per-element copies

## Reading

- Sutherland *SV for Design* 2e — §5.3.7 (pp. 124–125)
- IEEE 1800-2017 §11.4.3 — "Bit-stream casting" — the formal definition
