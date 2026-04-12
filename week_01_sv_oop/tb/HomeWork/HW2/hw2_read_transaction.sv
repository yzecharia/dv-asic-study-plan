class ReadTransaction extends Transaction;
    rand int unsigned latency;

    virtual function void display();
        $display("Read: addr=%0h, latency=%0d", addr, latency);
    endfunction : display

    virtual function string get_type();
        return "READ";
    endfunction : get_type
endclass : ReadTransaction