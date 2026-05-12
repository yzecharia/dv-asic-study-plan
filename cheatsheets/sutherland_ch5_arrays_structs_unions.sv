// ============================================================================
// CHEATSHEET: SystemVerilog Arrays, Structures and Unions
//   Sutherland *SV for Design* 2nd ed., Chapter 5 (pp. 95-136)
// ============================================================================
// A reference module covering all 5.1-5.7 syntax. Most of this elaborates
// in iverilog -g2012; commercial-only constructs are marked [COMMERCIAL ONLY].
//
// Compile (lint) with:
//   $ verilator --lint-only -Wall sutherland_ch5_arrays_structs_unions.sv
//   $ iverilog -g2012 -t null sutherland_ch5_arrays_structs_unions.sv
//
// Cross-references (concept notes for the *why* behind each section):
//   packed_vs_unpacked, sv_unions, bit_stream_casting,
//   foreach_loop, array_query_functions, structure_expressions
// ============================================================================


// ============================================================================
//  PACKAGE: typedefs that need to cross module boundaries
// ============================================================================
package ch5_types_pkg;

    // -- Section 5.1.1: typed structure (can pass through ports) ------------
    typedef struct {
        logic [31:0] a, b;
        logic [ 7:0] opcode;
        logic [23:0] address;
    } instruction_word_t;

    // -- Section 5.1.3: packed structure (vector layout, no padding) --------
    typedef struct packed {
        logic        valid;     // bit 40
        logic [ 7:0] tag;       // bits 39:32
        logic [31:0] data;      // bits 31:0
    } data_word_t;              // total = 41 bits

    // -- Section 5.1.3: signed packed struct (vector compares signed) -------
    typedef struct packed signed {
        logic        valid;
        logic [ 7:0] tag;
        logic signed [31:0] data;
    } signed_word_t;

    // -- Section 5.2.3: packed union (synthesizable; all members same width)
    typedef struct packed {
        logic [15:0] source_address;
        logic [15:0] destination_address;
        logic [23:0] data;
        logic [ 7:0] opcode;
    } data_packet_t;            // total = 64 bits

    typedef union packed {
        data_packet_t    packet;   // 64-bit struct view
        logic [7:0][7:0] bytes;     // 64-bit byte-array view
    } dreg_t;

    // -- Section 5.2.5: structure with union member -------------------------
    typedef enum {ADD, SUB, MULT, DIV, SL, SR} opcode_t;
    typedef enum {UNSIGNED, SIGNED}             operand_type_t;

    typedef union packed {
        logic        [31:0] u_data;
        logic signed [31:0] s_data;
    } data_t;

    typedef struct packed {
        opcode_t       opc;
        operand_type_t op_type;
        data_t         op_a;
        data_t         op_b;
    } instr_t;

endpackage : ch5_types_pkg


// ============================================================================
//  MODULE: cheatsheet_ch5
//   - each "SECTION" demonstrates one construct from ch.5
//   - declarations + a small initial block exercising the syntax
// ============================================================================
module cheatsheet_ch5;

    import ch5_types_pkg::*;


    // ========================================================================
    //  SECTION 5.1.1 — Structure declarations (anonymous vs typed)
    // ========================================================================
    //
    // RULE OF THUMB: use typedef + package for any struct that crosses a
    // module port. Anonymous structs can't be passed through ports because
    // the type identity is per-declaration-site.

    // anonymous struct — local use only
    struct {
        logic [31:0] a, b;
        logic [ 7:0] opcode;
        logic [23:0] address;
    } anon_instr;

    // typed struct — declared in package above, used here
    instruction_word_t IW_typed;


    // ========================================================================
    //  SECTION 5.1.2 — Assigning values to structures (three forms)
    // ========================================================================
    //
    // 1. Per-member       — IW.a = 100;
    // 2. Positional list  — IW = '{100, 5, 8'hFF, 0};   <-- declaration order
    // 3. Named list       — IW = '{address:0, opcode:8'hFF, a:100, b:5};
    //
    // WARNING: '{...} (apostrophe-brace) is a structure value list.
    //          {...} (no apostrophe) is Verilog concatenation. They are
    //          NOT interchangeable.

    initial begin : sec_5_1_2_assignments
        // form 1: per-member
        IW_typed.a       = 100;
        IW_typed.b       = 5;
        IW_typed.opcode  = 8'hFF;
        IW_typed.address = 0;

        // form 2: positional
        IW_typed = '{100, 5, 8'hFF, 0};

        // form 3: named (any order)
        IW_typed = '{address:0, opcode:8'hFF, a:100, b:5};

        // ILLEGAL: cannot mix positional and named
        // IW_typed = '{address:0, 8'hFF, 100, 5};   // <-- compile error
    end


    // ========================================================================
    //  SECTION 5.1.2 — default values in structure expressions
    // ========================================================================
    //
    // Precedence (lowest to highest):
    //   1. default:<v>     -- catch-all
    //   2. <type>:<v>      -- per-type fallback (e.g. real:1.0)
    //   3. <member>:<v>    -- explicit per-member (highest priority)

    typedef struct {
        real          r0, r1;
        int           i0, i1;
        logic [ 7:0]  opcode;
        logic [23:0]  address;
    } mixed_t;

    mixed_t MX;

    initial begin : sec_5_1_2_defaults
        // all members ← 0
        MX = '{default: 0};

        // all real members ← 1.0; everything else ← 0
        // synthesizable for packed only; this is unpacked because of 'real'
        MX = '{real: 1.0, default: 0};

        // r1 explicitly = 3.1415; other real members = 1.0; rest = 0
        MX = '{real: 1.0, default: 0, r1: 3.1415};
    end


    // ========================================================================
    //  SECTION 5.1.3 — Packed structures
    // ========================================================================
    //
    // Packed structs are stored as one contiguous bit-vector:
    //   - first member = MSB,  last member = LSB
    //   - no padding, no alignment
    //   - all members must be integral (no real, no unpacked anything)
    //   - operations on the whole struct = vector operations

    data_word_t dword_a, dword_b;

    initial begin : sec_5_1_3_packed
        dword_a = '{1'b1, 8'hF0, 32'hDEAD_BEEF};

        // access by member name
        dword_a.tag = 8'hAA;

        // EQUIVALENT — access by bit range (packed = vector)
        dword_a[39:32] = 8'hAA;

        // vector ops on the whole struct
        dword_b = dword_a << 2;
        dword_b = dword_a + 1;

        // packed structs assigned via '{...} treat each member as one value,
        // NOT concatenated bits
        dword_a = '{1'b1, 8'h01, 32'h0000_0400};   // valid=1, tag=1, data=1024
    end


    // ========================================================================
    //  SECTION 5.1.3 — Signed vs unsigned packed structures
    // ========================================================================
    //
    // The signed/unsigned modifier on a packed struct affects how the WHOLE
    // struct compares when used as a vector. Individual members keep their
    // own signedness based on declaration.

    signed_word_t A, B;

    initial begin : sec_5_1_3_signed
        A = '{1'b0, 8'h80, 32'shFFFF_FFFE};
        B = '{1'b0, 8'h00, 32'sh0000_0001};
        if (A < B) begin
            // signed comparison of the whole 41-bit struct
        end
    end


    // ========================================================================
    //  SECTION 5.2 — Unions: three flavors
    // ========================================================================
    //
    // 1. Unpacked union   -- any types, NOT synthesizable
    // 2. Tagged union     -- runtime tag check, partial synth support
    // 3. Packed union     -- all members same width, SYNTHESIZABLE


    // ---- 5.2.1 unpacked union (NOT SYNTH) ----------------------------------
    typedef union {
        int  i;
        real r;       // real is non-integral → forces unpacked
    } unp_union_t;

    unp_union_t U_unp;

    initial begin : sec_5_2_1_unpacked_union
        U_unp.i = -5;
        // reading U_unp.r here is UNDEFINED — wrote int, reading real
        // The simulator does not track which member was last written.
    end


    // ---- 5.2.2 tagged union (partial synth) --------------------------------
    //
    // A tagged union wraps a union with an automatic "I last wrote member X"
    // tracker. The compiler enforces at runtime that reads use the same
    // member that was last written. It's SV's version of a "sum type" /
    // "variant type" — like Rust's enum, C++'s std::variant, Swift enums.
    //
    // Three things to know:
    //   1. Writes MUST use `tagged <member_name> <value>` form.
    //   2. Reads through a different member trigger a RUNTIME error.
    //   3. There is NO way to query the tag — it's an assertion mechanism,
    //      not a queryable runtime type field. Track intent with a parallel
    //      enum if you need to branch on the current type.
    //
    // [COMMERCIAL ONLY] - Verilator, iverilog, Yosys all reject the 'tagged'
    //                     keyword. VCS / Questa / Xcelium support it.
    //                     Uncomment the example below to try it on a
    //                     commercial simulator.

    /*
    // -------- simple example: int OR real, with runtime tag checking -------
    typedef union tagged {
        int  i;
        real r;
    } tag_union_t;

    tag_union_t U_tag;

    initial begin
        U_tag = tagged i 5;             // store 5 in i, set implicit tag = i
        $display("%0d", U_tag.i);       // OK — tag matches
        // $display("%f", U_tag.r);     // RUNTIME ERROR — tag mismatch
        U_tag = tagged r 3.1415;        // overwrite, tag = r
        U_tag.r = 2.71;                 // OK — tag is r, direct write allowed
        // U_tag.i = 10;                // RUNTIME ERROR — tag is r, not i
    end

    // -------- killer use case: instruction with variant operand layouts ----
    typedef enum {ADD_OP, SUB_OP, JMP_OP, NOP_OP} opcode_t;

    typedef struct { int reg_a, reg_b, reg_dst; } alu_op_t;
    typedef struct { int target_addr;            } jmp_op_t;

    typedef union tagged {
        alu_op_t  alu;
        jmp_op_t  jmp;
    } operands_u;

    typedef struct {
        opcode_t   op;
        operands_u operands;
    } instr_t;

    instr_t inst;

    initial begin
        // ADD: operands take the alu shape
        inst.op       = ADD_OP;
        inst.operands = tagged alu '{reg_a:1, reg_b:2, reg_dst:3};
        // process(inst.operands.alu);   // legal

        // JMP: same union, different shape — tag tracks the change
        inst.op       = JMP_OP;
        inst.operands = tagged jmp '{target_addr:'h1000};
        // process(inst.operands.jmp);   // legal
        // process(inst.operands.alu);   // RUNTIME ERROR — tag is jmp
    end

    // -------- tagged + packed: members may differ in width ---------------
    typedef union tagged packed {
        logic [15:0] short_word;
        logic [31:0] word;
        logic [63:0] long_word;
    } sized_word_t;
    // Storage = max(16, 32, 64) + tag bits.
    */


    // ---- 5.2.3 packed union (SYNTH ✓) --------------------------------------
    dreg_t dreg;
    logic [7:0] byte_in;

    initial begin : sec_5_2_3_packed_union
        // write through one view (byte array)
        for (int i = 0; i < 8; i++)
            dreg.bytes[i] = 8'hAA + i;

        // read through the OTHER view (packet struct)
        // bits are preserved — no copy, just renaming
        $display("opcode = %h",   dreg.packet.opcode);
        $display("data   = %h",   dreg.packet.data);
        $display("src    = %h",   dreg.packet.source_address);
        $display("dst    = %h",   dreg.packet.destination_address);
    end


    // ---- 5.2.5 structure + union worked example (the ALU model) -----------
    //
    // An ALU command word that carries:
    //   - opcode
    //   - operand_type (signed vs unsigned)
    //   - two operands, each a union of signed/unsigned int

    instr_t IR;

    initial begin : sec_5_2_5_alu_word
        IR.opc            = ADD;
        IR.op_type        = SIGNED;
        IR.op_a.s_data    = -100;
        IR.op_b.s_data    =   50;
        // when op_type == SIGNED, code reads .s_data; when UNSIGNED, .u_data
    end


    // ========================================================================
    //  SECTION 5.3.1 — Unpacked arrays
    // ========================================================================
    //
    // Unpacked dimensions go AFTER the variable name.
    // Elements stored independently (possibly with padding).
    // SV-style declarations accept either [hi:lo] range or [size] shortcut.

    byte mem_sram [0:4095];           // 4096-byte unpacked array (Verilog style)
    byte mem_sram_c [4096];            // SAME, C-style size (SV-only shortcut)

    logic [31:0] data_words [1024];    // 1024 unpacked words, each 32 bits
    real         coefs [0:89];          // unpacked array of reals (TB-only)

    initial begin : sec_5_3_1_unpacked
        mem_sram[10]  = 8'h5A;          // single element write
        mem_sram_c[0] = 8'hFF;
        coefs[12]     = 3.14;
    end


    // ========================================================================
    //  SECTION 5.3.2 — Packed arrays
    // ========================================================================
    //
    // Packed dimensions go BEFORE the variable name.
    // All elements stored as ONE contiguous bit-vector. No padding.
    // The entire array is a vector — all vector ops apply.

    logic [3:0][7:0] packed_array;     // 32-bit packed; 4 sub-fields of 8 bits

    initial begin : sec_5_3_2_packed
        // whole-vector assignment
        packed_array = 32'hDEAD_BEEF;

        // part-select (sub-field)
        packed_array[0] = 8'hAA;        // byte 0 (LSB end)
        packed_array[3] = 8'h55;        // byte 3 (MSB end)

        // bit-select inside a sub-field
        packed_array[2][7] = 1'b1;

        // vector ops
        packed_array = packed_array << 4;
        packed_array = packed_array + 1;
    end


    // ========================================================================
    //  SECTION 5.3.4 — Initializing arrays at declaration
    // ========================================================================
    //
    // packed array          → assign like a vector (no apostrophe)
    // unpacked array        → '{...} list of values (apostrophe required)
    // replicator shortcut   → 2{a,b,c} repeats list twice

    logic [3:0][7:0] init_packed   = 32'hCAFE_BABE;
    logic [3:0][7:0] init_packed2  = {16'hz, 16'h0};     // concat
    logic [3:0][7:0] init_packed3  = {16{2'b01}};         // replicate (=32'h55555555)

    int  init_unpacked  [0:1][0:3] = '{ '{7,3,0,5}, '{2,0,1,6} };
    int  init_replicate [0:1][0:3] = '{ '{7,3,0,5}, '{7,3,0,5} };
    // shortcut form (some tools accept):  '{ 2{ '{7,3,0,5} } }

    // '{default:VAL} on a 2-D unpacked array
    // [COMMERCIAL ONLY] — Verilator's strict elaborator rejects this form
    /*
    int  init_default   [0:7][0:1023] = '{default: int'(8'h55)};
    */


    // ========================================================================
    //  SECTION 5.3.5 — Assigning values to arrays (in procedural code)
    // ========================================================================

    byte a2d [0:3][0:3];

    initial begin : sec_5_3_5_assign
        a2d[1][0] = 8'h5;               // one element

        a2d = '{ '{0,1,2,3}, '{4,5,6,7},        // entire 2-D array
                 '{7,6,5,4}, '{3,2,1,0} };

        a2d[3] = '{'hF, 'hA, 'hC, 'hE};         // a slice (one row)

        // [COMMERCIAL ONLY] — Verilator rejects '{default:VAL} on 2-D unpacked
        // a2d    = '{default: byte'(0)};           // fill all
        // a2d[0] = '{default: byte'(4)};           // fill one row
    end


    // ========================================================================
    //  SECTION 5.3.6 — Copying arrays (4 cases)
    // ========================================================================
    //
    //   packed → packed     ✓ direct (vector rules: truncate / zero-extend)
    //   unpacked → unpacked ✓ direct ONLY if same layout, type, dim count
    //   unpacked → packed   ✗ requires bit-stream cast
    //   packed   → unpacked ✗ requires bit-stream cast

    bit   [1:0][15:0] cp_p_a;          // 32-bit
    logic [3:0][ 7:0] cp_p_b;          // 32-bit, different shape but same total bits
    logic     [15:0]  cp_p_c;          // 16-bit — will truncate
    logic     [39:0]  cp_p_d;          // 40-bit — will zero-extend

    initial begin : sec_5_3_6_copy
        cp_p_b = cp_p_a;     // 32→32, OK
        cp_p_c = cp_p_a;     // upper 16 bits truncated
        cp_p_d = cp_p_a;     // upper 8 bits zero-filled
    end


    // ========================================================================
    //  SECTION 5.3.7 — Bit-stream casting
    // ========================================================================
    //
    // When direct copy is illegal, you can still copy if total $bits match.
    // Cast operator: <typedef_name>'(<source>)
    // The destination type MUST be a typedef.

    typedef int data_arr_t [3:0][7:0];     // 32 ints = 1024 bits

    data_arr_t bs_a;
    int        bs_b [1:0][3:0][3:0];        // 32 ints, different shape, same total bits

    initial begin : sec_5_3_7_bit_stream
        // bit-stream cast: flatten bs_b, repack into bs_a
        // Compile error if $bits(bs_b) != $bits(data_arr_t)
        // [COMMERCIAL ONLY] - Verilator doesn't support cross-shape array casts
        // bs_a = data_arr_t'(bs_b);
        // (uncomment in VCS / Questa / Xcelium)
    end
    // legal in real tools: bs_a = '{default: 0};


    // ========================================================================
    //  SECTION 5.3.8 — Arrays of arrays (indexing order)
    // ========================================================================
    //
    // Index UNPACKED dimensions FIRST (left→right),
    // then PACKED dimensions (left→right).

    logic [3:0][7:0] mixed_array [0:7][0:7][0:7];
    //          ↑    ↑                ↑   ↑    ↑
    //   packed-2  packed-1   unpacked-1  -2   -3

    initial begin : sec_5_3_8_indexing
        // 5 index positions; first 3 are unpacked, last 2 are packed
        mixed_array[0][1][2][3][4] = 1'b1;
    end


    // ========================================================================
    //  SECTION 5.3.9 — User-defined types with arrays
    // ========================================================================

    typedef int unsigned uint;
    uint  u_array [0:127];                  // array of unsigned ints

    typedef logic [3:0] nibble_t;           // packed type
    nibble_t  nib_array [0:3];              // 4 nibbles (unpacked array of nibbles)


    // ========================================================================
    //  SECTION 5.3.11 — Arrays of structures (and structures of arrays)
    // ========================================================================
    //
    // Packed array of structs   → struct must be packed
    // Unpacked array of structs → struct can be either

    typedef struct packed {
        logic [31:0] a;
        logic [ 7:0] b;
    } pkt_t;

    pkt_t [23:0] packet_array;              // packed array of 24 packed structs

    typedef struct {                        // unpacked struct
        int  a;
        real b;
    } data_unp_t;

    data_unp_t data_array [23:0];           // unpacked array of unpacked structs

    // packed struct WITH an array member — array must also be packed
    struct packed {
        logic       parity;
        logic [3:0][7:0] data;              // 2-D packed array inside packed struct
    } data_word_with_arr;


    // ========================================================================
    //  SECTION 5.4 — The foreach loop
    // ========================================================================
    //
    // Iterate without specifying bounds.
    // Comma-separated loop vars correspond to the array's dimensions.
    // Variables are implicit, automatic, read-only inside the body.

    int sum_2d [1:8][1:3];
    int row_sum [1:8];

    initial begin : sec_5_4_foreach
        // 2-D iteration
        foreach (sum_2d[i, j])
            sum_2d[i][j] = i + j;

        // iterate ONLY the outer dim — leave inner slot blank
        foreach (row_sum[i])
            row_sum[i] = i * 2;
    end


    // ========================================================================
    //  SECTION 5.5 — Array query system functions
    // ========================================================================
    //
    // $dimensions(arr)          — number of dimensions
    // $left(arr, n)             — MSB index of dimension n
    // $right(arr, n)            — LSB index of dimension n
    // $low(arr, n)              — smaller of left/right
    // $high(arr, n)             — larger of left/right
    // $size(arr, n)             — element count of dim n
    // $increment(arr, n)        — +1 if $left ≥ $right, else -1
    //
    // Dimension numbering: 1 = leftmost UNPACKED, then unpacked R→, then packed L→R

    logic [1:2][7:0] word_qry [0:3][4:1];   // 4 dimensions

    initial begin : sec_5_5_queries
        $display("dims      = %0d", $dimensions(word_qry));      // 4
        $display("$left  1  = %0d", $left(word_qry, 1));         // 0  (unpacked [0:3])
        $display("$right 1  = %0d", $right(word_qry, 1));        // 3
        $display("$left  3  = %0d", $left(word_qry, 3));         // 1  (packed   [1:2])
        $display("$size  4  = %0d", $size(word_qry, 4));         // 8
        $display("$incr  1  = %0d", $increment(word_qry, 1));    // -1
    end


    // ========================================================================
    //  SECTION 5.6 — $bits "sizeof" function
    // ========================================================================
    //
    // Total bit-count of any expression, array, struct, union.
    // Synthesizable (except for dynamically-sized args).
    // Useful for parameterized RTL and sanity-checking bit-stream casts.

    bit   [63:0]     bits_a;
    wire  [3:0][7:0] bits_c [0:15];
    struct packed { byte tag; logic [31:0] addr; } bits_d;

    initial begin : sec_5_6_bits
        $display("$bits(bits_a)  = %0d", $bits(bits_a));   // 64
        $display("$bits(bits_c)  = %0d", $bits(bits_c));   // 4 * 8 * 16 = 512
        $display("$bits(bits_d)  = %0d", $bits(bits_d));   // 8 + 32 = 40
        $display("$bits(a + b)   = %0d", $bits(bits_a + 1'b1));  // 64 (full op width)
    end


    // ========================================================================
    //  SECTION 5.7 — Dynamic, associative, sparse, string  [VERIFICATION ONLY]
    // ========================================================================
    //
    // [COMMERCIAL ONLY] — these are NOT SYNTHESIZABLE.
    // Used in testbenches and reference models. Iverilog supports them
    // partially; see Spear "SV for Verification" for the full story.

    /*
    int    dyn[];                  // dynamic array — size set at runtime
    int    assoc[string];           // associative — sparse / key-indexed
    byte   sparse[*];               // sparse — any int key
    string s = "hello world";       // first-class string type

    initial begin
        dyn = new[10];              // allocate at runtime
        assoc["foo"] = 42;
        sparse[100_000] = 8'hAA;
    end
    */


    // ========================================================================
    //  SYNTHESIS QUICK-REFERENCE
    // ========================================================================
    //
    //   Construct                          Synthesizable?
    //   ----------------------------------  -------------
    //   Unpacked struct                     ✓
    //   Packed struct                       ✓
    //   Unpacked union                      ✗
    //   Tagged union                        ⚠ partial / tool-dependent
    //   Packed union                        ✓
    //   Packed array (any dim count)        ✓
    //   Unpacked array (any dim count)      ✓
    //   Bit-stream cast                     ✓
    //   foreach (fixed-size array)          ✓
    //   $bits / $size / $left / $right ...  ✓ (fixed-size, constant dim arg)
    //   Dynamic / associative / string      ✗ (TB only)


    // ========================================================================
    //  COMMON GOTCHAS
    // ========================================================================
    //
    //  1. {...} vs '{...} : concat vs structure/array value list.
    //     They look almost identical. Don't mix them up.
    //
    //  2. Anonymous structs cannot cross module ports.
    //     Use typedef in a package and import.
    //
    //  3. Packed-to-unpacked direct assign fails.
    //     Use a bit-stream cast.
    //
    //  4. Mixing positional and named in ONE structure expression is illegal.
    //
    //  5. real / shortreal inside a packed struct/union is illegal.
    //     Packed = integral types only.
    //
    //  6. Tagged union read with wrong tag = runtime error, not compile-time.
    //     Doesn't show up in synthesis.
    //
    //  7. $increment is -1 when $left < $right (i.e. [0:N]).
    //     Reads as "step needed to traverse from $right back to $left".
    //
    //  8. logic [32] x;   ← SYNTAX ERROR.
    //     Packed dims must be ranges. logic [31:0] x; is correct.

endmodule : cheatsheet_ch5
