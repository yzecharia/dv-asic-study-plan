// ============================================================================
// CHEATSHEET: SystemVerilog Data Types (Spear & Tumbush Chapter 2)
// ============================================================================
// A RUNNABLE testbench covering all Chapter 2 topics.
// Compile & simulate:
//   iverilog -g2012 -o build/cheatsheet_ch2.out tb/cheatsheet_ch2_tb.sv
//   vvp build/cheatsheet_ch2.out
//
// NOTE: Icarus Verilog supports a SUBSET of SystemVerilog. Features that
// only work in commercial tools (VCS, Xcelium, Questa) are shown in
// comment blocks marked [COMMERCIAL ONLY]. These are CRITICAL to learn —
// interviewers and real projects expect you to know them!
// ============================================================================


module cheatsheet_ch2_tb;

    // ======================================================================
    //  SECTION 1: logic TYPE (Section 2.1.1)
    // ======================================================================
    // logic replaces both 'reg' and 'wire' in most cases.
    // 4-state: holds 0, 1, X (unknown), Z (high-impedance).
    // Only limitation: cannot have multiple drivers (use wire for that).
    //
    // RULE OF THUMB: Declare everything as logic. You'll get a compile
    // error if it has multiple drivers — catches bugs!

    logic [7:0] sec1_data;
    logic       sec1_flag;
    logic [3:0] sec1_nibble;


    // ======================================================================
    //  SECTION 2: 2-STATE TYPES (Section 2.1.2)
    // ======================================================================
    //  | Type     | Bits | Signed | Range              |
    //  |----------|------|--------|--------------------|
    //  | bit      | 1    | No     | 0, 1               |
    //  | byte     | 8    | Yes    | -128 to +127        |
    //  | shortint | 16   | Yes    | -32768 to +32767    |
    //  | int      | 32   | Yes    | -2^31 to +2^31-1    |
    //  | longint  | 64   | Yes    | -2^63 to +2^63-1    |
    //
    // WARNING: byte is SIGNED — max 127, not 255! Use bit[7:0] unsigned.
    // WARNING: X/Z assigned to 2-state silently becomes 0/1. Use $isunknown()!

    bit        sec2_b;
    byte       sec2_y;
    int        sec2_i;
    shortint   sec2_s;
    bit [3:0]  sec2_safe;


    // ======================================================================
    //  SECTION 3: FIXED-SIZE ARRAYS (Section 2.2)
    // ======================================================================
    // Size set at compile time. C-style declaration.

    int sec3_arr[5];                       // 5 elements: [0] to [4]
    int sec3_matrix[2][3];                 // 2x3 multi-dimensional


    // ======================================================================
    //  SECTION 4: PACKED ARRAYS (Section 2.2.6)
    // ======================================================================
    // Packed = contiguous bits, dimensions BEFORE the name.
    // Can treat as one big number AND access individual sub-elements.

    bit [3:0][7:0] sec4_packed;            // 4 packed bytes = 32 bits


    // ======================================================================
    //  SECTION 5: DYNAMIC ARRAYS (Section 2.3)
    // ======================================================================
    // Size determined at RUNTIME. Must call new[] before use.

    int sec5_dyn[];


    // ======================================================================
    //  SECTION 6: QUEUES (Section 2.4)
    // ======================================================================
    // THE most important verification data structure!
    // Combines linked list (grow/shrink) + array (random access).
    // NO new[] needed. Used for: scoreboards, FIFOs, transaction lists.

    int sec6_q[$];


    // ======================================================================
    //  SECTION 7: ASSOCIATIVE ARRAYS (Section 2.5) — [COMMERCIAL ONLY]
    // ======================================================================
    // Sparse storage — only allocates memory for written entries.
    // Like Python dict / Perl hash. Perfect for large memory models.
    //
    //   int mem[int];                  // indexed by int
    //   mem[0]      = 100;
    //   mem[999999] = 300;             // no wasted space!
    //   $display("entries = %0d", mem.num());   // 2
    //
    //   if (mem.exists(500)) ...       // check before reading
    //
    //   foreach (mem[addr])            // iterate written entries only
    //       $display("mem[%0d] = %0d", addr, mem[addr]);
    //
    //   // Manual iteration with first()/next():
    //   int key;
    //   if (mem.first(key)) do
    //       $display("mem[%0d] = %0d", key, mem[key]);
    //   while (mem.next(key));
    //
    //   mem.delete(999999);            // remove one entry
    //
    //   // String-indexed (hash table):
    //   int opcodes[string];
    //   opcodes["ADD"] = 1;
    //   opcodes["SUB"] = 2;


    // ======================================================================
    //  SECTION 8: typedef — Creating New Types (Section 2.8)
    // ======================================================================
    // Convention: suffix _t for types, _s for structs, _e for enums

    typedef logic [31:0] word_t;
    typedef bit   [31:0] uint;             // unsigned 32-bit — very useful!
    typedef logic [7:0]  byte_t;

    word_t sec8_w;
    uint   sec8_u;
    byte_t sec8_b;


    // ======================================================================
    //  SECTION 9: ENUMERATED TYPES (Section 2.13)
    // ======================================================================
    // Named constants. ALWAYS define a value for 0 (default init = 0).

    typedef enum logic [2:0] {
        IDLE    = 3'b000,
        FETCH   = 3'b001,
        DECODE  = 3'b010,
        EXECUTE = 3'b011,
        DONE    = 3'b100
    } state_e;

    state_e sec9_current, sec9_next, sec9_tmp;


    // ======================================================================
    //  SECTION 10: PACKED STRUCTS (Section 2.9.4)
    // ======================================================================
    // Group related signals. Packed = contiguous bits.
    //
    // [COMMERCIAL ONLY] Unpacked structs (more common in testbenches):
    //   typedef struct {
    //       logic [7:0]  addr;
    //       logic [31:0] data;
    //       logic        wr_en;
    //   } bus_txn_s;
    //   bus_txn_s txn;
    //   txn.addr = 8'hFF;
    //   bus_txn_s txn2 = '{addr: 8'h00, data: 32'h0, wr_en: 1'b0};

    typedef struct packed {
        logic [3:0] opcode;
        logic [3:0] operand;
    } instruction_s;                       // total = 8 bits

    instruction_s sec10_instr;


    // ======================================================================
    //  CONSTANTS (Section 2.14)
    // ======================================================================
    parameter  int BUS_WIDTH   = 32;       // can be overridden
    localparam int DEPTH       = 16;       // cannot be overridden
    localparam int ADDR_BITS   = $clog2(DEPTH);  // = 4


    // Module-level helpers for type conversion section
    logic [7:0]  sec12_small;
    logic [15:0] sec12_big;


    // ======================================================================
    //  MAIN TEST
    // ======================================================================
    initial begin

        // ==============================================================
        $display("\n========================================");
        $display("  SECTION 1: logic TYPE");
        $display("========================================");
        // ==============================================================

        sec1_data   = 8'hA5;
        sec1_flag   = 1'b1;
        sec1_nibble = 4'bxx10;              // X values are valid in logic!

        $display("data   = %b (0x%h)", sec1_data, sec1_data);
        $display("flag   = %b", sec1_flag);
        $display("nibble = %b (has X bits!)", sec1_nibble);

        // $isunknown() — returns 1 if ANY bit is X or Z
        if ($isunknown(sec1_nibble))
            $display("WARNING: nibble contains X or Z values");


        // ==============================================================
        $display("\n========================================");
        $display("  SECTION 2: 2-STATE TYPES");
        $display("========================================");
        // ==============================================================

        sec2_b = 1;
        sec2_y = 127;                       // byte is SIGNED, max = 127
        sec2_i = 42;
        sec2_s = -100;

        $display("bit      b = %0d", sec2_b);
        $display("byte     y = %0d (signed! adding 1...)", sec2_y);
        sec2_y = sec2_y + 1;
        $display("byte 127+1 = %0d (overflow to -128!)", sec2_y);
        $display("int      i = %0d", sec2_i);
        $display("shortint s = %0d", sec2_s);

        // X/Z silently converted to 0/1 in 2-state types!
        sec2_safe = 4'bxxz1;
        $display("4'bxxz1 -> bit[3:0] = %b (X/Z lost!)", sec2_safe);


        // ==============================================================
        $display("\n========================================");
        $display("  SECTION 3: FIXED-SIZE ARRAYS");
        $display("========================================");
        // ==============================================================

        $display("sec3_arr has %0d elements", $size(sec3_arr));

        // --- for loop with local variable ---
        for (int i = 0; i < $size(sec3_arr); i++)
            sec3_arr[i] = i * 10;

        $display("for loop:");
        for (int i = 0; i < $size(sec3_arr); i++)
            $display("  arr[%0d] = %0d", i, sec3_arr[i]);

        // --- foreach — cleaner, auto-declares index ---
        $display("foreach loop:");
        foreach (sec3_arr[i])
            $display("  arr[%0d] = %0d", i, sec3_arr[i]);

        // --- Multi-dimensional: foreach uses COMMA syntax! ---
        sec3_matrix[0][0] = 1; sec3_matrix[0][1] = 2; sec3_matrix[0][2] = 3;
        sec3_matrix[1][0] = 4; sec3_matrix[1][1] = 5; sec3_matrix[1][2] = 6;

        $display("2D matrix (foreach uses comma [i,j] not [i][j]):");
        foreach (sec3_matrix[i, j])
            $display("  matrix[%0d][%0d] = %0d", i, j, sec3_matrix[i][j]);

        // --- Array literal syntax (apostrophe + braces) ---
        //   int scores[4] = '{10, 20, 30, 40};
        //   int zeros[8]  = '{default: 0};
        //
        // --- Aggregate copy and compare --- [COMMERCIAL ONLY full support]
        //   int a[4] = '{1, 2, 3, 4};
        //   int b[4] = a;                    // copy entire array
        //   if (a == b) $display("Equal");   // compare entire array
        //
        // --- Out of bounds reads ---
        //   logic arrays -> return X
        //   int/bit arrays -> return 0 (no crash, just silent default)

        // $clog2() — ceiling of log2 (useful for address widths)
        $display("$clog2(16) = %0d bits for 16 entries", $clog2(16));
        $display("$clog2(17) = %0d bits for 17 entries", $clog2(17));


        // ==============================================================
        $display("\n========================================");
        $display("  SECTION 4: PACKED ARRAYS");
        $display("========================================");
        // ==============================================================

        sec4_packed = 32'hDEAD_BEEF;

        $display("packed = 0x%h (single 32-bit value)", sec4_packed);
        $display("  byte[3] = 0x%h", sec4_packed[3]);    // DE
        $display("  byte[2] = 0x%h", sec4_packed[2]);    // AD
        $display("  byte[1] = 0x%h", sec4_packed[1]);    // BE
        $display("  byte[0] = 0x%h", sec4_packed[0]);    // EF

        // Packed dims = BEFORE name, stored contiguously
        //   Good for: register fields, pixel data, instruction encoding
        //   Can use @ (event control) on packed arrays
        //
        // Unpacked dims = AFTER name, stored separately
        //   Good for: memories, most testbench arrays
        //
        // You can mix: bit [3:0][7:0] memory [5];
        //   5 unpacked entries, each containing 4 packed bytes


        // ==============================================================
        $display("\n========================================");
        $display("  SECTION 5: DYNAMIC ARRAYS");
        $display("========================================");
        // ==============================================================

        sec5_dyn = new[5];                   // must call new[] first!
        foreach (sec5_dyn[i]) sec5_dyn[i] = i * 10;

        $display("After new[5]:");
        foreach (sec5_dyn[i]) $display("  dyn[%0d] = %0d", i, sec5_dyn[i]);
        $display("  size = %0d", sec5_dyn.size());

        // Resize and KEEP existing values
        sec5_dyn = new[8](sec5_dyn);
        $display("After new[8](dyn) — grew, kept old values:");
        foreach (sec5_dyn[i]) $display("  dyn[%0d] = %0d", i, sec5_dyn[i]);

        // Resize WITHOUT keeping values
        sec5_dyn = new[3];
        $display("After new[3] — old values LOST:");
        foreach (sec5_dyn[i]) $display("  dyn[%0d] = %0d", i, sec5_dyn[i]);

        // Delete (free memory)
        sec5_dyn.delete();
        $display("After delete: size = %0d", sec5_dyn.size());

        // TIP: dynamic array with literal lets SV count for you:
        //   int masks[] = '{8'hFF, 8'h0F, 8'hF0, 8'h33};


        // ==============================================================
        $display("\n========================================");
        $display("  SECTION 6: QUEUES");
        $display("========================================");
        // ==============================================================

        // push_back / push_front
        sec6_q.push_back(10);               // {10}
        sec6_q.push_back(20);               // {10, 20}
        sec6_q.push_back(30);               // {10, 20, 30}
        sec6_q.push_front(5);               // {5, 10, 20, 30}

        $display("After pushes: size = %0d", sec6_q.size());
        foreach (sec6_q[i]) $display("  q[%0d] = %0d", i, sec6_q[i]);

        // insert(index, value)
        sec6_q.insert(2, 15);               // {5, 10, 15, 20, 30}
        $display("After insert(2, 15):");
        foreach (sec6_q[i]) $display("  q[%0d] = %0d", i, sec6_q[i]);

        // pop_front / pop_back — remove and return
        begin
            int val;
            val = sec6_q.pop_front();        // val=5
            $display("pop_front = %0d", val);
            val = sec6_q.pop_back();         // val=30
            $display("pop_back  = %0d", val);
        end

        // delete(index) — remove by position
        sec6_q.delete(1);                    // remove index 1
        $display("After delete(1):");
        foreach (sec6_q[i]) $display("  q[%0d] = %0d", i, sec6_q[i]);

        // Direct index access like an array
        sec6_q[0] = 99;
        $display("After q[0]=99: q[0] = %0d", sec6_q[0]);

        // Clear queue
        while (sec6_q.size() > 0) begin
            int dummy;
            dummy = sec6_q.pop_back();
        end
        $display("After clearing: size = %0d", sec6_q.size());

        // IMPORTANT syntax difference:
        //   Queue literal:  {1, 2, 3}       (NO apostrophe)
        //   Array literal: '{1, 2, 3}       (HAS apostrophe)
        //
        // Performance:
        //   push/pop front/back = O(1) — very fast!
        //   insert/delete middle = O(n) — must shift elements


        // ==============================================================
        $display("\n========================================");
        $display("  SECTION 7: ASSOCIATIVE ARRAYS (comments)");
        $display("========================================");
        // ==============================================================
        // [COMMERCIAL ONLY] — See detailed examples in comments above
        // at the variable declaration section.
        //
        // Key points:
        //   int mem[int];               — sparse storage, indexed by int
        //   int lookup[string];         — hash table, indexed by string
        //   mem.num() / mem.size()      — number of entries
        //   mem.exists(key)             — check if key was written
        //   mem.delete(key)             — remove one entry
        //   mem.first(key)/next(key)    — manual iteration
        //   foreach (mem[k])            — automatic iteration

        $display("(See source code comments for full examples)");


        // ==============================================================
        $display("\n========================================");
        $display("  SECTION 8: ARRAY METHODS (comments)");
        $display("========================================");
        // ==============================================================
        // [COMMERCIAL ONLY] — These are ESSENTIAL for interviews!
        //
        // --- REDUCTION METHODS (Section 2.6.1) ---
        //   int arr[5] = '{1, 2, 3, 4, 5};
        //   arr.sum()       -> 15
        //   arr.product()   -> 120
        //   arr.xor()       -> XOR of all elements
        //   arr.and() / arr.or()
        //
        // --- LOCATOR METHODS (Section 2.6.2) ---
        //   int arr[6] = '{3, 9, 1, 8, 4, 2};
        //   int q[$];
        //
        //   q = arr.min();                          // {1}
        //   q = arr.max();                          // {9}
        //   q = arr.unique();                       // remove duplicates
        //
        //   // 'item' = iterator, represents each element:
        //   q = arr.find       with (item > 5);     // {9, 8}
        //   q = arr.find_index with (item > 5);     // {1, 3}
        //   q = arr.find_first with (item > 5);     // {9}
        //   q = arr.find_last  with (item > 5);     // {8}
        //
        //   // Count items matching condition:
        //   int count = arr.sum with (int'(item > 5));   // 2
        //   // Sum only matching items:
        //   int total = arr.sum with ((item > 5) ? item : 0); // 17
        //
        //   // Custom iterator name:
        //   q = arr.find(x) with (x > 5);
        //
        // --- SORTING METHODS (Section 2.6.3) ---
        //   arr.sort();      // ascending
        //   arr.rsort();     // descending
        //   arr.reverse();   // flip order
        //   arr.shuffle();   // random order
        //
        //   // Sort structs by field:
        //   students.sort with (item.score);
        //
        //   NOTE: sort/rsort/reverse/shuffle modify IN PLACE
        //   Work on fixed, dynamic, queues — NOT associative

        // Manual equivalents (always work everywhere):
        begin
            int demo[5];
            int min_val, max_val, total;
            demo[0] = 3; demo[1] = 1; demo[2] = 4; demo[3] = 1; demo[4] = 5;

            min_val = demo[0];
            max_val = demo[0];
            total   = 0;
            foreach (demo[i]) begin
                if (demo[i] < min_val) min_val = demo[i];
                if (demo[i] > max_val) max_val = demo[i];
                total = total + demo[i];
            end
            $display("Manual: min=%0d, max=%0d, sum=%0d", min_val, max_val, total);

            $display("Elements > 3:");
            foreach (demo[i])
                if (demo[i] > 3) $display("  demo[%0d] = %0d", i, demo[i]);
        end


        // ==============================================================
        $display("\n========================================");
        $display("  SECTION 9: typedef & CUSTOM TYPES");
        $display("========================================");
        // ==============================================================

        sec8_w = 32'hCAFE_BABE;
        sec8_u = 32'hFFFF_FFFF;              // unsigned: 4294967295, not -1
        sec8_b = 8'hFF;

        $display("word_t  w = 0x%h", sec8_w);
        $display("uint    u = %0d (unsigned — no negative!)", sec8_u);
        $display("byte_t  b = 0x%h", sec8_b);

        // More typedef patterns:
        //   typedef int fixed5_t[5];          // array type
        //   fixed5_t my_arr = '{1,2,3,4,5};
        //
        //   typedef bit [63:0] addr_t;        // for assoc array index
        //   int mem[addr_t];


        // ==============================================================
        $display("\n========================================");
        $display("  SECTION 10: PACKED STRUCTS");
        $display("========================================");
        // ==============================================================

        sec10_instr = 8'hA5;                 // assign as 8-bit value
        $display("instruction = 0x%h", sec10_instr);
        $display("  opcode  = 0x%h (upper 4 bits)", sec10_instr.opcode);
        $display("  operand = 0x%h (lower 4 bits)", sec10_instr.operand);

        sec10_instr.opcode  = 4'hB;
        sec10_instr.operand = 4'h3;
        $display("  modified = 0x%h", sec10_instr);

        // Packed struct = contiguous bits, assign as vector OR access fields
        // Use for: register fields, instruction encoding, pixel data
        //
        // [COMMERCIAL ONLY] Unpacked struct examples in declaration section
        //
        // TIP: Use CLASSES (Chapter 5) for testbench objects — they add
        // methods + constrained randomization on top of data grouping.


        // ==============================================================
        $display("\n========================================");
        $display("  SECTION 11: ENUMERATED TYPES");
        $display("========================================");
        // ==============================================================

        sec9_current = IDLE;
        $display("current = %s (value = %0d)", sec9_current.name(), sec9_current);

        sec9_current = FETCH;
        $display("current = %s (value = %0d)", sec9_current.name(), sec9_current);

        // --- Enum navigation methods ---
        sec9_tmp = sec9_current.first();
        $display("first = %s", sec9_tmp.name());               // IDLE
        sec9_tmp = sec9_current.last();
        $display("last  = %s", sec9_tmp.name());               // DONE
        sec9_tmp = sec9_current.next();
        $display("next  = %s", sec9_tmp.name());               // DECODE
        sec9_tmp = sec9_current.prev();
        $display("prev  = %s", sec9_tmp.name());               // IDLE

        // --- Step through ALL values with do..while ---
        $display("All states:");
        begin
            state_e s;
            s = s.first();
            do begin
                $display("  %s = %0d", s.name(), s);
                s = s.next();
            end while (s != s.first());      // wraps around to stop

            // NOTE: for loops with enums are tricky — next() wraps,
            // so the loop condition never becomes false.
            // Always use do..while for enum iteration!
        end

        // --- Type conversion rules ---
        begin
            int x;
            // enum -> int: IMPLICIT (always works)
            x = sec9_current;
            $display("enum -> int: %0d", x);

            // int -> enum: MUST CAST
            // sec9_current = 3;            // COMPILE ERROR!
            sec9_next = state_e'(3);        // static cast (no checking)
            $display("state_e'(3) = %s", sec9_next.name());

            // [COMMERCIAL ONLY] Dynamic cast with bounds checking:
            //   if ($cast(sec9_next, 3))   // returns 1 on success
            //       $display("OK: %s", sec9_next.name());
            //   if (!$cast(sec9_next, 7))  // returns 0 on failure
            //       $display("FAIL: 7 not a valid state");
        end

        // ALWAYS define a constant with value 0!
        //   typedef enum { FIRST=1, SECOND=2 } bad_e;  // 0 is invalid!
        //   bad_e x;  // x = 0 — silent bug! Not FIRST or SECOND.


        // ==============================================================
        $display("\n========================================");
        $display("  SECTION 12: TYPE CONVERSION");
        $display("========================================");
        // ==============================================================

        // --- Static cast: type'(value) ---
        begin
            int ci;
            real cr;
            ci = 42;
            cr = ci;                         // int -> real (implicit)
            $display("int 42 -> real = %f", cr);

            ci = cr + 0.7;                   // real -> int (truncates)
            $display("real 42.7 -> int = %0d (truncated)", ci);
        end

        // --- Implicit width conversion ---
        sec12_small = 8'hFF;
        sec12_big   = sec12_small;           // zero-extended to 16 bits
        $display("8'hFF -> 16-bit = 0x%h (zero-extended)", sec12_big);

        sec12_small = 16'h1234;              // truncated to lower 8 bits
        $display("16'h1234 -> 8-bit = 0x%h (truncated)", sec12_small);

        // Full cast syntax: type'(expression)
        //   real'(42)         — int to real
        //   int'(3.7)         — real to int
        //   state_e'(3)       — int to enum
        //   8'(some_4bit)     — widen to 8 bits


        // ==============================================================
        $display("\n========================================");
        $display("  SECTION 13: STREAMING OPERATORS (comments)");
        $display("========================================");
        // ==============================================================
        // [COMMERCIAL ONLY] — Pack/unpack between different representations.
        //
        // >> streams left-to-right, << streams right-to-left.
        //
        //   int h = 32'h0123_4567;
        //   byte bytes[4];
        //
        //   // Unpack word -> byte array (big-endian):
        //   {>>{bytes}} = h;      // bytes = {01, 23, 45, 67}
        //
        //   // Pack byte array -> word:
        //   int rebuilt = {>>{bytes}};   // 32'h01234567
        //
        //   // Little-endian (reverse byte order):
        //   {<<byte{bytes}} = h;  // bytes = {67, 45, 23, 01}
        //
        //   // Struct <-> byte array (packet serialization):
        //   typedef struct packed { logic [7:0] addr, data; } pkt_s;
        //   pkt_s p = '{addr: 8'hAB, data: 8'hCD};
        //   byte stream[] = {>> {p}};   // serialize to bytes

        $display("(See source code comments for streaming examples)");


        // ==============================================================
        $display("\n========================================");
        $display("  SECTION 14: STRINGS");
        $display("========================================");
        // ==============================================================

        begin
            string name, greeting;
            name = "Yuval";

            // Concatenation with curly braces
            greeting = {name, " - Welcome to SV!"};
            $display("greeting = %s", greeting);

            // String length
            $display("len = %0d", name.len());

            // substr(start, end) — inclusive both ends
            $display("substr(0,2) = %s", name.substr(0,2));

            // [COMMERCIAL ONLY] More string methods:
            //   name.toupper()         // "YUVAL"
            //   name.tolower()         // "yuval"
            //   name.getc(0)           // 'Y' (char at index)
            //   name.putc(0, "Z")      // change char at index
            //   name.compare("other")  // -1, 0, or +1 (like C strcmp)

            // $sformatf — returns formatted string (EXTREMELY useful!)
            begin
                string msg;
                msg = $sformatf("Error at time %0t: val=0x%0h", $time, 32'hDEAD);
                $display("sformatf: %s", msg);
            end

            // Comparison with ==
            begin
                string a_str, b_str;
                a_str = "abc";
                b_str = "abc";
                $display("\"abc\" == \"abc\" ? %0d", (a_str == b_str));
                b_str = "xyz";
                $display("\"abc\" == \"xyz\" ? %0d", (a_str == b_str));
            end
        end


        // ==============================================================
        $display("\n========================================");
        $display("  SECTION 15: EXPRESSION WIDTH PITFALL");
        $display("========================================");
        // ==============================================================
        // A PRIME source of bugs! SV uses the width of the context.

        begin
            bit       a_1, b_1;
            bit [7:0] c_8;

            a_1 = 1'b1;
            b_1 = 1'b1;

            // 1-bit + 1-bit in 1-bit context = OVERFLOW!
            $display("1'b1 + 1'b1 (1-bit)  = %0d (OVERFLOW!)", a_1 + b_1);

            // Fix 1: assign to wider variable
            c_8 = a_1 + b_1;
            $display("1'b1 + 1'b1 (8-bit)  = %0d", c_8);

            // Fix 2: cast to wider type
            $display("1'b1 + 1'b1 (2-bit cast) = %0d", 2'(a_1) + b_1);

            // Fix 3: add wider zero
            $display("1'b1 + 1'b1 + 2'b0      = %0d", a_1 + b_1 + 2'b0);
        end


        // ==============================================================
        $display("\n========================================");
        $display("  SECTION 16: CONSTANTS");
        $display("========================================");
        // ==============================================================

        $display("parameter  BUS_WIDTH  = %0d", BUS_WIDTH);
        $display("localparam DEPTH      = %0d", DEPTH);
        $display("localparam ADDR_BITS  = $clog2(%0d) = %0d", DEPTH, ADDR_BITS);

        // Constant types summary:
        //   `define MACRO val   — global text substitution (avoid in TB)
        //   parameter            — can be overridden from parent
        //   localparam           — cannot be overridden (preferred)
        //   const                — run-time constant, assigned once in initial


        // ==============================================================
        $display("\n========================================");
        $display("  SECTION 17: SCOREBOARD PATTERN");
        $display("========================================");
        // ==============================================================
        // THE fundamental verification pattern! UVM does this with classes.
        //
        // [COMMERCIAL ONLY] Elegant version with structs + locator methods:
        //   typedef struct { int addr; int data; } packet_t;
        //   packet_t scoreboard[$];
        //   scoreboard.push_back('{addr: 32'hA000, data: 42});
        //   int idx[$] = scoreboard.find_index with (item.addr == rx_addr);
        //   if (idx.size() == 0) $error("Unexpected!");
        //   else begin
        //       assert(scoreboard[idx[0]].data == rx_data);
        //       scoreboard.delete(idx[0]);
        //   end

        // Simplified version using parallel queues (works in iverilog):
        begin
            int sb_addr[$];
            int sb_data[$];
            int rx_addr, rx_data, found;

            // Add expected packets
            sb_addr.push_back(32'hA000); sb_data.push_back(42);
            sb_addr.push_back(32'hB000); sb_data.push_back(99);
            sb_addr.push_back(32'hC000); sb_data.push_back(7);
            $display("Scoreboard: %0d expected packets", sb_addr.size());

            // "Receive" a packet and check it
            rx_addr = 32'hB000;
            rx_data = 99;
            found = -1;

            // Manual search (in commercial tools: find_index)
            foreach (sb_addr[i]) begin
                if (sb_addr[i] == rx_addr) begin
                    found = i;
                    break;
                end
            end

            if (found == -1)
                $display("  ERROR: Unexpected packet at 0x%h!", rx_addr);
            else begin
                if (sb_data[found] == rx_data)
                    $display("  PASS: addr=0x%h data=%0d matched!", rx_addr, rx_data);
                else
                    $display("  FAIL: expected %0d got %0d", sb_data[found], rx_data);
                sb_addr.delete(found);
                sb_data.delete(found);
            end

            $display("Scoreboard: %0d remaining", sb_addr.size());
        end


        // ==============================================================
        $display("\n========================================");
        $display("  SECTION 18: PACKAGES REFERENCE (comments)");
        $display("========================================");
        // ==============================================================
        //   package my_bus_pkg;
        //       typedef logic [31:0] data_t;
        //       typedef enum logic [1:0] {RD, WR, IDLE_CMD} cmd_e;
        //       parameter int TIMEOUT = 1000;
        //       function automatic int calc_crc(...); ... endfunction
        //   endpackage
        //
        //   import my_bus_pkg::*;           // import all symbols
        //   import my_bus_pkg::data_t;      // import one symbol
        //   my_bus_pkg::TIMEOUT             // scope operator (no import)
        //
        // RULES:
        //   - Can contain: types, parameters, functions, classes
        //   - CANNOT reference outside signals/hierarchy
        //   - Local variables shadow imported names
        //   - Use pkg::symbol to access shadowed names

        $display("BUS_WIDTH = %0d (from parameter)", BUS_WIDTH);
        $display("DEPTH     = %0d (from localparam)", DEPTH);


        // ==============================================================
        $display("\n========================================");
        $display("  SECTION 19: UNIONS (comments)");
        $display("========================================");
        // ==============================================================
        // [COMMERCIAL ONLY] Multiple views of the same memory location.
        //
        //   typedef union packed {
        //       logic [31:0] raw;
        //       struct packed {
        //           logic [7:0] byte3, byte2, byte1, byte0;
        //       } bytes;
        //   } reg32_u;   // convention: suffix _u
        //
        //   reg32_u r;
        //   r.raw = 32'hDEADBEEF;
        //   $display("byte0 = 0x%h", r.bytes.byte0);  // EF
        //
        // TIP: Don't overuse. The book recommends a class with a "kind"
        // discriminant variable instead (Section 8.4.4).

        $display("(See source code comments for union examples)");


        // ==============================================================
        $display("\n========================================");
        $display("  SECTION 20: CHOOSING STORAGE TYPES");
        $display("========================================");
        // ==============================================================
        //
        //  | Use Case                    | Best Type             |
        //  |-----------------------------|-----------------------|
        //  | Fixed-size packet buffer    | Fixed array           |
        //  | Variable-size transactions  | Dynamic array         |
        //  | Scoreboard / FIFO           | Queue                 |
        //  | Sparse memory (>1M addr)    | Associative [int]     |
        //  | Opcode/command lookup       | Associative [string]  |
        //
        //  Performance:
        //    Fixed/Dynamic: O(1) random access — fastest
        //    Queue: O(1) push/pop ends, O(n) middle
        //    Associative: O(log n) — slowest but most flexible
        //
        //  Memory tips:
        //    Use 2-state types (bit, int) over 4-state (logic)
        //    Pack data into 32-bit multiples
        //    Packed arrays avoid wasted bits

        $display("(See source code comments for guidelines)");


        // ==============================================================
        $display("\n========================================");
        $display("  ALL CHAPTER 2 TOPICS COVERED!");
        $display("========================================");
        $display("");
        $display("  Runnable demos (iverilog):");
        $display("    1.  logic type + $isunknown()");
        $display("    2.  2-state types (bit/byte/int)");
        $display("    3.  Fixed-size arrays + foreach");
        $display("    4.  Packed arrays");
        $display("    5.  Dynamic arrays (new/resize/delete)");
        $display("    6.  Queues (push/pop/insert/delete)");
        $display("    7.  typedef custom types");
        $display("    8.  Packed structs (field access)");
        $display("    9.  Enumerated types + navigation");
        $display("    10. Type conversion (cast, widths)");
        $display("    11. Strings + $sformatf");
        $display("    12. Expression width pitfalls");
        $display("    13. Constants (parameter/localparam)");
        $display("    14. Scoreboard pattern with queues");
        $display("");
        $display("  In comments (need VCS/Xcelium/Questa):");
        $display("    - Unpacked structs + struct literals");
        $display("    - Associative arrays + methods");
        $display("    - Array locator methods (find/min/max)");
        $display("    - Array sorting (sort/rsort/shuffle)");
        $display("    - Streaming operators (<< >>)");
        $display("    - $cast() dynamic casting");
        $display("    - Unions");
        $display("    - Full package examples");
        $display("    - String methods (toupper/getc/putc)");
        $display("========================================\n");

        $finish;
    end

endmodule
