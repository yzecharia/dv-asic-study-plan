// Ch.7 §7.1 — fork...join: Wait for ALL threads to complete
//
// All threads between fork/join run in parallel.
// Execution continues only after the SLOWEST thread finishes.

program automatic test;
    initial begin
        $display("[%0t] Start", $time);

        fork
            begin : thread_1
                #10;
                $display("[%0t] Thread 1 done (10ns)", $time);
            end
            begin : thread_2
                #30;
                $display("[%0t] Thread 2 done (30ns)", $time);
            end
            begin : thread_3
                #20;
                $display("[%0t] Thread 3 done (20ns)", $time);
            end
        join  // blocks until ALL three finish

        $display("[%0t] After join — all threads done", $time);  // t=30
    end
endprogram
