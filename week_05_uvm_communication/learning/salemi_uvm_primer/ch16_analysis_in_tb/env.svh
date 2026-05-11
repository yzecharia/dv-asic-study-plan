class env extends uvm_env;
    `uvm_component_utils(env)

    random_tester random_tester_h;
    coverage coverage_h;
    command_monitor command_monitor_h;
    result_monitor result_monitor_h;
    scoreboard scoreboard_h;

    function new (string name, uvm_component parent);
        super.ner(name, parent);
    endfunction : new

    function void build_phase (uvm_phase phase);
        random_tester_h = random_tester::type_id::create("random_tester_h", this);
        coverage_h = coverage::type_id::create("coverage_h", this);
        scoreboard_h = scoreboard::type_id::create("scoreboard_h", this);
        command_monitor_h = command_monitor::type_id::create("commamd_monitor_h", this);
        result_monitor_h = result_monitor::type_id::create("result_monitor_h", this);
    endfunction : build_phase

    function void connect_phase (uvm_phase phase);
        result_monitor_h.ap.connect(scoreboard_h.analysis_export);
        commamd_monitor_h.ap.connect(scoreboard_h.cmd_f.analysis_export);
        commamd_monitor_h.ap.connect(coverage_h.analysis_export);
    endfunction : connect_phase
endclass : env