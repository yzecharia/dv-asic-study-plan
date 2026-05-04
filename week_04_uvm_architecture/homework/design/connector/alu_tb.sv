// Design HW1 — ALU sanity TB (non-UVM). Spec: docs/week_04.md (Design HW1).
module alu_tb;
        typedef enum logic [2:0] {
        ADD = 3'b000,
        SUB = 3'b001,
        AND = 3'b010,
        OR = 3'b011,
        XOR = 3'b100
    } operation_e;

    operation_e op;

    logic clk, rst_n;
    logic [8:0] expected_result;
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    alu_if #(8) u_if(.clk(clk), .rst_n(rst_n));

    alu #(8) dut (.clk(u_if.clk), .rst_n(u_if.rst_n),
                .operand_a(u_if.operand_a), .operand_b(u_if.operand_b),
                .operation(u_if.operation), .valid_in(u_if.valid_in),
                .result(u_if.result), .valid_out(u_if.valid_out));



    initial begin
        reset();
        op = op.first();
        repeat(op.num()) begin
            drive(8'h00, 8'h00, op, 1'b1);
            drive(8'h00, 8'h00, op, 1'b0);
            drive(8'hFF, 8'hFF, op ,1'b1);
            drive(8'hFF, 8'hFF, op ,1'b0);
            drive(8'h00, 8'hFF, op, 1'b1);
            drive(8'hFF, 8'h00, op, 1'b0);
            op = op.next();
        end
        repeat (1000) begin
            drive(8'($urandom), 8'($urandom), 3'($urandom), 1'($urandom));
        end

        $display("Test Pass");
        $finish;
    end

    task reset();
    #20; rst_n = 1'b0;
    #20; rst_n = 1'b1;
    #20;
    endtask : reset

    task drive (input logic[7:0] a, b, input logic [2:0] op_d, input logic v_in);
        @(u_if.cb);
        u_if.cb.operand_a <= a;
        u_if.cb.operand_b <= b;
        u_if.cb.operation <= op_d;
        u_if.cb.valid_in <= v_in;
        @(u_if.cb);
        #1;
        verify();
    endtask : drive

    task verify();
        operation_e dut_op;                                                                                                                                                                                           
        bit op_was_valid;                                                                                                                                                                                               
        bit expected_v_out;                                                                                                                                                                                           
                                                                                                                                                                                                                        
        op_was_valid = ($cast(dut_op, u_if.operation) != 0);                                                                                                                                                       
        expected_v_out = op_was_valid && u_if.valid_in;                                                                                                                                                                
                                                                                                                                                                                                                    
        if (u_if.valid_out !== expected_v_out)                                                                                                                                                                          
            $fatal(1, "valid_out mismatch: op=%0b valid_in=%0b → expected=%0b got=%0b",                                                                                                                               
                    u_if.operation, u_if.valid_in, expected_v_out, u_if.valid_out);                                                                                                                                      
                                                                                                                                                                                                                    
        // Only check result when DUT actually produced a new one                                                                                                                                                       
        if (expected_v_out) begin                                                                                                                                                                                     
            case (dut_op)                                                                                                                                                                                             
                ADD: expected_result = u_if.operand_a + u_if.operand_b;                                                                                                                                         
                SUB: expected_result = u_if.operand_a - u_if.operand_b;                                                                                                                                       
                AND: expected_result = {1'b0, u_if.operand_a & u_if.operand_b};                                                                                                                                         
                OR: expected_result = {1'b0, u_if.operand_a | u_if.operand_b};                                                                                                                                         
                XOR: expected_result = {1'b0, u_if.operand_a ^ u_if.operand_b};                                                                                                                                       
                default: $fatal(1, "Unreachable: dut_op=%0b after $cast", dut_op);                                                                                                                                      
            endcase                                                                                                                                                                                                     
            if (u_if.result !== expected_result)                                                                                                                                                                      
                $fatal(1, "result mismatch: op=%s a=%0h b=%0h → expected=%0h got=%0h",                                                                                                                                  
                        dut_op.name(), u_if.operand_a, u_if.operand_b, expected_result, u_if.result);                                                                                                                    
        end                                
    endtask:verify
endmodule : alu_tb
