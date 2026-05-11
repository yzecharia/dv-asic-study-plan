class producer extends uvm_component;
    `uvm_component_utils(producer)

    uvm_analysis_port #(command_s) ap;

    function new (string name = "producer", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    function void build_phase (uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
    endfunction : build_phase

    task run_phase (uvm_phase phase);
        command_s cmd;
        phase.raise_objection(this);
            repeat (5) begin
                cmd.A = $urandom;
                cmd.B = $urandom;
                void'(std::randomize(cmd.op));
                ap.write(cmd);
                `uvm_info("PROD", $sformatf("write cmd: A=%0h B=%0h op=%0s", cmd.A, cmd.B, cmd.op.name()), UVM_LOW)
                #10ns;
            end
        phase.drop_objection(this);
    endtask : run_phase

endclass : producer