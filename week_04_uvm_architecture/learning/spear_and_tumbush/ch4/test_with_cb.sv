// Code lives in the scheduling region 
module test_with_cb (arb_if_modport.TEST arbif);
    initial begin
        @arbif.cb;
        arbif.cb.request <= 2'b01;

        @arbif.cb;

        $display("@[%0t]: Grant = %0b", $time, arbif.cb.grant);
        @arbif.cb;
        $display("@[%0t]: Grant = %b", $time, arbif.cb.grant);
        $finish;
    end
endmodule : test_with_cb

// Code lives in the reactive region
program automatic test (arb_if_modport.TEST arbif);
    initial begin
        @arbif.cb;
        arbif.cb.request <= 2'b01;
        $display("@[%0t]: Drove req = 01", $time);
        repeat (2) @arbif.cb;
        if (arbif.cb.grant == 2'b01) $display("@[%0t]: Success: grant == 2'b01", $time);
        else $display("@[%0t]: Error: grant != 2'b01", $time);
    end
endprogram : test

// Signal synchronization
program automatic test (bus_if.TB bus);
    initial begin
        @bus.cb;                    // Continue on active edge in clocking block

        repeat (3) @bus.cb;         // Wait for 3 active edges
        @bus.cb.grant;              // Continue on any edge
        @(posedge bus.cb.grant);    // Continue on posedge
        @(negedge bus.cb.grant);    // Continue on negedge
        wait (bus.cp.grant == 1);   // Wait for expression (No delay if already true)
        @(posedge bus.cb.grant or negedge bus.rst) //Wait for sevral signals 
    end
endprogram : test


// Synchronous interface sample and drive from module (not synthesizable)
program automatic test (arb_if_modport.TEST arbif);
    initial begin
        $monitor("@[%0t]: grant=%h", $time, arbif.cb.grant);
        #500; $display("End of the test");
    end
endprogram : test

// So the value of grant doesnt propagate to the testbench until the next cycle
module arb_dummy (arb_if_modport.DUT arbif);
    initial begin
        fork
            #70ns arbif.grant = 1;
            #170ns arbif.grant = 2;
            #250ns arbif.grant = 3;
        join
    end
endmodule : arb_dummy