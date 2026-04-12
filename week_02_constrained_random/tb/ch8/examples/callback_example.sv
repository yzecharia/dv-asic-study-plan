class Transaction;
    rand bit [7:0] data;
    rand bit [7:0] addr;
    bit            crc_ok;

    function new();
        crc_ok = 1;
    endfunction

    function void display(string tag = "");
        $display("%s addr=%0h data=%0h crc_ok=%0b", tag, addr, data, crc_ok);
    endfunction
endclass


class DriverCallbacks;
    virtual task pre_send(Transaction tr);
    endtask

    virtual task post_send(Transaction tr);
    endtask
endclass


class Driver;
    mailbox #(Transaction) mbx;
    DriverCallbacks cbs[$];

    function new(mailbox #(Transaction) mbx);
        this.mbx = mbx;
    endfunction

    task run();
        Transaction tr;
        while (mbx.num() > 0) begin
            mbx.get(tr);

            foreach (cbs[i]) cbs[i].pre_send(tr);

            tr.display("[DRV] sending:");

            foreach (cbs[i]) cbs[i].post_send(tr);
        end
    endtask
endclass


// Callback 1: inject CRC errors on 50% of transactions
class ErrorInjectionCb extends DriverCallbacks;
    virtual task pre_send(Transaction tr);
        if ($urandom_range(0,1) == 0) begin
            tr.crc_ok = 0;
            $display("       [ErrorCb] corrupted CRC!");
        end
    endtask
endclass

// Callback 2: count how many transactions were sent
class CounterCb extends DriverCallbacks;
    int count = 0;

    virtual task post_send(Transaction tr);
        count++;
        $display("       [CounterCb] total sent: %0d", count);
    endtask
endclass

// Callback 3: log every transaction to a "file"
class LoggerCb extends DriverCallbacks;
    virtual task post_send(Transaction tr);
        $display("       [LoggerCb] logged addr=%0h data=%0h", tr.addr, tr.data);
    endtask
endclass


program automatic test;
    initial begin
        mailbox #(Transaction) mbx = new();
        Driver drv = new(mbx);

        // Generate 6 transactions
        repeat (6) begin
            Transaction tr = new();
            assert(tr.randomize());
            mbx.put(tr);
        end

        // === Test 1: No callbacks (clean driver) ===
        $display("\n=== Test 1: No Callbacks ===");
        drv.run();

        // Refill mailbox
        repeat (6) begin
            Transaction tr = new();
            assert(tr.randomize());
            mbx.put(tr);
        end

        // === Test 2: Add error injection ===
        $display("\n=== Test 2: Error Injection Callback ===");
        begin
            ErrorInjectionCb err_cb = new();
            drv.cbs.push_back(err_cb);
        end
        drv.run();

        // Refill mailbox
        repeat (6) begin
            Transaction tr = new();
            assert(tr.randomize());
            mbx.put(tr);
        end

        // === Test 3: Stack ALL callbacks ===
        $display("\n=== Test 3: Error + Counter + Logger (stacked) ===");
        begin
            CounterCb cnt_cb = new();
            LoggerCb  log_cb = new();
            drv.cbs.push_back(cnt_cb);
            drv.cbs.push_back(log_cb);
        end
        drv.run();
    end
endprogram
