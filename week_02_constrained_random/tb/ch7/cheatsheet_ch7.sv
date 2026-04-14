// ============================================================================
// Chapter 7 Cheatsheet: Threads & Interprocess Communication (IPC)
// Spear & Tumbush — SystemVerilog for Verification, 3rd Edition
// ============================================================================
//
// WHY THIS MATTERS:
// A real testbench has multiple things happening at once — a driver pushing
// data, a monitor watching the bus, a scoreboard checking results. Threads
// let you model this concurrency. IPC (mailboxes, semaphores, events) lets
// those threads talk to each other safely.
//
// This is the foundation of UVM's run_phase where all components run as
// parallel threads communicating through TLM ports (which are mailboxes
// under the hood).
// ============================================================================


// ──────────────────────────────────────────────────────────────────────────────
// 1. FORK...JOIN VARIANTS
// ──────────────────────────────────────────────────────────────────────────────
//
// fork...join       — waits for ALL threads to finish
// fork...join_any   — waits for FIRST thread to finish, others keep running
// fork...join_none  — launches all threads, parent continues immediately
//
//  ┌─────────────────────────────────────────────────┐
//  │           fork...join (wait for ALL)             │
//  │                                                  │
//  │   Thread A ████████████████──┐                   │
//  │   Thread B ████████──┐      │                   │
//  │   Thread C ██████████████───┤ ← all done        │
//  │                              ▼                   │
//  │                         continues here           │
//  └─────────────────────────────────────────────────┘
//
//  ┌─────────────────────────────────────────────────┐
//  │        fork...join_any (wait for FIRST)          │
//  │                                                  │
//  │   Thread A ████████████████───                   │
//  │   Thread B ████████──┐  (still running)         │
//  │   Thread C ██████████████─── (still running)    │
//  │                      ▼                           │
//  │                 continues here                   │
//  │          (other threads still alive!)             │
//  └─────────────────────────────────────────────────┘
//
//  ┌─────────────────────────────────────────────────┐
//  │        fork...join_none (launch & go)            │
//  │                                                  │
//  │   fork ──┬── Thread A (background)               │
//  │          ├── Thread B (background)               │
//  │          └── Thread C (background)               │
//  │   ▼ continues immediately                        │
//  │   (threads start at next time step)              │
//  └─────────────────────────────────────────────────┘


// ── Example: fork...join ─────────────────────────────────────────────────────

module fork_join_demo;
    initial begin
        $display("[%0t] Before fork", $time);

        fork
            begin  // Thread 1
                #10;
                $display("[%0t] Thread 1 done", $time);
            end
            begin  // Thread 2
                #20;
                $display("[%0t] Thread 2 done", $time);
            end
            begin  // Thread 3
                #5;
                $display("[%0t] Thread 3 done", $time);
            end
        join  // waits for ALL — continues at t=20

        $display("[%0t] After join", $time);  // prints at t=20
    end
endmodule


// ── Example: fork...join_any ─────────────────────────────────────────────────

module fork_join_any_demo;
    initial begin
        fork
            begin #10; $display("[%0t] Thread 1", $time); end
            begin #20; $display("[%0t] Thread 2", $time); end
            begin #5;  $display("[%0t] Thread 3", $time); end
        join_any  // continues at t=5 (Thread 3 finishes first)

        $display("[%0t] After join_any", $time);  // t=5

        // IMPORTANT: Threads 1 and 2 are STILL RUNNING in background!
        // Use disable fork to kill them:
        disable fork;
    end
endmodule


// ── Example: fork...join_none ────────────────────────────────────────────────

module fork_join_none_demo;
    initial begin
        $display("[%0t] Before fork", $time);

        fork
            begin #10; $display("[%0t] Background thread", $time); end
        join_none  // continues immediately

        $display("[%0t] After fork (thread hasn't started yet!)", $time);
        // Thread starts at next time step (after #0 or blocking statement)

        #20;  // now the background thread has run
        $display("[%0t] All done", $time);
    end
endmodule


// ──────────────────────────────────────────────────────────────────────────────
// 2. WAIT FORK & DISABLE FORK
// ──────────────────────────────────────────────────────────────────────────────
//
// wait fork    — block until ALL forked children complete
// disable fork — kill ALL active child threads
//
// Common pattern: timeout with cleanup
//
//   fork
//       begin : main_work
//           // ... do something that might hang ...
//       end
//       begin : timeout
//           #1000;
//           $display("TIMEOUT!");
//       end
//   join_any
//   disable fork;  // kill whichever thread is still running

module timeout_demo;
    initial begin
        fork
            begin : work
                #500;
                $display("[%0t] Work completed", $time);
            end
            begin : watchdog
                #1000;
                $display("[%0t] TIMEOUT — work took too long!", $time);
            end
        join_any
        disable fork;  // kill the loser
    end
endmodule


// ──────────────────────────────────────────────────────────────────────────────
// 3. AUTOMATIC VARIABLES IN FORK (CRITICAL!)
// ──────────────────────────────────────────────────────────────────────────────
//
// BUG: Loop variable shared across all forked threads
//
//   for (int i = 0; i < 3; i++)
//       fork
//           $display("i = %0d", i);  // ALL print "i = 3" !!
//       join_none
//
// FIX: Use automatic variable to capture the value
//
//   for (int i = 0; i < 3; i++) begin
//       automatic int ai = i;       // each iteration gets its own copy
//       fork
//           $display("i = %0d", ai); // prints 0, 1, 2
//       join_none
//   end

module auto_var_demo;
    initial begin
        // WRONG — all threads see i=3
        $display("--- BUG ---");
        for (int i = 0; i < 3; i++)
            fork
                automatic int j = i;  // FIX: capture i
                // $display("i = %0d", i);   // BUG: would print 3,3,3
                $display("j = %0d", j);      // FIXED: prints 0,1,2
            join_none
        #1;  // let threads execute
    end
endmodule


// ──────────────────────────────────────────────────────────────────────────────
// 4. MAILBOX — Thread-Safe FIFO Between Threads
// ──────────────────────────────────────────────────────────────────────────────
//
// Think of it as a pipe between a producer and consumer.
// In UVM: Generator → Driver communication uses mailboxes.
//
// Key methods:
//   new(N)    — create mailbox with bound N (0 = unbounded)
//   put(item) — blocking: waits if mailbox is full (bounded)
//   get(item) — blocking: waits if mailbox is empty
//   try_put() — non-blocking: returns 0 if full
//   try_get() — non-blocking: returns 0 if empty
//   peek()    — get without removing
//   num()     — number of items currently in mailbox
//
//  ┌────────────┐    mailbox    ┌────────────┐
//  │  Generator  │──── put() ──→│   Driver    │
//  │  (producer) │              │  (consumer) │
//  │             │    ← get() ──│             │
//  └────────────┘              └────────────┘

class Transaction;
    rand bit [7:0] data;
    rand bit [3:0] addr;
endclass

module mailbox_demo;
    mailbox #(Transaction) mbx;  // typed mailbox (SV parameterized)

    initial begin
        mbx = new(4);  // bounded: max 4 items

        fork
            producer();
            consumer();
        join
    end

    task producer();
        repeat (8) begin
            Transaction tr = new();
            assert(tr.randomize());
            mbx.put(tr);  // blocks if mailbox full (4 items)
            $display("[%0t] Produced: addr=%0d data=%0d", $time, tr.addr, tr.data);
            #5;
        end
    endtask

    task consumer();
        repeat (8) begin
            Transaction tr;
            mbx.get(tr);  // blocks if mailbox empty
            $display("[%0t] Consumed: addr=%0d data=%0d", $time, tr.addr, tr.data);
            #10;  // consumer is slower — mailbox will fill up
        end
    endtask
endmodule


// ──────────────────────────────────────────────────────────────────────────────
// 5. SEMAPHORE — Mutual Exclusion / Resource Sharing
// ──────────────────────────────────────────────────────────────────────────────
//
// Like a key rack — limited number of keys. Thread must grab a key before
// accessing the shared resource, and return it when done.
//
// Key methods:
//   new(N)    — create with N keys (default 0)
//   get(N)    — blocking: grab N keys (default 1), wait if not enough
//   put(N)    — return N keys
//   try_get() — non-blocking: returns 0 if not enough keys
//
// Classic use: two threads sharing one bus
//
//  Thread A ──┐                ┌── Thread B
//             ▼                ▼
//         sem.get(1)      sem.get(1)  ← one waits
//         use bus          use bus
//         sem.put(1)      sem.put(1)

module semaphore_demo;
    semaphore bus_lock;

    initial begin
        bus_lock = new(1);  // 1 key = mutex (only one thread at a time)

        fork
            bus_access("Agent A");
            bus_access("Agent B");
        join
    end

    task bus_access(string name);
        repeat (3) begin
            bus_lock.get(1);  // grab the key (blocks if taken)
            $display("[%0t] %s: got bus access", $time, name);
            #10;  // use the bus
            $display("[%0t] %s: releasing bus", $time, name);
            bus_lock.put(1);  // return the key
            #1;  // small gap
        end
    endtask
endmodule


// ──────────────────────────────────────────────────────────────────────────────
// 6. EVENTS — Thread Synchronization
// ──────────────────────────────────────────────────────────────────────────────
//
// An event is a synchronization flag. One thread triggers it, another waits.
//
// Key operations:
//   -> evt          — trigger the event (instantaneous pulse)
//   @(evt)          — EDGE-triggered: wait for next trigger
//   wait(evt.triggered) — LEVEL-triggered: passes if already triggered this timestep
//
// CRITICAL DIFFERENCE:
//   @(evt)                 — misses trigger if it happened SAME timestep
//   wait(evt.triggered)    — catches trigger even in same timestep
//
//  ┌─────────────────────────────────────────────────────────────────┐
//  │  Timeline     t=0         t=0         t=5                      │
//  │               -> evt      @(evt)      ...                      │
//  │                                                                │
//  │  @(evt) MISSES the trigger at t=0 because it was already       │
//  │  fired before the wait started (same delta cycle).             │
//  │                                                                │
//  │  wait(evt.triggered) CATCHES it because .triggered stays       │
//  │  high for the entire timestep.                                 │
//  └─────────────────────────────────────────────────────────────────┘

module event_demo;
    event data_ready;
    event ack;

    initial begin
        fork
            sender();
            receiver();
        join
    end

    task sender();
        #10;
        $display("[%0t] Sender: data is ready", $time);
        -> data_ready;     // trigger

        wait(ack.triggered);  // wait for acknowledgment
        $display("[%0t] Sender: got ack", $time);
    endtask

    task receiver();
        @(data_ready);  // wait for trigger (edge-sensitive)
        $display("[%0t] Receiver: got data", $time);
        #5;
        -> ack;  // acknowledge
    endtask
endmodule


// ──────────────────────────────────────────────────────────────────────────────
// 7. COMMON TESTBENCH PATTERN: Generator → Driver → Monitor
// ──────────────────────────────────────────────────────────────────────────────
//
// This is the pattern UVM uses internally:
//
//  ┌───────────┐  mbx_gen2drv  ┌──────────┐
//  │ Generator  │──── put() ──→│  Driver   │──→ DUT
//  └───────────┘              └──────────┘
//                                              │
//                             ┌──────────┐     │
//                             │  Monitor  │←───┘
//                             └──────────┘
//                                  │
//                           mbx_mon2scb
//                                  │
//                             ┌──────────┐
//                             │Scoreboard│
//                             └──────────┘

class Packet;
    rand bit [7:0] data;
    rand bit [3:0] addr;

    function void display(string prefix = "");
        $display("%s addr=%0d data=%0d", prefix, addr, data);
    endfunction
endclass

module tb_pattern_demo;
    mailbox #(Packet) gen2drv;

    initial begin
        gen2drv = new();  // unbounded mailbox

        fork
            generator(10);  // generate 10 packets
            driver();
        join
    end

    task generator(int count);
        repeat (count) begin
            Packet p = new();
            assert(p.randomize());
            gen2drv.put(p);
            p.display("[GEN]");
            #1;
        end
    endtask

    task driver();
        Packet p;
        forever begin
            gen2drv.get(p);   // blocks until packet available
            p.display("[DRV]");
            #10;  // simulate driving to bus
        end
    endtask
endmodule


// ──────────────────────────────────────────────────────────────────────────────
// QUICK REFERENCE TABLE
// ──────────────────────────────────────────────────────────────────────────────
//
// ┌──────────────────────┬─────────────────────────────────────────────────────┐
// │ Construct            │ When to use                                        │
// ├──────────────────────┼─────────────────────────────────────────────────────┤
// │ fork...join          │ Need ALL threads to complete before continuing     │
// │ fork...join_any      │ Timeout patterns, race between threads             │
// │ fork...join_none     │ Launch background tasks (monitors, scoreboards)    │
// │ wait fork            │ End-of-test: wait for all background threads       │
// │ disable fork         │ Cleanup: kill remaining threads after timeout      │
// │ automatic int x = i  │ Capture loop variable in fork (avoid sharing bug)  │
// ├──────────────────────┼─────────────────────────────────────────────────────┤
// │ mailbox              │ Producer-consumer FIFO (Generator → Driver)        │
// │ mailbox (bounded)    │ Back-pressure: slow down producer when full        │
// │ semaphore            │ Shared resource access (bus arbitration, mutex)     │
// │ event + ->           │ Simple signaling between threads                   │
// │ wait(e.triggered)    │ Level-sensitive wait (safer than @)                │
// ├──────────────────────┼─────────────────────────────────────────────────────┤
// │ UVM MAPPING:                                                              │
// │   mailbox       →  uvm_tlm_fifo / uvm_analysis_port                      │
// │   fork/join_none → run_phase (all components run in parallel)             │
// │   semaphore     →  shared register bus access                             │
// │   event         →  uvm_event (enhanced with data and callbacks)           │
// └──────────────────────┴─────────────────────────────────────────────────────┘
