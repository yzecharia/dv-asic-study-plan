virtual class Driver_cbs; // Driver callbacks
    virtual task pre_tx(ref Transaction tr, ref bit drop);

    endtask : pre_tx

    virtual task post_tx(ref Transaction tr);

    endtask : post_tx
endclass : Driver_cbs