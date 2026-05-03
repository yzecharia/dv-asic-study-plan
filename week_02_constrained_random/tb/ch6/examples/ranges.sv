// Sample 6.10
class Ranges;
    rand bit [31:0] c;
    bit [31:0] lo, hi;
    constraint c_range {
        c inside {[lo, hi]};
    }
endclass : Ranges