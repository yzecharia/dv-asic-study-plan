package alu_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    parameter int WIDTH   = 8;
    localparam int NUM_TXN = 1000;

    typedef enum logic [2:0] {
        ADD = 3'b000,
        SUB = 3'b001,
        AND = 3'b010,
        OR  = 3'b011,
        XOR = 3'b100
    } operation_e;

    `include "alu_base_tester.svh"
    `include "alu_random_tester.svh"
    `include "alu_directed_tester.svh"
    `include "alu_scoreboard.svh"
    `include "alu_coverage.svh"
    `include "alu_env.svh"
    `include "alu_random_test.svh"
    `include "alu_directed_test.svh"

endpackage : alu_pkg