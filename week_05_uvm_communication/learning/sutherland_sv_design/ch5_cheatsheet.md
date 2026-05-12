# Sutherland SV for Design — Ch.5 Cheat Sheet

> Arrays, Structures, and Unions (pp. 95–136, 2nd ed.)
>
> Quick-reference card. For the *why* behind each construct, see the
> concept notes linked at the bottom.

---

## 5.1 Structures

### Declaration

```systemverilog
// Anonymous (one-off; not portable across modules)
struct {
    logic [31:0] a, b;
    logic [ 7:0] opcode;
    logic [23:0] address;
} instruction;

// Typed (preferred — can cross module ports and tasks)
typedef struct {
    logic [31:0] a, b;
    logic [ 7:0] opcode;
    logic [23:0] address;
} instruction_word_t;

instruction_word_t IW;          // allocate a variable
```

**Scope rules:**
- Typed struct inside a module → that module only
- Typed struct in a package or `$unit` → reusable across modules

### Assignment (three patterns)

```systemverilog
// 1. Per-member
IW.a = 100;
IW.opcode = 8'hFF;

// 2. Positional structure expression ('{...} with single quote)
IW = '{100, 5, 8'hFF, 0};       // values in declaration order

// 3. Named structure expression
IW = '{address:0, opcode:8'hFF, a:100, b:5};   // any order

// Default fill
IW = '{default:0};              // every member to 0
IW = '{real:1.0, default:0};    // all real members → 1.0, rest → 0
IW = '{real:1.0, default:0, r1:3.1415};   // explicit name beats type beats default
```

**Critical:** SV uses `'{` (apostrophe-brace) to distinguish from Verilog's `{`
concatenation operator. Mixing positional and named in one expression is
illegal.

### Packed vs unpacked

```systemverilog
// Unpacked (default): members are independent variables grouped under one name
// Storage layout: implementation-defined, may have padding
struct {
    logic        valid;
    logic [ 7:0] tag;
    logic [31:0] data;
} d_unpacked;

// Packed: stored as a single contiguous vector (left-to-right = MSB-to-LSB)
struct packed {
    logic        valid;     // bit 40
    logic [ 7:0] tag;       // bits 39:32
    logic [31:0] data;      // bits 31:0
} d_packed;

// Operations on packed structs: behave like vectors
d_packed = d_packed << 2;       // legal — vector shift
d_packed[39:32] = 8'hF0;         // same as d_packed.tag
d_packed.tag    = 8'hF0;         // same bits

// Signed / unsigned: affects how the *whole struct* compares as a vector
typedef struct packed signed {
    logic        valid;
    logic [ 7:0] tag;
    logic signed [31:0] data;
} signed_t;
```

**Packed restrictions:** all members must be integral (bit/logic/reg/byte/int/longint/packed sub-types). No real, shortreal, unpacked struct/union/array.

### Passing through ports / tasks

```systemverilog
// Must be typed (via typedef) — anonymous structs can't cross module boundaries
package definitions;
    typedef struct {
        logic [31:0] a, b;
        opcode_t     opcode;
        logic [23:0] address;
        logic        error;
    } instruction_word_t;
endpackage

module alu (input definitions::instruction_word_t IW,
            input wire clock);
    ...
endmodule
```

### Synthesis

Both packed and unpacked structures are synthesizable.

---

## 5.2 Unions

A union stores a *single* value but allows multiple type interpretations.

### Three flavors

```systemverilog
// 1. Unpacked union — NOT synthesizable
union {
    int  i;
    real r;
} data;

// 2. Tagged union — runtime-checked, NOT widely synthesizable
union tagged {
    int  i;
    real r;
} data;

data = tagged i 5;          // store as int with implicit tag
d_out = data.i;             // OK — tag matches
d_out = data.r;             // ERROR at runtime — tag mismatch

// 3. Packed union — SYNTHESIZABLE, all members must be same bit-width
typedef struct packed {
    logic [15:0] source_address;
    logic [15:0] destination_address;
    logic [23:0] data;
    logic [ 7:0] opcode;
} data_packet_t;

union packed {
    data_packet_t packet;
    logic [7:0][7:0] bytes;     // same 64 bits, viewed as 8 bytes
} dreg;

// Now you can stream-in as bytes, read out as a packet
dreg.bytes[i] = byte_in;        // write byte-at-a-time
case (dreg.packet.opcode) ...   // read as packet
```

### Synthesis

- Packed unions ✅ synthesizable
- Unpacked unions ❌ not synthesizable
- Tagged unions ⚠️ intended synthesizable but compiler support is spotty

---

## 5.3 Arrays

### Unpacked vs packed dimensions — the cardinal distinction

```systemverilog
// Packed dimensions go BEFORE the name. The variable is treated as a vector.
logic [3:0][7:0] data;      // 2-D packed array — stored as 32 contiguous bits

// Unpacked dimensions go AFTER the name. Elements stored independently.
byte mem [0:4095];          // unpacked array of 4096 bytes (typical RAM)

// MIXED — packed sub-fields inside unpacked array slots
logic [63:0] mem [0:4095];  // RAM of 64-bit words
                            // [0:4095] unpacked, [63:0] packed per slot
```

**Layout diagram for `logic [3:0][7:0] data;`:**
```
31      23      15      7       0
| data[3] | data[2] | data[1] | data[0] |    ← contiguous, no padding
```

### Declaration styles

```systemverilog
// Verilog-style range
reg  [15:0] RAM [0:4095];           // [0:4095] = 4096 elements
int  i  [7:0][3:0][7:0];            // 3-D unpacked

// SV C-style size (unpacked only; equivalent to [0:size-1])
logic [31:0] data [1024];           // ≡ data [0:1023]

// Packed must use range, NOT size
logic [32] d;                       // ❌ ILLEGAL
logic [31:0] d;                     // ✅
```

### Initialization at declaration

```systemverilog
// Packed array — init like a vector
logic [3:0][7:0] a = 32'h0;
logic [3:0][7:0] b = {16'hz, 16'h0};        // concatenation
logic [3:0][7:0] c = {16{2'b01}};            // replication

// Unpacked array — list of values inside '{...}
int d [0:1][0:3] = '{ '{7,3,0,5}, '{2,0,1,6} };

// Replicate shortcut for unpacked
int e [0:1][0:3] = '{ 2{7,3,0,5} };          // both rows = {7,3,0,5}

// Default-fill
int a1 [0:7][0:1023] = '{default:8'h55};
```

⚠️ `'{...}` (with apostrophe) = list of values. `{...}` (no apostrophe) =
concatenation/replication. Two different operations.

### Assigning to arrays

```systemverilog
byte a [0:3][0:3];

a[1][0] = 8'h5;                              // 1 element
a = '{ '{0,1,2,3}, '{4,5,6,7},
       '{7,6,5,4}, '{3,2,1,0} };             // entire array
a[3] = '{'hF, 'hA, 'hC, 'hE};                // one row (a slice)
a    = '{default:0};                          // fill all with 0
a[0] = '{default:4};                          // fill one row with 4
```

### Copying arrays — the 4 cases

| From | To | Allowed? |
|---|---|---|
| packed | packed | ✅ direct (vector rules: truncate/zero-extend) |
| unpacked | unpacked | ✅ direct **only if** same layout, element type, dim sizes |
| unpacked | packed | ⚠️ requires bit-stream cast |
| packed | unpacked | ⚠️ requires bit-stream cast |

### Bit-stream casting

When direct copy is illegal, cast through a bit-stream:

```systemverilog
typedef int data_t [3:0][7:0];     // unpacked type
data_t a;                           // unpacked array
int    b [1:0][3:0][3:0];           // different-shape unpacked array

a = data_t'(b);                     // bit-stream cast — total bits must match
```

Cast flattens source into a bit stream, then re-packs into destination layout.
**Total bit count of source and destination must be identical** — the layouts
can differ wildly.

### Arrays of arrays — indexing order

```systemverilog
logic [3:0][7:0] mixed [0:7][0:7][0:7];     // unpacked × 3, packed × 2

// Index UNPACKED dimensions first (left to right), then PACKED.
mixed [0][1][2][3][4] = 1'b1;
//     ↑─↑─↑  unpacked              ↑─↑  packed
```

### Passing arrays through ports

Both packed and unpacked arrays can cross module boundaries in SV.
(Verilog allowed packed only.) The formal and actual must have identical
layout and element type.

```systemverilog
module CPU;
    logic [7:0] lookup_table [0:255];
    lookup_inst i1 (.LUT(lookup_table));
endmodule

module lookup_inst (output logic [7:0] LUT [0:255]);
    initial load(LUT);
    task load (inout logic [7:0] t [0:255]);
        ...
    endtask
endmodule
```

### Arrays of structures / structures-of-arrays

```systemverilog
// Array of packed structs (the structs must be packed in a packed array)
typedef struct packed {
    logic [31:0] a;
    logic [ 7:0] b;
} packet_t;
packet_t [23:0] packet_array;          // packed array of 24 structs

// Unpacked array of unpacked structs
typedef struct {
    int  a;
    real b;
} data_t;
data_t data_array [23:0];               // unpacked array of 24 structs

// Packed struct with an array member — array must be packed too
struct packed {
    logic       parity;
    logic [3:0][7:0] data;              // 2-D packed array inside packed struct
} data_word;
```

---

## 5.4 The `foreach` loop

Iterate without manually computing dimension sizes.

```systemverilog
int sum [1:8][1:3];

foreach (sum[i,j])
    sum[i][j] = i + j;

// Iterate only the OUTER dimension
foreach (gen_crc[i])
    gen_crc[i] = ^d[i];

// Skip an inner dim by leaving the slot blank
foreach (array[i,,k])           // skip middle dim
    ...
```

**Loop variable rules:**
- Variables are implicitly declared, automatic, read-only, scoped to the loop
- Type matches the array's index type (usually `int`)
- Cardinality matches the array's dimension order (unpacked first, then packed)

---

## 5.5 Array query system functions

```systemverilog
logic [1:2][7:0] word [0:3][4:1];
```

| Function | Meaning | Example return |
|---|---|---|
| `$dimensions(word)` | Number of dimensions | 4 |
| `$left(word, n)` | MSB number of dimension n | `$left(word,1)` = 0 |
| `$right(word, n)` | LSB number of dimension n | `$right(word,1)` = 3 |
| `$low(word, n)` | Smaller of left/right | `$low(word,1)` = 0 |
| `$high(word, n)` | Larger of left/right | `$high(word,1)` = 3 |
| `$size(word, n)` | $high - $low + 1 | `$size(word,1)` = 4 |
| `$increment(word, n)` | +1 if left ≥ right, else -1 | `$increment(word,1)` = -1 |

**Dimension numbering:** start at 1 with the leftmost unpacked dimension,
then continue rightward through unpacked, then through packed.

**Synthesizable** if array size is fixed and dimension arg is constant.

---

## 5.6 `$bits` ("sizeof")

```systemverilog
$bits (any_expression)
```

Returns total number of bits in any packed/unpacked array, struct, union, literal.

```systemverilog
bit   [63:0] a;                                     // $bits(a) = 64
wire  [3:0][7:0] c [0:15];                          // $bits(c) = 512
struct packed { byte tag; logic [31:0] addr; } d;   // $bits(d) = 40
$bits(a + b);                                       // = 128 (full operand width)
```

Synthesizable except on dynamically-sized arrays.

---

## 5.7 Dynamic / associative / sparse arrays, strings — *NOT synthesizable*

Mentioned for completeness. Used in verification only. See Spear *SV for
Verification* for details.

```systemverilog
int  dyn[];                  // dynamic — size set at runtime
int  assoc[string];           // associative — sparse/key-indexed
byte sparse[*];               // sparse
string s;                     // character array with string ops
```

---

## Synthesis cheat lines

| Feature | Synth? |
|---|---|
| Unpacked struct | ✅ |
| Packed struct | ✅ |
| Unpacked union | ❌ |
| Tagged union | ⚠️ partial |
| Packed union | ✅ |
| Packed array (any dim count) | ✅ |
| Unpacked array (any dim count) | ✅ |
| Bit-stream cast | ✅ |
| `foreach` loop | ✅ (fixed-size array) |
| `$bits`, `$size`, `$left`, etc. | ✅ (fixed-size, constant dim arg) |
| Dynamic / associative / string | ❌ |

---

## Common bugs / gotchas

1. **`{...}` vs `'{...}`.** Concatenation vs structure/array value list.
   They look almost identical. Mixing them up produces wrong sizes silently.
2. **Anonymous structs can't cross module ports.** Use `typedef` in a
   package and import.
3. **Packed-to-unpacked direct assign fails.** Must use bit-stream cast.
4. **Mixing positional and named in one structure expression** is illegal.
5. **`real` / `shortreal` inside a packed struct/union** is illegal.
   Packed = integral types only.
6. **Tagged union read with wrong tag** = runtime error, not compile-time.
7. **`int unsigned u_array [...]` — array of user-defined types** requires
   `typedef` first if the type is used elsewhere.

---

## Concept notes for the genuinely new material

- [`packed_vs_unpacked`](../../../docs/concepts/packed_vs_unpacked.md) — layout, port crossings, when to pick each
- [`sv_unions`](../../../docs/concepts/sv_unions.md) — three flavors and their synthesizability
- [`bit_stream_casting`](../../../docs/concepts/bit_stream_casting.md) — array/struct conversion mechanics
- [`foreach_loop`](../../../docs/concepts/foreach_loop.md) — iteration without dimension hardcoding
- [`array_query_functions`](../../../docs/concepts/array_query_functions.md) — `$bits` / `$dimensions` / `$left` family
- [`structure_expressions`](../../../docs/concepts/structure_expressions.md) — `'{...}` syntax + default precedence
