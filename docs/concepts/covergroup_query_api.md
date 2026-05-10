# Querying Covergroup Coverage — `get_inst_coverage`, `get_coverage`, and the `option` System

**Category**: SystemVerilog · **Used in**: W3 (anchor — Spear ch.9), W4–W7 (subscribers reporting in `report_phase`), W12, W14, W17, W18, W20 (regression coverage gating) · **Type**: authored

A covergroup samples values, but it doesn't tell you anything until you *ask*. SystemVerilog exposes a small set of query methods that return coverage as a percentage — and getting the right one matters, because two of them answer different questions. The simulator's coverage-report HTML is convenient for humans, but the testbench itself needs a programmatic answer for end-of-test summaries, regression sign-off gates, and adaptive coverage-driven stimulus. This note covers the four query APIs, the per-instance vs aggregate distinction, the `option` system that controls what the queries return, and the failure modes that produce coverage numbers nobody can interpret.

## The four query methods

```systemverilog
covergroup cg_dice;
    cp_sum: coverpoint roll_val { bins sum[] = {[2:12]}; }
endgroup

cg_dice cg = new();
// ... samples happen ...

real inst_pct = cg.get_inst_coverage();           // 1. instance, all coverpoints/crosses
real type_pct = cg_dice::get_coverage();          // 2. type-aggregate, all instances
real cp_inst  = cg.cp_sum.get_inst_coverage();    // 3. instance, single coverpoint
real cp_type  = cg.cp_sum.get_coverage();         // 4. type-aggregate, single coverpoint
```

| API | Scope | Aggregation |
|---|---|---|
| `cg.get_inst_coverage()` | this covergroup object | this instance only |
| `cg_type::get_coverage()` (static) | this covergroup type | union across **all** instances of this type |
| `cg.cp.get_inst_coverage()` | this object's named coverpoint or cross | this instance only |
| `cg.cp.get_coverage()` | this object's named coverpoint or cross | union across all instances |

All four return a `real` in the range `0.0`–`100.0`. They never return -1, never throw — they're pure inspectors of the coverage database.

## Instance vs type — pick the right one

The two scopes answer different questions, and using the wrong one silently gives you a wrong number.

**`get_inst_coverage()` answers:** "How well did *this* observer cover its bins?"

Use when each instance corresponds to a distinct stimulus stream: one coverage subscriber per UVM agent, one covergroup per protocol channel, one per CPU core in a multi-core DUT. The number tells you how much of the design slice that instance saw was actually exercised.

**`::get_coverage()` (static) answers:** "Did the union of *all* instances cover the bin set?"

Use for a regression-wide pass/fail gate: even if no single subscriber hit every bin, did the team's whole testsuite hit them collectively? In a single-instance testbench the two return identical numbers; the difference only emerges with ≥ 2 instances.

```systemverilog
// Two agents, two coverage subscribers
agent_a.cov_h.get_inst_coverage()  // 78%  (what agent A's stimulus exercised)
agent_b.cov_h.get_inst_coverage()  // 84%  (what agent B's stimulus exercised)
coverage::get_coverage()           // 95%  (their union — bins one agent missed, the other hit)
```

**Common bug:** reporting `::get_coverage()` from inside a per-agent subscriber's `report_phase`. You print 95 % three times (once per subscriber) — every line of your end-of-test summary lies because they all show the aggregate, not the per-agent slice. Use the instance method.

## The `option` system — what counts toward the percentage

Covergroups expose two parallel option blocks: `option.<name>` (per-instance defaults set at construction) and `type_option.<name>` (per-type, identical across all instances). They control **what the query methods report**. Senior code always sets a few of these explicitly; default values rarely match what you mean.

```systemverilog
covergroup cg_dice;
    option.name           = "dice_sum_coverage";   // human-readable label in reports
    option.per_instance   = 1;                     // track per-instance counts (default 0!)
    option.weight         = 10;                    // weight in the parent group's coverage rollup
    option.goal           = 100;                   // target % (informational; doesn't change actual coverage)
    option.comment        = "anchored on Salemi ch.15 dice example";
    option.at_least       = 1;                     // hits per bin to count it as covered (default 1)

    type_option.merge_instances = 1;               // ::get_coverage() merges, doesn't average
    type_option.strobe          = 0;               // sample at the event, not at the next NBA region

    cp_sum: coverpoint roll_val { bins sum[] = {[2:12]}; }
endgroup
```

**The two options that bite juniors:**

- **`option.per_instance = 1`** — without this, `get_inst_coverage()` may return data merged with other instances of the same type. The IEEE-1800 default is `0` (don't track per-instance), which is wrong for any multi-instance testbench. **Set this to 1 for every covergroup.**
- **`option.at_least = N`** — a bin is "covered" only after `N` hits, not 1. Useful for distribution coverage (you want each bin hit ≥ 100 times to call the test thorough) but counterintuitive if left at the default 1 when you assumed otherwise.

**`type_option.merge_instances`** controls whether `::get_coverage()` does a union (1) or a weighted average (0) across instances. The union is almost always what regression managers want — average coverage across instances doesn't have a meaningful interpretation.

## Per-coverpoint and per-bin queries

For diagnosing **why** a covergroup is at 73 % rather than 100 %, drill in:

```systemverilog
real cp_pct = cg.cp_sum.get_inst_coverage();    // single coverpoint's %
```

For per-bin information, use the cumulative `get_coverage` across coverpoints, plus the simulator's coverage report — the LRM does not provide a per-bin query method on covergroups directly. The standard pattern is **explicit illegal/missing-bin assertions**:

```systemverilog
function void report_phase(uvm_phase phase);
    real pct = cg_dice.get_inst_coverage();
    if (pct < 100.0)
        `uvm_warning("COV", $sformatf("dice coverage only %0.2f%% — see report HTML for missing bins", pct))
    else
        `uvm_info("COV", "dice coverage = 100%", UVM_LOW)
endfunction
```

If you genuinely need per-bin counts at runtime (rare — usually the simulator's report is enough), iterate the coverpoint via SystemVerilog's coverage API queries (`get_inst_coverage()` on the bin index — vendor-specific) or write a counter-and-bin pair manually outside the covergroup.

## Coverage goal vs current — they're independent

```systemverilog
option.goal = 90;            // declared target
real pct    = cg.get_inst_coverage();   // current
```

`option.goal` does **not** affect what `get_inst_coverage()` returns — it's metadata for the reporting tool and for your own pass/fail logic. The query method always returns actual coverage divided by total bins (× 100).

The standard regression-gate pattern:

```systemverilog
function void report_phase(uvm_phase phase);
    real pct  = cg_dice.get_inst_coverage();
    real goal = real'(cg_dice.option.goal);
    if (pct < goal)
        `uvm_error("COV", $sformatf("coverage %0.2f%% below goal %0.2f%%", pct, goal))
endfunction
```

If you want signed-off pass/fail to fail the test on under-coverage, escalate `\`uvm_error` → `\`uvm_fatal`, **or** check the count via `uvm_report_server::get_severity_count(UVM_ERROR)` in `final_phase` and force a non-zero exit.

## Reporting placement — where in the phase tree

| Phase | Use for |
|---|---|
| `report_phase` | end-of-test summary; covergroup is fully sampled by now |
| `extract_phase` | gathering stats from siblings before reporting; unusual for a subscriber |
| `final_phase` | last-ditch checks after all `report_phase`s; pair with simulator-level exit code |

Print in `report_phase`. If you also want a regression gate, do the comparison there too — UVM aggregates `\`uvm_error` counts and the regression harness reads them.

## Worked example — single-instance dice subscriber

```systemverilog
class coverage_mon extends uvm_subscriber #(int);
    `uvm_component_utils(coverage_mon)

    int roll_val;

    covergroup cg_dice;
        option.name         = "dice_sum_coverage";
        option.per_instance = 1;
        option.goal         = 100;

        cp_sum: coverpoint roll_val { bins sum[] = {[2:12]}; }
    endgroup

    function new(string name = "coverage_mon", uvm_component parent = null);
        super.new(name, parent);
        cg_dice = new();
    endfunction : new

    function void write(int t);
        roll_val = t;
        cg_dice.sample();
    endfunction : write

    function void report_phase(uvm_phase phase);
        real pct = cg_dice.get_inst_coverage();
        if (pct < 100.0)
            `uvm_warning("COV", $sformatf("dice sum coverage only %0.2f%% — bins missed", pct))
        else
            `uvm_info("COV", $sformatf("dice sum coverage = %0.2f%%", pct), UVM_LOW)
    endfunction : report_phase

endclass : coverage_mon
```

20 rolls of 2d6 are nowhere near enough to hit all 11 bins (sum=2 has probability 1/36, so you expect to wait ~36 samples to see one). The above will typically print a warning, not an info — which is the correct behaviour. **Coverage queries are honest.** If you want a "100 %" line, run more samples.

## Pitfalls

| Pitfall | Symptom |
|---|---|
| Reporting `::get_coverage()` from a per-instance subscriber | every per-agent line shows the same aggregate number |
| Forgot `option.per_instance = 1` | `get_inst_coverage()` returns merged-or-zero depending on simulator |
| Comparing `pct == 100.0` with floating-point equality | may fail by ULP — use `>= 99.99` or compare counts of hit-vs-total bins |
| Used `option.at_least` and forgot you set it | numbers look low; bins need N hits each to count, not 1 |
| Querying coverage in `run_phase` | the run hasn't finished sampling — query in `report_phase` |
| Iterated bins assuming a specific report API | per-bin runtime queries are vendor-specific; rely on the report tool or write your own counters |
| Set `option.goal = 100` and assumed it gates the test | `goal` is informational only; you must compare-and-error yourself |

## Reading

- Spear *SV for Verification* (3e) ch.9 — Functional Coverage. §9.4 (covergroup syntax), §9.6 (coverage options), §9.10 (coverage methods).
- IEEE 1800-2017 §19.7 (coverage options), §19.8 (predefined coverage methods — `get_coverage`, `get_inst_coverage`).
- Verification Academy — Coverage Cookbook → "Coverage Reporting": https://verificationacademy.com/cookbook/coverage
- Doulos — covergroup options reference: https://www.doulos.com/knowhow/systemverilog/

## Cross-links

- `[[covergroup_sampling]]` — how snapshots happen (the input side); this note is the output side.
- `[[covergroup_crosses_filters]]` — what gets *into* the bins that these methods then count.
- `[[coverage_functional_vs_code]]` — the higher-level context for why these numbers matter.
- `[[uvm_subscriber_coverage]]` — the standard UVM home for covergroups, where `report_phase` queries live.
- `[[uvm_run_workflow]]` — phase ordering for when reports fire.
