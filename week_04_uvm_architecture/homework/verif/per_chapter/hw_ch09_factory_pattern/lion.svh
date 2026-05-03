class lion extends animal;
    `uvm_object_utils(lion)
    bit thorn_in_paw;

    function new (string name = "lion");
        super.new(name);
    endfunction : new

    virtual function void make_sound();
        $display("LION: ROARRR");
    endfunction : make_sound
endclass : lion