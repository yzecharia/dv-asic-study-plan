class dice_roller extends uvm_component;
    `uvm_component_utils(dice_roller)

    rand bit [3:0] die1, die2;

    constraint c_dies {
        die1 inside {[1:6]};
        die2 inside {[1:6]};
    }

    uvm_analysis_port #(int) ap;

    function new (string name = "dice_roller", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    function void build_phase (uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
    endfunction : build_phase

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
            repeat (20) begin
                int dice_sum;
                // xsim 2024.1 bug: bare `randomize()` resolves to std::randomize() (no-op).
                // Must use explicit `this.` prefix or the call silently does nothing.
                if (!this.randomize()) `uvm_fatal("RAND", "dice randomize failed")
                dice_sum = die1 + die2;
                ap.write(dice_sum);
            end
        phase.drop_objection(this);

    endtask : run_phase


endclass : dice_roller