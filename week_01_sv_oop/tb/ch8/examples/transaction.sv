class Transaction;
    rand bit [31:0] src, dst, data[8]; // Random variables
    bit [31:0] csm;                    // Calculated Check Sum

    virtual function void calc_csm();
        csm = src ^ dst ^ data.xor;
    endfunction : calc_csm

    virtual function void display(input string prefix="");
        $display("%sTr: src=%h, dst=%h, csm=%h", prefix, src, dst, csm);
    endfunction : display

    virtual function Transaction copy(input Transaction to=null);
        if (to == null)
            copy = new();
        else begin
            copy = to;
        end

        copy.src = this.src;
        copy.dst = this.dst;
        copy.data = this.data;
        copy.csm = this.csm;
        return copy;
    endfunction : copy

endclass : Transaction
