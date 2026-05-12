# Array Query Functions — `$bits`, `$dimensions`, `$left`/`$right`/`$size` etc.

**Category**: SV Language · **Used in**: parameterized RTL that adapts to incoming array shapes, generic verification routines, helper functions that must work for any width · **Type**: authored

Sutherland §5.5 (pp. 132–134) and §5.6 (pp. 134–135) introduce a family of system functions that report **shape information about an array or value**. They let you write width-agnostic code: a generic XOR-tree, a generic checksum, a function that works whether the array is `[0:N-1]` or `[N-1:0]`. Combined with `foreach` ([[foreach_loop]]), they cover almost every "iterate over something whose size is parameterized" case.

## The seven query functions

For an array with multiple dimensions, the **dimension argument `n`** counts from 1 at the **leftmost unpacked** dimension, continuing rightward through unpacked, then through packed. So for:

```systemverilog
logic [1:2][7:0] word [0:3][4:1];
//            ↑      ↑     ↑      ↑
//        packed-2  packed-1  unpacked-1  unpacked-2
//        (dim 4)   (dim 3)   (dim 1)     (dim 2)
```

Wait — re-checking Sutherland §5.5 (p. 132): "Dimensions begin with the number 1, starting from the **left-most unpacked dimension**. After the right-most unpacked dimension, the dimension number continues with the **left-most packed dimension**, and ends with the right-most packed dimension."

So for `logic [1:2][7:0] word [0:3][4:1];`:
- dim 1: `[0:3]` — leftmost unpacked
- dim 2: `[4:1]` — next unpacked
- dim 3: `[1:2]` — leftmost packed
- dim 4: `[7:0]` — rightmost packed

| Function | Returns | Example value for `word` |
|---|---|---|
| `$dimensions(array)` | Total dim count | 4 |
| `$left(array, n)` | The "left" (MSB) index of dim `n` | `$left(word,1)` = 0, `$left(word,3)` = 1 |
| `$right(array, n)` | The "right" (LSB) index of dim `n` | `$right(word,1)` = 3, `$right(word,2)` = 1 |
| `$low(array, n)` | The smaller of left/right | `$low(word,2)` = 1, `$low(word,3)` = 1 |
| `$high(array, n)` | The larger of left/right | `$high(word,2)` = 4, `$high(word,3)` = 2 |
| `$size(array, n)` | Element count of dim `n` | `$size(word,1)` = 4, `$size(word,4)` = 8 |
| `$increment(array, n)` | +1 if left ≥ right, else -1 | `$increment(word,1)` = -1, `$increment(word,2)` = +1 |

`$size(a, n) = $high(a, n) - $low(a, n) + 1`. Always positive.

`$increment(a, n) = sign of (left - right)`. Tells you the iteration direction implied by the declaration.

## `$bits` — total bit count of anything

```systemverilog
$bits(expression)
```

Works on any packed or unpacked array, struct, union, or expression. Returns the total bit count.

```systemverilog
bit   [63:0] a;                                 // $bits(a) = 64
wire  [3:0][7:0] c [0:15];                      // $bits(c) = 4×8×16 = 512
struct packed { byte tag; logic [31:0] addr; } d;   // $bits(d) = 8 + 32 = 40

$bits(a + b);    // = 128 if a and b are each 64-bit — width of the OPERATION
```

Critical points:
- Returns the **size of the operation result**, not just the LHS. `$bits(a + b)` reflects how SV sized the addition.
- Synthesizable when the argument is not a dynamic/associative array (the size is elaboration-time-constant).
- Use it for sanity-checking before a [[bit_stream_casting]] operation.

## When to use which

- **You need the total number of bits** → `$bits`.
- **You need to iterate a 0-based dimension and don't care about direction** → `foreach` (simplest) or `for (int i = 0; i < $size(a, n); i++)`.
- **You need to iterate a possibly non-0-based dimension or in a non-standard order** → use `$left` / `$right` / `$increment` so the loop adapts to either direction:

```systemverilog
for (int j = $left(array, 1);
     j != ($right(array, 1) + $increment(array, 1));
     j += $increment(array, 1))
    ...  // works whether array is [N-1:0] or [0:N-1]
```

That's the canonical "iterate dim 1 in declaration order, agnostic to direction" idiom (Sutherland §5.5, p. 133).

## Iterating dimensions of an unknown-shape array

```systemverilog
logic [3:0][7:0] array [0:1023];

int d = $dimensions(array);            // = 3
if (d > 0) begin
    for (int j = $right(array,1);
         j != ($left(array,1) + $increment(array,1));
         j += $increment(array,1)) begin
        // ... do something with array[j]
    end
end
```

Use this in helper functions / verification utilities where you don't know the array shape at the call site.

## Synthesis

Synthesizable (Sutherland §5.5 p. 134) **provided**:
1. The array has fixed size (not dynamic / not associative).
2. The dimension argument is a **constant** (or omitted, which implies dim 1).

`$bits` is synthesizable except on dynamic arrays. The return value is elaboration-time-constant, so synth treats it as a literal.

## `$increment` quirk

`$increment` returns `+1` when `$left ≥ $right` (declaration like `[7:0]` — left is 7, right is 0, so left ≥ right, increment = +1). For `[0:7]`, left = 0, right = 7, so increment = `-1`.

This is the **opposite** of what you might guess if you think "increment means go forward." Read it as: "going from $left to $right, how do you change the index?" If left > right, you subtract. If left < right, you add.

So:
- `logic [7:0] a` — `$left=7, $right=0, $increment = -1` (going from 7 down to 0)
- `logic [0:7] a` — `$left=0, $right=7, $increment = +1` (going from 0 up to 7)

Wait, that's the opposite of what Sutherland says on p. 133: "Returns 1 if `$left` is greater than or equal to `$right`, and -1 if `$left` is less than `$right`."

Re-checking the example on p. 133: `$increment(array, 1)` returns -1 for `logic [3:0][7:0] array [0:1023]` — and `$left(array,1)` returns 0 (left of [0:1023]), `$right(array,1)` returns 1023. So $left < $right → $increment = -1.

Hmm — that's the **opposite direction**: $increment is the step to go from $right back to $left (i.e., for traversal in the direction left-to-right of the **declaration**).

So the canonical loop is:
```systemverilog
for (int j = $right(array,1);              // start at the "right" index
     j != $left(array,1) + $increment(array,1);  // stop just past "left"
     j += $increment(array,1))              // step
```

Which is `j = 1023; j != -1; j += -1` — iterating 1023 down to 0. Confusing but consistent if you read it as "walk from right to left, taking $increment-sized steps."

## Gotchas

1. **Dimension numbering surprises.** Unpacked first, then packed — `$left(word, 1)` on `logic [1:2][7:0] word [0:3][4:1]` returns 0 (the unpacked `[0:3]`), not 1 (the packed `[1:2]`). Easy to misread.
2. **`$increment` direction reversal.** As discussed above — read it as the step needed to traverse declaration left-to-right, **starting from the $right index**.
3. **`$bits` on signed expressions** returns the width of the result, including sign-extension when applicable. `$bits(int_a + int_b)` is 32 even if both inputs are smaller.
4. **Non-constant dim arg** makes the call non-synthesizable. The synth tool needs to evaluate the size at elaboration.
5. **`$size` returns 0 for empty unpacked arrays** but errors on the parameter being out of range. Always sanity-check `$dimensions(a) >= n` before calling `$size(a, n)`.

## Use case — generic CRC over any-width data

```systemverilog
function automatic logic crc1 (logic [N-1:0] data);
    crc1 = 1'b0;
    for (int i = 0; i < $bits(data); i++)
        crc1 ^= data[i];
endfunction
```

Works for any `N` because `$bits(data)` resolves at elaboration.

## Cross-links

- [[foreach_loop]] — simpler iteration when you don't need to ask about shape
- [[bit_stream_casting]] — use `$bits` to verify total widths match before casting
- [[packed_vs_unpacked]] — the dimension ordering rule that determines what `n` means

## Reading

- Sutherland *SV for Design* 2e — §5.5 (pp. 132–134), §5.6 (pp. 134–135)
- IEEE 1800-2017 §20.7 — "Array querying functions"
- IEEE 1800-2017 §20.6.2 — "Bit-width function `$bits`"
