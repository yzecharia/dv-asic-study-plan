program automatic test;
    import memtrans_pkg::*;

    initial begin
        MemTrans t_array [5];
        generator(t_array);
    end

    task generator(ref MemTrans t_array [5]);
        foreach(t_array[i]) begin
            t_array[i] = new();
            transmit(t_array[i]);
        end
    endtask : generator

    task transmit (MemTrans tr);
        tr.print();
    endtask : transmit
endprogram : test

