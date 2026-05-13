class env extends uvm_env;
    `uvm_component_utils(env)

    command_monitor command_monitor_h;
    result_monitor result_monitor_h;
    scoreboard scoreboard_h;
    coverage coverage_h;
    base_tester tester;

    function new (string name = "env", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    function void build_phase (uvm_phase phase);
        super.build_phase(phase);
        command_monitor_h = command_monitor::type_id::create("command_monitor_h", this);
        result_monitor_h = result_monitor::type_id::create("result_monitor_h", this);
        scoreboard_h = scoreboard::type_id::create("scoreboard_h", this);
        coverage_h = coverage::type_id::create("coverage_h", this);
        tester = base_tester::type_id::create("tester", this);
    endfunction : build_phase

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        command_monitor_h.ap.connect(coverage_h.analysis_export);
        command_monitor_h.ap.connect(scoreboard_h.cmd_fifo.analysis_export);
        result_monitor_h.ap.connect(scoreboard_h.analysis_export);
    endfunction : connect_phase
endclass : env