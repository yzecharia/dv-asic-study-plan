package alu_pkg;
    typedef enum logic [2:0] {
        OP_ADD,
        OP_SUB,
        OP_AND,
        OP_OR,
        OP_XOR,
        OP_SHL,
        OP_SHR,
        OP_NOP
    } alu_op_t;

    typedef struct packed {
        alu_op_t op;
        logic [7:0] a;
        logic [7:0] b;
        logic [3:0] id;
        logic valid;
    } command_t; // total 24 bits

    typedef struct packed {
        logic [7:0] result;
        logic error; // Overflow and no op indicator
        logic [3:0] id;
        logic valid;
    } result_t; // total 14 bits
endpackage : alu_pkg
