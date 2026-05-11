class average extends uvm_subscriber #(int);
    `uvm_component_utils(average)

    real dice_total;
    real count;

    function new (string name = "average", uvm_component parent = null);
        super.new(name, parent);
        dice_total = 0.0;
        count = 0.0;
    endfunction : new

    function void write (int t);
        dice_total = dice_total + t;
        count++;
    endfunction : write

    function void report_phase (uvm_phase phase);
        $display("DICE AVERAGE: %2.1f", dice_total/count);
    endfunction : report_phase
endclass : average