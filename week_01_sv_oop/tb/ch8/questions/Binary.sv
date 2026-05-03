class Binary;
    rand bit [3:0] val1, val2;

    function new(input bit [3:0] val1, val2);
        this.val1 = val1;
        this.val2 = val2;
    endfunction : new

    virtual function void print_int(input int val);
        $display("val=%0d", val);
    endfunction : print_int

    virtual function Binary copy();
        Binary cpy = new(val1, val2);
        return cpy;
    endfunction : copy

endclass : Binary

class ExtBinary extends Binary;

    function new(input bit [3:0] val1=0, val2=0);
        super.new(val1, val2);
    endfunction : new

    function int mul();
        return val1 * val2;
    endfunction

    virtual function Binary copy();
        ExtBinary cpy = new(val1, val2);
        return cpy;
    endfunction : copy

endclass : ExtBinary

class Exercise3 extends ExtBinary;
    constraint val_valurs {
        val1 < 10;
        val2 < 10;
    }

    function new(input bit [3:0] val1=0, val2=0);
        super.new(val1, val2);
    endfunction : new
endclass : Exercise3

program automatic test;
    ExtBinary bin;

    initial begin
        bin = new(15, 8);
        $display("val1=%0d, val2=%0d", bin.val1, bin.val2);
        $display("val1 x val2 = %0d", bin.mul());

        begin
            repeat(3) begin
                Exercise3 ex3 = new();
                assert(ex3.randomize());
                $display("val1=%0d, val2=%0d", ex3.val1, ex3.val2);
                $display("val1 x val2 = %0d", ex3.mul());
            end
        end

        begin
            Binary b;
            ExtBinary mc, mc2;

            //a:
            mc = new(15, 8);
            b = mc;

            //b: Will generate error because trying to apply parent handle to kid handle (parent handle doesnt have all the properties the kid has)
            // b = new(15,8);
            // mc = b;

            //c: This is not an okay assignment again but we can do it with cast (this is a compile time check error)
            // mc = new(15,8);
            // b = mc;
            // mc2 = b;

            //d:
            mc = new(15,8);
            b = mc;
            if ($cast(mc2, b)) $display("Success");
            else $display("Error: cannot assign");

            $display("mc: val1=%0d, val2=%0d", mc.val1, mc.val2);
            $cast(mc2, mc.copy());
            $display("mc2: val1=%0d, val2=%0d", mc2.val1, mc2.val2);

        end
    end

endprogram : test