// =============================================================================
// SystemVerilog Assertions (SVA) — Cheatsheet
// Progressive: basics -> syntax -> sequences -> implication -> advanced ops.
// Run with:  X1. xsim: Compile + Run TB Only   (Vivado xsim)
// =============================================================================
//
// Mental model:
//   ASSERTION  = a statement about behavior the design MUST obey.
//   COVER      = a statement about behavior we WANT to see happen at least once.
//   ASSUME     = a constraint on INPUTS (used in formal / drives random stim).
//
//   Two flavors:
//     * IMMEDIATE  — evaluated like a regular if-statement, in procedural code.
//     * CONCURRENT — clocked, evaluated on a clock edge, lives outside always.
//
// =============================================================================

module cheatsheet_sva;

    // -------------------------------------------------------------------------
    // Clock + reset + a small "DUT-ish" signal set to exercise assertions on
    // -------------------------------------------------------------------------
    logic clk = 0;
    always #5 clk = ~clk;               // 10 time-unit period

    logic rst_n;                        // active-low reset
    logic req, gnt, busy, done;
    logic [3:0] data;
    logic       valid, ready;           // for handshake examples

    // =========================================================================
    // 1. IMMEDIATE ASSERTIONS
    // =========================================================================
    // Syntax:
    //   assert (<boolean>) <pass stmt>; else <fail stmt>;
    //
    //   - Lives inside always/initial/task/function (procedural).
    //   - Checked instantly when reached (no clock, no sampled values).
    //   - Use for:  sanity checks, argument validation, combinational invariants.

    task check_non_zero(input int x);
        // "Hard" immediate assertion — if x==0, simulation error (severity=error)
        assert (x != 0) else $error("x must be non-zero, got %0d", x);
    endtask

    // Immediate assertion variants:
    //   assert      — fails => $error by default
    //   assume      — same syntax, used as an input constraint
    //   cover       — counts as a hit when the expression is true
    //
    // Deferred immediate (preferred over plain immediate in always_comb):
    //   assert #0  (cond);    // evaluates after all glitches settle (observed)
    //   assert final (cond);  // evaluates at end of current time step

    // =========================================================================
    // 2. CONCURRENT ASSERTIONS — ANATOMY
    // =========================================================================
    // Syntax:
    //   assert property ( @(posedge clk) <property_expr> );
    //
    // Parts:
    //   @(posedge clk)  — clocking event; values sampled just before this edge
    //   <property_expr> — a sequence or a boolean built from sampled signals
    //
    // Why "sampled values"?
    //   SVA reads signals in the preponed region (just before the clock edge),
    //   so race conditions with non-blocking assigns are avoided automatically.

    // Simplest concurrent assertion — a pure boolean invariant, every clock.
    // "busy must never be X/Z"
    assert property (@(posedge clk) !$isunknown(busy));

    // =========================================================================
    // 3. DISABLE IFF — handling reset
    // =========================================================================
    // Always ignore assertion while reset is active. Without this, every
    // assertion will likely fire at time 0 or during reset.
    //
    //   assert property (@(posedge clk) disable iff (!rst_n) <expr>);

    // "During normal operation, data must never be X"
    assert property (@(posedge clk) disable iff (!rst_n) !$isunknown(data));

    // =========================================================================
    // 4. SAMPLED-VALUE SYSTEM FUNCTIONS
    // =========================================================================
    // These ONLY make sense in concurrent assertions (need sampled values).
    //
    //   $rose(sig)    — sig was 0 last clock, is 1 now      (0 -> 1)
    //   $fell(sig)    — sig was 1 last clock, is 0 now      (1 -> 0)
    //   $stable(sig)  — sig is the same as last clock
    //   $past(sig, n) — value of sig n clocks ago (default n=1)
    //   $changed(sig) — !$stable(sig)
    //
    // Examples (used inside properties below).

    // =========================================================================
    // 5. IMPLICATION: |->  and  |=>
    // =========================================================================
    // The most important SVA construct.
    //
    //   antecedent |->  consequent   // OVERLAPPING: consequent starts SAME cycle
    //   antecedent |=>  consequent   // NON-OVERLAPPING: consequent starts NEXT cycle
    //
    // Read as: "WHEN antecedent is true, THEN consequent must hold."
    // If antecedent is false, the assertion "vacuously" passes (doesn't care).

    // "If req rises, gnt must be asserted the NEXT cycle"
    property p_req_then_gnt;
        @(posedge clk) disable iff (!rst_n)
            $rose(req) |=> gnt;
    endproperty
    assert property (p_req_then_gnt);

    // "If gnt is high, busy must be high the SAME cycle" (overlap)
    property p_gnt_busy_same_cycle;
        @(posedge clk) disable iff (!rst_n)
            gnt |-> busy;
    endproperty
    assert property (p_gnt_busy_same_cycle);

    // =========================================================================
    // 6. SEQUENCES — ##N DELAY (time steps)
    // =========================================================================
    //   ##N    = exactly N clock cycles later
    //   ##[m:n]= between m and n cycles later (inclusive)
    //   ##[1:$]= 1 or more cycles later, eventually
    //
    // Sequences chain events in time.

    // "When req rises, busy must go high within 1-3 cycles"
    property p_req_busy_window;
        @(posedge clk) disable iff (!rst_n)
            $rose(req) |-> ##[1:3] busy;
    endproperty
    assert property (p_req_busy_window);

    // "After busy falls, done must come EXACTLY 2 cycles later"
    property p_busy_done_fixed;
        @(posedge clk) disable iff (!rst_n)
            $fell(busy) |-> ##2 done;
    endproperty
    assert property (p_busy_done_fixed);

    // =========================================================================
    // 7. REPETITION OPERATORS
    // =========================================================================
    //   sig [*N]        — sig high for EXACTLY N consecutive cycles
    //   sig [*m:n]      — sig high for m to n consecutive cycles
    //   sig [*0:$]      — zero or more cycles (useful for "hold until")
    //
    //   sig [=N]        — sig true N times total (not necessarily consecutive)
    //   sig [->N]       — "goto" — N-th true cycle (consumed)
    //
    // [*] = consecutive repetition     (think: back-to-back ticks)
    // [=] = non-consecutive count      (think: N ticks, any time)
    // [->] = non-consecutive goto      (think: stop on the N-th tick)

    // "If req is held high for 4 consecutive cycles, gnt must follow"
    property p_req_held;
        @(posedge clk) disable iff (!rst_n)
            req [*4] |=> gnt;
    endproperty
    assert property (p_req_held);

    // "After req rises, we should see busy on the 2nd true cycle of gnt"
    property p_goto_gnt;
        @(posedge clk) disable iff (!rst_n)
            $rose(req) |-> gnt[->2] ##1 busy;
    endproperty
    assert property (p_goto_gnt);

    // =========================================================================
    // 8. SEQUENCE COMPOSITION
    // =========================================================================
    //   s1 and  s2     — both match, starting same clock; end on later end
    //   s1 or   s2     — either matches
    //   s1 intersect s2— both match AND end on the SAME clock (same length)
    //   expr throughout s — expr must be true through every cycle of s
    //   s1 within s2   — s1 matches somewhere inside s2's window

    // "When req rises, busy must be high throughout the next 3 cycles"
    property p_busy_throughout;
        @(posedge clk) disable iff (!rst_n)
            $rose(req) |=> (busy throughout ##[0:2] done);
    endproperty
    assert property (p_busy_throughout);

    // =========================================================================
    // 9. $past — referring to history
    // =========================================================================
    //   $past(sig)     = sig one clock ago
    //   $past(sig, N)  = sig N clocks ago
    //
    // Great for stability / change / rollback checks.

    // "data must not change while valid is high and ready is low" (stable hold)
    property p_data_stable_when_waiting;
        @(posedge clk) disable iff (!rst_n)
            (valid && !ready) |=> $stable(data);
    endproperty
    assert property (p_data_stable_when_waiting);

    // "If done fires, req must have been asserted in the last 5 cycles"
    property p_done_implies_recent_req;
        @(posedge clk) disable iff (!rst_n)
            $rose(done) |-> (req || $past(req,1) || $past(req,2)
                                  || $past(req,3) || $past(req,4));
    endproperty
    assert property (p_done_implies_recent_req);

    // =========================================================================
    // 10. VALID / READY HANDSHAKE — the classic assertion set
    // =========================================================================
    // These are the 5 canonical handshake checks (good for HW3).

    // (a) valid must not drop before ready is seen (no retraction)
    property p_hs_valid_stable_until_ready;
        @(posedge clk) disable iff (!rst_n)
            (valid && !ready) |=> valid;
    endproperty
    assert property (p_hs_valid_stable_until_ready);

    // (b) data must be stable while valid is high and ready is low
    property p_hs_data_stable;
        @(posedge clk) disable iff (!rst_n)
            (valid && !ready) |=> $stable(data);
    endproperty
    assert property (p_hs_data_stable);

    // (c) no X on data when valid is high
    property p_hs_no_x_on_data;
        @(posedge clk) disable iff (!rst_n)
            valid |-> !$isunknown(data);
    endproperty
    assert property (p_hs_no_x_on_data);

    // (d) a transfer only happens when BOTH valid and ready are high
    //     (expressed as a cover — we want to see it at least once)
    cover property (@(posedge clk) disable iff (!rst_n) valid && ready);

    // (e) after a transfer (valid && ready), valid may drop next cycle (legal)
    //     — shown as a cover so we confirm this scenario is exercised
    cover property (@(posedge clk) disable iff (!rst_n)
                    (valid && ready) ##1 !valid);

    // =========================================================================
    // 11. ACTION BLOCKS — custom pass/fail messages
    // =========================================================================
    // Syntax:
    //   assert property (p) <pass_stmt>; else <fail_stmt>;
    //
    // Severity levels (increasing):
    //   $info, $warning, $error (default), $fatal

    property p_gnt_needs_req;
        @(posedge clk) disable iff (!rst_n)
            gnt |-> req;
    endproperty
    assert property (p_gnt_needs_req)
        $info("OK: gnt asserted while req is active");
    else
        $error("VIOLATION: gnt asserted without req at t=%0t", $time);

    // =========================================================================
    // 12. COVER PROPERTY — ensure interesting scenarios happen
    // =========================================================================
    // Same syntax as assert, but doesn't fail — it just records a hit.
    // Use for: proving stimulus reaches corner cases.

    cover property (@(posedge clk) disable iff (!rst_n)
                    $rose(req) ##[1:5] done);        // "req -> done in <=5"

    cover property (@(posedge clk) disable iff (!rst_n)
                    req [*3]);                        // req held 3 cycles

    // =========================================================================
    // 13. ASSUME PROPERTY — constrain inputs (used by formal / random gen)
    // =========================================================================
    // "rst_n must be low for at least 2 cycles at startup"
    // (In sim, assume behaves like assert; its real power is in formal tools.)
    //
    //   assume property (@(posedge clk) $fell(rst_n) |=> !rst_n[*2]);

    // =========================================================================
    // 14. BIND — attach assertions to a DUT without editing its RTL
    // =========================================================================
    // Keeps assertions in a separate file, great for reusable IP.
    //
    //   // in assertion file:
    //   module fifo_checker(input clk, input rst_n, input full, input wr);
    //       assert property (@(posedge clk) disable iff (!rst_n)
    //                        full |-> !wr);
    //   endmodule
    //
    //   // in top TB:
    //   bind dut_fifo fifo_checker chk (.*);
    //
    // After binding, assertions are evaluated as if written inside `dut_fifo`.

    // =========================================================================
    // 15. QUICK REFERENCE TABLE
    // =========================================================================
    //  Operator       Meaning
    //  --------       ------------------------------------------------
    //  |->            overlap implication (same cycle consequent)
    //  |=>            non-overlap implication (next cycle consequent)
    //  ##N            delay N clocks
    //  ##[m:n]        delay m..n clocks
    //  [*N]           consecutive repetition, exactly N
    //  [*m:n]         consecutive repetition, m..n
    //  [=N]           non-consecutive count, exactly N
    //  [->N]          goto the N-th true occurrence
    //  and / or       sequence conjunction / disjunction
    //  intersect      both match with SAME length
    //  throughout     boolean must hold throughout a sequence
    //  within         one sequence occurs inside another's window
    //  $rose/$fell    edge detection
    //  $stable        unchanged since last clock
    //  $past(s,N)     value N clocks ago
    //  disable iff    suppress while condition (typically reset) is true

    // =========================================================================
    // STIMULUS — exercises the DUT-ish signals so the assertions run
    // =========================================================================
    initial begin
        $dumpfile("sva_dump.vcd");
        $dumpvars(0, cheatsheet_sva);

        // Reset phase
        rst_n = 0;
        req   = 0;
        gnt   = 0;
        busy  = 0;
        done  = 0;
        data  = 4'h0;
        valid = 0;
        ready = 0;
        repeat (3) @(posedge clk);
        rst_n = 1;

        // --- Scenario 1: clean req -> gnt -> busy -> done sequence ---
        @(posedge clk) req <= 1;
        @(posedge clk) gnt <= 1;    busy <= 1;          // gnt next cycle (|=>)
        @(posedge clk) req <= 0;    gnt  <= 0;
        @(posedge clk) busy <= 0;
        @(posedge clk);
        @(posedge clk) done <= 1;                       // 2 cycles after busy fell
        @(posedge clk) done <= 0;

        // --- Scenario 2: valid/ready handshake, stable data ---
        @(posedge clk) begin valid <= 1; data <= 4'hA; ready <= 0; end
        repeat (3) @(posedge clk);                      // stall — data must stay 'A
        @(posedge clk) ready <= 1;                      // transfer happens
        @(posedge clk) begin valid <= 0; ready <= 0; end

        // --- Scenario 3: req held 4 cycles -> gnt ---
        @(posedge clk) req <= 1;
        repeat (3) @(posedge clk);                      // req stays high 4 total
        @(posedge clk) begin req <= 0; gnt <= 1; end    // gnt after 4 cycles
        @(posedge clk) gnt <= 0;

        // Settle and finish
        repeat (5) @(posedge clk);
        $display("\nSVA cheatsheet stimulus complete — check report for coverage & asserts.");
        $finish;
    end

endmodule : cheatsheet_sva
