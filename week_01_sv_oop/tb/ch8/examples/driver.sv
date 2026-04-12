class Driver;
    mailbox #(Transaction) gen2drv;

    function new(input mailbox #(Transaction) gen2drv);
        this.gen2drv = gen2drv;
    endfunction : new

    virtual task run();
        Transaction tr;

        forever begin
            gen2drv.get(tr);            // Block until a transaction arrives
            tr.calc_csm();              // Process it
            tr.display("  [DRV] ");     // Print instead of driving interface
        end
    endtask : run

endclass : Driver
