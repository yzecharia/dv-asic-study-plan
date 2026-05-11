package analysis_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    typedef enum bit [2:0] {
        no_op = 3'b000,
        add_op = 3'b001,
        and_op = 3'b010,
        xor_op = 3'b011,
        mul_op = 3'b100,
        rst_op = 3'b111
    } operation_t;

    typedef struct {
      byte unsigned A;
      byte unsigned B;
      operation_t op;
    } command_s;

    `include "producer.svh"
    `include "printer_a.svh"
    `include "printer_b.svh"
    `include "analysis_test.svh"

endpackage : analysis_pkg