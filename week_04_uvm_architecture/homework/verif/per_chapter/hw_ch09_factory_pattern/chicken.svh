class chicken extends animal;
    `uvm_object_utils(chicken)

    function new (string name = "chicken");
        super.new(name);
    endfunction : new

    virtual function void make_sound();
        $display("CHICKEN: BAWWKAWWKK");
    endfunction : make_sound
endclass : chicken