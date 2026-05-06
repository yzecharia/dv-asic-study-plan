virtual class animal;
    int age;
    string name;

    function new(input int age, input string name);
        this.name = name;
        this.age = age;
    endfunction : new

    function int get_age();
        return this.age;
    endfunction : get_age

    function string get_name();
        return this.name;
    endfunction : get_name

    pure virtual function void make_sound();

endclass : animal