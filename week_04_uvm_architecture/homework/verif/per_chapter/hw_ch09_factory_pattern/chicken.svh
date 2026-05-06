class chicken extends animal;
    function new (input int age, input string name);
        super.new(age, name);
    endfunction : new

    virtual function void make_sound();
        $display("CHICKEN: BAWWKAAKK");
    endfunction : make_sound
endclass : chicken