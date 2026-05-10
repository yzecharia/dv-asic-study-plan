class dice_test extends uvm_test;
    `uvm_component_utils(dice_test)

    dice_roller dice_roller_h;
    average average_h;
    coverage_mon coverage_mon_h;
    histogram histogram_h;

    function new (string name = "dice_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        dice_roller_h = dice_roller::type_id::create("dice_roller_h", this);
        average_h = average::type_id::create("average_h", this);
        coverage_mon_h = coverage_mon::type_id::create("coverage_mon_h", this);
        histogram_h = histogram::type_id::create("histogram_h", this);
    endfunction : build_phase

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        dice_roller_h.ap.connect(average_h.analysis_export);
        dice_roller_h.ap.connect(coverage_mon_h.analysis_export);
        dice_roller_h.ap.connect(histogram_h.analysis_export);
    endfunction : connect_phase

endclass : dice_test;