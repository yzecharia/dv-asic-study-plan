class tester;
    virtual tinyalu_bfm bfm;

    function new (virtual tinyalu_bfm b);
        this.bfm = b;
    endfunction : new

    protected function operation_t get_op();
        bit [1:0] op_choice;
        op_choice = $random;
        case (op_choice)
            2'b00: return add_op;
            2'b01: return and_op;
            2'b10: return xor_op;
            2'b11: return mul_op;
        endcase
    endfunction : get_op

    protected function byte get_data();
        bit [1:0] zero_ones;
        zero_ones = $random;
        if (zero_ones == 2'b00)
            return 8'h00;
        else if (zero_ones == 2'b11)
            return 8'hFF;
        else
            return $random;
    endfunction : get_data

    task execute();
        byte unsigned     iA;
        byte unsigned     iB;
        shortint unsigned result;
        operation_t       op_set;
        bfm.reset_alu();
        repeat (100) begin
            op_set = get_op();
            iA     = get_data();
            iB     = get_data();
            bfm.send_op(iA, iB, op_set, result);
            $display("%2h %6s %2h = %4h", iA, op_set.name(), iB, result);
        end
        $display("OO TB DEMO PASS");
        $finish;
    endtask : execute

endclass : tester
