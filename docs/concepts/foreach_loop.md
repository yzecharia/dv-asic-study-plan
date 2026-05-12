# `foreach` — Array Iteration Without Hardcoding Dimension Sizes

**Category**: SV Language · **Used in**: parameterized RTL (gen_crc, parity trees, default-init), testbench initialization loops over transaction buffers, scoreboards iterating queues · **Type**: authored

Sutherland §5.4 (pp. 130–132) introduces a small but important addition: a loop construct that knows the shape of its iterand. You write the array name once, the language fills in the bounds. The benefit is reach: a parameterized array works in a parameterized loop, with no `$size` or `for (int i = 0; i < N; i++)` boilerplate.

## Syntax

```systemverilog
foreach (array_name[loop_var_list])
    statement;
```

The loop variables in the square brackets correspond, **in order**, to the dimensions of the array. Each variable iterates over its respective dimension. Variables are automatically declared, automatic, read-only inside the loop body, and have the index type of that dimension (usually `int`).

## Single-dimension example

```systemverilog
logic [7:0] data [0:255];

foreach (data[i])
    data[i] = 8'h0;             // i ranges 0..255
```

## Multi-dimensional example

```systemverilog
int sum [1:8][1:3];

foreach (sum[i, j])
    sum[i][j] = i + j;
// i iterates 1..8, j iterates 1..3
// the OUTER loop is the leftmost variable
```

Note the comma-separated list inside the same square brackets — not nested brackets. `sum[i][j]` inside the body is a regular indexed access.

## Iterating only some dimensions

You can skip dimensions by leaving the slot blank. The skipped dim does **not** iterate; the body sees the array as if that dim were a free index.

```systemverilog
function [15:0] gen_crc (logic [15:0][7:0] d);
    foreach (gen_crc[i])         // only iterate the [15:0] dim
        gen_crc[i] = ^d[i];      // XOR-reduce the inner 8 bits
endfunction
```

You can drop trailing dims entirely (no commas), or skip middle dims (use commas as placeholders):

```systemverilog
int a [1:4][1:4][1:4];

foreach (a[i])        ↔   foreach (a[i,,])     // iterate only outermost
foreach (a[,j,])                                // iterate only middle
foreach (a[i,,k])                               // iterate outermost + innermost
```

## Loop variable rules (Sutherland §5.4, p. 131)

1. **Implicitly declared** in the foreach header. You do not (and cannot) declare them elsewhere.
2. **Automatic.** Each entry creates fresh bindings.
3. **Read-only inside the body.** Assigning to them is illegal.
4. **Local scope.** They don't exist outside the loop body.
5. **Type** matches the indexing type of the corresponding dimension. For `int` arrays and standard `[hi:lo]` ranges, the type is `int`. Associative arrays may use the key type (`string`, `bit [k:0]`, etc.).

## Dimension order — unpacked first, then packed

When the array mixes packed and unpacked dimensions, **unpacked dimensions iterate first** (left to right), then packed dimensions (left to right). Same rule as the indexing convention from §5.3.8.

```systemverilog
logic [3:0][7:0] mixed [0:7][0:7];      // unpacked × 2, packed × 2

foreach (mixed[a, b, c, d])
    // a, b range over unpacked [0:7][0:7]
    // c, d range over packed [3:0][7:0]
    mixed[a][b][c][d] = '0;
```

## `foreach` vs. manual `for` loops vs. array query functions

```systemverilog
// All three iterate the same array. Pick the one with the right trade-offs.

// 1. foreach — concise, can't customize the iteration
foreach (a[i,j])
    sum += a[i][j];

// 2. for + $size — explicit bounds, can iterate in non-standard order
for (int i = 0; i < $size(a, 1); i++)
    for (int j = 0; j < $size(a, 2); j++)
        sum += a[i][j];

// 3. for + $left/$right/$increment — works even for non-zero-based dims
for (int i = $left(a,1); i != ($right(a,1) + $increment(a,1)); i += $increment(a,1))
    ...
```

**When to use `foreach`:** when you want every element, in declaration order, with no fancy iteration logic. ~90 % of cases.

**When to use a manual `for`:** when you need to break early, iterate backwards, skip every-other, or compute a non-trivial index expression.

**When to use query functions ([[array_query_functions]]):** when the array's bounds aren't 0-based or when you need to iterate part of a dimension.

## Synthesis

Synthesizable (Sutherland §5.4 implicit, confirmed in §5.5 p. 134 for query functions; foreach is synthesizable on the same conditions). Two requirements:

1. The array must be **fixed-size** (not dynamic, not associative, not sparse).
2. The loop body must itself be synthesizable.

For dynamic/associative arrays, `foreach` works at simulation only.

## Worked example — bit-vector parity using packed iteration

```systemverilog
function automatic logic parity (logic [31:0] data);
    parity = 1'b0;
    foreach (data[i])           // iterates 0..31 over the packed vector
        parity ^= data[i];
endfunction
```

Two lessons here:
- A packed vector counts as a 1-D packed array; `foreach` iterates over each bit.
- The body uses `parity ^=` to accumulate — totally normal procedural code.

## Gotchas

1. **Bracket placement.** `foreach (a[i,j])` is one bracket pair with a comma-list. `foreach (a[i][j])` is **a syntax error** — that's array indexing, not iteration declaration.
2. **Loop variables are read-only.** `foreach (a[i]) i++;` is illegal. Use `for` if you need to mutate the index.
3. **No `break` in `foreach`?** Wrong — `break` is legal (Sutherland §7.6, SV-2005). It exits the loop just like in `for`.
4. **Order matters when there are side effects.** `foreach` walks the array in declaration order. Don't assume it'll match a hand-coded reverse iteration.
5. **`foreach (q[i])` on a queue or dynamic array** works at simulation but not in synth (the array isn't fixed-size).

## Cross-links

- [[array_query_functions]] — `$size`/`$left`/`$right` for when `foreach` isn't expressive enough
- [[packed_vs_unpacked]] — dimension-order rules carry over from indexing to iteration
- [[structure_expressions]] — initialization shorthand; for any pattern that fits `'{default:X}`, prefer that over a foreach loop

## Reading

- Sutherland *SV for Design* 2e — §5.4 (pp. 130–132)
- IEEE 1800-2017 §12.7.3 — "The foreach-loop"
