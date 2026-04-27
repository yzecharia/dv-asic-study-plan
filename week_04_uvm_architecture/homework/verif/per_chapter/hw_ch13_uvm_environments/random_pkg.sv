package random_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"
    `include "base_tester.svh"
    `include "random_tester.svh"
    `include "add_tester.svh"
    `include "my_env.svh"
    `include "my_test.svh"

    typedef enum logic [2:0] {
        ADD,
        SUB,
        AND,
        XOR, 
        MUL
    } op_t;
endpackage : random_pkg