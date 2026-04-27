/*
Design an interface and testbench for the ARM Advanced High-performance Bus (AHB).
You are provided a bus master as verification IP that can initiate AHB transactions. 
You are testing a slave design. The testbench instantiates the interface, slave, and master. 
Your interface will display an error if the transaction type is not IDLE or NONSEQ on the negative edge of HCLK. 
The AHB signals are described in Table 4.2.
*/

interface ahb_if (input bit HCLK);
    logic [20:0] HADDR;     //Address
    logic HWRITE;           // Write flag: 1=write, 0=read
    logic [1:0] HTRANS;     // Transaction type: {2'b00=IDLE, 2'b10=NONSEQ}
    logic [7:0] HWDATA, HRDATA;

    clocking cb @(posedge HCLK);
        output HADDR, HWRITE, HTRANS, HWDATA;
        input  HRDATA;
    endclocking : cb

    clocking mon_cb @(posedge HCLK);
        input HADDR, HWRITE, HTRANS, HWDATA, HRDATA;
    endclocking

    modport slave (
        input  HCLK, HADDR, HWRITE, HTRANS, HWDATA,
        output HRDATA
    );

    modport master (
        clocking cb
    );

    modport monitor (
        clocking mon_cb
    );

    property valid_trans_on_negedge;
        @(negedge HCLK) HTRANS inside {2'b00, 2'b10};
    endproperty

    assert property (valid_trans_on_negedge) else $error("@[%0t]: AHB: illegal HTRANS=%b", $time, HTRANS);


endinterface : ahb_if

module ahb_slave (ahb_if.slave bus);
    logic [7:0] mem [logic [20:0]];
    always_ff @(posedge bus.HCLK) begin
        if (bus.HTRANS == 2'b10 && bus.HWRITE) mem[bus.HADDR] = bus.HWDATA;
        else if (bus.HTRANS == 2'b10 && !bus.HWRITE) bus.HRDATA <= mem[bus.HADDR];
    end
endmodule : ahb_slave

module ahb_master (ahb_if.master bus);
    initial begin
        @(bus.cb);
        bus.cb.HTRANS <= 2'b00;

        @(bus.cb);
        bus.cb.HADDR  <= 21'h123;
        bus.cb.HTRANS <= 2'b10;
        bus.cb.HWRITE <= 1'b1;
        bus.cb.HWDATA <= 8'hDD;

        @(bus.cb);
        bus.cb.HWRITE <= 1'b0;

        @(bus.cb);
        @(bus.cb);
        if (bus.cb.HRDATA === 8'hDD)
            $display("@[%0t]: PASS read 0x%h from addr 0x123", $time, bus.cb.HRDATA);
        else
            $error("@[%0t]: FAIL expected 0xDD got 0x%h", $time, bus.cb.HRDATA);

        bus.cb.HTRANS <= 2'b00;

        @(bus.cb);
        bus.cb.HTRANS <= 2'b01;

        @(bus.cb);
        bus.cb.HTRANS <= 2'b00;

        @(bus.cb);
        $finish;
    end
endmodule : ahb_master

module ahb_monitor (ahb_if.monitor bus);
    initial forever begin
        @(bus.mon_cb);
        if (bus.mon_cb.HTRANS == 2'b10)
            $display("@[%0t]: MON %s addr=0x%h wdata=0x%h rdata=0x%h",
                     $time,
                     bus.mon_cb.HWRITE ? "WRITE" : "READ ",
                     bus.mon_cb.HADDR,
                     bus.mon_cb.HWDATA,
                     bus.mon_cb.HRDATA);
    end
endmodule : ahb_monitor

module tb_top;
    bit clk;
    always #10 clk = ~clk;

    ahb_if bus (clk);
    ahb_slave DUT (.*);
    ahb_master test (.*);
    ahb_monitor mon (.*);
endmodule : tb_top