// Chapter 8 Exercise 8:
// Add the ability to randomly delay a transaction between 0 and 100ns.
// Uses the callback pattern from §8.7.1 and §8.7.2

// ── BaseTr (abstract base) ──────────────────────────────────────────
virtual class BaseTr;
    static int count;
    int id;

    function new();
        id = count++;
    endfunction

    pure virtual function bit compare(input BaseTr to);
    pure virtual function BaseTr copy(input BaseTr to=null);
    pure virtual function void display(input string prefix="");
endclass

// ── Transaction ─────────────────────────────────────────────────────
class Transaction extends BaseTr;
    rand bit [31:0] src, dst, csm, data[8];

    function new();
        super.new();
    endfunction

    virtual function bit compare(input BaseTr to);
        Transaction tr;
        if (!$cast(tr, to)) return 0;
        return ((this.src == tr.src) && (this.dst == tr.dst) &&
                (this.csm == tr.csm) && (this.data == tr.data));
    endfunction

    virtual function BaseTr copy(input BaseTr to=null);
        Transaction cp;
        if (to == null) cp = new();
        else $cast(cp, to);
        cp.src  = this.src;
        cp.dst  = this.dst;
        cp.csm  = this.csm;
        cp.data = this.data;
        return cp;
    endfunction

    virtual function void display(input string prefix="");
        $display("%s Tr %0d: src=%0h dst=%0h csm=%0h", prefix, id, src, dst, csm);
    endfunction
endclass

// ── Driver_cbs (callback base class) ────────────────────────────────
virtual class Driver_cbs;
    virtual task pre_tx(ref Transaction tr, ref bit drop);
    endtask

    virtual task post_tx(ref Transaction tr);
    endtask
endclass

// ── Driver ──────────────────────────────────────────────────────────
class Driver;
    mailbox #(Transaction) mbx;
    Driver_cbs cbs[$];

    function new(mailbox #(Transaction) mbx);
        this.mbx = mbx;
    endfunction

    task transmit(Transaction tr);
        tr.display("[DRV] sent");
    endtask

    task run();
        bit drop;
        Transaction tr;

        while (mbx.num() > 0) begin
            drop = 0;
            mbx.get(tr);
            foreach (cbs[i]) cbs[i].pre_tx(tr, drop);
            if (drop) continue;
            transmit(tr);
            foreach (cbs[i]) cbs[i].post_tx(tr);
        end
    endtask
endclass

// ============================================================================
// YOUR TASK:
// Create a callback class called "DelayCallback" that extends Driver_cbs.
// In pre_tx, add a random delay between 0 and 100ns before the transaction
// is sent. Print the delay value so you can see it working.
//
// Then in the test program, create the callback, attach it to the driver,
// and run.
// ============================================================================

// ── YOUR CODE HERE ──────────────────────────────────────────────────

class DelayCallback extends Driver_cbs;
    virtual task pre_tx (ref Transaction tr, ref bit drop);
        int delay = $urandom_range(0,100);
        $display("  [DelyaCb] delaying %0dns", delay);
        #delay;
    endtask : pre_tx
endclass : DelayCallback

// ── Test Program ────────────────────────────────────────────────────
program automatic test;
    initial begin
        mailbox #(Transaction) mbx = new();
        Driver drv = new(mbx);

        // Generate 5 transactions
        repeat (5) begin
            Transaction tr = new();
            assert(tr.randomize());
            mbx.put(tr);
        end

        // TODO: Create your DelayCallback, attach it to drv.cbs, then run
        DelayCallback delay_cb = new();
        drv.cbs.push_back(delay_cb);

        drv.run();
    end
endprogram
