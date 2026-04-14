class MemTrans;
    rand bit rw;            // read if rw=0, write if rw=1
    rand bit [7:0] data_in; 
    rand bit [3:0] address;

    constraint c_read {
        if (!rw) {address inside {[0:7]}};
    }
endclass : MemTrans

program automatic test;
    initial begin
        MemTrans mt = new();
        mt.c_read.constraint_mode(0);       // Turn off the c_read constraint

        repeat (100) begin
            assert(mt.randomize() with {
                !rw -> address inside {[0:8]};
            });
            if (mt.address == 8) $display("Inline Randomization worked");
        end



    end
endprogram : test