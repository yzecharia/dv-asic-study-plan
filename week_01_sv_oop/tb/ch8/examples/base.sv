class Base;
    int val;
    function new(input int val);
        this.val = val;
    endfunction : new
endclass : Base

class Extended extends Base;
    function new(input int val);
        super.new(val);         // Must be the first line of new
        // Other constructor actions
    endfunction : new
endclass : Extended