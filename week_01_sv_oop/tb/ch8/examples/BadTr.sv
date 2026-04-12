class BadTr extends Transaction;
    rand bit bad_csm;

    virtual function void calc_csm();
        super.calc_csm();           // Compute good csm
        if (bad_csm) csm = ~csm;    // Corrupt the csm bits
    endfunction : calc_csm

    virtual function void display(input string prefix="");
        $write("%sBadTr: bad_csm=%b, ", prefix, bad_csm);
        super.display();
    endfunction : display

    // Deep copy — must also copy the bad_csm field
    virtual function Transaction copy(input Transaction to=null);
        BadTr = bad;
        if (to == null) begin
            bad = new();
        end else begin
            $cast(bad, to);
        end
        super.copy();
        bad.bad_csm = this.bad_csm;

        return bad;    // BadTr IS-A Transaction, so return type is fine
    endfunction : copy

endclass : BadTr
