class Driver_cbs_coverage extends Driver_cbs;
    covergroup CovDst7;
        // ...
    endgroup

    virtual task post_tx(ref Transaction);
        CovDst7.sample();       // sample coverage values
    endtask : post_tx
endclass