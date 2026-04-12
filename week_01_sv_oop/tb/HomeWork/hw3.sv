class Inner;
    int value;

    function new(int value = 0);
        this.value = value;
    endfunction : new
endclass : Inner

class Outer;
    string name;
    Inner inner;

    function new(string name, int val);
        this.name = name;
        this.inner = new(val);
    endfunction : new

    function void display();
        $display("%s: inner.value = %0d", name, inner.value);
    endfunction : display

    function Outer deep_copy(string new_name);
        Outer cpy = new(new_name, inner.value);
        return cpy;
    endfunction : deep_copy
endclass : Outer

program automatic test;
    initial begin
        Outer a, b, c;

        $display("=== Shallow Copy ===");
        a = new("a", 42);
        b = a;
        b.name = "b";

        a.display();
        b.display();

        b.inner.value = 99;
        $display("After b.inner.value = 99:");
        a.display();
        b.display();

        $display("\n=== Deep Copy ===");
        a = new("a", 42);
        c = a.deep_copy("c");

        a.display();
        c.display();

        c.inner.value = 99;
        $display("After c.inner.value = 99:");
        a.display();
        c.display();
    end
endprogram : test
