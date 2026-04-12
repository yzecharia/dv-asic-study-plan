virtual class Driver_cbs;           // Driver callbacks
    virtual task pre_tx(ref Transaction tr, ref bit drop);
        // By default, callback does nothing
    endtask : pre_tx

    virtual task post_tx(ref Transaction tr);
        // By default, callback does nothing
    endtask : post_tx
endclass : Driver_cbs

class Driver;
    Driver_cbs cbs[$];

    task run();
        bit drop;
        Transaction tr;

        forever begin
            drop = 0; 
            agt2drv.get(tr);    // Agent to driver mailbox
            foreach (cbs[i]) begin
                cbs[i].pre_tx(tr, drop);
            end
            if (drop) continue;
            transmit(tr)        // Actual work
            foreach (cbs[i]) cbs[i].post_tx(tr);
        end 
    endtask : run
endclass : Driver