class coverage;
    virtual tinyalu_bfm bfm;
    int adds, ands, xors, muls;

    function new (virtual tinyalu_bfm b);
        this.bfm = b;
        adds = 0;
        ands = 0;
        xors = 0;
        muls = 0;
    endfunction : new

    task execute();
        forever begin
            @(posedge bfm.done);
            #1;
            case (bfm.op_set)
                add_op: adds++;
                and_op: ands++;
                xor_op: xors++;
                mul_op: muls++;
                default: ;
            endcase
        end
    endtask : execute

endclass : coverage
