class StrobePat;
    rand bit strobe[10];
    constraint c_set_four {
        strobe.sum() == 4'h4;
    }
endclass : StrobePat

program automtic test;
    initial begin
        StrobePat sp;
        int count = 0;

        sp = new();
        assert(sp.randomize());
        foreach (sp.strobe[i]) begin
            if(sp.strobe[i]) bus.cb.data <= data[count++];
        end
    end
endprogram : test