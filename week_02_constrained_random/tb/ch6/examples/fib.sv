class Fib;
    rand bit[7:0] f;
    bit [7:0] vals[] = '{1, 2, 3, 5, 8};
    constraint c_fib {
        f inside {vals};
    }
endclass : Fib

program automatic test;
    initial begin
        Fib fib;
        int count[9], maxx[$];

        fib = new ();
        repeat (20_000) begin
            assert(fib.randomize());
            count[fib.f]++; // Count the number of hits
        end
        maxx = count.max();

        foreach (count[i]) begin
            if (count[i]) begin
                $write("count[%0d]=%5d ", i, count[i]);
                repeat (count[i]*40/maxx[0]) begin
                    $write("*");
                end
                $display;
            end
        end

    end
endprogram : test