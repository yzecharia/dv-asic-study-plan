class consumer extends uvm_component;
    `uvm_component_utils(consumer)

    uvm_get_port #(int) get_port_h;
    virtual clk_bfm clk_bfm_i;
    int shared;

    function new (string name = "consumer", uvm_component parent = null);
        super.new(name, parent);
        get_port_h = new("get_port_h", this);
    endfunction : new

    function void build_phase (uvm_phase phase);
        clk_bfm_i = nonblocking_pkg::clk_bfm_i;
    endfunction : build_phase

    task run_phase (uvm_phase phase);
        forever begin
            @(posedge clk_bfm_i.clk);
            if (get_port_h.try_get(shared))
                $display("%0tns Received: %0d", $time, shared);
        end
    endtask : run_phase

endclass : consumer