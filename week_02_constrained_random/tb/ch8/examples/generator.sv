class Generator #(type T=BaseTr);
    mailbox #(Transaction) gen2drv;
    T blueprint;

    function new (input mailbox#(Transaction) gen2drv);
        this.gen2drv = gen2drv;
        blueprint = new();
    endfunction : new

    task run (input int num_tr = 10);
        T tr;
        repeat (num_tr) begin
            assert(blueprint.randomize());
            $cast(tr, blueprint.copy());
            gen2drv.put(tr);
        end
    endtask : run
endclass : Generator