// Ch.7 §7.7 — Full Testbench Pattern: Generator → Driver with Mailbox
//
// This is the pattern that UVM automates. Understanding this "from scratch"
// version makes UVM's Sequence → Driver flow much clearer.
//
//  ┌───────────┐  mailbox   ┌──────────┐
//  │ Generator  │── put() ─→│  Driver   │──→ (simulated DUT interface)
//  └───────────┘           └──────────┘
//       ↑ creates N                ↑ consumes & "drives"
//         random transactions        each transaction

class Packet;
    static int count = 0;
    int id;
    rand bit [7:0] data;
    rand bit [3:0] addr;
    rand bit       rw;  // 0=read, 1=write

    function new();
        id = count++;
    endfunction

    function void display(string tag);
        $display("[%0t] %s pkt#%0d: %s addr=%0d data=%0d",
                 $time, tag, id, rw ? "WR" : "RD", addr, data);
    endfunction
endclass

class Generator;
    mailbox #(Packet) mbx;
    int num_packets;

    function new(mailbox #(Packet) mbx, int n);
        this.mbx = mbx;
        this.num_packets = n;
    endfunction

    task run();
        repeat (num_packets) begin
            Packet p = new();
            assert(p.randomize());
            mbx.put(p);
            p.display("GEN");
        end
        $display("[%0t] Generator: done — sent %0d packets", $time, num_packets);
    endtask
endclass

class Driver;
    mailbox #(Packet) mbx;

    function new(mailbox #(Packet) mbx);
        this.mbx = mbx;
    endfunction

    task run();
        Packet p;
        forever begin
            mbx.get(p);  // blocks until packet available
            drive(p);
        end
    endtask

    task drive(Packet p);
        // Simulate bus timing
        p.display("DRV");
        #10;  // address phase
        #10;  // data phase
    endtask
endclass

program automatic test;
    initial begin
        mailbox #(Packet) mbx = new();
        Generator gen = new(mbx, 5);
        Driver    drv = new(mbx);

        $display("=== Generator → Driver Testbench Pattern ===\n");

        fork
            gen.run();
            drv.run();  // runs forever — waiting for packets
        join_any       // gen finishes first

        // Wait for driver to finish processing remaining packets
        wait(mbx.num() == 0);
        #20;  // let last drive() complete

        $display("\n[%0t] Test complete", $time);
    end
endprogram
