class wr_txn;
    rand bit [7:0] wrtxh;

    virtual function void display();
        $display("wr_txn:  wrtxh=%0d", wrtxh);
    endfunction : display
endclass : wr_txn

class wr_txn2 extends wr_txn;
    rand bit [15:0] data_in;

    virtual function void display();
        $display("wr_txn2: wrtxh=%0d data_in=%0d", wrtxh, data_in);
    endfunction : display
endclass : wr_txn2

class generator;
    wr_txn wtxnh;
    mailbox #(wr_txn) gen_drv_mb;

    function new (mailbox #(wr_txn) gen_drv_mb, wr_txn txn_type);
        this.gen_drv_mb = gen_drv_mb;
        wtxnh = txn_type;
    endfunction : new

    task send_packet();
        assert(wtxnh.randomize());
        wtxnh.display();

        gen_drv_mb.put(wtxnh);
    endtask : send_packet

endclass : generator

class driver;
    mailbox #(wr_txn) gen_drv_mb;

    function new (mailbox #(wr_txn) gen_drv_mb);
        this.gen_drv_mb = gen_drv_mb;
    endfunction : new

    task drive_packet();
        wr_txn wtxnh;
        gen_drv_mb.get(wtxnh);
        wtxnh.display();
    endtask : drive_packet
endclass : driver

class env;
    generator genh;
    driver drvh;
    wr_txn txn_type;

    mailbox #(wr_txn) gen_drv_mb;

    function new(wr_txn txn_type);
        gen_drv_mb = new();
        this.txn_type = txn_type;
        genh = new(gen_drv_mb, txn_type);
        drvh = new(gen_drv_mb);
    endfunction : new

    task run();
        genh.send_packet();
        drvh.drive_packet();
    endtask : run
endclass : env

module test;
    env envh;
    wr_txn txnh;

    initial begin
        wr_txn2 txnh2 = new();
        txnh = txnh2;

        envh = new(txnh);
        envh.run();
        $display("test finished");
        $finish;
    end
endmodule : test
