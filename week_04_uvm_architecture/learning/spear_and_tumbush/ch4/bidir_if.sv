interface bidir_if (input bit clk);
    wire [7:0] data;            // Bidirectional signal
    clocking cb @(posedge clk);
        inout data;
    endclocking
    modport TEST (clocking cb);
endinterface : bidir_if

program automatic test (bidir_if.TEST mif);
    initial begin
        mif.cb.data <= 'z;      // Tri state the bus
        @mif.cb;
        $displayh(mif.cb.data); // Read from the bus
        @mif.cb;
        mif.cb.data <= 7'h5a;   // Drive the bus
        @mif.cb;
        $displayh(mif.cb.data); // Read from bus
        mif.cb.data <= 'z;      // Release the bus
    end
endprogram : test