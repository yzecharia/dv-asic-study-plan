# Testbench Top Module

**Category**: Verification · **Used in**: W4+ (every drill from Salemi ch.10 forward), W12, W14, W20 · **Type**: authored

The TB top is the single `module` that **bridges static elaboration with class-based stimulus**. Class instances can't exist on their own — they must be created inside an `initial` block inside a module. The TB top is that module, and exists only to: import the package, instantiate the DUT and BFM/interface, declare a testbench class handle, and kick the simulation. Anything beyond those four jobs belongs somewhere else.

## The four jobs of a TB top

```systemverilog
module oo_tb_demo;
    import oo_tb_pkg::*;                       // 1. import class definitions

    tinyalu_bfm bfm();                          // 2. instantiate BFM/interface
    tinyalu DUT (                               //    instantiate DUT, wire to BFM
        .clk     (bfm.clk),
        .reset_n (bfm.reset_n),
        .start   (bfm.start),
        .A       (bfm.A),
        .B       (bfm.B),
        .op      (bfm.op),
        .done    (bfm.done),
        .result  (bfm.result)
    );

    testbench testbench_h;                      // 3. declare class handle (null)

    initial begin                               // 4. construct + launch
        testbench_h = new(bfm);
        testbench_h.execute();
        $display("TB PASS");
        $finish;
    end
endmodule : oo_tb_demo
```

That's the whole shape. Everything that isn't one of those four jobs is a smell.

## Job 1 — Import the package

The TB top imports the package containing every class the TB uses. The classes themselves live in `.svh` files inside that package; the top doesn't `` `include `` them directly.

## Job 2 — Instantiate DUT and BFM

The BFM is an `interface` instance. Wiring the DUT through `.signal(bfm.signal)` keeps the connection in one place — change one signal name and only the BFM-vs-DUT mapping changes.

The clock generator typically lives **inside the BFM**, not the top. That keeps every signal-related thing in the BFM file, and the top stays focused on structure.

## Job 3 — Declare the testbench class handle

A class handle, not a `new` call. Construction is done in the `initial` block — never at module scope.

```systemverilog
testbench testbench_h;             // declaration only; value is null
```

The handle's type comes from the imported package; the actual object materialises only when `new(...)` is called inside `initial`.

## Job 4 — The `initial` block

The simulation entry point:

```systemverilog
initial begin
    testbench_h = new(bfm);        // construct, pass BFM via constructor
    testbench_h.execute();         // BLOCKS until stimulus completes
    $display("TB PASS");           // greppable PASS line for Iron Rule (b)
    $finish;                       // exit cleanly
end
```

The `execute()` task **must block** until the test is done. If `execute()` returns immediately (e.g. `fork ... join_none` without a `wait fork;`), the PASS prints at time 0 and the sim ends before any stimulus runs. This is the most common ch.10 drill bug.

## What does NOT go in a TB top

- **Test logic.** No `if (mismatch) ...` checks; that's the scoreboard's job.
- **Stimulus generation.** That's the tester / sequence's job.
- **Bus-level signal manipulation.** That's the BFM's (or driver's) job.
- **Reference model.** That's the scoreboard's job.
- **Coverage groups.** Those go in the coverage class (or a `uvm_subscriber`).
- **Multiple `initial` blocks racing.** Keep the simulation entry in *one* initial. Other initial blocks (BFM clock gen, waveform dumping) are fine; multiple simulation kickoffs aren't.

A TB top with more than ~30 lines of useful content is doing too much.

## UVM equivalent

The UVM-style TB top is structurally identical, with `run_test()` replacing the manual `new` + `execute()`:

```systemverilog
module top;
    import my_pkg::*;
    my_if   vif (.clk(clk));
    my_dut  DUT (...);

    initial begin
        uvm_config_db#(virtual my_if)::set(null, "*", "vif", vif);
        run_test();    // factory + +UVM_TESTNAME picks the test class
    end
endmodule
```

Same four jobs, different glue. `run_test()` is what reads `+UVM_TESTNAME=my_test` from the command line, factory-creates the test class, and runs the phase machine.

## Common gotchas

- **Constructing the testbench at module scope** (`testbench testbench_h = new(...);` outside any `initial`) — allowed in SV, but the timing of construction is implementation-defined. Always construct in `initial`.
- **Forgetting `$finish`** — sim runs forever after PASS prints, hard to spot the issue in CI logs. Always pair `$display("PASS")` with `$finish`.
- **Calling `tester_h.execute()` directly from the top** instead of going through the testbench class — defeats the OO composition the chapter is teaching. The whole point is `testbench` orchestrates `tester` + `scoreboard` + `coverage`.
- **Two `initial` blocks both calling `run_test()` or both launching the test** — chaos. Pick one.
- **Hard-coding signal names that don't match the BFM** — write the DUT instantiation by copying the BFM's signal list, don't retype.

## Reading

- Salemi *UVM Primer* ch.10 (OO testbench top), pp. 59–66.
- Salemi ch.11 (UVM top + `run_test`), pp. 67–75.
- Spear *SV for Verification* (3e) — testbench top patterns.
- IEEE 1800-2017 §23 — module instantiation and elaboration.

## Cross-links

- `[[uvm_testbench_skeleton]]` — the production UVM-side equivalent.
- `[[interfaces_modports]]` · `[[bfm_pattern]]` — what the top instantiates.
- `[[sv_packages]]` — what the top imports.
- `[[uvm_test]]` · `[[uvm_env]]` — the classes the top hands off to via `run_test()`.
