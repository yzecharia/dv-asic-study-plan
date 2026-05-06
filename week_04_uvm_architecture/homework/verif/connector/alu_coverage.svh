class alu_coverage extends uvm_component;
    `uvm_component_utils(alu_coverage)

    virtual alu_if aluif;

    /*
    Coverage axes:                                                                                                                      
        cp_op           : 5 ops    {ADD, SUB, AND, OR, XOR}
        cp_a_corner     : 3 bins   {zero=0, max=255, mid=[1:254]}                                                                         
        cp_b_corner     : 3 bins   {zero=0, max=255, mid=[1:254]}                                                                         
        cross_op_a_b    : 5 × 3 × 3 = 45 bins (ignore_bins for [mid,mid] crosses if not interesting)  
    */

    covergroup cg_alu;
        cp_op: coverpoint aluif.monitor_cb.operation {
            bins ops[] = {[ADD:XOR]};
        }
        cp_operand_a: coverpoint aluif.monitor_cb.operand_a {
            bins a_zero = {8'h00};
            bins a_ones = {8'hFF};
            bins a_mid = {[8'h01:8'hFE]};
        }
        cp_operand_b: coverpoint aluif.monitor_cb.operand_b {
            bins b_zero = {8'h00};
            bins b_ones = {8'hFF};
            bins b_mid = {[8'h01:8'hFE]};
        }

        cross_op_opera_operb: cross cp_op, cp_operand_a, cp_operand_b {
            ignore_bins both_mid = binsof(cp_operand_a.a_mid) && binsof(cp_operand_b.b_mid);
        }
    endgroup : cg_alu


    function new(string name = "alu_coverage", uvm_component parent = null);
        super.new(name, parent);
        cg_alu = new();
    endfunction : new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual alu_if)::get(this, "", "aluif", aluif))
            `uvm_fatal("NOALUIF", "aluif is not set in config_db")
    endfunction : build_phase

    task run_phase(uvm_phase phase);
        forever begin
            @(aluif.monitor_cb iff aluif.monitor_cb.valid_out);
            cg_alu.sample();
        end
    endtask : run_phase

endclass : alu_coverage