class dice_test extends uvm_test;
    `uvm_component_utils(dice_test)

    dice_roller dice_roller_h;
    coverage coverage_h;
    histogram histogram_h;
    average average_h;

    function void connect_phase(uvm_phase phase);
        dice_roller_h.roll_ap.connect(coverage_h.analysis_export);
        dice_roller_h.roll_ap.connect(histogram_h.analysis_export);
        dice_roller_h.roll_ap.connect(average_h.analysis_export);
    endfunction : connect_phase

    function new (string name = "dice_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        dice_roller_h = new("dice_roller_h", this);
        coverage_h = new("coverage_h", this);
        histogram_h = new("histogram_h", this);
        average_h = new("average_h", this);
    endfunction : build_phase
endclass : dice_test