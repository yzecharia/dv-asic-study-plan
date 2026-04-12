
`include "transaction.sv"
`include "BadTr.sv"
`include "generator_blue_print.sv"   
`include "driver.sv"

class Enviroment;
    Generator gen;
    Driver drv;
    mailbox #(Transaction) gen2drv;

    virtual function void build();
        gen2drv = new();
        gen = new(gen2drv);
        drv = new(gen2drv);
    endfunction : build

    virtual task run();
        fork
            gen.run(5);     // Generate 5 transactions
            drv.run();      // Drive them (prints to console)
        join_any           // End when EITHER finishes (gen finishes after 5)
        disable fork;      // Kill the driver's forever loop
    endtask : run

    virtual task wrap_up();
        $display("\n  [ENV] === Test Complete ===");
    endtask : wrap_up

endclass : Enviroment

/*
To change the transaction to a badtr need to change it between the build and run phases in the test.
*/
program automatic test;
    Enviroment env;
    initial begin
        // ── Test 1: Normal transactions ──────────────────
        $display("\n=== TEST 1: Normal Transaction ===");
        env = new();
        env.build();
        env.run();
        env.wrap_up();

        // ── Test 2: Bad checksum transactions ────────────
        $display("\n=== TEST 2: BadTr (corrupted checksum) ===");
        begin
            BadTr bad = new();             // create a BadTr object
            env = new();
            env.build();
            env.gen.blueprint = bad;       // ← swap blueprint
            env.run();
            env.wrap_up();
        end

        // ── Test 3: Using nearby constraints ────────────
        // Uncomment once you create the Nearby class
        // (must also `include "Nearby.sv" at the top)
        // begin
        //     Nearby nb = new();
        //     env = new();
        //     env.build();
        //     env.gen.blueprint = nb;
        //     env.run();
        //     env.wrap_up();
        // end


    end
endprogram : test
