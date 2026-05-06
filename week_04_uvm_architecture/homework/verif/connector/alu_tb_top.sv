module alu_tb_top;
    import uvm_pkg::*;
    import alu_pkg::*;
    `include "uvm_macros.svh"

    bit clk, rst_n;

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    task reset_dut();
        rst_n = 1'b0;
        #20 rst_n = 1'b1;
    endtask

    initial reset_dut();

    alu_if aluif(.clk(clk), .rst_n(rst_n));
    alu dut (
        .clk(aluif.clk),
        .rst_n(aluif.rst_n),
        .operand_a(aluif.operand_a),
        .operand_b(aluif.operand_b),
        .operation(aluif.operation),
        .valid_in(aluif.valid_in),
        .result(aluif.result),
        .valid_out(aluif.valid_out)
    );

    initial begin
        uvm_config_db #(virtual alu_if)::set(null, "*", "aluif", aluif);
        run_test();
    end
endmodule : alu_tb_top