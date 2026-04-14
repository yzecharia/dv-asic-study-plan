// Ch.7 §7.1 — fork...join_any: Wait for FIRST thread to complete
//
// Continues after the FASTEST thread finishes.
// Other threads keep running in the background!

program automatic test;
    initial begin
        $display("[%0t] Start", $time);

        fork
            begin : fast
                #5;
                $display("[%0t] Fast thread done", $time);
            end
            begin : slow
                #50;
                $display("[%0t] Slow thread done", $time);
            end
        join_any  // continues when fast finishes at t=5

        $display("[%0t] After join_any — first thread done", $time);
        // slow thread is STILL RUNNING in the background!

        // Option 1: wait for remaining threads
        // wait fork;

        // Option 2: kill remaining threads
        disable fork;
        $display("[%0t] Killed remaining threads", $time);
    end
endprogram
