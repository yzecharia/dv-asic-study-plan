class Transaction;
    rand bit [7:0] addr;
    rand bit [31:0] data;

    virtual function void display();
        $display("Transaction: addr=%0h, data=%0h", addr, data);
    endfunction : display

    virtual function string get_type();
        return $typename(this);
    endfunction: get_type

endclass : Transaction