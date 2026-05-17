class communication_test extends uvm_test;
    `uvm_component_utils(communication_test)

    producer producer_h;
    consumer consumer_h;
    uvm_tlm_fifo #(int) fifo_h;

    function new (string name = "communication_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    function void build_phase (uvm_phase phase);
        producer_h = new("producer_h", this);
        consumer_h = new("consumer_h", this);
        fifo_h = new("fifo_h", this);
    endfunction : build_phase

    function void connect_phase (uvm_phase phase);
        producer_h.put_port_h.connect(fifo_h.put_export);
        consumer_h.get_port_h.connect(fifo_h.get_export);
    endfunction : connect_phase
    
endclass : communication_test