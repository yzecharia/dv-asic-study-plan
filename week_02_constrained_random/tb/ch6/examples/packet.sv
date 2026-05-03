// Sample 6.1
class Packet;
    // The random vaiables:
    rand bit [31:0] src, dst, data[8];
    randc bit [7:0] kind;

    // Constraint: Limit the values for src
    constraint c {
        src > 10;
        src < 15;
    }

endclass : Packet

program automatic test;
    Packet p;
    initial begin
        p = new ();
        if (!p.randomize())
            $finish;
        transmit(p);
    end
endprogram : test