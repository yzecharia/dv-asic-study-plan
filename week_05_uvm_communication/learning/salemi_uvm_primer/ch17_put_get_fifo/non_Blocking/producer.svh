class producer extends uvm_component;
    `uvm_component_utils(producer)

    int shared;
    uvm_put_port #(int) put_port_h;
    
    function new (string name = "producer", uvm_component parent = null);
        super.new(name, parent);
        put_port_h = new("put_port_h", this);
    endfunction : new

    task run_phase (uvm_phase phase);
        phase.raise_objection(this);
        repeat (3) begin
            put_port_h.put(++shared);
            $display("%0tns Send %0d", $time, shared);
        end
        #17;
        phase.drop_objection(this);
    endtask : run_phase


endclass : producer