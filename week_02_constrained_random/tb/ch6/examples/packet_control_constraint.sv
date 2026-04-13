class Packet;
    rand bit [31:0] length;

    constraint c_short {
        length inside {[1:32]};
    }
    constraint c_long {
        length inside {[1000:1023]};
    }

endclass : Packet

program automatic test;
    Packet p;
    initial begin
        p = new ();
        p.c_short.constraint_mode(0);
        assert(p.randomize());

        //transmit(p);

        p.constraint_mode(0);
        p.c_short.constraint_mode(1);
        assert(p.randomize());

        //transmit(p);
    end
endprogram : test