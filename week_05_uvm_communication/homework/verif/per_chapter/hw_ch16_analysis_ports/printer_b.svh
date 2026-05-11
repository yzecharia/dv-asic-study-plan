class printer_b extends uvm_subscriber #(command_s);
    `uvm_component_utils(printer_b)

    function new (string name = "printer_b", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    function void write (command_s t);
        `uvm_info("PRINT_B", $sformatf("A=%0h B=%0h operation=%0s", t.A, t.B, t.op.name()), UVM_LOW)
    endfunction : write

endclass : printer_b