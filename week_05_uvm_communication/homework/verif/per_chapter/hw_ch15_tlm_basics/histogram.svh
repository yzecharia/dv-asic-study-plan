class histogram extends uvm_subscriber #(int);
    `uvm_component_utils(histogram)

    int roles[int];

    function new (string name = "histogram", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    function void write (int t);
        roles[t]++;
    endfunction : write

    function void report_phase (uvm_phase phase);
        string s = "\n Dice Histogram: \n";
        foreach (roles[i]) begin
            string bar = "";
            repeat (roles[i]) begin
                bar = {bar, "#"};
            end
            s = {s, $sformatf("     %2d: %-20s (%0d)\n", i, bar, roles[i])};
        end
        `uvm_info("HIST", s, UVM_LOW);
    endfunction : report_phase

endclass : histogram