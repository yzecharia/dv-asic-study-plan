// ============================================================================
// memtrans_pkg.sv — Reusable package for Chapter 5 exercises
// ============================================================================
// Import it from any testbench with:
//     import memtrans_pkg::*;
// ============================================================================
package memtrans_pkg;

    // ─── Helper class: PrintUtilities ──────────────────────────
    class PrintUtilities;
        function void print_4(input string name, input [3:0] val_4bits);
            $display("%t: %s = %h", $time, name, val_4bits);
        endfunction

        function void print_8(input string name, input [7:0] val_8bits);
            $display("%t: %s = %h", $time, name, val_8bits);
        endfunction
    endclass : PrintUtilities


    // ─── Main class: MemTrans ──────────────────────────────────
    class MemTrans;

        logic [7:0]        data_in;
        logic [3:0]        address;
        static logic [3:0] last_address;
        PrintUtilities     printer;

        function new(input logic [7:0] data_in = 8'b0,
                            logic [3:0] address = 4'b0);
            this.data_in = data_in;
            this.address = address;
            last_address = address;
            printer      = new();
        endfunction : new

        function void print();
            $display("data_in = %b, address = %b", data_in, address);
        endfunction : print

        function void print_all();
            printer.print_8("data_in", data_in);
            printer.print_4("address", address);
        endfunction : print_all

        static function void print_last_address();
            $display("last_address = %b", last_address);
        endfunction : print_last_address

    endclass : MemTrans

endpackage : memtrans_pkg
