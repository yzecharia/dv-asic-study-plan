package my_package;
    typedef enum {READ, WRITE} rw_e;

    // Q10
    class Transaction;
        rw_e old_rw;
        rand rw_e rw;
        rand bit [31:0] addr, data, old_addr;

        constraint rw_c {
            if (old_rw == rw) addr != old_addr;
        }

        function void post_randomize;
            old_rw = rw;
            old_addr = addr;
        endfunction : post_randomize

        function void print_all;
            $display("addr=%0d, data=%0d, rw=%s", addr, data, rw.name());
        endfunction : print_all
    endclass : Transaction

    // Q11
    class RandTransaction;
        parameter TESTS = 20;
        rand Transaction trans_array[];

        constraint rw_c {
            foreach (trans_array[i])
                if ((i > 0) && (trans_array[i].rw == trans_array[i-1].rw))
                    trans_array[i].addr != trans_array[i-1].addr;
        }

        function new();
            trans_array = new[TESTS];
            foreach (trans_array[i])
                trans_array[i] = new();
        endfunction : new
    endclass : RandTransaction

endpackage : my_package

program automatic test;
    import my_package::*;
    initial begin
        // Q10
        begin
            Transaction tr = new();
            repeat (20) begin
                assert(tr.randomize());
                tr.print_all();
            end
        end

        // Q11
        begin
            RandTransaction rt = new();
            assert(rt.randomize());
            foreach (rt.trans_array[i])
                rt.trans_array[i].print_all();
        end
    end
endprogram : test
