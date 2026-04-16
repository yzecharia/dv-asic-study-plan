program automatic test;

    class Transaction;
        rand bit [31:0] data;
        rand bit [2:0] dst;             // 8 dst ports
    endclass : Transaction

    Transaction tr;

    covergroup CovDst2;
        coverpoint tr.dst;              // Measure coverage
    endgroup : CovDst2

    initial begin
        CovDst2 ck;
        ck = new();                     // Instantiate group
        repeat (32) begin               // Run cycles
            @ifc.cb;                    // Wait a cycle
            tr = new();
            assert(tr.randomize());
            ifc.cb.dst <= tr.dst;
            ifc.cb.data <= tr.data;
            ck.sample();
        end
    end

endprogram : test