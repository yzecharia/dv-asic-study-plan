# Covergroup Sampling — Construction, Triggers, and the Three Forms

**Category**: SystemVerilog · **Used in**: W3 (anchor — Spear ch.9), W4–W7 (UVM coverage subscribers), W12, W14, W17, W18, W20 · **Type**: authored

A covergroup doesn't observe values continuously — it takes **discrete snapshots**. Each snapshot increments hit counts on whichever bins match. Two questions decide whether your coverage is correct: **when does the snapshot fire?** and **what values does it read?** Get either wrong and your report lies — you can hit 100 % on a covergroup that never sampled the data you cared about, because every sample landed on a stale field. This note covers the three industry-standard sampling forms, the mandatory construction step, and the failure modes that make junior coverage code lie.

## Two-step lifecycle: declare, construct, sample

```systemverilog
class coverage extends uvm_subscriber #(int);
    covergroup cg_dice;                                  // 1. declare
        cp_sum: coverpoint roll_val { bins sum[] = {[2:12]}; }
    endgroup

    int roll_val;

    function new(string name, uvm_component parent = null);
        super.new(name, parent);
        cg_dice = new();                                 // 2. construct — mandatory
    endfunction

    function void write(int t);
        roll_val = t;
        cg_dice.sample();                                // 3. sample
    endfunction
endclass
```

Three things juniors miss:

1. **Covergroups are not auto-constructed.** Unlike scalar fields or queues, you **must** call `cg = new();` in the constructor. Skip this and the first `sample()` call is a null-pointer fatal. The compiler does not catch it.
2. **The covergroup's `new()` takes no arguments by default** — there's no parent handle and no name string. It's a different `new` from `uvm_component::new`. Don't pass `this` to it.
3. **You construct in `new()` (or `build_phase`), never in `write()`.** Constructing on every sample creates a new covergroup each time, throwing away accumulated bins.

## The three sampling forms

### Form A — clocked sampling (`@(event)`)

```systemverilog
covergroup cg_bus @(posedge clk iff valid);
    cp_op:   coverpoint op   { bins read = {READ}; bins write = {WRITE}; }
    cp_addr: coverpoint addr { bins zero = {0}; bins max = {'1}; }
endgroup
```

The covergroup samples itself automatically on every rising edge of `clk` where `valid == 1`. No `sample()` call needed — the simulator wires the event up at construction time.

**Use when:** the covergroup lives near the DUT (interface coverage, RTL-bound covergroups) and there's a natural clock edge defining "a transaction happened." The `iff` filter gates samples by a qualifier — only count cycles where the bus is active. Without `iff`, you'd sample on every clock and get coverage on idle cycles too, which dilutes the report.

**Don't use when:** the covergroup lives inside a UVM subscriber. Subscribers don't see clocks — they see `write(t)` callbacks at transaction boundaries, and there's no rising edge to attach to.

### Form B — manual sampling reading class fields (`cg.sample()`)

```systemverilog
class coverage extends uvm_subscriber #(int);
    int roll_val;                                      // ← class field

    covergroup cg_dice;
        cp_sum: coverpoint roll_val { bins sum[] = {[2:12]}; }   // refs roll_val by name
    endgroup
    ...
    function void write(int t);
        roll_val = t;                                  // update field FIRST
        cg_dice.sample();                              // covergroup reads class state
    endfunction
endclass
```

The covergroup hard-codes a reference to a class member at compile time. `sample()` reads that member; the test must update it before each call.

**Use when:** the covergroup observes **multiple** fields of a transaction or component — passing six args to `sample()` is verbose, and the fields already exist as class state.

```systemverilog
covergroup cg_pkt;
    cp_op:   coverpoint pkt.op;          // reads class member's class member
    cp_size: coverpoint pkt.size;
    cp_addr: coverpoint pkt.addr[31:24]; // bit-slices welcome
    cross cp_op, cp_size, cp_addr;
endgroup
```

**Don't use when:** there's only one value to observe and you'd be creating a class field just to feed the covergroup. That's a footgun — see Form C.

### Form C — manual sampling with arguments (`with function sample(...)`)

```systemverilog
class coverage extends uvm_subscriber #(int);
    // no roll_val field needed

    covergroup cg_dice with function sample(int roll);    // ← typed argument list
        cp_sum: coverpoint roll { bins sum[] = {[2:12]}; }   // refs the argument
    endgroup
    ...
    function void write(int t);
        cg_dice.sample(t);                                // pass directly
    endfunction
endclass
```

`with function sample(int roll)` declares the covergroup's auto-generated `sample()` to take typed arguments. The coverpoints reference those arguments as if they were locals. No class field involved.

**Use when:** the covergroup observes a small, fixed set of values and you don't want to litter the class with single-purpose fields. This is the production-default form for any subscriber that samples ≤ 3 values per transaction.

**Bonus:** the argument list can include a sampling-control flag:

```systemverilog
covergroup cg_op with function sample(opcode_t op, bit is_legal);
    cp_op: coverpoint op iff (is_legal) { bins all[] = op with (item.legal); }
endgroup
```

— gating the sample with a per-call qualifier the caller computes.

### Picking the form

| Form | Pros | Cons | Default for |
|---|---|---|---|
| **A — clocked** | zero plumbing once attached; aligns with DUT timing | only works at the RTL/interface boundary; can't be used in a subscriber | interface-bound coverage in W3-style testbenches |
| **B — class field** | many fields, no arg-list verbosity | risk of stale-field bug if you forget the assignment; hidden coupling | transaction-coverage where the class already holds the data |
| **C — sample args** | self-documenting; no stale-data risk; minimal class state | argument list grows with field count | single-value or few-field coverage in subscribers (the dice case) |

For UVM subscribers specifically, Form C is the modern default; Form B remains common for legacy code and for covergroups that read deep transaction structures.

## The stale-field trap (Form B's #1 bug)

```systemverilog
function void write(int t);
    cg_dice.sample();          // ← BUG: roll_val still holds the previous transaction's value
    roll_val = t;              // updated AFTER sampling
endfunction
```

The covergroup sampled the **old** `roll_val`, not `t`. The bin for the previous transaction got incremented twice; the current one was never sampled. Coverage reports will look reasonable — every bin gets hit eventually — but each sample is off by one transaction. **Always update class fields before calling `sample()`.**

Form C eliminates this class of bug by construction.

## The `iff` filter

Both Form A (event-clocked) and Form B/C (manual) accept `iff (expr)` to gate the sample:

```systemverilog
covergroup cg_bus @(posedge clk iff (valid && !reset_n));    // Form A
covergroup cg_op with function sample(opcode_t op, bit en);
    cp_op: coverpoint op iff (en) { ... }                    // per-coverpoint iff
endgroup
```

`iff` at the **covergroup-level event** suppresses the entire snapshot when false. `iff` at the **coverpoint level** suppresses only that coverpoint's count. Use coverpoint-level `iff` when one coverpoint depends on a different qualifier than the others (e.g. only count `cp_resp` on cycles where the response is valid, but always count `cp_req`).

## Constructor placement

```systemverilog
function new(string name, uvm_component parent = null);
    super.new(name, parent);
    cg_dice = new();           // construct here — runs once per object
endfunction
```

vs.

```systemverilog
function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    cg_dice = new();           // also legal — runs in UVM build phase
endfunction
```

Both work. **`new()` is preferred** for covergroups because:

1. They're not part of the UVM phase machinery — there's no factory override, no config, nothing that needs `build_phase`.
2. Constructing in `new()` means even unit tests that instantiate the class outside a UVM run will work.
3. It keeps the cost-of-existence rule simple: "a coverage object is born ready."

`build_phase` only wins if you need to read `uvm_config_db` to **decide whether to construct** the covergroup at all (test-controlled disable). Even then, prefer a `bit cov_enabled` field set in `build_phase` and gate the `sample()` calls.

## Reporting coverage

Inside the subscriber's `report_phase`:

```systemverilog
function void report_phase(uvm_phase phase);
    `uvm_info("COV", $sformatf("dice coverage = %0.2f%%",
                               cg_dice.get_inst_coverage()), UVM_LOW)
endfunction
```

| API | Returns |
|---|---|
| `cg.get_inst_coverage()` | This **instance**'s coverage % across all coverpoints/crosses. |
| `cg::get_coverage()` (static) | Aggregate coverage across **all instances** of this covergroup type. |
| `cg.cp.get_inst_coverage()` | Single coverpoint's instance coverage. |

Two instances of the same covergroup type accumulate separately for `get_inst_coverage()` but jointly for the static `::get_coverage()`. Be deliberate which one you report — they answer different questions.

## Pitfalls

| Pitfall | Symptom |
|---|---|
| Forgot `cg = new()` in constructor | null-pointer fatal on first `sample()` |
| Constructed `cg` inside `write()` / `sample()` | every call resets the covergroup; report shows last-sample-only |
| Form B: assigned class field **after** `sample()` | covergroup samples stale data; bins look populated but mismatched per transaction |
| Form A in a UVM subscriber | covergroup never fires — subscribers don't see clocks |
| Used `+=`/`++` on the sample-arg variable inside the covergroup | covergroup arguments are read-only inside coverpoints |
| Mixed `iff` and `wildcard` poorly | bins are silently ignored; check report's hit count for sanity |
| Forgot to call `sample()` on at least one path | phantom holes — the bin **could** be hit but isn't, and you can't tell whether stimulus or sampling is to blame |
| Constructed two separate `cg` objects but reported `::get_coverage()` (static) | double-counted coverage; instance-level was wanted |

## Reading

- Spear *SV for Verification* (3e) ch.9 — Functional Coverage. §9.4 (covergroup syntax), §9.5 (coverpoints), §9.7 (crosses), §9.8 (sampling control / `with function sample`).
- IEEE 1800-2017 §19.3 (covergroup declaration), §19.4 (sampling), §19.6 (`with function sample`).
- Verification Academy — Coverage Cookbook: https://verificationacademy.com/cookbook/coverage
- ChipVerify — covergroup: https://www.chipverify.com/systemverilog/systemverilog-covergroup

## Cross-links

- `[[coverage_functional_vs_code]]` — why functional coverage matters at all (the framing).
- `[[covergroup_crosses_filters]]` — what to put **inside** the covergroup once you've decided how to sample it.
- `[[uvm_subscriber_coverage]]` — the canonical home for a covergroup in a UVM env.
- `[[uvm_analysis_ports]]` — the broadcast that delivers transactions to the subscriber's `write()`, where Form B/C `sample()` calls live.
- `[[randomization_rand_randc]]` — the producer of the stimulus this covergroup measures.
