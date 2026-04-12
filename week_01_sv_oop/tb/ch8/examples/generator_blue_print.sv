// "Good" Generator — uses a blueprint pattern
// The blueprint is constructed ONCE in the constructor.
// run() only randomizes and copies it — never calls new().
// This means you can swap in a BadTr (or any extended type) as the blueprint
// from the test, and the Generator doesn't need to change at all.

class Generator;
    mailbox #(Transaction) gen2drv;
    Transaction blueprint;                  // The blueprint object

    function new(input mailbox #(Transaction) gen2drv);
        this.gen2drv = gen2drv;
        blueprint = new();                  // Default blueprint is base Transaction
    endfunction : new

    virtual task run(input int num_tr = 10);
        repeat (num_tr) begin
            assert(blueprint.randomize());          // Randomize the blueprint
            gen2drv.put(blueprint.copy());           // Send a COPY to driver
        end
    endtask : run

endclass : Generator
