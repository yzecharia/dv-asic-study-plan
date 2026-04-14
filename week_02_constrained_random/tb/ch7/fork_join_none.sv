// Ch.7 §7.1 — fork...join_none: Launch threads and continue immediately
//
// Parent does NOT wait at all. Threads start at the next time step.
// This is how UVM launches background monitors and drivers.

program automatic test;
    initial begin
        $display("[%0t] Before fork", $time);

        fork
            begin
                #10;
                $display("[%0t] Background thread A", $time);
            end
            begin
                #20;
                $display("[%0t] Background thread B", $time);
            end
        join_none  // continues immediately — threads haven't started yet!

        $display("[%0t] After fork — threads launched but not started", $time);

        // Threads start at next blocking statement / time step
        #1;
        $display("[%0t] Now threads are running in background", $time);

        // Wait for all background threads to complete before exiting
        wait fork;
        $display("[%0t] All background threads done", $time);  // t=20
    end
endprogram
