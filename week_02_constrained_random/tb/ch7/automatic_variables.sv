// Ch.7 §7.3 — Automatic variables in fork (the classic bug)
//
// When you fork inside a loop, ALL threads share the same loop variable.
// By the time threads execute, the loop is done and the variable has its
// final value. Fix: use `automatic` to capture a private copy.

program automatic test;
    initial begin
        // ── BUG: All threads see i=3 ──
        $display("=== BUG: shared loop variable ===");
        for (int i = 0; i < 3; i++)
            fork
                // i is shared — by the time thread runs, loop is done, i=3
                $display("[%0t] i = %0d (all will be 3!)", $time, i);
            join_none
        #1;  // let threads run

        // ── FIX: automatic captures a private copy ──
        $display("\n=== FIX: automatic variable ===");
        for (int i = 0; i < 3; i++) begin
            automatic int ai = i;  // each iteration gets its own copy
            fork
                $display("[%0t] ai = %0d (correct!)", $time, ai);
            join_none
        end
        #1;  // let threads run
    end
endprogram
