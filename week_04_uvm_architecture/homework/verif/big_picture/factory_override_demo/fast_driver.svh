class fast_driver extends slow_driver;
    `uvm_component_utils(fast_driver)

    function new (string name = "fast_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    task run_phase (uvm_phase phase);
        phase.raise_objection(this);
        repeat (5) begin
            #1 $display("FAST: tick");
        end
        phase.drop_objection(this);
    endtask : run_phase
endclass : fast_driver