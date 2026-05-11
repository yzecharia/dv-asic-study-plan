class result_monitor extends uvm_component;
    `uvm_component_utils(result_monitor)

    uvm_analysis_port #(shortint r) ap;

    function void write_to_monitor(shortint r);
        $display("RESULT MONITOR: resultA: 0x%0h", r);
        ap.write(r);
    endfunction : write_to_monitor

    function void build_phase (uvm_phase phase);
        virtual tinyalu_bfm bfm;

        if (!uvm_config_db #(virtual tinyalu_bfm)::get(null, "*", "bfm", bfm))
            $fatal("Failed to get BFM");

        bfm.result_monitor_h = this;

        ap = new ("ap", this);
    endfunction : build_phase

    function new (string name = "result_monitor", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

endclass : result_monitor