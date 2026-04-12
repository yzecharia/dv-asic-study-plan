// ============================================================================
// Chapter 5 — OOP BASICS — Complete Runnable Cheatsheet
// Spear & Tumbush "SystemVerilog for Verification"
//
// Run with:  ../../run_xsim.sh tb/ch5_examples/cheatsheet_ch5.sv
//
// This file contains every major OOP concept from Chapter 5 in one
// runnable file. Each concept is in its own named begin..end block.
// ============================================================================


// ╔══════════════════════════════════════════════════════════════╗
// ║  CLASS DEFINITIONS  (all defined at file scope, before the   ║
// ║  module so the module can use them)                          ║
// ╚══════════════════════════════════════════════════════════════╝


// ════════════════════════════════════════════════════════════════════════
// 5.1 / 5.3 — Your First Class
// ────────────────────────────────────────────────────────────────────────
// A class groups DATA (properties) and FUNCTIONS (methods) together.
// This is the classic Transaction example from the book.
// ════════════════════════════════════════════════════════════════════════
class Transaction;
    // ── Properties (a.k.a. fields or members) ──
    bit [31:0] addr;            // destination address
    bit [31:0] csm;             // checksum
    bit [31:0] data[8];         // fixed-size payload (8 words)

    // ── Methods ──
    // 'function void' means it returns nothing; use it like a C void func.
    function void display();
        $display("  Transaction: addr=0x%08h  csm=0x%08h", addr, csm);
    endfunction : display

    // Calculate a simple XOR checksum over addr + all data words.
    // 'data.xor()' is the array reduction method from Chapter 2 — it
    // XORs every element of 'data' into a single value.
    function void calc_csm();
        csm = addr ^ data.xor();
    endfunction : calc_csm
endclass : Transaction


// ════════════════════════════════════════════════════════════════════════
// 5.6 — The new() Constructor
// ────────────────────────────────────────────────────────────────────────
// When you write 'obj = new();', SV calls this special function to
// initialize the object. It's where you give fields their starting values.
// ════════════════════════════════════════════════════════════════════════
class TransactionInit;
    bit [31:0] addr;
    bit [31:0] data[8];

    // The constructor MUST be called 'new'.
    // Returns nothing (no return type written).
    function new();
        addr = 32'h1000;                      // default address
        foreach (data[i]) data[i] = i;        // fill data with indices
    endfunction : new
endclass : TransactionInit


// ════════════════════════════════════════════════════════════════════════
// 5.6 — Constructor With Arguments + DEFAULT VALUES
// ────────────────────────────────────────────────────────────────────────
// SV does NOT support constructor overloading (unlike C++/Java).
// Instead, use default argument values to make parameters optional.
// ════════════════════════════════════════════════════════════════════════
class TransactionArgs;
    bit [31:0] addr;
    bit [31:0] data[8];

    // '= 32'hFFFF' and '= 32'h0' make these arguments OPTIONAL.
    // Call new() with 0, 1, or 2 arguments — all are valid.
    function new(input bit [31:0] a = 32'hFFFF, d = 32'h0);
        addr = a;
        data = '{default: d};                 // set all 8 elements to 'd'
    endfunction : new
endclass : TransactionArgs


// ════════════════════════════════════════════════════════════════════════
// 5.9 — Class Methods (function vs task)
// ────────────────────────────────────────────────────────────────────────
//   function — executes instantly (simulation time does NOT advance)
//   task     — can consume time with #, @, wait, etc.
// ════════════════════════════════════════════════════════════════════════
class TransactionMethods;
    bit [31:0] addr;

    // Instantaneous — must finish in zero time.
    function void print();
        $display("  addr = 0x%08h", addr);
    endfunction : print

    // Tasks can have delays. Useful for drivers that need to wait cycles.
    task wait_a_bit();
        #5;                                   // wait 5 time units
        $display("  wait_a_bit done at t=%0t", $time);
    endtask : wait_a_bit
endclass : TransactionMethods


// ════════════════════════════════════════════════════════════════════════
// 5.10 — Defining Methods Outside the Class (extern)
// ────────────────────────────────────────────────────────────────────────
// Large classes become unreadable if every method is inline. Use 'extern'
// to declare a prototype inside the class, then define the body outside
// using the 'ClassName::method' syntax.
// ════════════════════════════════════════════════════════════════════════
class TransactionExtern;
    bit [31:0] addr;

    // Declare the prototype — no body here.
    extern function void display();
endclass : TransactionExtern

// Define the body OUTSIDE the class, using the scope-resolution operator '::'
function void TransactionExtern::display();
    $display("  [extern] addr = 0x%08h", addr);
endfunction : display


// ════════════════════════════════════════════════════════════════════════
// 5.11 — The 'this' Keyword
// ────────────────────────────────────────────────────────────────────────
// When a method parameter has the same name as a class field, the
// parameter SHADOWS the field. Use 'this.' to explicitly refer to
// the field instead of the parameter.
// ════════════════════════════════════════════════════════════════════════
class TransactionThis;
    bit [31:0] addr;

    // Parameter 'addr' shadows the field 'addr'.
    function new(bit [31:0] addr);
        this.addr = addr;      // this.addr = field, addr = parameter
    endfunction : new
endclass : TransactionThis


// ════════════════════════════════════════════════════════════════════════
// 5.12 — Composition (Class Inside a Class)
// ────────────────────────────────────────────────────────────────────────
// A class can contain handles to other classes. This is called
// "composition" — building complex classes from smaller parts.
// IMPORTANT: the sub-object must also be allocated (with new())!
// ════════════════════════════════════════════════════════════════════════
class Stats;
    int num_txns = 0;

    function void increment();
        num_txns++;
    endfunction : increment
endclass : Stats

class Generator;
    Stats stats;                              // handle to a Stats object

    function new();
        stats = new();                        // MUST allocate the sub-object!
    endfunction : new
endclass : Generator


// ════════════════════════════════════════════════════════════════════════
// 5.14 — Shallow Copy (new src_obj)
// ────────────────────────────────────────────────────────────────────────
// 'new src_obj' creates a new object and copies all properties.
// IMPORTANT distinction (IEEE 1800-2017 §8.10):
//   - Simple types (int, bit, string)     → copied (independent)
//   - Dynamic arrays / queues / assoc     → copied (independent)
//   - Nested CLASS OBJECT handles         → NOT copied (shared!)
//
// The shallow-copy trap shows up when your class CONTAINS another
// class object — the handle is copied but they point to the SAME
// sub-object in memory.
// ════════════════════════════════════════════════════════════════════════
class Header;                                 // a sub-object class
    int size;
endclass : Header

class PacketShallow;
    int    id;
    Header hdr;                               // handle to a Header object

    function new();
        hdr = new();                          // allocate sub-object
        hdr.size = 64;
    endfunction : new

    function void display(string name);
        $display("  %s: id=%0d  hdr.size=%0d", name, id, hdr.size);
    endfunction : display
endclass : PacketShallow


// ════════════════════════════════════════════════════════════════════════
// 5.14 — Deep Copy (custom copy() method)
// ────────────────────────────────────────────────────────────────────────
// To truly duplicate an object, write a custom copy() method that
// recursively allocates new storage for every dynamic element.
// ════════════════════════════════════════════════════════════════════════
class PacketDeep;
    int id;
    int data[];

    function new();
        data = new[3];
        foreach (data[i]) data[i] = i;
    endfunction : new

    // Custom deep-copy method.
    function PacketDeep copy();
        copy = new();                         // new Packet object
        copy.id = this.id;                    // copy scalar field
        copy.data = new[data.size()];         // ALLOCATE new array
        foreach (data[i]) copy.data[i] = this.data[i];   // copy contents
        // 'copy' is the implicit return variable (same name as function)
    endfunction : copy

    function void display(string name);
        $display("  %s: id=%0d  data=%p", name, id, data);
    endfunction : display
endclass : PacketDeep


// ════════════════════════════════════════════════════════════════════════
// 5.15 — Public vs local (Encapsulation)
// ────────────────────────────────────────────────────────────────────────
//   public (default) — accessible from anywhere
//   local            — only this class can access it
//   protected        — this class + subclasses can access (Chapter 8)
// ════════════════════════════════════════════════════════════════════════
class Secret;
    int       public_val;       // default = public — accessible everywhere
    local int secret_val;       // private — only methods of Secret

    function new();
        public_val = 100;
        secret_val = 999;       // OK — we're inside the class
    endfunction : new

    // Provide a "getter" so outside code can read secret_val (read-only).
    function int get_secret();
        return secret_val;
    endfunction : get_secret
endclass : Secret


// ════════════════════════════════════════════════════════════════════════
// Static Class Members (shared across all instances)
// ────────────────────────────────────────────────────────────────────────
// Normal fields exist ONCE PER OBJECT.
// Static fields exist ONCE PER CLASS — shared by every instance.
// Great for counting how many objects have been created.
// ════════════════════════════════════════════════════════════════════════
class Counter;
    static int count = 0;       // ONE 'count' shared by all Counter objects
    int        my_id;           // each object has its own 'my_id'

    function new();
        count++;                // increment the shared counter
        my_id = count;          // save unique ID for this instance
    endfunction : new
endclass : Counter


// ════════════════════════════════════════════════════════════════════════
// Array of Handles
// ────────────────────────────────────────────────────────────────────────
// You can make an array of class handles, but each handle starts as null.
// You must new() each slot individually.
// ════════════════════════════════════════════════════════════════════════
class Packet;
    int id;

    function new(int i = 0);
        id = i;
    endfunction : new

    function void print();
        $display("    Packet id=%0d", id);
    endfunction : print
endclass : Packet


// ╔══════════════════════════════════════════════════════════════╗
// ║  TESTBENCH MODULE  (simulation entry point)                  ║
// ╚══════════════════════════════════════════════════════════════╝
module cheatsheet_ch5_tb;

    initial begin
        $display("============================================================");
        $display("   CHAPTER 5 - OOP BASICS - COMPLETE EXAMPLES");
        $display("============================================================\n");

        // ──────────────────────────────────────────────────────────────
        // 5.1 / 5.3 — Basic class: declare handle, new(), use it
        // ──────────────────────────────────────────────────────────────
        begin: s01_basic_class
            Transaction t;
            $display("--- 5.1 / 5.3  Basic class definition + usage ---");
            $display("  Before new(): 't' is a handle that points to NOTHING (null)");

            t = new();                        // allocate a Transaction object
            $display("  After  new(): 't' points to a fresh Transaction object");

            t.addr = 32'hDEAD_BEEF;
            t.data[0] = 32'h1111_1111;
            t.data[1] = 32'h2222_2222;
            t.calc_csm();                     // method that modifies 'csm'
            t.display();                      // method that prints
            $display("");
        end

        // ──────────────────────────────────────────────────────────────
        // 5.6 — new() constructor initializes fields automatically
        // ──────────────────────────────────────────────────────────────
        begin: s02_new_constructor
            TransactionInit t;
            $display("--- 5.6  new() constructor auto-initializes fields ---");
            t = new();                        // constructor runs automatically
            $display("  t.addr = 0x%h  (set by constructor)", t.addr);
            $display("  t.data = %p",  t.data);
            $display("");
        end

        // ──────────────────────────────────────────────────────────────
        // 5.6 — Constructor with default arguments (no overloading!)
        // ──────────────────────────────────────────────────────────────
        begin: s03_new_with_args
            TransactionArgs t1, t2, t3, t4;
            $display("--- 5.6  Constructor with default arguments ---");
            t1 = new();                               // both defaults
            t2 = new(32'hA000);                       // 1 arg  (d uses default)
            t3 = new(32'hB000, 32'h99);               // both args
            t4 = new(.d(32'h42));                     // named arg skip
            $display("  t1 (no args)           : addr=0x%h  data[0]=0x%h", t1.addr, t1.data[0]);
            $display("  t2 (1 arg)             : addr=0x%h  data[0]=0x%h", t2.addr, t2.data[0]);
            $display("  t3 (2 args)            : addr=0x%h  data[0]=0x%h", t3.addr, t3.data[0]);
            $display("  t4 (named .d(0x42))    : addr=0x%h  data[0]=0x%h", t4.addr, t4.data[0]);
            $display("");
        end

        // ──────────────────────────────────────────────────────────────
        // 5.5 — Handle vs Object  (THE most important concept!)
        // ──────────────────────────────────────────────────────────────
        begin: s04_handle_vs_object
            Transaction t1, t2;
            $display("--- 5.5  Handle vs Object (reference semantics) ---");
            t1 = new();                       // create ONE object
            t1.addr = 32'h1000;

            t2 = t1;                          // copy the HANDLE, not the object!
            t2.addr = 32'h2000;               // modify via t2

            $display("  t1.addr = 0x%h  <-- changed via t2!", t1.addr);
            $display("  t2.addr = 0x%h", t2.addr);
            $display("  Both handles point to the SAME object in memory.");
            $display("  To duplicate the object, use shallow/deep copy.");
            $display("");
        end

        // ──────────────────────────────────────────────────────────────
        // 5.7 — Object deallocation (assigning null releases the object)
        // ──────────────────────────────────────────────────────────────
        begin: s05_object_deallocation
            Transaction t;
            $display("--- 5.7  Object deallocation (garbage collection) ---");
            t = new();
            t.addr = 32'hAAAA_AAAA;
            $display("  Before null: t.addr = 0x%h", t.addr);

            t = null;                         // drop the reference
            $display("  After 't = null;' the object has no more handles ->");
            $display("  SV's garbage collector will free its memory.");
            $display("");
        end

        // ──────────────────────────────────────────────────────────────
        // 5.9 — Class methods: function (instant) vs task (can have delays)
        // ──────────────────────────────────────────────────────────────
        begin: s06_class_methods
            TransactionMethods t;
            $display("--- 5.9  Class methods (function vs task) ---");
            t = new();
            t.addr = 32'h55;
            t.print();                        // function — instant
            t.wait_a_bit();                   // task — consumes time
            $display("");
        end

        // ──────────────────────────────────────────────────────────────
        // 5.10 — Method defined OUTSIDE the class using 'extern'
        // ──────────────────────────────────────────────────────────────
        begin: s07_extern_method
            TransactionExtern t;
            $display("--- 5.10  Methods defined outside the class (extern) ---");
            t = new();
            t.addr = 32'h1234_5678;
            t.display();                      // body defined outside class
            $display("");
        end

        // ──────────────────────────────────────────────────────────────
        // 5.11 — 'this' keyword to disambiguate shadowed names
        // ──────────────────────────────────────────────────────────────
        begin: s08_this_keyword
            TransactionThis t;
            $display("--- 5.11  'this' keyword (when param shadows field) ---");
            t = new(32'hFACE_CAFE);           // param 'addr' shadows field
            $display("  t.addr = 0x%h  (set via this.addr = addr)", t.addr);
            $display("");
        end

        // ──────────────────────────────────────────────────────────────
        // 5.12 — Composition: one class contains another
        // ──────────────────────────────────────────────────────────────
        begin: s09_composition
            Generator g;
            $display("--- 5.12  Composition (class inside class) ---");
            g = new();                        // Generator.new() calls Stats.new()

            // Call methods on the nested object via the outer one
            g.stats.increment();
            g.stats.increment();
            g.stats.increment();
            $display("  g.stats.num_txns = %0d", g.stats.num_txns);
            $display("  NOTE: Generator.new() must allocate 'stats' itself,");
            $display("  otherwise g.stats would be null and crash!");
            $display("");
        end

        // ──────────────────────────────────────────────────────────────
        // 5.14 — Shallow copy: the trap with NESTED class objects
        // ──────────────────────────────────────────────────────────────
        begin: s10_shallow_copy
            PacketShallow p1, p2;
            $display("--- 5.14  Shallow copy (new src_obj) -- THE TRAP ---");
            p1 = new();
            p1.id       = 1;
            p1.hdr.size = 64;

            p2 = new p1;                      // SHALLOW copy
            p2.id       = 2;                  // scalar — independent
            p2.hdr.size = 128;                // sub-object — SHARED!

            $display("  p1.id=%0d  p1.hdr.size=%0d", p1.id, p1.hdr.size);
            $display("  p2.id=%0d  p2.hdr.size=%0d", p2.id, p2.hdr.size);
            $display("  Notice: p1.hdr.size also became 128!");
            $display("  Shallow copy copies scalars/arrays but SHARES nested class objects.");
            $display("");
        end

        // ──────────────────────────────────────────────────────────────
        // 5.14 — Deep copy: custom copy() method allocates new storage
        // ──────────────────────────────────────────────────────────────
        begin: s11_deep_copy
            PacketDeep p1, p2;
            $display("--- 5.14  Deep copy (custom copy() method) ---");
            p1 = new();
            p1.id      = 1;
            p1.data[0] = 100;

            p2 = p1.copy();                   // custom deep-copy method
            p2.id      = 2;
            p2.data[0] = 999;                 // only p2 changes

            p1.display("p1");
            p2.display("p2");
            $display("  p1 is completely unchanged -- the arrays are separate.");
            $display("");
        end

        // ──────────────────────────────────────────────────────────────
        // 5.15 — Public vs local (encapsulation)
        // ──────────────────────────────────────────────────────────────
        begin: s12_public_vs_local
            Secret s;
            $display("--- 5.15  Public vs local (encapsulation) ---");
            s = new();
            $display("  s.public_val      = %0d  (directly accessible)", s.public_val);
            // $display("%0d", s.secret_val);   // ERROR: local member
            $display("  s.get_secret()    = %0d  (via public accessor)", s.get_secret());
            $display("  'local' hides implementation details from outside code.");
            $display("");
        end

        // ──────────────────────────────────────────────────────────────
        // Static members: ONE copy shared across ALL instances
        // ──────────────────────────────────────────────────────────────
        begin: s13_static_members
            Counter c1, c2, c3;
            $display("--- Static class members (shared across instances) ---");
            c1 = new();                       // count -> 1, c1.my_id = 1
            c2 = new();                       // count -> 2, c2.my_id = 2
            c3 = new();                       // count -> 3, c3.my_id = 3
            $display("  c1.my_id = %0d", c1.my_id);
            $display("  c2.my_id = %0d", c2.my_id);
            $display("  c3.my_id = %0d", c3.my_id);
            $display("  Counter::count = %0d  (accessed WITHOUT any instance)", Counter::count);
            $display("");
        end

        // ──────────────────────────────────────────────────────────────
        // Array of handles: each slot must be new()'d separately
        // ──────────────────────────────────────────────────────────────
        begin: s14_array_of_handles
            Packet pkts[5];                   // 5 NULL handles
            $display("--- Array of handles ---");
            $display("  Just declaring 'Packet pkts[5]' gives 5 NULL handles");
            $display("  (no objects exist yet). Must new() each one:");

            foreach (pkts[i]) begin
                pkts[i] = new(i * 10);        // allocate each slot
            end

            foreach (pkts[i]) pkts[i].print();
            $display("");
        end

        $display("============================================================");
        $display("   ALL CHAPTER 5 EXAMPLES COMPLETE");
        $display("============================================================");
        $finish;
    end

endmodule
