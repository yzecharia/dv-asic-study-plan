# HW1 (Analysis-Path ALU TB) — Q&A Notebook

> Captured during the HW1 implementation session. Questions Yuval asked,
> simple answers, key takeaways, and the points where the implementation
> diverged from Salemi *The UVM Primer* ch.16–17.

---

## Architecture & mental models

### Q: Why does the BFM logic live inside the SystemVerilog interface?

Three reasons, in priority order:

1. **SV language constraint.** `always @(posedge clk)` blocks can only live in modules or interfaces — never in UVM classes. If you need clocked behavior watching bus signals, it must live where SV allows it.
2. **Adjacency to signals.** The interface declares the signals; the BFM block reads them directly (no `vif.X` indirection). Same naming as the DUT sees.
3. **Encapsulation.** Protocol-aware code lives next to the protocol signals. Swap the DUT (same protocol, different implementation) and only the interface stays put; classes are protocol-agnostic.

→ See [`bfm_pattern.md`](../docs/concepts/bfm_pattern.md).

---

### Q: Pull vs push monitor pattern — what's the difference?

| | Pull (W4 style) | Push (analysis-path, this HW) |
|---|---|---|
| Who watches the bus? | Monitor (has a virtual interface) | Interface BFM (`always @(posedge clk)`) |
| Who decides the timing? | Monitor's own clocked logic | The BFM's `always` block — already at signal level |
| What does the monitor know? | Protocol details + bus signal names | Nothing about the bus; just receives transactions |
| Reuse story | Monitor is bus-specific | Monitor is bus-agnostic; same template for any 1-cmd-per-event protocol |

**Pizza analogy:** push pattern = your friend texts you when pizza arrives. You don't need their house key, you don't need to know what a pizza delivery car looks like — just a phone number they can reach. Pull pattern = you stand at their window peering through the blinds.

→ See [`uvm_analysis_ports.md`](../docs/concepts/uvm_analysis_ports.md).

---

### Q: Why doesn't the monitor have a virtual-interface handle?

Because **the interface pushes to the monitor**, not the other way around. The monitor only needs:
- An analysis port (`ap`) to broadcast to subscribers.
- A public function (`write_to_monitor(...)`) the BFM calls.

A virtual interface in the monitor would be the W4 pull pattern — and would also create bidirectional coupling. The whole point of analysis-path is to keep monitors signal-free.

---

## UVM building blocks

### Q: What's a `uvm_analysis_port` and how is it different from `uvm_analysis_imp`?

- **`uvm_analysis_port #(T)`** — *outbound* / publisher side. The producer owns it. Calling `ap.write(t)` fans out to every connected subscriber's `write()` callback (Observer pattern).
- **`uvm_analysis_imp #(T, OWNER)`** — *inbound* / single-subscriber side. Rarely declared manually because `uvm_subscriber #(T)` gives you one for free (called `analysis_export`).

In the analysis-path testbench:
- Each monitor owns one `uvm_analysis_port`.
- Each subscriber (coverage, scoreboard) inherits one `analysis_export` from `uvm_subscriber #(T)`.

→ See [`uvm_analysis_ports.md`](../docs/concepts/uvm_analysis_ports.md).

---

### Q: What does `ap.write(t)` actually do?

It synchronously calls `write(t)` on every connected subscriber's `analysis_export`, in connect order, in zero simulation time. The analysis port is just a multiplexer; the real work is in each subscriber's `write()` body.

In your `command_monitor`:
```
function void write_to_monitor (command_t cmd);
    `uvm_info(get_type_name(), $sformatf(...), UVM_HIGH)
    ap.write(cmd);          // ← fan-out happens here
endfunction
```

One `ap.write(cmd)` call → `coverage.write(cmd)` fires → `scoreboard.cmd_fifo` enqueues — both, same simulation time.

---

### Q: Why `uvm_subscriber #(T)` for coverage and scoreboard?

Two things you get for free:
1. **An `analysis_export`** — pre-built `analysis_imp` ready for the publisher's `connect()` call.
2. **A pure-virtual `function void write(T t)`** — the contract. You MUST implement it; otherwise the class won't compile.

Compare with `extends uvm_component` where you'd have to manually declare `uvm_analysis_imp #(T, my_class) imp;` and remember to construct it.

→ See [`uvm_subscriber_coverage.md`](../docs/concepts/uvm_subscriber_coverage.md).

---

## Scoreboard & TLM

### Q: Why does the scoreboard need a FIFO?

Because commands and results arrive at **different latencies**. ADD is one cycle; MUL is three. The scoreboard can't compare predicted vs actual until both halves are present:

- **Push side (command):** as commands fly past the BFM, they go into the FIFO.
- **Trigger side (result):** when a result arrives, pop the matching command from the FIFO, predict, compare.

Without the FIFO, you'd need a state machine inside the scoreboard to remember pending commands — same logic, more error-prone.

**Assumption:** in-order DUT (single-issue). FIFO order matches issue order. For out-of-order DUTs you'd need tagged transactions.

→ See [`uvm_tlm_analysis_fifo.md`](../docs/concepts/uvm_tlm_analysis_fifo.md).

---

### Q: `try_get` vs `get` — which one in the scoreboard?

`try_get` — **non-blocking**. Returns 1 if a transaction was available, 0 if FIFO empty. Used inside `function void write(...)` because functions cannot block.

`get` — **blocking**. Used in tasks (`task run_phase`).

In your scoreboard's `write(result_t t)`, you must use `try_get` because `write` is a function. If `try_get` returns 0, that means "result arrived without matching command" — log a `\`uvm_error`, increment fail count, don't crash silently.

---

### Q: Does the DUT have an internal queue for pending commands?

No. Your ALU is **single-issue, in-order, blocking**:
- DUT only accepts a command when `state == IDLE && start == 1`.
- During MUL (3 cycles), the DUT is non-IDLE. Any `start` assertion during that window is **silently dropped**.

The protocol contract: tester must **wait for `done`** before issuing the next `start`. The scoreboard's FIFO buffers commands during the multi-cycle window, but the DUT itself has no queue.

---

## Factory pattern

### Q: Why `type_id::create(...)` instead of `new(...)`?

`new()` is final — hard-codes the class at compile time. `type_id::create(...)` goes through the **UVM factory**, which consults a registry of overrides at runtime.

When env does `base_tester::type_id::create("tester", this)`, the factory checks: "does any test have a `set_type_override` for `base_tester`?" If yes, it constructs that subclass instead. This is what makes `random_test` and `add_test` use different stimulus while sharing the same env.

→ See [`factory_pattern_sv.md`](../docs/concepts/factory_pattern_sv.md), [`uvm_factory_config_db.md`](../docs/concepts/uvm_factory_config_db.md).

---

### Q: How does `set_type_override` work?

It's a static method on `<class>::type_id`. Called in a test's `build_phase` BEFORE env's build_phase fires (test phases run parent → child):

```
base_tester::type_id::set_type_override(random_tester::get_type());
```

Reads as: "wherever someone tries to `create` a `base_tester` via the factory, give them a `random_tester` instead." This is the entire mechanism that lets you swap the active tester without touching env.

---

### Q: Why does env declare `base_tester tester;` instead of `random_tester tester;`?

Because the **handle type** = "what subclasses can be assigned to this variable." Declaring as `base_tester` lets it hold any descendant (random_tester, add_tester, future mul_tester...). Declaring as `random_tester` would lock out `directed_tester` if it extends `base_tester` directly.

For polymorphism via factory override: handle type is the **broadest reasonable base**. Factory call is for what you want to instantiate.

---

## uvm_config_db

### Q: Is it like a dictionary?

Yes — with two extra dimensions:
1. **Per-type registry**: `#(T)` parameterization. `uvm_config_db#(virtual alu_if)` and `uvm_config_db#(int)` are separate tables.
2. **Hierarchical scope patterns**: each entry has a glob pattern (e.g., `"*"`, `"env.*"`) controlling which components can read it.

```
uvm_config_db#(virtual alu_if):
┌──────────────┬──────────┬───────────────────┐
│ scope        │ key      │ value             │
├──────────────┼──────────┼───────────────────┤
│ "*"          │ "aluif"  │ <handle to vif>   │
└──────────────┴──────────┴───────────────────┘
```

→ See [`uvm_factory_config_db.md`](../docs/concepts/uvm_factory_config_db.md).

---

### Q: What are the four args to `uvm_config_db::get(...)`?

```
uvm_config_db #(<TYPE>)::get(<CNTXT>, <INST>, <KEY>, <VALUE>)
                #(...)     ^      ^       ^      ^
                type      ctx   scope   key    output
```

- **Type param `#(T)`**: the type of the stored value. Publisher and getter must use *identical* types — `virtual alu_if` and `virtual alu_if.dut` are different.
- **Arg 1 `cntxt`**: anchor for hierarchical lookups. From a component, pass `this`. From a module (alu_tb_top), pass `null`.
- **Arg 2 `inst`**: instance suffix appended to `cntxt.get_full_name()` to form the lookup path. Usually `""` on get, `"*"` on set.
- **Arg 3 `key`**: the lookup string. Publisher and getter must match exactly (case-sensitive).
- **Arg 4 `value`**: the output reference (filled on get) or input value (on set).

Standard pair for "publish for everyone":
- Publisher (alu_tb_top): `set(null, "*", "aluif", aluif)`.
- Getter (component): `get(this, "", "aluif", aluif)`.

---

### Q: Why does `this` fail in alu_tb_top.sv?

`this` is a class/component reference. Modules are not classes — they don't have `this`. In a module, use `null` for the cntxt arg.

This is one of the easiest UVM compile-blockers to hit; xvlog rejects it with "this is only valid within a class."

---

## SystemVerilog specifics

### Q: Why do we need `new_command` (the edge detector)?

The tester drives `start = 1` and holds it high until `done` arrives (the protocol contract). For a 3-cycle MUL, that's 3 cycles of `start == 1`. Without an edge detector, the BFM's `if (start) write_to_monitor(cmd)` would fire **once per cycle**, broadcasting the same command 3 times → FIFO accumulates 3 entries, only 1 result arrives → 2 phantom commands stuck in the FIFO forever.

`new_command` is a one-shot latch: set to 1 when `start == 0` (armed), fires + clears when `start == 1` (one broadcast per rising edge of start).

**Static lifetime matters.** Declared inside the always block, some simulators give it automatic lifetime → re-initializes to 0 every cycle → latch never holds → BFM never fires. Moved to interface scope to force static.

→ See new note [`bfm_edge_detector.md`](../docs/concepts/bfm_edge_detector.md).

---

### Q: Why did `cp_carry` need `{1'b0, cmd_in.a} + {1'b0, cmd_in.b}` instead of just `cmd_in.a + cmd_in.b`?

SV expression width rules. `cmd.a` and `cmd.b` are 8-bit. The comparison `> 8'hFF` is also 8-bit. **Self-determined context** means the `+` evaluates at 8-bit width — truncating the carry. `0xFF + 0x01` produces `0x00`, not `0x100`. `0x00 > 0xFF` is false. The `carry` bin is unreachable.

Fix: zero-extend both operands to 9 bits with `{1'b0, ...}`. Now the `+` evaluates at 9-bit width, no truncation, and `> 9'hFF` correctly detects carry-out.

**Contrast with scoreboard's `predict`** — there, the result of `cmd.a + cmd.b` is assigned to a 16-bit `result_t res`. The LHS context width is 16, so the operands get context-extended to 16 before adding. No truncation. The bug only bit us in coverage because the LHS context there was 1-bit boolean.

→ See new note [`sv_expression_width_context.md`](../docs/concepts/sv_expression_width_context.md).

---

### Q: Why use a clocking block instead of direct signal drives?

Three benefits:
1. **Race-free.** Outputs drive at `posedge clk + skew`; inputs sample at `posedge clk - skew`. The tester never collides with the DUT's sample edge.
2. **One-line skew change.** If timing changes, edit the clocking block header — not every `<=` statement.
3. **Cleaner code.** `@(aluif.cb_tb iff aluif.cb_tb.done);` replaces a manual `@(posedge clk); if (done) break;` loop.

In your alu_if.svh, `modport tb (clocking cb_tb);` exposes ONLY the clocking block — the tester literally cannot bypass it.

→ See [`clocking_resets.md`](../docs/concepts/clocking_resets.md), [`interfaces_modports.md`](../docs/concepts/interfaces_modports.md).

---

### Q: Why bare `virtual alu_if` in classes, not `virtual alu_if.tb`?

The publisher (alu_tb_top) sets with type `virtual alu_if`. All getters must match exactly. Using `virtual alu_if.tb aluif;` in classes would require the publisher to also publish with that modport type — adds maintenance overhead with no functional gain. Discipline at access time (`aluif.cb_tb.cmd <= ...`) gives you the synchronization benefits without the type-juggling.

---

### Q: Why initialize `start = 0` in the interface?

`logic start` defaults to `X`. The BFM's `if (!start)` arms the edge detector — but `!X` is `X`, which is falsy. The detector never arms. The very FIRST command is missed.

Adding `initial start = 1'b0;` at the top of the interface forces `start` to a defined value at time 0. The detector arms correctly on the first cycle and fires on the first 0→1 transition.

---

### Q: Why does the tester need a `@(aluif.cb_tb);` AFTER dropping `start = 0`?

Without the wait, the loop iterates and drives `start = 1` again **in the same simulation timestep** as the `start = 0` drive. Both are non-blocking — the LAST one wins. `start` never actually goes back to 0 → the BFM's edge detector never sees a 0→1 transition → write_to_monitor fires once (or zero times) and never again.

Adding the wait lets the clocking block apply the `start = 0` drive at the next clock edge before the next iteration overwrites it.

---

### Q: How do you wait N clock cycles in SV?

```
repeat (N) @(posedge clk);
```

For your reset generator:
```
initial begin
    reset_n = 1'b0;
    repeat (5) @(posedge clk);
    reset_n = 1'b1;
end
```

Inside a clocking block you can also use `##N;` shorthand. Procedural code outside a clocking block uses `repeat`.

---

## Differences vs Salemi's pattern

The HW1 stack diverges from *The UVM Primer* (ch.16–17) in three places. All three are stylistic / architectural — both work — but worth knowing.

### 1. Where clk/reset live

**Salemi (Figure 10):** declared as `bit clk; bit reset_n;` *inside* the BFM (`tinyalu_bfm` is `interface tinyalu_bfm;` with no port list). The interface generates its own clock and exposes a `reset_alu()` task that the tester calls.

**Yuval's design:** `interface alu_if (input logic clk, reset_n);` — clk and reset are *inputs to* the interface. alu_tb_top generates them and drives them through the port connection.

| Aspect | Salemi pattern | Yuval's pattern |
|---|---|---|
| Top module size | ~5 lines | ~25 lines (clk + reset + UVM kickoff) |
| Reuse w/ different clocks | Have to edit BFM | BFM unchanged |
| Separation of concerns | Mixed (BFM owns timing) | Clean (top owns timing) |

Both are valid; production codebases lean toward Yuval's pattern for the reuse angle.

### 2. Monitor handle wiring (config_db direction)

**My initial teaching (wrong, then corrected):** env publishes monitor handles to config_db; the BFM's `initial` block fetches them. Three config_db round-trips total (vif + 2 monitors).

**Salemi (Figure 104, the right answer):** the **monitors self-inject** into the BFM during their own `build_phase`. Each monitor fetches the BFM from config_db, then does `bfm.command_monitor_h = this;`. Only ONE config_db publish (the BFM itself); zero env-side publishes for monitor handles.

We switched to Salemi's pattern partway through HW1. The resulting code is simpler and matches the book.

### 3. `ap = new(...)` placement

**Salemi (Figure 104):** `ap = new("ap", this);` lives in **`build_phase`**.

**Yuval's choice:** `ap = new("ap", this);` lives in **`new()`** (constructor).

Both work — `build_phase` is the documented pattern in *The UVM Primer*, `new()` is common in production code. Yuval's classes keep them in `new()` for consistency.

### 4. Pattern A vs Pattern B for tests

**Salemi Pattern A (used here):** every test explicitly calls `set_type_override` in its own `build_phase`. random_test overrides to random_tester; add_test overrides to add_tester. env declares `base_tester` as a placeholder (abstract).

**Alternative Pattern B (not used):** env's build_phase calls `random_tester::type_id::create(...)` directly (concrete default). add_test still overrides to add_tester. random_test becomes trivial.

Pattern A wins on **self-documenting tests** — open random_test.svh, see exactly which tester it uses. Pattern B trades that for fewer lines.

---

## Cheat-sheet — APIs you used and their semantics

| API | What it does |
|---|---|
| `uvm_analysis_port#(T)` | Outbound publisher. Owns no state. Call `.write(t)` to fan-out. |
| `uvm_subscriber#(T)` | Inbound receiver. Inherits `analysis_export` and pure-virtual `write(T t)`. |
| `uvm_tlm_analysis_fifo#(T)` | Buffering subscriber. Owns `analysis_export` (in) + `try_get(t)` / `get(t)` (out). |
| `uvm_config_db#(T)::set(cntxt, scope, key, val)` | Publish value under key, visible to scope-matching consumers. |
| `uvm_config_db#(T)::get(cntxt, "", key, var)` | Fetch value; returns 0 if not found. |
| `T::type_id::create("name", parent)` | Factory-build a component. Honors `set_type_override`. |
| `T::type_id::set_type_override(U::get_type())` | "Wherever someone creates T, give them U instead." |
| `cg.sample()` | Manually trigger a covergroup sample (paired with subscriber `write()`). |
| `cg.get_inst_coverage()` | Returns this instance's coverage 0–100. |
| `cg.get_coverage()` | Returns coverage across all instances of this covergroup type. |
| `phase.raise_objection(this)` / `drop_objection(this)` | Keep `run_phase` alive between the two calls. |
| `repeat (N) @(posedge clk);` | Wait N clock cycles. |
| `@(aluif.cb_tb iff condition);` | Wait for next clocking edge where condition is true. |
| `\`uvm_info(id, msg, verb)` | Log info with verbosity gating. |
| `\`uvm_error(id, msg)` | Log error (no verbosity; always shown, counts toward fail tally). |
| `$fatal(1, msg)` | Halt simulation immediately. Use when a get failure would null-pointer later. |

---

## Recap — three biggest lessons

1. **Analysis-path inverts the timing authority.** The BFM (in the interface) is the protocol expert. Monitors are dumb broadcasters. Subscribers are leaf consumers. Each layer knows exactly one job.

2. **`uvm_config_db` is a typed hierarchical dictionary.** Type parameter, scope pattern, key, value. Mismatches are silent — `set#(virtual alu_if)` vs `get#(virtual alu_if.dut)` return null, then later code null-pointer-crashes. Always match types exactly.

3. **SV expression width is context-determined.** Operands extend to the LHS or comparison context width. When the context is narrow (e.g. `> 8'hFF` as a 1-bit boolean), arithmetic truncates inside. Always zero-extend operands when checking for overflow.
