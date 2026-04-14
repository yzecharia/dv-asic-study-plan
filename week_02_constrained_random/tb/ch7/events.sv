// Ch.7 §7.4 — Events: Thread synchronization
//
// One thread triggers an event, another waits for it.
//
// CRITICAL: two ways to wait:
//   @(evt)                  — EDGE-triggered: misses if triggered same timestep
//   wait(evt.triggered)     — LEVEL-triggered: catches same-timestep triggers
//
// Rule of thumb: use wait(evt.triggered) to avoid race conditions.

program automatic test;

    event data_ready;
    event ack;

    // Example 1: Basic event handshake
    task sender();
        #10;
        $display("[%0t] Sender: data ready, triggering event", $time);
        -> data_ready;

        wait(ack.triggered);  // level-sensitive — safe
        $display("[%0t] Sender: got acknowledgment", $time);
    endtask

    task receiver();
        @(data_ready);  // edge-sensitive — OK here because receiver starts first
        $display("[%0t] Receiver: got data", $time);
        #5;
        $display("[%0t] Receiver: sending ack", $time);
        -> ack;
    endtask

    initial begin
        $display("=== Event Handshake ===");
        fork
            sender();
            receiver();
        join
    end

    // Example 2: Demonstrating @ vs wait race condition
    event evt;

    initial begin
        #100;
        $display("\n=== @ vs wait(triggered) race ===");

        fork
            begin
                -> evt;  // trigger at t=100
                $display("[%0t] Event triggered", $time);
            end
            begin
                // @(evt) might MISS this because trigger and wait
                // happen in the same timestep. Use wait instead:
                wait(evt.triggered);
                $display("[%0t] wait(triggered) caught it!", $time);
            end
        join
    end
endprogram
