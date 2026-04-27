class animal extends uvm_object;
    `uvm_object_utils(animal)
    int age;

    function new (string name = "animal");
        super.new(name);
    endfunction : new

    function int get_age();
        return this.age;
    endfunction : get_age

    function void set_age(int age);
        this.age = age;
    endfunction : set_age

    virtual function void make_sound();
        $display("ANIMAL: general animal sound");
    endfunction : make_sound
    


endclass : animal