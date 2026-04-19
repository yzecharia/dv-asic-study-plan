// =============================================================================
// Chapter 9 — Functional Coverage (Spear & Tumbush)
// Cheatsheet — organized by book section, with comments and runnable examples.
// Run with:  X1. xsim: Compile + Run TB Only   (Vivado xsim — best covergroup support)
// =============================================================================

module cheatsheet_ch9;

    // -------------------------------------------------------------------------
    // 9.1  — Gathering Coverage Data
    // -------------------------------------------------------------------------
    // "Have I tested enough?" is answered by coverage. Two main kinds:
    //   - Code coverage: did every line/branch/expression execute?  (tool generated)
    //   - Functional coverage: did every *interesting scenario* occur? (YOU define)
    //
    // Functional coverage is written by the verification engineer using covergroups.

    // -------------------------------------------------------------------------
    // 9.2  — Coverage Types
    // -------------------------------------------------------------------------
    // 9.2.1 Code coverage   — line, toggle, branch, FSM, expression (automatic)
    // 9.2.2 Functional cov. — you define what "done" means (manual)
    // 9.2.3 Bug rate        — not a metric you code; it's a project tracking curve
    // 9.2.4 Assertion cov.  — did each assertion fire / cover property hit?
    //
    // For signoff: 100% code coverage is necessary but not sufficient.
    //              100% functional coverage is the real goal.

    // -------------------------------------------------------------------------
    // 9.3 / 9.4  — A Simple Functional Coverage Example
    // -------------------------------------------------------------------------
    // A covergroup is a container. Inside it you put coverpoints.
    // A coverpoint tracks which values of a variable have been observed.

    logic clk = 0;
    always #5 clk = ~clk;       // 10 time-unit period

    // A transaction-like object to randomize and sample
    class Transaction;
        rand bit [31:0] data;
        rand bit [2:0]  dst;    // 8 values  (0..7)
        rand bit [3:0]  len;    // 16 values (0..15)
        rand bit        kind;   // 0 = READ, 1 = WRITE
    endclass

    Transaction tr;

    // -------------------------------------------------------------------------
    // 9.5  — Anatomy of a Covergroup
    // -------------------------------------------------------------------------
    // Structure:
    //   covergroup <name> [@trigger];     // optional trigger expression
    //       <label>: coverpoint <expr> { <bins/options> }
    //       <label>: cross <cp1>, <cp2>;
    //   endgroup
    //
    //   <inst> = new();        // instantiate
    //   <inst>.sample();       // manually collect (optional if trigger defined)

    // -------------------------------------------------------------------------
    // 9.6  — Triggering a Covergroup
    // -------------------------------------------------------------------------
    // 9.6.1 Clocking-block / @(posedge clk) trigger — auto-sample on clock edge
    // 9.6.2 .sample() — call manually from TB
    // 9.6.3 Event-based — covergroup cg @(evt);  then -> evt;

    // Example: covergroup that auto-samples on @(posedge clk)
    // NOTE: the covergroup samples whatever it references every clock edge —
    // so references must exist (non-null) from time 0. We use a plain signal
    // here instead of a class handle (which would be null at t=0).
    bit [2:0] auto_dst_sig;     // simple signal (not a class member)

    covergroup CovAutoSample @(posedge clk);
        coverpoint auto_dst_sig;
    endgroup

    CovAutoSample cg_auto;

    // -------------------------------------------------------------------------
    // 9.7  — Data Sampling (Bins)
    // -------------------------------------------------------------------------

    // 9.7.1  Individual bins & total coverage
    //   Default: one "auto" bin per value (up to auto_bin_max, default 64)
    //   Explicit: list bins with {bins name = {value_set}}
    covergroup CovBinsExplicit;
        cp_dst: coverpoint tr.dst {
            bins low    = {0, 1};           // single bin collecting 2 values
            bins mid[]  = {[2:5]};           // array of bins, one per value  (4 bins)
            bins hi     = {[6:7]};           // another range bin
        }
    endgroup
    CovBinsExplicit cg_bins;

    // 9.7.2  Bins for enumerated types
    typedef enum {READ, WRITE, NOP} op_e;
    op_e op;
    covergroup CovEnum;
        coverpoint op;          // auto-bins: one bin per enum label
    endgroup
    CovEnum cg_enum;

    // 9.7.3  Conditional coverage (iff)
    //   Only sample when condition is true — e.g., ignore reset cycles
    logic in_reset = 0;
    covergroup CovCond;
        coverpoint tr.dst iff (!in_reset);   // skip sampling while in_reset
    endgroup
    CovCond cg_cond;

    // 9.7.4  Bin naming — labels shown in reports
    //   (covered above — "low", "mid", "hi" are named bins)

    // 9.7.5  Creating bins automatically
    //   coverpoint without {bins ...} uses auto-bins.
    //   `option.auto_bin_max = N;` controls how many buckets auto-binning splits into.
    covergroup CovAutoMax;
        cp: coverpoint tr.data {
            option.auto_bin_max = 8;   // split 32-bit data into 8 buckets
        }
    endgroup
    CovAutoMax cg_auto_max;

    // 9.7.6  Covergroups in classes
    //   You can embed a covergroup inside a class — useful for OOP TBs.
    //   Demonstrated in class Packet below.

    // 9.7.7  Coverage options (instance-level)
    //   .at_least = N   → bin only counts hit after N samples
    //   .weight   = N   → how much this point contributes to group %
    //   .goal     = N   → target coverage for signoff (default 100)
    //   .comment = "..." → metadata string
    covergroup CovOptions;
        cp: coverpoint tr.dst {
            option.at_least = 2;      // each bin needs 2 hits to count
            option.weight   = 5;
            option.comment  = "dst coverage with at_least=2";
        }
    endgroup
    CovOptions cg_opts;

    // 9.7.9  Transition bins — what values followed what
    //   A => B   means B immediately after A
    //   A => B => C  is a 3-step sequence
    covergroup CovTrans;
        cp: coverpoint tr.dst {
            bins fill_up[]  = ([0:6] => [1:7]);   // any low-to-next transition
            bins drain      = (7 => 0);           // wrap from 7 back to 0
            bins triple     = (0 => 1 => 2);      // 3-step sequence
        }
    endgroup
    CovTrans cg_trans;

    // 9.7.10  Wildcard bins — ? matches 0 or 1
    covergroup CovWildcard;
        cp: coverpoint tr.dst {
            wildcard bins even = {3'b??0};    // any value ending in 0 (even)
            wildcard bins odd  = {3'b??1};    // any value ending in 1 (odd)
        }
    endgroup
    CovWildcard cg_wild;

    // 9.7.11  Ignore bins — values to exclude entirely
    covergroup CovIgnore;
        cp: coverpoint tr.dst {
            ignore_bins reserved = {7};       // value 7 is reserved, don't count
        }
    endgroup
    CovIgnore cg_ignore;

    // 9.7.12  Illegal bins — hitting these fails the test
    covergroup CovIllegal;
        cp: coverpoint tr.dst {
            illegal_bins invalid = {[5:6]};   // hitting 5 or 6 = error
        }
    endgroup
    // (Not instantiated below — would require extra setup to avoid fatal errors.)

    // 9.7.13  State machine coverage — coverpoint on a state variable + transitions
    //   Same as transition bins, applied to an FSM's `state` signal.

    // -------------------------------------------------------------------------
    // 9.8  — Cross Coverage
    // -------------------------------------------------------------------------
    // cross combines two or more coverpoints.
    // If cp_A has 2 bins and cp_B has 4 bins, cross makes 2*4 = 8 cross bins.

    covergroup CovCross;
        cp_kind: coverpoint tr.kind {
            bins rd = {0};
            bins wr = {1};
        }
        cp_dst:  coverpoint tr.dst {
            bins low  = {[0:3]};
            bins high = {[4:7]};
        }
        // 9.8.1  Basic cross
        cx_all: cross cp_kind, cp_dst;    // 2 * 2 = 4 cross bins

        // 9.8.2  Excluding cross bins
        //   ignore_bins ig = binsof(cp_kind.wr) && binsof(cp_dst.high);
        //   (commented — would remove 1 of the 4 bins)
    endgroup
    CovCross cg_cross;

    // -------------------------------------------------------------------------
    // 9.9 / 9.11  — Generic & Parameterized Covergroups
    // -------------------------------------------------------------------------
    // Covergroups can take arguments in `new()` to parameterize at runtime.
    // Useful when you want multiple covergroup instances for different signals.
    //
    // Example sketch (commented — needs extra scaffolding to run meaningfully):
    //   covergroup CovParam (ref bit [2:0] sig);
    //       coverpoint sig;
    //   endgroup
    //   CovParam cg1 = new(tr.dst);
    //   CovParam cg2 = new(other_signal);

    // -------------------------------------------------------------------------
    // 9.10  — Covergroup-level Options
    // -------------------------------------------------------------------------
    // Options can be placed at group level (apply to all coverpoints) or
    // per-coverpoint.
    //   option.per_instance = 1;  // track each instance separately
    //   option.name         = "my_cg";
    //   option.goal         = 90;

    // -------------------------------------------------------------------------
    // 9.12 / 9.13  — Analyzing Coverage Data
    // -------------------------------------------------------------------------
    // Runtime queries:
    //   real cov = cg.get_coverage();          // whole covergroup
    //   real cp  = cg.cp_name.get_coverage();  // one coverpoint
    //   real ix  = cg.get_inst_coverage();     // this instance only
    //
    // Offline: tools (xsim, VCS, Questa) dump UCDB / XML reports that can be
    //          merged across runs with different seeds — the industry approach.

    // =========================================================================
    // MAIN TEST — exercise all the covergroups above
    // =========================================================================
    initial begin
        // Instantiate everything
        cg_auto     = new();
        cg_bins     = new();
        cg_enum     = new();
        cg_cond     = new();
        cg_auto_max = new();
        cg_opts     = new();
        cg_trans    = new();
        cg_wild     = new();
        cg_ignore   = new();
        cg_cross    = new();

        // Do a short reset window to show `iff` in 9.7.3
        in_reset = 1;
        repeat (3) @(posedge clk);
        in_reset = 0;

        // Drive 200 random transactions
        repeat (200) begin
            @(posedge clk);
            tr = new();
            assert(tr.randomize());

            // mirror tr.dst into the plain signal for the auto-sample group
            auto_dst_sig = tr.dst;

            // randomize an enum (pick from {READ, WRITE, NOP})
            op = op_e'($urandom_range(0, 2));

            // Manually sample all covergroups except cg_auto
            // (cg_auto auto-samples on @posedge clk already)
            cg_bins.sample();
            cg_enum.sample();
            cg_cond.sample();
            cg_auto_max.sample();
            cg_opts.sample();
            cg_trans.sample();
            cg_wild.sample();
            cg_ignore.sample();
            cg_cross.sample();
        end

        // ---------------------------------------------------------------------
        // Coverage Report
        // ---------------------------------------------------------------------
        $display("\n================= CHAPTER 9 COVERAGE REPORT =================");
        $display("9.6.1 auto-sample        : %6.2f%%", cg_auto.get_coverage());
        $display("9.7.1 explicit bins      : %6.2f%%", cg_bins.get_coverage());
        $display("9.7.2 enum coverage      : %6.2f%%", cg_enum.get_coverage());
        $display("9.7.3 conditional (iff)  : %6.2f%%", cg_cond.get_coverage());
        $display("9.7.5 auto_bin_max=8     : %6.2f%%", cg_auto_max.get_coverage());
        $display("9.7.7 option overrides   : %6.2f%%", cg_opts.get_coverage());
        $display("9.7.9 transition bins    : %6.2f%%", cg_trans.get_coverage());
        $display("9.7.10 wildcard bins     : %6.2f%%", cg_wild.get_coverage());
        $display("9.7.11 ignore bins       : %6.2f%%", cg_ignore.get_coverage());
        $display("9.8   cross coverage     : %6.2f%%", cg_cross.get_coverage());
        $display("=============================================================");

        // Per-coverpoint query (9.12)
        $display("\n9.8 cross — per-point details:");
        $display("  cp_kind = %6.2f%%", cg_cross.cp_kind.get_coverage());
        $display("  cp_dst  = %6.2f%%", cg_cross.cp_dst.get_coverage());
        $display("  cx_all  = %6.2f%%", cg_cross.cx_all.get_coverage());

        $finish;
    end

endmodule : cheatsheet_ch9
