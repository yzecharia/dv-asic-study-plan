class WriteTransaction extends Transaction;
    rand bit [3:0] byte_enable;
        
    virtual function void display();
        $display("Write: addr=%0h, data=%0h, be=%0h", addr, data, byte_enable);
    endfunction : display

    virtual function string get_type();
        return "Write";
    endfunction : get_type
endclass : WriteTransaction