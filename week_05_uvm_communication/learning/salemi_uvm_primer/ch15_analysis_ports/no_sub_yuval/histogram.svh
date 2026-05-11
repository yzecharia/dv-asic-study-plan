class histogram extends uvm_component;
    `uvm_component_utils(histogram)

    int rolls[int];

    function new (string name = "histogram", uvm_component parent = null);
        super.new(name, parent);
        for (int i = 2; i <= 12; i++) 
            rolls[i] = 0;
    endfunction : new

    function void write (int t);
        rolls[t]++;
    endfunction : write

    function void report_phase (uvm_phase phase);
        string bar;
        string message;

        message = "\n";
        foreach (rolls[i]) begin
            string roll_msg;
            bar = "";
            repeat (rolls[1]) begin
                roll_msg = $sformatf("%2d: %s\n", i, bar);
                message = {message, roll_msg};
            end
        end
        $display(message);
    endfunction : report_phase
endclass : histogram