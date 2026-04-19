
class Transactor;
    Transaction tr;
    mailbox #(Transaction) mbx;
    covergroup CovDst5;
        coverpoint tr.dst;
    endgroup : CovDst5

    function new (input mailbox #(Transaction) mbx);
        CovDst5 = new();
        this.mbx = mbx;
    endfunction : new

    task run(); 
        forever begin
            mbx.get(tr);            // Get next transaction
            @ifc.cb;
            ifc.cb.dst <= tr.dst;
            ifc.cb.data <= tr.data;
            CovDst5.sample();
        end
    endtask : run

endclass : Transactor