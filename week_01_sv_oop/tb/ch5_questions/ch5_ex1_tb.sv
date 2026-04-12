// ============================================================================
// Chapter 5 — Exercises 1-7 (MemTrans + PrintUtilities)
// ============================================================================
// The MemTrans and PrintUtilities classes now live in memtrans_pkg.sv so
// they can be reused by other testbenches.  Compile both files together:
//
//     ./run_xsim.sh tb/ch5_questions/memtrans_pkg.sv \
//                   tb/ch5_questions/ch5_ex1_tb.sv
// ============================================================================

program automatic test;
    import memtrans_pkg::*;                // bring in MemTrans + PrintUtilities

    MemTrans m;

    initial begin
        // ── Q1 / Q2 ───────────────────────────────────────────
        begin : q1_2
            m = new();
            m.print();
            m = null;
        end

        // ── Q3 / Q4 / Q5 / Q6 ─────────────────────────────────
        begin : q3_4
            MemTrans t1, t2;
            t1 = new(.data_in(8'h02));
            t2 = new(.data_in(8'h03), .address(4'h4));
            t1.print();
            t2.print();
            $display("last_address = %b", MemTrans::last_address);
            t1.print_last_address();
            t1.address = 4'hF;
            t1.print();
            t2.print();
            $display("last_address = %b", t1.last_address);
            MemTrans::print_last_address();
            t1 = null;
            t2 = null;
        end

        // ── Q7 ────────────────────────────────────────────────
        begin : q7
            MemTrans t3;
            t3 = new(8'hFA, 4'h8);
            t3.print_all();
        end
    end
endprogram : test
