class lion extends animal;
    bit thorn_in_paw;

    function new (input int age, input string name);
        super.new(age, name);
    endfunction : new

    virtual function void make_sound();
        $display("LION: RAAWWRR");
    endfunction : make_sound
endclass : lion