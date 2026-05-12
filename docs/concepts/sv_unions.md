# SystemVerilog Unions — Unpacked, Packed, and Tagged

**Category**: SV Language · **Used in**: TLM transactions with multiple interpretations (instruction registers, packet headers re-read as byte streams), high-level abstract models · **Type**: authored

SystemVerilog adds C-like unions to Verilog. A union is one piece of storage that can be **read or written as different types**. Sutherland ch.5 covers three flavors (§5.2, pp. 105–113), and only one of them is reliably synthesizable. Knowing which one to reach for, and which to avoid, is what this note is about.

## What a union is — and isn't

A **structure** is many variables grouped under one name; each variable has its own storage. A **union** is one storage location that can be interpreted as different variables — but only one at a time.

```systemverilog
union {
    int  i;
    real r;
} data;

data.i = -5;            // store as int
$display("%d", data.i); // OK — read as int
$display("%d", data.r); // UNDEFINED — written as int, read as real
```

The compiler doesn't track which member you "last wrote." Reading a different member than you wrote produces implementation-defined garbage. (Tagged unions, below, fix this at runtime.)

## Flavor 1 — Unpacked unions (Sutherland §5.2.1, pp. 106–107)

```systemverilog
union {
    int  i;
    real r;
} data;
```

- Can hold any type — including `real`, unpacked structs, unpacked arrays.
- Storage layout is implementation-defined; the simulator may pad differently for each member type.
- Reading a different member than you wrote = undefined result.
- **Not synthesizable.** Used only in high-level abstract models or verification.

When you reach for it: rarely. Useful for behavioral models where one variable might represent several types depending on a mode bit.

## Flavor 2 — Tagged unions (Sutherland §5.2.2, pp. 108–109)

```systemverilog
union tagged {
    int  i;
    real r;
} data;

data = tagged i 5;       // store value 5 in member 'i', implicit tag = i
d_out = data.i;          // OK — tag matches
d_out = data.r;          // RUNTIME ERROR — tag mismatch
```

The compiler adds an implicit hidden "tag" member that records which named member was last written. Reading through a different member triggers a runtime check.

### What problem it solves

A plain union stores raw bits and lets you reinterpret them through any member. If you wrote through `data.i` and then read `data.r`, the simulator hands back whatever bit pattern `5` looks like as a real — garbage, but no error. This is the source of an entire class of silent bugs in protocol stacks and instruction decoders, where a value's "type" is implicit in the surrounding context.

A tagged union closes that loophole. It enforces a simple invariant: **the member you read through must match the member you last wrote through.** Violations are caught at simulation time, not in a debugger three weeks later.

### Why this matters — it's a "sum type" / "variant type"

This is the SystemVerilog equivalent of constructs from other languages:

| Language | Equivalent |
|---|---|
| Rust | `enum` with associated values |
| Haskell / ML | Algebraic data types |
| C++17+ | `std::variant` |
| Swift | `enum` with associated values |
| TypeScript | Discriminated unions |

Reach for a tagged union when a single value can **legitimately be one of several distinct types at different moments**, and you want the language to track which one is currently valid.

### The killer use case — instructions with variant operand layouts

```systemverilog
typedef enum {ADD, SUB, JMP, NOP} opcode_t;

typedef struct { int reg_a, reg_b, reg_dst; } alu_op_t;
typedef struct { int target_addr;           } jmp_op_t;

union tagged {
    alu_op_t  alu;
    jmp_op_t  jmp;
} operands_u;

typedef struct {
    opcode_t   op;
    operands_u operands;
} instr_t;

instr_t inst;

// ADD instruction — operands take the alu shape
inst.op       = ADD;
inst.operands = tagged alu '{reg_a:1, reg_b:2, reg_dst:3};

// JMP instruction — operands take the jmp shape, same union
inst.op       = JMP;
inst.operands = tagged jmp '{target_addr:'h1000};

// later: decode an instruction
case (inst.op)
    ADD, SUB: process_alu(inst.operands.alu);   // tag must be alu
    JMP:      jump_to    (inst.operands.jmp);    // tag must be jmp
endcase

// catches the bug if op and operands get out of sync:
$display(inst.operands.alu.reg_a);    // RUNTIME ERROR if last write was tagged jmp
```

Without the tag, an ADD instruction whose `operands` were set with the jmp shape would silently misinterpret `target_addr` as `reg_a`, and you'd debug for hours wondering why register 4096 keeps getting clobbered. With the tag, the simulator stops you at the bad read.

### Writing — must use the `tagged` keyword

```systemverilog
data = tagged i 5;        // store 5 in i, set tag to "i"
data = tagged r 3.14;     // store 3.14 in r, change tag to "r"
data.i = 7;               // direct write — allowed ONLY if current tag is "i"
data.r = 1.5;             // RUNTIME ERROR if current tag is "i"
```

The form `tagged <member_name> <value>` is **required** to set the tag. After that, direct member-name writes (`data.i = 7`) are legal only when they match the current tag.

### Reading — the tag check

```systemverilog
d_int  = data.i;          // legal only if tag is "i"
d_real = data.r;          // legal only if tag is "r"
```

The simulator silently inserts a check `assert(current_tag == member_being_read)` at every read. Mismatch → runtime error.

There is no "test the tag" syntax in standard SV — you can't query the tag directly. The pattern is: maintain a parallel enum (like `opcode_t` above) that mirrors the union's intent, and use that for control-flow decisions. The hidden tag is the runtime *check*; your visible enum is the runtime *intent*.

### Combined with `packed` — different widths allowed

```systemverilog
union tagged packed {
    logic [15:0] short_word;
    logic [31:0] word;
    logic [63:0] long_word;
} data_word;
```

This is the **only** union form where members can be different bit-widths. Storage = `max(member_widths)` bits + tag bits. When you `data_word = tagged word 32'hDEADBEEF`, the storage is sized for the 64-bit max, the value goes into the bottom 32 bits, and the tag remembers "this is a word."

### Synthesis status

**Partial / tool-dependent.** This is the key honest caveat:

- The SystemVerilog standard (IEEE 1800-2017 §7.3.2) says tagged unions are synthesizable.
- Most commercial simulators (VCS, Questa, Xcelium) accept the syntax.
- **Most open-source tools reject it outright** — Verilator and iverilog don't support `tagged` at all.
- Synthesis tools that accept the syntax often produce inefficient hardware (the tag bits cost storage, and the runtime checks must either be discarded — losing the safety — or implemented as extra logic).
- UVM RAL and most sequence libraries don't model tagged-union fields well.

**Practical rule:** treat tagged unions as a **simulation-time variant-type tool** for TB code and abstract models. If you need a variant in synthesizable RTL, use a `packed` (non-tagged) union plus a separate enum field for the intent — equivalent semantics, universal tool support.

### Gotcha — there's no clean way to query the tag

```systemverilog
// Wishful syntax — DOES NOT EXIST in standard SV:
// if (data.tag == i) ...
// case (tagof(data)) ...
```

Tagged unions check the tag on read but don't expose it for inspection. If you need to branch on which type is currently stored, you must track that intent in a separate field. This makes the construct less useful than `std::variant` in C++ (which provides `std::holds_alternative<T>(v)` and pattern matching). Treat the tag as **an assertion mechanism**, not a queryable runtime type field.

When you reach for it: when modeling a value that legitimately has multiple representations and you want the simulator to police access patterns (e.g. variant types in high-level TB code). When you DON'T: in synthesizable RTL with cross-tool portability requirements.

## Flavor 3 — Packed unions (Sutherland §5.2.3, pp. 109–111)

```systemverilog
typedef struct packed {
    logic [15:0] source_address;
    logic [15:0] destination_address;
    logic [23:0] data;
    logic [ 7:0] opcode;
} data_packet_t;

union packed {
    data_packet_t   packet;     // 64 bits
    logic [7:0][7:0] bytes;      // 64 bits — same storage, different view
} dreg;
```

- **All members must be the same bit-width.** Storage is unambiguous: one fixed-size bit array.
- All members must be integral (no `real`, no unpacked anything).
- Same value can be written as one type and read as another, **deterministically**: the bit pattern is preserved. Reading `dreg.bytes[0]` after writing `dreg.packet.opcode` retrieves the same bottom 8 bits.
- **Synthesizable** ✅ — this is the workhorse.

When you reach for it: any time you have a value that's *legitimately viewable two ways*. Classic uses:
- **Serial-in, parallel-process**: write bytes via a streaming interface, read as a packet (Sutherland's example, pp. 109–110).
- **Network header parsing**: a 64-bit ingress word that is "header[63:0]" OR "{src[15:0], dst[15:0], data[23:0], opcode[7:0]}" depending on the consumer.
- **Register field overlays**: a 32-bit CSR that's a flat vector for the bus interface AND a typed struct internally.

## Packed + tagged combination

```systemverilog
union tagged packed {
    logic [15:0] short_word;
    logic [31:0] word;
    logic [63:0] long_word;
} data_word;
```

Members can be **different bit-widths** when combined with tagged. The storage is `max(member_widths)` bits, and tag policing enforces "read as the type you wrote." Synthesizability claims exist but compiler support is uneven.

## Synthesis cheat lines

| Form | Synthesizable? | Use when |
|---|---|---|
| Unpacked union | ❌ | High-level abstract model only |
| Tagged union (unpacked) | ⚠️ partial | TB-side variant types with runtime safety |
| Packed union | ✅ | Multi-view of same storage in RTL |
| Packed + tagged | ⚠️ partial | Multi-view with different widths |

## Worked example — packed union as a streaming buffer

```systemverilog
typedef struct packed {
    logic [15:0] src;
    logic [15:0] dst;
    logic [23:0] payload;
    logic [ 7:0] opcode;
} pkt_t;                            // 64 bits

union packed {
    pkt_t              packet;
    logic [7:0][7:0]   bytes;       // 8 bytes
} dreg;

// Write byte-by-byte from a serial input
always_ff @(posedge clk)
    if (load_byte) begin
        dreg.bytes[byte_idx] <= byte_in;
        byte_idx <= byte_idx + 1;
    end

// Read decoded fields once all bytes are loaded
always_comb begin
    src_addr = dreg.packet.src;
    op       = dreg.packet.opcode;
end
```

You write through one view, read through another, and the hardware does no copy — both views refer to the same flops.

## Gotchas

1. **Unpacked unions are NOT synthesizable.** If your synthesis tool silently passes one, it's because it's substituting padded storage for each member. The simulation behavior won't match.
2. **Packed unions require all members the same width.** Compiler enforces; common mistake when iterating designs.
3. **`real` inside ANY packed thing is illegal.** Packed = integral only.
4. **Tagged-union runtime errors don't fire in synthesis.** The tag check is a simulator/elaboration feature; in real hardware, the tag bit either exists as additional storage or doesn't, depending on the synth tool's interpretation.
5. **Anonymous unions** are scoped like anonymous structs — they can't cross module ports. Use `typedef`.

## Cross-links

- [[packed_vs_unpacked]] — the underlying storage distinction also applies to unions
- [[structure_expressions]] — assignment syntax for union/struct value lists
- [[bit_stream_casting]] — alternative to unions when you need one-time conversion

## Reading

- Sutherland *SV for Design* 2e — §5.2 (pp. 105–113), example 5-1 (pp. 111–112)
- IEEE 1800-2017 §7.3 — "Unions"
- IEEE 1800-2017 §7.3.2 — "Tagged unions"
