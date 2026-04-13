class RandcInside;
    int array[];                // Values to choose
    randc bit [2:0] index;     // Index to array

    function new(input int a[]);
        array = a;
    endfunction : new

    function int pick();
        return array[index];
    endfunction : pick

    constraint c_size {
        index < array.size();
    }

endclass : RandcInside

program automatic test;
    initial begin
        RandcInside ri;

        ri = new('{1,3,5,7,9,11,13});
        repeat (ri.array.size()) begin
            assert(ri.randomize());
            $display("Picked %2d [%0d]", ri.pick(), ri.index);
        end
    end
endprogram : test

