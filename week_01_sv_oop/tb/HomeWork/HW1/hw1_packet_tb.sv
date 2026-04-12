`include "hw1_packet.sv" 
program automatic test;
    Packet pck;

    initial begin
        pck = new();
        assert(pck.randomize());

        pck.display();

        begin
            Packet pck1;
            pck1 = pck.copy();
            pck1.src_addr = 8'hAA;
            pck.display();
            pck1.display();

            if (pck.compare(pck1)) $display("Error: DeepCopy did not work");
            else $display("Success: Copied and modified new copy");
        end
    end


endprogram : test