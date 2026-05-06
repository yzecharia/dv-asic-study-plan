class alu_env extends uvm_env;
    `uvm_component_utils(alu_env)

    alu_base_tester base_tester_h;
    alu_scoreboard scoreboard_h;
    alu_coverage coverage_h;

    function new (string name = "alu_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    function void build_phase (uvm_phase phase);
        super.build_phase(phase);
        base_tester_h = alu_base_tester::type_id::create("base_tester_h", this);
        scoreboard_h = alu_scoreboard::type_id::create("scoreboard_h", this);
        coverage_h = alu_coverage::type_id::create("coverage_h", this);
    endfunction : build_phase

    function void report_phase(uvm_phase phase);
        uvm_report_server svr = uvm_report_server::get_server();
        int unsigned err = svr.get_severity_count(UVM_ERROR)
                          + svr.get_severity_count(UVM_FATAL);
        if (err == 0)
            $display("ALU_TB PASS  cov=%0.2f%%", coverage_h.cg_alu.get_inst_coverage());
        else
            $display("ALU_TB FAIL  errors=%0d", err);
    endfunction : report_phase
endclass : alu_env