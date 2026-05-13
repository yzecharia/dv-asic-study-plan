class command_monitor extends uvm_component;

    `uvm_component_utils(command_monitor)

    uvm_analysis_port #(command_t) ap;
    function new (string name = "command_monitor", uvm_component parent = null);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction : new

    function void build_phase (uvm_phase phase);
        virtual alu_if aluif;
        super.build_phase(phase);
        if (!uvm_config_db #(virtual alu_if)::get(this, "", "aluif", aluif))
            $fatal(1, "Failed to get aluif");
        aluif.command_monitor_h = this;
    endfunction : build_phase

    function void write_to_monitor (command_t cmd);
        `uvm_info(get_type_name(), $sformatf("Command: op=%0s a=%0h b=%0h", cmd.op.name(), cmd.a, cmd.b), UVM_HIGH)
        ap.write(cmd);
    endfunction : write_to_monitor


endclass : command_monitor
