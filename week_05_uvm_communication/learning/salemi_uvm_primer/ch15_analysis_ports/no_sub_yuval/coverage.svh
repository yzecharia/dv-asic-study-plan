class coverage extends uvm_component;
    `uvm_component_utils(coverage)

    int the_roll;

    covergroup dice_cg;
        coverpoint the_roll {
            bins twod6[] = {2,3,4,5,6,7,8,9,10,11,12};
        }
    endgroup

    function new (string name = "coverage", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    function void write (int t);
        the_roll = t;
        the_roll.sample();
    endfunction : write

    function void report_phase (uvm_phase phase);
        $display("\nCOVERAGE: %2.0f%%", dice_cg.get_coverage());
    endfunction : report_phase
endclass : coverage