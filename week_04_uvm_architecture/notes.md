# Week 4 — Notes

## Open questions

- (none yet — add as they come up while reading or coding)

## Aha moments

- (none yet)

## AI corrections

> Track here any time AI confidently said something the book
> contradicted. Include the source (chat date, book chapter,
> page).

## AI interview Qs — UVM

> Output of this week's AI productivity task. Question first, your
> answer second, AI's suggested answer third, your reflection last.

## Methodology lessons

> One paragraph per debug session worth remembering. Feeds your STAR
> story bank in `docs/star_stories/`.

## Salemi ch.10 — OO Testbench

### File / class roles (pp. 59–65)

- **top** — top-level module. Where the DUT, BFM, and testbench class
  are instantiated; the `initial` block fires up the run by calling
  `testbench_h = new(bfm); testbench_h.execute();`.
- **testbench** — top-level class. Composes `tester`, `scoreboard`,
  and `coverage` **directly** — flat hierarchy, no env layer in ch.10.
  (`uvm_env` is introduced in ch.13.)
- **tester** — generates **and** drives stimulus via the BFM. The
  pre-UVM equivalent of "sequence + sequencer + driver" rolled into a
  single class. UVM later splits this responsibility three ways.
- **scoreboard** — holds the **reference model** and compares DUT
  actual outputs against expected values.
- **coverage** — wraps a `covergroup`, samples bins per transaction.

### Corrections to my first paraphrase (2026-05-06)

- I said the testbench "instantiates the env" — wrong. No env class
  exists until ch.13. In ch.10, testbench composes tester /
  scoreboard / coverage directly.
- I said tester == "driver in industry terms" — too narrow. UVM
  industry pattern splits stimulus generation (sequence), arbitration
  (sequencer), and pin driving (driver) into three classes. The
  Salemi tester is all three combined.

### What the top module does (pp. 65–66)

- **Module-scope instantiations** (compile/elaboration time):
  - DUT (`tinyalu DUT (...)`) wired through the BFM signals.
  - BFM/interface (`tinyalu_bfm bfm()`).
  - Testbench class **handle** (`testbench testbench_h;`) — the
    object is null at this point; only the handle exists.
- **Imports**: `import oo_tb_pkg::*;` — the project package, which
  carries `operation_t` and `` `include`s all class .svh files.
- **`initial` block** (simulation time):
  - Construct: `testbench_h = new(bfm);`
  - Launch:    `testbench_h.execute();`

### Corrections — second paraphrase (2026-05-06)

- I said we "instantiate the testbench" alongside the DUT and BFM.
  Wrong mechanism: classes are not instantiated like modules.
  Module-scope can only hold the **handle** declaration; the **object
  construction** (`new(...)`) must be inside `initial` (or a task /
  function that runs at sim time). Don't put `testbench testbench_h
  = new(bfm);` at module scope.
- I said we "import the UVM package and macros" in the ch.10 top.
  Wrong chapter — ch.10 is pre-UVM by design. UVM (`uvm_pkg::*` +
  `uvm_macros.svh`) doesn't enter until ch.11. The ch.10 top imports
  only the project package.

### `execute()` vs UVM phases (p.65)

The `initial` block does two things:

1. **Construct** the testbench — `testbench_h = new(bfm);` — which
   triggers the testbench constructor's `new` calls for tester /
   scoreboard / coverage children, wiring the BFM into each.
2. **Launch** — `testbench_h.execute();` — which forks the three
   children's `execute()` tasks.

OO ch.10 ↔ UVM ch.11+ mapping:

| OO ch.10 | UVM ch.11+ |
|---|---|
| `testbench_h = new(bfm)` (children's `new`s run inline) | factory `create()` + `build_phase` + `connect_phase` |
| `testbench_h.execute()` | `run_phase` only |
| (none) | `extract_phase` → `check_phase` → `report_phase` → `final_phase` |

So `execute()` is **just `run_phase`**, not "all the phases." UVM's
phase machine exists because production envs need deterministic
build/connect ordering across many components; ch.10 doesn't need
that — wiring is manual and fork-join is enough.

### Corrections — third paraphrase (2026-05-06)

- I said `execute()` corresponds to "all the phases in actual UVM."
  Wrong scope. `execute()` ≈ `run_phase` only. Build/connect work
  happens in `new()` for the OO version; extract/check/report/final
  have no OO analog at all.
- "Instantiate the testbench with the interface" again — class
  **construction** via `new(bfm)`, not module-style instantiation.
  Same correction as the previous note; muscle-memory it.

### What the testbench class does (p.62, p.65)

- The OO testbench is **both** entry point (the `initial` constructs
  it and calls `execute()`) **and** structural container (it owns
  `tester_h`, `scoreboard_h`, `coverage_h`). UVM later splits these
  responsibilities into `uvm_test` (entry / per-run intent) and
  `uvm_env` (reusable container).
- "Connecting" the children in ch.10 means **passing the shared BFM**
  into each child's constructor. The three children **do not talk to
  each other** — they each independently access the BFM. Class-to-
  class wiring via analysis ports starts in ch.16.

OO ch.10 ↔ UVM mapping:

| OO ch.10 | UVM equivalent |
|---|---|
| `top` module | `top` module (same) |
| `testbench` class | `uvm_test` **+** `uvm_env` combined |
| `tester` class | `uvm_sequence` + `uvm_sequencer` + `uvm_driver` combined |
| `scoreboard` class | `uvm_scoreboard` |
| `coverage` class | `uvm_subscriber#(T)` |
| BFM (interface w/ tasks) | `interface` + `uvm_driver` + `uvm_monitor` (split in UVM) |

### Corrections — fourth paraphrase (2026-05-06)

- I said the testbench class "is basically the env." Closer to
  **env + test combined**. The OO testbench is the entry point AND
  the container; UVM separates those two roles for reuse.
- I said the testbench "connects them together." In ch.10 the three
  children are **peers around the BFM**, not connected to each
  other. Cross-class TLM wiring is a ch.16 concept.

### `virtual` interface — what it actually means (p.62)

The interface **does exist at compile time** — it's the
`tinyalu_bfm bfm()` line in `top`. What doesn't exist yet is the
**class instance**. Classes and modules/interfaces live in two
different worlds:

- **Static world** — modules and interfaces, elaborated once, wired
  with `.signal(...)`.
- **Dynamic world** — classes, constructed at runtime via `new()`,
  live on the heap.

A class can't directly bind to a static-world interface. The bridge
is a **handle** — `virtual tinyalu_bfm bfm` means "a phone number
that points at some `tinyalu_bfm` instance over there."

Mechanics for `function new(virtual tinyalu_bfm b); bfm = b; endfunction`:

1. `b` is the constructor arg — a handle the caller passed in.
2. `bfm` is the class member — also a handle.
3. `bfm = b;` copies **the handle (phone number), not the interface**
   itself. Both refer to the same single interface in `top`.
4. Calls like `bfm.send_op(...)` dereference the handle and run the
   actual interface's task.

```
   top.bfm  (THE interface — one instance in the static world)
       ▲     ▲     ▲
       │     │     │  (handles — all point at the same instance)
   tester_h.bfm  scoreboard_h.bfm  coverage_h.bfm
```

**Without `virtual`** (i.e. `tinyalu_bfm bfm;` inside a class) →
compile error. You can't put a static-world citizen into a
dynamic-world container.

### Corrections — fifth paraphrase (2026-05-06)

- I said `virtual` "tells the compiler there isn't an interface
  passed at compilation but there will be one in the future." Wrong
  framing. The interface DOES exist at compile time (it's in `top`).
  What `virtual` does is allow a class (dynamic-world object) to
  hold a **handle** pointing at a static-world interface instance.
  The "virtual" keyword here is about *indirection*, not "later".

### Salemi's actual ch.10 testbench pattern (p.65 — verified from book)

The constructor just stashes the BFM handle. All the real work
(creating children + forking) happens inside `execute()`:

```systemverilog
class testbench;
    virtual tinyalu_bfm bfm;
    tester     tester_h;
    coverage   coverage_h;
    scoreboard scoreboard_h;

    function new (virtual tinyalu_bfm b);
        bfm = b;
    endfunction : new

    task execute();
        tester_h     = new(bfm);
        coverage_h   = new(bfm);
        scoreboard_h = new(bfm);

        fork
            tester_h.execute();
            coverage_h.execute();
            scoreboard_h.execute();
        join_none
    endtask : execute
endclass : testbench
```

Two valid OO design choices for where children get created:

| Pattern | Constructor | execute() | Salemi uses |
|---|---|---|---|
| **A — Salemi style (ch.10)** | only stores BFM handle | creates children, then forks | ✓ |
| **B — build/run-separated** | stores BFM + creates children | only forks | (closer to UVM phase model) |

Both are correct in pre-UVM OO. Salemi picks A for compactness; UVM
later mandates B because production envs need deterministic
elaboration order.

### `join_none` vs the scaffolded top (gotcha for our HW)

Salemi's `execute()` ends with **plain `join_none`** — no
`wait fork`. His top.sv also has **no `$finish`**, so the forked
children just keep running and the simulator decides when to stop.

But the scaffolded `oo_tb_demo.sv` for our HW has:

```systemverilog
initial begin
    testbench_h = new(bfm);
    testbench_h.execute();
    $display("OO TB DEMO PASS");
    $finish;
end
```

With `join_none` and no `wait fork`, `execute()` returns at time 0
and `$finish` fires before any stimulus runs — sim "passes" with
zero work.

Fix: add **`wait fork;`** after `join_none` inside
`testbench::execute()`. Now the parent task blocks until the three
children finish; the top's `$display(PASS); $finish;` runs only
after real stimulus + checking has happened.

### Build/run mapping to UVM (still useful)

Even with Salemi's pattern A, the build-vs-run distinction is real —
it's just that build happens in the first three lines of `execute()`
instead of in `new()`. The conceptual mapping holds:

| OO ch.10 (whichever style) | UVM equivalent |
|---|---|
| BFM handle wiring | `build_phase` |
| child `new()` calls | `build_phase` |
| forking children's `execute()` | `run_phase` |

### Correction-of-correction — sixth paraphrase revisited (2026-05-06)

Yuval's note was right; my previous response was wrong. **Salemi
puts the children's creation inside `execute()`, not in `new()`.**
The "Canonical shape" code block I appended earlier showed creation
in `new()` — that's a valid alternative pattern, but it's NOT what
the book teaches. The actual pattern is the one shown directly above.

Yuval's homework should follow Salemi's pattern A and add
`wait fork;` after `join_none` to play nicely with the scaffolded
`$finish` in `oo_tb_demo.sv`.

### `fork ... join` variants — reference

| Construct | Behaviour | Use when |
|---|---|---|
| `fork ... join` | spawn N threads, **block until ALL finish** | every child must complete before continuing |
| `fork ... join_any` | spawn N threads, **block until FIRST finishes**, others keep running | racing two things (stimulus vs watchdog) |
| `fork ... join_none` | spawn N threads, **don't block** — children run in background | parent has more work after fork, or children own their own lifetime |

**Why Salemi picks `join_none` in ch.10:**

The three children (tester, scoreboard, coverage) own their own
lifetimes — each runs until it decides to exit. The parent doesn't
need a synchronous handle on them. This is a deliberate teaching
rehearsal for UVM's `run_phase` model, where many components run in
parallel and the test ends when **objections drop**, not when any
one task finishes.

**`wait fork`** — after `fork ... join_none`, the forked threads are
still alive. `wait fork;` blocks until every thread previously
forked off in this scope completes. Necessary when the parent must
synchronise back (e.g. before letting the top hit `$finish`).

## Salemi ch.11 — UVM Tests

### `uvm_config_db` — what it is and the API (p.~70)

`uvm_config_db` is **not a global variable.** It's a hierarchically-
scoped key/value store. Components SET values at a path with a
field name; other components GET values from a path matching the
field name. Lookup rules: most-specific-match-wins, wildcards
allowed in paths.

Full API:

```systemverilog
// SET
uvm_config_db#(T)::set(
    uvm_component cntxt,     // context component (or null for absolute path)
    string        inst_name, // path under cntxt; supports "*"
    string        field_name,// the lookup key
    T             value      // the data being stored
);

// GET
bit found = uvm_config_db#(T)::get(
    uvm_component cntxt,     // usually `this`
    string        inst_name, // usually ""
    string        field_name,// must match the SET's field_name
    ref T         value      // out-arg
);
```

`get` returns 0 on miss — **always check the return** or you use an
uninitialised handle silently. The non-negotiable pattern in
`build_phase`:

```systemverilog
if (!uvm_config_db#(virtual tinyalu_bfm)::get(this, "", "bfm", bfm))
    `uvm_fatal("NOVIF", "bfm not set in config_db")
```

### Decoding `uvm_config_db#(virtual tinyalu_bfm)::set(null, "*", "bfm", bfm);`

| Arg | Value | Meaning |
|---|---|---|
| `cntxt` | `null` | no context component; treat `inst_name` as absolute path |
| `inst_name` | `"*"` | wildcard — match every hierarchical path |
| `field_name` | `"bfm"` | the lookup key components will GET by |
| `value` | `bfm` | the virtual interface handle from the top module |

Combined effect: the BFM handle is reachable from anywhere in the
UVM hierarchy under the field name `"bfm"`.

### Why config_db instead of ch.10's constructor passing

In ch.10, the testbench passed the BFM into each child's
constructor. In UVM, you SET it once at the top and every component
GETs it where needed. Three wins:

- **Decoupling** — no threading through five layers.
- **Per-instance overrides** — different agents can get different
  BFMs (multi-protocol envs).
- **Test-time config** — tests change what components see without
  touching env/agent code.

### Corrections — first ch.11 paraphrase (2026-05-06)

- I called `uvm_config_db` a "global variable." Wrong abstraction.
  It's a **hierarchically-scoped key/value store** with wildcard
  matching — that scoping is exactly what makes per-instance
  overrides possible. Don't import "global variable" intuitions.

### `run_test()` and the factory (p.~70)

The flow:

1. `top.initial` calls `run_test()`.
2. `run_test()` reads the `+UVM_TESTNAME=<class_name>` plusarg from
   the simulator command line.
3. `run_test()` asks the **factory** to create an instance of that
   class by string name — the same factory pattern from ch.9, but
   string-keyed and macro-registered instead of hand-rolled `case`.
4. The phase machine kicks in: `build_phase → connect_phase →
   end_of_elaboration_phase → start_of_simulation_phase → run_phase
   → extract_phase → check_phase → report_phase → final_phase`.
5. `run_phase` blocks until all objections drop.

### Factory registration via `uvm_component_utils`

For `run_test()` to find a test class, the class must be registered
with the factory. One macro:

```systemverilog
class my_test extends uvm_test;
    `uvm_component_utils(my_test)    // adds my_test to factory string registry
    ...
endclass
```

Same machinery as ch.9's animal factory:
- ch.9: hand-rolled `case (spe) LION: new lion(); ...`
- UVM: string-keyed associative array, macro-registered, looked up via `+UVM_TESTNAME`

The macros hide the plumbing; the underlying mechanism is identical.

### Corrections — second ch.11 paraphrase (2026-05-06)

- I said `run_test()` "instantiates the object of the test" without
  naming the mechanism. The mechanism is the **UVM factory** (ch.9
  pattern in disguise) — `create_object_by_name(<string>)`. The
  factory is what makes string-driven test selection possible.
- `\`uvm_component_utils(<class>)` is the registration step that
  makes a class findable by the factory. Without it, the factory
  doesn't know your class exists and `run_test()` fails to find it.

### Standard `uvm_test` skeleton

```systemverilog
class random_test extends uvm_test;
    `uvm_component_utils(random_test)

    virtual tinyalu_bfm bfm;

    function new(string name = "random_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual tinyalu_bfm)::get(this, "", "bfm", bfm))
            `uvm_fatal("NOVIF", "Failed to get BFM from config_db")
    endfunction : build_phase

endclass : random_test
```

Five rules in this skeleton:

1. **`virtual tinyalu_bfm bfm;`** — the `interface` keyword is
   redundant; canonical is `virtual <iface_name> <handle>`.
2. **`parent = null` default** — required so the factory can call
   `new` with no parent (top-level test has no parent).
3. **`new()` does only `super.new(...)`** — no real work. Real work
   goes in `build_phase`.
4. **Config_db `get` goes in `build_phase`, not `new`** — UVM's
   phase machine guarantees `set` happens before `build_phase`. If
   you `get` in `new`, you race the phase ordering.
5. **`\`uvm_fatal` not `$fatal`** — UVM-native macro routes through
   the reporting infrastructure (severity counters, verbosity); the
   SV `$fatal` system task bypasses all of that.

### `get` patterns

| Pattern | Meaning |
|---|---|
| `get(this, "", "bfm", bfm)` | "from my own scope, look up `bfm`" — most explicit, recommended |
| `get(null, "*", "bfm", bfm)` | "search the whole hierarchy" — works but less precise |

### Corrections — third ch.11 paraphrase (2026-05-06)

- I said we "override the `new` function." Constructors aren't
  virtual in SV; you **implement** a constructor for the subclass
  that delegates to `super.new`. "Override" implies polymorphic
  dispatch, which doesn't apply to constructors.
- I put the `uvm_config_db::get` call inside `new()`. Wrong phase.
  The config_db lookup belongs in **`build_phase`** because UVM's
  phase machine is designed to guarantee all `set` calls happen
  before any component's `build_phase` runs.
- I used `$fatal` instead of `` `uvm_fatal ``. The macro is UVM-
  aware; the system task is not.
- I wrote `virtual interface tinyalu_bfm bfm;` — the `interface`
  keyword is redundant. Canonical: `virtual tinyalu_bfm bfm;`.
- I omitted the `= null` default on the `parent` argument, which
  breaks the standard factory creation pattern.

## Self-check answers — UVM ch.9–13

Captured from senior-mentor review on 2026-05-07 after a first pass
that scored 1.5/6 cleanly. The corrected versions below are the
"interview-grade" form — re-read before any UVM interview.

### Q1 — `uvm_object` vs `uvm_component`

|                | `uvm_component`                                                       | `uvm_object`                                                                |
|----------------|-----------------------------------------------------------------------|-----------------------------------------------------------------------------|
| Lifetime       | persistent — exists for the entire simulation                         | transient — created and destroyed on demand                                 |
| Hierarchy      | yes — has a parent and a name in the component tree                   | none                                                                        |
| Phases         | yes — `build_phase`, `connect_phase`, `run_phase`, `report_phase`, …  | none                                                                        |
| Typical use    | structural elements (test, env, agent, driver, monitor, scoreboard)   | flow-through data (sequence_item, sequence, config object, reg-model field) |

One-liner: **"components live in a static tree with phases; objects
flow through that tree as data."**

### Q2 — `type_id::create()` vs `new()`

`type_id::create()` goes through the UVM **factory** — a registry of
types that maps "requested class" → "actual class to construct."
Default is identity; `set_type_override` changes the right-hand side.

`new()` skips the factory entirely and constructs the literal class
you asked for, ignoring any overrides.

The override mechanism *only* works because components were created
via `type_id::create`. Replace with `new()` and `set_type_override`
silently does nothing.

This week's `factory_override_demo` is the proof: env's
`slow_driver::type_id::create("driver_h", this)` returns a real
`fast_driver` when fast_test installs the override. The handle is
typed `slow_driver`; the runtime object is `fast_driver`.
Polymorphism + factory = override works.

### Q3 — Which UVM phases does Salemi ch.12 actually USE (vs just name)

**`build_phase` and `run_phase`** — only those two are demonstrated.
The chapter names five (build, connect, end_of_elaboration, run,
report); the others are placeholders until later chapters.

### Q4 — Which class installs the factory override — `uvm_test` or `uvm_env`?

**`uvm_test`**. Three reasons:

1. **Phase ordering.** `build_phase` runs **top-down** through the
   component tree. The test's `build_phase` fires *before* the env's.
   The override has to be in the factory before the env calls
   `type_id::create()`, otherwise the env builds the wrong type.

2. **Separation of concerns.** Env defines *structure*; test defines
   *behavior*. Overrides are a behavior choice → they belong with
   the test.

3. **`+UVM_TESTNAME` swapping.** Different tests install different
   overrides; the env structure stays identical. This is what makes
   compile-once / run-many actually useful.

### Q5 — What does `uvm_config_db` do, and why does ch.11's `top` need it?

`uvm_config_db` is a **hierarchically-scoped key/value store**. Keys
are tuples of `(scope, type, field_name)`; scope can be wildcard
`"*"` or a specific component path; values can be anything (virtual
interface handles, config objects, parameters, switches).

Why `top` needs it:

- `top` is the **static SV world** — modules and interfaces, wired
  at elaboration. It has the actual `tinyalu_bfm bfm()` instance.
- UVM components are **dynamic objects** on the heap. They cannot
  directly reference a static-world interface; they need a `virtual`
  handle.
- `uvm_config_db` is the **bridge**. `top` calls `set` with the
  virtual interface; components call `get` in their `build_phase`
  to retrieve it.

One-liner: **"config_db is the static-to-dynamic handoff for
interfaces, plus a general-purpose parameter store."**

### Q6 — Why is the abstract-base-class + factory-override pattern useful?

Four reasons, increasing in depth:

1. **Decouple stimulus from env structure.** The env never changes.
   Only the test classes change. Adding test #50 doesn't require
   touching env code.
2. **Open-closed extension.** New behavior = new subclass + a
   one-line `set_type_override`. You extend the env's behavior
   *without modifying* the env.
3. **Coverage closure scales linearly.** Chasing a missing bin?
   Write a constrained subclass that hits it. Doesn't perturb the
   env or any other test.
4. **Inheritance + late binding.** The handle is typed as the base
   class; the actual runtime object can be any subclass. The factory
   picks at build time. Same call site, different runtime type.

The W4 `factory_override_demo` is the clean proof: env declares
`slow_driver driver_h`, env's `create` call is identical for both
runs, but `+UVM_TESTNAME=slow_test` produces SLOW: tick × 5 while
`+UVM_TESTNAME=fast_test` produces FAST: tick × 5. **Same compiled
snapshot, two opposite behaviors, zero env code edits.**
