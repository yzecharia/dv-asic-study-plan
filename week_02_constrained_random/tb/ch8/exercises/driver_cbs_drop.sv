class Driver_cbd_drop extends Driver_cbs;
    virtual task pre_tx(ref Transaction tr, ref bit drop);
        drop = ($urandom_range(0, 99) == 0); // Randomly drop 1 out of 100 transaction
    endtask : pre_tx
endclass : Driver_cbd_drop
