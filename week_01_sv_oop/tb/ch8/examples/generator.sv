// "Bad" Generator — constructs Transaction directly in run()
// Problem: only creates Transaction objects, never BadTr or any extended type.
//          To change behavior you'd have to modify this class.
//          See generator_blue_print.sv for the better pattern.

class Generator;
    mailbox #(Transaction) gen2drv;

    function new(input mailbox #(Transaction) gen2drv);
        this.gen2drv = gen2drv;
    endfunction : new

    virtual task run(input int num_tr = 10);
        Transaction tr;
        repeat (num_tr) begin
            tr = new();                     // Always constructs base Transaction
            assert(tr.randomize());         // Randomize it
            gen2drv.put(tr.copy());         // Send a copy to driver
        end
    endtask : run

endclass : Generator
