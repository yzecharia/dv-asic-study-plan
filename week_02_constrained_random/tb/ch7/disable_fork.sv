// Ch.7 §7.2 — disable fork & wait fork
//
// disable fork — kills ALL active child threads
// wait fork    — blocks until ALL child threads finish
//
// Classic use: timeout pattern — race between work and a watchdog timer

program automatic test;

    // Example 1: Timeout pattern
    initial begin
        $display("=== Timeout Pattern ===");
        fork
            begin : work
                #50;
                $display("[%0t] Work completed!", $time);
            end
            begin : watchdog
                #100;
                $display("[%0t] TIMEOUT — work took too long!", $time);
            end
        join_any      // first to finish wins
        disable fork; // kill the loser

        $display("[%0t] Continuing after timeout check", $time);
    end

    // Example 2: Launch multiple background tasks, then wait for all
    initial begin
        #200;  // wait for Example 1 to finish
        $display("\n=== Wait Fork Pattern ===");

        for (int i = 0; i < 4; i++) begin
            automatic int id = i;  // capture loop variable!
            fork
                begin
                    #(10 * (id + 1));
                    $display("[%0t] Task %0d done", $time, id);
                end
            join_none
        end

        $display("[%0t] All tasks launched", $time);
        wait fork;  // wait for all 4 to finish
        $display("[%0t] All tasks completed", $time);
    end
endprogram
