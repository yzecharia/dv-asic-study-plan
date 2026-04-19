
module ch9_ex1;

    typedef enum {ADD, SUB, MULT, DIV} opcode_e;

    logic clk = 0;
    always #5 clk = ~clk;  

    opcode_e current_op;
    byte     current_operand1, current_operand2;

    class Transaction;
        rand opcode_e opcode;
        rand byte     operand1, operand2;

        constraint c_no_div {
            opcode != DIV;
        }

        covergroup CovOpCodes @(posedge clk);
            opcode_cp: coverpoint current_op {
                bins add_or_sub = {ADD, SUB};
                bins sub_after_add = (ADD => SUB);
                illegal_bins illegal_div = {DIV};
            }   
            operand1_cp: coverpoint current_operand1 {
                bins max_neg = {-128};
                bins zero    = {0};
                bins max_pos = {127};
                bins others  = default;
            }
            operand2_cp: coverpoint current_operand2 {
                bins max_neg = {-128};
                bins zero    = {0};
                bins max_pos = {127};
                bins others  = default;
            }
            cross_op_op1: cross opcode_cp, operand1_cp {
                bins interesting = binsof(operand1_cp) intersect {-128,127}
                                   && binsof(opcode_cp.add_or_sub);
                option.weight = 5;
            }
        endgroup

        function new();
            CovOpCodes = new();
        endfunction : new
    endclass : Transaction

    Transaction tr;

    initial begin
        tr = new();

        repeat (50) begin
            @(posedge clk);
            assert(tr.randomize());
            current_op = tr.opcode;   
            current_operand1 = tr.operand1;
            current_operand2 = tr.operand2;
            $display("[%0t] opcode=%s operand1=%0d operand2=%0d",
                     $time, tr.opcode.name(), tr.operand1, tr.operand2);
        end

        $display("\n=== Coverage Report ===");
        $display("CovOpCodes = %6.2f%%", tr.CovOpCodes.get_coverage());
        $display("operand1_cp coverage = %6.2f%%", tr.CovOpCodes.operand1_cp.get_coverage());
        $display("opcode_cp coverage = %6.2f%%", tr.CovOpCodes.opcode_cp.get_coverage());
        $finish;
    end

endmodule : ch9_ex1
