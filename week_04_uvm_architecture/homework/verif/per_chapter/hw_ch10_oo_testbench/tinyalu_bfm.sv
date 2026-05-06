interface tinyalu_bfm;
    import tinyalu_pkg::*;

    bit           clk;
    bit           reset_n;
    byte unsigned A;
    byte unsigned B;
    operation_t   op_set;
    wire [2:0]    op;
    bit           start;
    wire          done;
    wire [15:0]   result;

    assign op = op_set;

    initial begin
        clk = 1'b0;
        forever #10 clk = ~clk;
    end

    task reset_alu();
        reset_n = 1'b0;
        start   = 1'b0;
        @(negedge clk);
        @(negedge clk);
        reset_n = 1'b1;
    endtask : reset_alu

    task send_op(input  byte unsigned iA,
                 input  byte unsigned iB,
                 input  operation_t   iop,
                 output shortint      alu_result);
        @(negedge clk);
        A      = iA;
        B      = iB;
        op_set = iop;
        start  = 1'b1;
        do
            @(negedge clk);
        while (done == 1'b0);
        start      = 1'b0;
        alu_result = result;
    endtask : send_op

endinterface : tinyalu_bfm
