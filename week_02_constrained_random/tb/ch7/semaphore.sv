// Ch.7 §7.5 — Semaphore: Mutual exclusion / resource sharing
//
// A semaphore is like a key rack. Limited keys available.
// A thread grabs a key before using a shared resource, returns it when done.
// With 1 key → mutex (only one thread at a time).
//
// Key methods:
//   new(N)     — create with N keys
//   get(N)     — blocking: grab N keys (waits if not enough available)
//   put(N)     — return N keys
//   try_get(N) — non-blocking: returns 0 if not enough keys

program automatic test;

    semaphore bus_lock;

    task bus_agent(string name, int delay);
        repeat (3) begin
            bus_lock.get(1);  // grab the key — blocks if taken
            $display("[%0t] %s: acquired bus", $time, name);
            #delay;           // use the bus
            $display("[%0t] %s: releasing bus", $time, name);
            bus_lock.put(1);  // return the key
            #2;               // small gap before next attempt
        end
    endtask

    initial begin
        bus_lock = new(1);  // 1 key = mutex

        $display("=== Two agents sharing one bus ===");
        fork
            bus_agent("Agent A", 10);
            bus_agent("Agent B", 15);
        join

        $display("[%0t] Done", $time);
    end
endprogram
