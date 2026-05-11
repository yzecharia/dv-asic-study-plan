class analysis_test extends uvm_test;
    `uvm_component_utils(analysis_test)

    printer_a printer_a_h;
    printer_b printer_b_h;
    producer producer_h;

    function new (string name = "analysis_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    function void build_phase (uvm_phase phase);
        super.build_phase(phase);
        producer_h = producer::type_id::create("producer_h", this);
        printer_a_h = printer_a::type_id::create("printer_a_h", this);
        printer_b_h = printer_b::type_id::create("printer_b_h", this);
    endfunction : build_phase

    function void connect_phase (uvm_phase phase);
        super.connect_phase(phase);
        producer_h.ap.connect(printer_a_h.analysis_export);
        producer_h.ap.connect(printer_b_h.analysis_export);
    endfunction : connect_phase
    
endclass : analysis_test