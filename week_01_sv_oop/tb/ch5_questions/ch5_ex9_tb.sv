// ============================================================================
// Chapter 5 — Exercise 9 (copy function + nested class deep copy)
// ============================================================================
// Task: add a copy() function to MemTrans that DEEP-copies the Statistics
//       object by calling Statistics' own copy() function, then demonstrate
//       the use of the new copy.
//
// Key idea — shallow vs deep copy:
//   - `new src_obj` gives you a *shallow* copy: scalar fields are duplicated
//     but nested class handles still point to the SAME object.
//   - A proper *deep* copy must also recursively copy nested objects
//     (here, Statistics) so that mutating the copy never affects the
//     original.
// ============================================================================
package automatic my_package;

    // ─── Statistics class (has its own copy) ──────────────────
    class Statistics;
        int num_trans;
        int total_bytes;

        // Statistics provides its OWN copy() so MemTrans can just call it.
        function Statistics copy();
            copy              = new();
            copy.num_trans    = this.num_trans;
            copy.total_bytes  = this.total_bytes;
        endfunction : copy

        function void print();
            $display("   Statistics: num_trans=%0d, total_bytes=%0d",
                     num_trans, total_bytes);
        endfunction : print
    endclass : Statistics


    // ─── MemTrans class with deep copy() ──────────────────────
    class MemTrans;
        bit [7:0]   data_in;
        bit [3:0]   address;
        Statistics  stats;

        function new();
            data_in = 3;
            address = 5;
            stats   = new();
        endfunction : new

        // Deep copy: duplicates MemTrans AND its nested Statistics object
        function MemTrans copy();
            copy          = new();
            copy.data_in  = this.data_in;
            copy.address  = this.address;
            copy.stats    = this.stats.copy();   // ← delegates to Statistics.copy()
        endfunction : copy

        function void print(string tag = "");
            $display("%s MemTrans: data_in=%h, address=%h", tag, data_in, address);
            stats.print();
        endfunction : print
    endclass : MemTrans

endpackage : my_package


// ╔══════════════════════════════════════════════════════════════╗
// ║  TEST PROGRAM — demonstrates the copy function               ║
// ╚══════════════════════════════════════════════════════════════╝
program automatic test;
    import my_package::*;

    initial begin
        MemTrans orig, cp;

        // ── 1. Create and fill the original ──────────────────
        orig = new();
        orig.data_in           = 8'hAA;
        orig.address           = 4'h5;
        orig.stats.num_trans   = 10;
        orig.stats.total_bytes = 200;

        // ── 2. Make a deep copy ──────────────────────────────
        cp = orig.copy();

        $display("--- right after copy (should be identical) ---");
        orig.print("orig:");
        cp.print  ("cp:  ");

        // ── 3. Mutate the COPY — the original must stay untouched
        cp.data_in             = 8'hBB;
        cp.address             = 4'hF;
        cp.stats.num_trans     = 999;
        cp.stats.total_bytes   = 9999;

        $display("--- after mutating cp ---");
        orig.print("orig:");   // still AA / 5 / 10 / 200
        cp.print  ("cp:  ");   // BB / F / 999 / 9999

        // ── 4. Prove the nested handles are DIFFERENT objects ─
        if (orig.stats === cp.stats)
            $display("FAIL: stats handles are the SAME object (shallow copy!)");
        else
            $display("PASS: stats handles are DIFFERENT objects (deep copy)");
    end
endprogram : test
