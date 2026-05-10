class average extends uvm_subscriber #(int);
    `uvm_component_utils(average)
    
    int dice_total;
    int count;

    function new (string name = "average", uvm_component parent = null);
        super.new(name, parent);
        dice_total = 0;
        count = 0;
    endfunction : new

    function void write(int t);
        dice_total += t;
        count++;
    endfunction : write

    function void report_phase(uvm_phase phase);
        if (count == 0)
            `uvm_info("AVG", "no rolls observed", UVM_LOW)
        else
            `uvm_info("AVG", $sformatf("Average roll: %0.2f", real'(dice_total)/count), UVM_LOW)
    endfunction : report_phase
endclass : average