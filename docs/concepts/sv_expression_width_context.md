# SystemVerilog Expression Width — Context-Determined vs Self-Determined

**Category**: SystemVerilog · **Used in**: W1+ (silent in early weeks), W5 (anchor — bit Yuval in HW1's `cp_carry`), every subsequent arithmetic-on-narrow-types comparison · **Type**: authored

The single most common SV gotcha that silently produces wrong results: **an arithmetic operator's effective width depends on its surrounding context**, not on its operands. Get the context wrong and the operator truncates inside; you get a value that's mathematically wrong but compiles clean and runs silently.

## The bug that anchored this note

In a coverage class, this coverpoint never hit its `carry` bin in 1000 random ADD operations:

```systemverilog
cp_carry: coverpoint ((cmd.op == OP_ADD) && (cmd.a + cmd.b > 8'hFF)) {
    bins carry    = {1};      // never reached
    bins no_carry = {0};
}
```

`cmd.a` and `cmd.b` are 8-bit. The intent: "this command is an ADD with carry-out." For `cmd.a == 8'hFF` and `cmd.b == 8'h01`, the mathematical sum is `9'h100` — clearly bigger than `8'hFF`. So `carry` should be 1.

But SV evaluates `cmd.a + cmd.b > 8'hFF` like this:

1. The outermost operator is `>` (comparison). Both sides are 8-bit (`cmd.a + cmd.b` self-determined as 8-bit because the wider operand inside is 8-bit; `8'hFF` is 8-bit).
2. The `+` therefore evaluates at 8-bit width.
3. `0xFF + 0x01` at 8 bits = `0x00` (carry out is dropped).
4. `0x00 > 0xFF` = false.
5. The `carry` bin is **unreachable**.

The fix:

```systemverilog
(({1'b0, cmd.a} + {1'b0, cmd.b}) > 9'h0FF)
```

Now both operands are zero-extended to 9 bits before the `+`. The `+` evaluates at 9-bit width. `9'h0FF + 9'h001 = 9'h100`. Comparison against `9'h0FF` works. `carry` bin populated.

## The two kinds of width determination

Per SV LRM 1800-2017 §11.6, every operand has two widths:

**Self-determined width:** the natural width of the operand standing alone. For literals, it's the declared width (`8'hFF` → 8 bits). For variables, it's the declared width. For expressions like `a + b`, it's the widest operand among them.

**Context-determined width:** how wide the operand actually evaluates **in this specific use**, taking into account the surrounding context (LHS of assignment, the other side of a comparison, etc.).

The rule: **the context determines the width** of all *context-determined* operators (most arithmetic, bitwise, conditional). Self-determined operators (comparisons, logical, reductions, shifts on shift-amount) ignore the wider context.

## The list — which operators are context-determined

Context-determined (width promoted to match RHS / LHS / wider sibling):
- `+`, `-`, `*`, `/`, `%`, `**` (arithmetic)
- `&`, `|`, `^`, `~`, `^~`, `~^` (bitwise)
- `?:` (conditional — the two branches are context-determined to the wider)
- Assignment RHS

Self-determined (use the operand's own width, ignore context):
- `==`, `!=`, `<`, `<=`, `>`, `>=` (comparison — operands extend to the wider operand only)
- `&&`, `||`, `!` (logical — produce 1-bit results)
- `&`, `|`, `^` reduction (with single operand — produce 1-bit results)
- `<<`, `>>`, `<<<`, `>>>` shift amount (right-hand operand)
- Concatenation `{a, b}`
- `'(...)` and `T'(...)` casts (cast operand is self-determined to the cast width)

The mnemonic: **comparison and logical are 1-bit-or-self-wide. Arithmetic and bitwise float to context.**

## Three flavors of the same trap

### Flavor 1: comparison narrows the arithmetic context

```systemverilog
logic [7:0] a, b;
if (a + b > 8'hFF) ...           // BUG: a+b evaluated at 8 bits, truncates
if (({1'b0, a} + {1'b0, b}) > 9'hFF) ...    // FIX: explicit 9-bit context
if (int'(a) + int'(b) > 8'hFF) ...           // FIX: cast forces 32-bit
```

This was the cp_carry bug. Any "did this overflow?" check on narrow types must zero-extend.

### Flavor 2: narrow LHS truncates arithmetic context

```systemverilog
logic [7:0] result_byte;
logic [7:0] a, b;
result_byte = a + b;             // expected: discard carry — INTENDED here
```

Here truncation is fine because we explicitly chose an 8-bit LHS. The compiler may warn "value may be truncated", but the behavior is what the code says.

### Flavor 3: wide LHS extends arithmetic context (the safe case)

```systemverilog
logic [15:0] sum;
logic [7:0] a, b;
sum = a + b;                     // a, b extend to 16 bits → no truncation
```

This is why your `predict()` function in the scoreboard works:

```systemverilog
function result_t predict(command_t cmd);
    result_t res;            // result_t is logic [15:0]
    case (cmd.op)
        OP_ADD: res = cmd.a + cmd.b;       // ✓ 16-bit context, no truncation
        OP_MUL: res = cmd.a * cmd.b;       // ✓ 16-bit context, 8×8 = 16-bit
        ...
    endcase
endfunction
```

The 16-bit `res` LHS forces the `+` and `*` to evaluate at 16-bit width. `0xFF + 0x01` correctly produces `0x0100`; `0xFF * 0xFF` correctly produces `0xFE01`. No truncation. The predict function is bug-free without needing zero-extension.

This is why the same width concern bit one piece of code (cp_carry) and not the other (predict) in the same file — different contexts, different widths.

## Defensive habits

1. **When checking for overflow/carry, always zero-extend before the arithmetic.** Don't trust comparison context.
2. **Cast to `int` for tester-side calculations.** `int'(a) + int'(b)` gives you 32-bit arithmetic — almost never overflows for 8/16/32-bit DV problems.
3. **Read the LHS first.** Whenever you're about to write an arithmetic expression, check the LHS or comparison context's width. If narrow, expect truncation; widen explicitly if you want to detect overflow.
4. **Tools warn (sometimes).** Vivado xvlog warns on some truncations. Don't rely on it — the cp_carry pattern produces no warning because the truncation happens *inside* a comparison, not on assignment.

## Reading anchor

Spear *SystemVerilog for Verification* ch.2 covers expression width rules with examples — required reading after this trap bites once. SV LRM 1800-2017 §11.6 ("Expression bit lengths") is the authoritative source but dense; Spear's chapter is the readable version.

## In your HW1 specifically

| Where the rule applied | What happened | Verdict |
|---|---|---|
| `coverage.svh` `cp_carry` | `cmd.a + cmd.b > 8'hFF` — comparison context 8-bit, truncated | ❌ Bug. Fixed with `{1'b0, ...}` extend. |
| `scoreboard.svh` `predict` ADD | `res = cmd.a + cmd.b` with `res` 16-bit | ✓ Correct. LHS width extends operands. |
| `scoreboard.svh` `predict` MUL | `res = cmd.a * cmd.b` with `res` 16-bit | ✓ Correct. 8 × 8 = 16-bit context. |
| DUT `res_reg <= bus.cmd.a + bus.cmd.b` for ADD | `res_reg` is 16-bit | ✓ Correct. Same context-width benefit. |

Three out of four context-extensions correct, one wrong. Coverage holes from this kind of bug are hard to spot from the report alone — the bin's hit count is just 0, indistinguishable from "haven't stimulated it yet." Always sanity-check that *any* of your arithmetic-on-narrow-types coverpoints actually can be reached given the operand range.
