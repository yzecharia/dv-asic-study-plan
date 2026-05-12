# Structure / Array Expressions — `'{...}` Syntax and `default` Precedence

**Category**: SV Language · **Used in**: any module or testbench that initializes or assigns a struct/array literal value (every test, every reset block in RTL using structs, every reference model setting up a known state) · **Type**: authored

The `'{...}` syntax (apostrophe-brace, not just `{...}`) is SystemVerilog's way to construct **structure expressions** and **array expressions** — list-of-values literals used in initialization, assignment, and function-return contexts. Sutherland §5.1.2 (pp. 98–101) and §5.3.4 (pp. 119–122) cover the syntax. The two surprises are (a) the apostrophe is required, and (b) when you use `default`, there's a non-obvious precedence rule.

## The apostrophe matters

```systemverilog
// '{...} — STRUCTURE/ARRAY VALUE LIST. Element-by-element assignment.
struct_var = '{100, 5, 8'hFF, 0};
unpacked_arr = '{ '{7,3,0,5}, '{2,0,1,6} };

// {...} — VERILOG CONCATENATION. Builds one wide vector by joining bits.
packed_struct = {1'b1, 8'hF0, 32'h1234};       // legal: each element is a bit-vector
unpacked_arr  = {7, 3, 0, 5};                   // ILLEGAL in unpacked context
```

**Rule of thumb:** if you're filling a struct or array with one value per member/element, use `'{...}`. If you're building one wide bit-vector by gluing pieces, use `{...}`.

Sutherland §5.1.2 (p. 99) explains the history: early drafts of SV used plain `{}` for both, which clashed with Verilog's concatenation. The final standard added the apostrophe specifically to disambiguate.

## Structure expressions — three forms

### 1. Positional

Values in **declaration order**.

```systemverilog
typedef struct {
    logic [31:0] a, b;
    logic [ 7:0] opcode;
    logic [23:0] address;
} iw_t;

iw_t IW = '{100, 5, 8'hFF, 0};
//          ↑    ↑   ↑       ↑
//          a    b   opcode  address
```

Order matters. Wrong number of values = compile error.

### 2. Named

Use member names, any order.

```systemverilog
IW = '{address: 0, opcode: 8'hFF, a: 100, b: 5};
```

Order doesn't matter. Every member must appear exactly once. Cleaner for big structs; lets you change struct layout without breaking call sites.

### 3. Mixing positional and named — **illegal**

```systemverilog
IW = '{address: 0, 8'hFF, 100, 5};       // ❌ COMPILE ERROR
```

You can't mix the two styles inside one structure expression.

## Default values — the precedence rule

`default` lets you fill multiple members without naming every one.

```systemverilog
IW = '{default: 0};                       // every member ← 0
```

Combined with type-specific defaults:

```systemverilog
typedef struct {
    real    r0, r1;
    int     i0, i1;
    logic [ 7:0] opcode;
    logic [23:0] address;
} mixed_t;

mixed_t IW = '{ real: 1.0, default: 0 };
//             ↑          ↑
//        all reals     everything else
//          ← 1.0          ← 0
```

And combined with explicit named values:

```systemverilog
IW = '{ real: 1.0, default: 0, r1: 3.1415 };
//                              ↑
//                  r1 overrides "real:1.0"
//                  r0 still gets 1.0
```

### The precedence — Sutherland §5.1.2 p. 101

Three levels, lowest to highest priority:

1. **`default:` keyword** — applies to anything not otherwise specified. Lowest priority.
2. **Type-keyword default** (`real:`, `int:`, etc.) — applies to all members of that type. Overrides `default`.
3. **Explicit member name** — applies only to that one member. Highest priority.

So in `'{real: 1.0, default: 0, r1: 3.1415}`:
- `r1` is explicitly named → 3.1415.
- `r0` is `real` and not named → 1.0 (type rule).
- `i0`, `i1`, `opcode`, `address` are not named and not `real` → 0 (default rule).

**Mnemonic:** more specific wins. Name > type > default.

## Array expressions

The same `'{...}` syntax serves array literals. Sutherland §5.3.4 (pp. 119–122).

### Unpacked array

```systemverilog
int d [0:1][0:3] = '{ '{7,3,0,5}, '{2,0,1,6} };
// d[0] = {7,3,0,5}, d[1] = {2,0,1,6}
```

Nested `'{...}` per dimension. The **C shortcut of omitting inner braces is not allowed** — you need braces for every dimension.

### Replication shortcut

```systemverilog
int e [0:1][0:3] = '{ 2{7,3,0,5} };
// both rows are {7,3,0,5}
```

The `{n{...}}` syntax (no apostrophe in front of the inner `{n{...}}`) repeats the inner list `n` times. Don't confuse it with Verilog's concatenation `{n{vector}}` — context distinguishes.

### Default fill for arrays

```systemverilog
int  a1 [0:7][0:1023] = '{default: 8'h55};      // every element ← 0x55
byte a2 [0:3][0:3];

always_ff @(posedge clock, negedge resetN)
    if (!resetN) begin
        a2 = '{default: 0};                      // whole array
        a2[0] = '{default: 4};                    // just row 0
    end
```

### Type-keyword defaults work inside arrays of structs too

```systemverilog
typedef struct { real x; int n; } pt_t;
pt_t pts [0:1] = '{ '{real:1.0, default:0}, '{real:2.0, default:0} };
```

## Packed arrays / packed structs — different rules

For **packed** containers, you can use either:
- `'{...}` value list (Sutherland §5.3.5, pp. 122–123) — element-by-element
- `{...}` concatenation — when treating the packed thing as a vector

```systemverilog
logic [3:0][7:0] data;

data = '{8'hAA, 8'hBB, 8'hCC, 8'hDD};            // element-by-element
data = {8'hAA, 8'hBB, 8'hCC, 8'hDD};              // concatenation (vector)
data = 32'hAA_BB_CC_DD;                            // also fine — vector literal
```

All three end up storing the same bits. Match the convention used elsewhere in your file for consistency.

## Synthesis

Both structure expressions and array expressions are **synthesizable** (Sutherland §5.1.6 p. 105 and §5.3.13 p. 129). They lower to wire connections and constant initialization; no special hardware required.

The `default:` and type-keyword forms are particularly common in `always_ff` reset clauses because they let you reset a structured register without listing every member:

```systemverilog
always_ff @(posedge clk)
    if (rst)
        reg_struct <= '{default: 0};
    else
        reg_struct <= next_reg_struct;
```

## Gotchas

1. **Missing the apostrophe.** `{...}` for a structure value (without the leading `'`) is interpreted as concatenation. The compiler will accept it sometimes and silently produce wrong bit assignments, especially when widths happen to line up. Always use `'{...}` for structs and unpacked arrays.
2. **Wrong number of positional values.** `'{100, 5}` for a 4-member struct = compile error. Switch to named form for safety.
3. **Mixing positional + named** in the same expression = compile error.
4. **`default` value type mismatch.** `'{default: -1}` in a struct whose only members are `bit` types — depending on context, you may get truncation. The default value must be assignment-compatible with each receiving member's type, or castable to it.
5. **Replicator scope confusion.** `'{2 {7, 3}}` expands to 4 elements `{7,3,7,3}` (replicate `7,3` twice). Not `{14, 6}` (no double-the-value).
6. **Anonymous struct + value list = problems.** If your struct is anonymous, the value-list form works in the same module but the struct can't be passed through ports, so the value list won't survive the boundary. Typedef the struct.

## Quick reference card

```systemverilog
'{...}              // structure / unpacked array value list
'{a, b, c}          // positional
'{x:a, y:b, z:c}    // named
'{default: 0}       // fill all
'{type: val, default: 0}    // fill by type, then default
'{name: a, default: 0}      // explicit name beats default
'{type: a, name: b, default: 0}    // name > type > default

{...}               // Verilog concatenation (bits)
{n{...}}            // Verilog replication (bits)
'{n{...}}           // SV array-list replication (elements)
```

## Cross-links

- [[packed_vs_unpacked]] — the underlying distinction that drives which form you'll use
- [[sv_unions]] — unions use the same `'{...}` syntax (with the tag-write extension)
- [[bit_stream_casting]] — alternative when you're copying between *different* layouts

## Reading

- Sutherland *SV for Design* 2e — §5.1.2 (pp. 98–101), §5.3.4 (pp. 119–122)
- IEEE 1800-2017 §10.9 — "Assignment patterns"
- IEEE 1800-2017 §10.9.1 — "Array assignment patterns"
- IEEE 1800-2017 §10.9.2 — "Structure assignment patterns"
