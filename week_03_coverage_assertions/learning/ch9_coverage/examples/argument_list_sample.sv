covergroup CovDst8;
    coverpoint dst;
    coverpoint hs;          // High speed mode
endgroup : CovDst8

class Transactor;
    CovDst8 covdst;
    task run();
        forever begin
            mbx.get(tr);
            ifc.cb.dst <= tr.dst;
            ifc.cb.data <= tr.data;
            covdst.sample(tr.dst, high_speed);
        end
    endtask : run
endclass : Transactor