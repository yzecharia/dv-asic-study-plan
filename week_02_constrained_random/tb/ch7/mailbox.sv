// Ch.7 §7.6 — Mailbox: Thread-safe FIFO between threads
//
// A mailbox is a queue that lets one thread produce data and another
// consume it. This is the foundation of UVM's Generator → Driver flow.
//
// Key methods:
//   put(item)  — blocking: adds item, waits if bounded mailbox is full
//   get(item)  — blocking: removes item, waits if empty
//   try_put()  — non-blocking: returns 0 if full
//   try_get()  — non-blocking: returns 0 if empty
//   peek(item) — blocking: copies item WITHOUT removing it
//   num()      — returns number of items in mailbox

class Transaction;
    rand bit [7:0] data;
    rand bit [3:0] addr;

    function void display(string tag);
        $display("[%0t] %s: addr=%0d data=%0d", $time, tag, addr, data);
    endfunction
endclass

program automatic test;

    mailbox #(Transaction) mbx;  // typed mailbox

    task generator(int count);
        repeat (count) begin
            Transaction tr = new();
            assert(tr.randomize());
            mbx.put(tr);       // blocks if bounded mailbox is full
            tr.display("GEN");
            #5;
        end
    endtask

    task driver(int count);
        repeat (count) begin
            Transaction tr;
            mbx.get(tr);       // blocks if mailbox is empty
            tr.display("DRV");
            #15;               // driver is slower than generator
        end
    endtask

    initial begin
        // Bounded mailbox — max 3 items
        // Generator will be forced to slow down when mailbox fills up
        mbx = new(3);

        $display("=== Bounded Mailbox (size=3): Generator faster than Driver ===");
        fork
            generator(6);
            driver(6);
        join

        $display("\n[%0t] Done — items in mailbox: %0d", $time, mbx.num());
    end
endprogram
