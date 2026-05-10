class coverage_mon extends uvm_subscriber #(int);
    `uvm_component_utils(coverage_mon)

    int roll_val;

    covergroup cg_dice;
        cp_all_dice_values: coverpoint roll_val {
            bins dice_value[] = {[2:12]};
        }
    endgroup

    function new (string name = "coverage_mon", uvm_component parent = null);
        super.new(name, parent);
        cg_dice = new();
    endfunction : new

    function void write(int t);
        roll_val = t;
        cg_dice.sample();
    endfunction : write

    function void report_phase (uvm_phase phase);
        `uvm_info("COV", $sformatf("Coverage: cg_dice: %0.2f%%", cg_dice.get_inst_coverage()), UVM_LOW)
    endfunction : report_phase
endclass : coverage_mon

/*
    just learnes that its possible to write the cover_group with a function that wai i can pass the sample when sampling and no need to declare a class variable
    covergroup cg_dice with function smaple(int roll);
        cp_sum: coverpoint roll {bins sum[] = {[2:12]};}
    endgroup

    then in the write function i can write
    cg_dice.sample(t);
*/