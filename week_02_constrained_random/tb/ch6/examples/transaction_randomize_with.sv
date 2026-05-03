class Transaction;
    rand bit [31:0] addr, data;
    constraint c1 {
        addr inside {[0:100], [1000:2000]};
    }
endclass : Transaction

program automatic test;
    initial begin
        Transaction t;
        t = new();

        assert(t.randomize() with {addr > 50; addr <= 1500; data <10});

        //drivebus(t);

        assert(t.randomize() with {addr == 2000; data >10;});

        //drivebus(t);
    end

endprogram : test