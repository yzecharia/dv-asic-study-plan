class slow_driver extends uvm_component;

    `uvm_component_utils(slow_driver)

    function new (string name = "slow_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        repeat (5) begin
            #10 $display("SLOW: tick");
        end
        phase.drop_objection(this);
    endtask : run_phase

endclass : slow_driver