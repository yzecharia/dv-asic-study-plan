class Transaction;
    rand bit [1:0] src, dst;

    constraint c_dist {
        src dist {0:=40, [1:3]:=60};
        // src = 0 weight = 40/220;
        // src = [1:3], weight = 60/220;
        // 220 = 3*60 + 40

        dst dist {0:/40, [1:3]/:60};
        // src = 0, weight = 40/100;
        //src = [1:3], weight = 20/100;
        // 100 = 3*20 + 40;
    }

endclass: Transaction