virtual class alu_base_tester extends uvm_component;
    `uvm_component_utils(alu_base_tester)

    virtual alu_if aluif;

    function new(string name = "alu_base_tester", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual alu_if)::get(this, "", "aluif", aluif))
            `uvm_fatal("NOALUIF", "aluif is not set in config_db")
    endfunction : build_phase

    task run_phase(uvm_phase phase);
        bit [WIDTH-1:0] iA, iB;
        operation_e op;

        phase.raise_objection(this);
            wait (aluif.rst_n === 1'b1);
            @(aluif.driver_cb);
            repeat (NUM_TXN) begin
                iA = get_operand();
                iB = get_operand();
                op = get_operation();
                drive_in(iA, iB, op);
            end
        phase.drop_objection(this);
    endtask : run_phase

    task drive_in(bit [WIDTH-1:0] a, bit [WIDTH-1:0] b, operation_e op);
        @(aluif.driver_cb);
        aluif.driver_cb.operand_a <= a;
        aluif.driver_cb.operand_b <= b;
        aluif.driver_cb.operation <= op;
        aluif.driver_cb.valid_in <= 1'b1;
        @(aluif.driver_cb);
        aluif.driver_cb.valid_in <= 1'b0;
        @(aluif.driver_cb iff aluif.driver_cb.valid_out);
    endtask : drive_in

    pure virtual function bit [WIDTH-1:0] get_operand();
    pure virtual function operation_e get_operation();
endclass : alu_base_tester