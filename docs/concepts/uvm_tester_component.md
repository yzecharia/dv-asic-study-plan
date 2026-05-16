# UVM Tester Component (Abstract Base + Concrete Extensions)

**Category**: UVM · **Used in**: W5 ch.18 (`base_tester.svh` + `random_tester.svh` + `add_tester.svh`) · **Type**: authored

The *tester component* is Salemi's pre-sequence stimulus generator: a `uvm_component` whose `run_phase` produces transactions and pushes them somewhere. In ch.18 the pattern matures into a small **template-method class hierarchy** — an abstract `base_tester` defines the generation loop and leaves the per-transaction *decisions* as pure-virtual hooks; concrete `random_tester` and `add_tester` subclasses fill those hooks in; a test selects which concrete tester runs via a **factory type override**. This note covers HW2's `base_tester.svh`, `random_tester.svh`, and `add_tester.svh`.

It is the direct conceptual ancestor of `uvm_sequence` + `uvm_sequencer`. Understand this hierarchy and the production sequence layer stops being mysterious — it is the same idea with the generation loop moved off the component and onto a sequence object.

## What the hierarchy looks like

```
        base_tester  (abstract / virtual uvm_component)
        ├─ owns  uvm_put_port #(command_t) command_port
        ├─ run_phase: the FIXED generation loop
        ├─ pure virtual  get_op()        ← decision hook
        └─ pure virtual  get_operand()   ← decision hook
                 ▲
                 │ extends
        random_tester                      add_tester
        ├─ get_op()      = random op       ├─ get_op()      = ADD only
        └─ get_operand() = random operand  └─ get_operand() = inherited
```

The base class owns the **invariant** (reset, then N commands, then drain, then drop objection). The subclasses own the **variant** (what each command is). That is the *template method* design pattern — the algorithm skeleton lives in the base, the customisable steps are virtual.

## Style A — Salemi ch.18: abstract tester component with pure-virtual hooks

This is exactly HW2's `base_tester.svh`. The base extends `uvm_component`, instantiates a `uvm_put_port`, and runs a fixed loop. It declares **no** signal-level code — the BFM handle that earlier Salemi testers carried is gone; stimulus *application* is now the `driver`'s job (see `[[uvm_driver]]`).

```systemverilog
virtual class base_tester extends uvm_component;          // abstract — see note below
    `uvm_component_utils(base_tester)

    uvm_put_port #(command_t) command_port;

    function void build_phase(uvm_phase phase);
        command_port = new("command_port", this);          // port: new(), not factory
    endfunction

    pure virtual function operation_t get_op();             // decision hooks —
    pure virtual function byte        get_operand();        // subclass MUST implement

    task run_phase(uvm_phase phase);
        command_t command;
        phase.raise_objection(this);                        // tester owns the objection
        command.op = rst_op;
        command_port.put(command);                          // blocking put into the fifo
        repeat (1000) begin
            command.op = get_op();                          // call the hook
            command.A  = get_operand();
            command.B  = get_operand();
            command_port.put(command);
        end
        #500;
        phase.drop_objection(this);
    endtask

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
endclass
```

```systemverilog
class random_tester extends base_tester;
    `uvm_component_utils(random_tester)

    virtual function operation_t get_op();                  // implements the hook
        bit [2:0] op_choice = $random;
        case (op_choice)
            3'b000, 3'b101: return no_op;
            3'b001:         return add_op;
            3'b010:         return and_op;
            3'b011:         return xor_op;
            3'b100:         return mul_op;
            3'b110, 3'b111: return rst_op;
        endcase
    endfunction

    virtual function byte get_operand();
        bit [1:0] corner = $random;
        if      (corner == 2'b00) return 8'h00;             // bias toward corners
        else if (corner == 2'b11) return 8'hFF;
        else                      return $random;
    endfunction

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
endclass

class add_tester extends random_tester;                     // extends the concrete one
    `uvm_component_utils(add_tester)

    function operation_t get_op();
        return add_op;                                      // override op; inherit get_operand()
    endfunction

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
endclass
```

Three things worth naming:

1. **`virtual class` for the base.** A class with a `pure virtual` method must be `virtual` (abstract) — it cannot be constructed directly. Salemi guards this with `` `ifdef QUESTA `` because some simulators reject `virtual class` together with `uvm_component_utils`; portable code keeps the `virtual` keyword. The base is never instantiated anyway — only the concrete subclasses are.
2. **`add_tester extends random_tester`, not `base_tester`.** It reuses `random_tester::get_operand()` and only re-specialises `get_op()`. Chaining extension to grab the nearest useful implementation is deliberate; extending `base_tester` would force `add_tester` to re-implement `get_operand()` for nothing.
3. **The tester raises the objection, not the test.** Salemi's tester is self-contained: it knows when its stimulus is done. The `driver` on the other end of the fifo runs a bare `forever get` loop and raises *nothing* — see `[[uvm_run_workflow]]`.

## Style B — Industry production: `uvm_sequence` on a `uvm_sequencer`

In production you do not write a tester component. The same job is split:

- **The generation algorithm** moves onto a `uvm_sequence #(req)` — a `uvm_object`, not a component. Its `body()` task is the loop; `uvm_do`/`start_item`/`finish_item` replace `command_port.put()`.
- **The thread + the port** live in a `uvm_sequencer #(req)`, a stock component you instantiate and never subclass.
- **The decision hooks** become **constraints** on a `uvm_sequence_item`, plus sequence subclassing or `p_sequencer` config — not pure-virtual functions.
- **Selection per test** is still a factory override, but you override the *sequence type* (or set it via config_db) rather than the tester component type.

```systemverilog
class alu_base_seq extends uvm_sequence #(alu_item);
    `uvm_object_utils(alu_base_seq)
    function new(string name = "alu_base_seq"); super.new(name); endfunction

    task body();
        repeat (1000) begin
            alu_item req = alu_item::type_id::create("req");
            start_item(req);
            if (!req.randomize())                           // constraints replace get_op()
                `uvm_fatal("RAND", "randomize failed")
            finish_item(req);                               // hands req to the driver
        end
    endtask
endclass

class add_only_seq extends alu_base_seq;                    // "add_tester" equivalent
    `uvm_object_utils(add_only_seq)
    function new(string name = "add_only_seq"); super.new(name); endfunction
    task body();
        repeat (1000) begin
            alu_item req = alu_item::type_id::create("req");
            start_item(req);
            if (!req.randomize() with { op == ADD; })       // narrowed by constraint
                `uvm_fatal("RAND", "randomize failed")
            finish_item(req);
        end
    endtask
endclass
```

The driver pulls with `get_next_item`/`item_done` off its built-in `seq_item_port`. The test does `seq.start(env.agent.sequencer)`. See `[[uvm_sequences_sequencers]]` and `[[uvm_sequence_item]]`.

## Why Salemi uses Style A

- **Sequences are four chapters away.** Ch.18 is mid-book; `uvm_sequence` lands in ch.23. The tester component teaches stimulus-vs-application separation *without* the sequencer's arbitration machinery.
- **It isolates the template-method idea.** Abstract base + pure-virtual hook + concrete subclass + factory override is a complete, self-contained lesson. Adding the sequencer here would bury it.
- **It motivates the next step.** After ch.18 the reader has felt the limits — no constraints, no layering, no arbitration — so the sequence layer arrives as an obvious upgrade rather than unexplained ceremony.

## Why industry uses Style B

- **Stimulus must be reusable and randomisable.** A `uvm_sequence` is a `uvm_object`: cloneable, randomisable, layerable, startable on any sequencer. A tester *component* is pinned into one place in the hierarchy and cannot be composed.
- **Constraints beat hand-written hooks.** `randomize() with { ... }` plus a constrained `uvm_sequence_item` expresses stimulus intent declaratively. `$random` inside a `case` is unconstrained, un-coverable, and not reusable.
- **The sequencer arbitrates.** Multiple concurrent sequences, virtual sequences across UVCs, priority — all stock. A single-producer tester component cannot do this.
- **`pure virtual` hooks do not scale.** Two hooks is fine; a real protocol has dozens of knobs. Constraints + config objects scale where a wall of pure-virtual functions does not.

## When to use which

| Context | Style |
|---|---|
| Salemi ch.18 homework (HW2) | A — abstract `base_tester`, concrete `random_tester`/`add_tester`, factory override |
| Any production UVC, W6 onward | **B** — `uvm_sequence` on a `uvm_sequencer` |
| W11 SPI/AXI-Lite, W12+ portfolio | **B, always** |
| Throwaway smoke test, no agent yet | A is acceptable; B is still cheap once an agent exists |

A tester component does not pass review at a silicon shop — but the *pattern underneath it* (abstract base, virtual hooks, factory-selected concrete class) is exactly how you structure base vs. derived **sequences** and base vs. derived **tests**. The skill transfers; the literal class does not.

## Reset handling — `rst_op` command vs driver-side wait

The Style A `run_phase` above opens with `command.op = rst_op; command_port.put(command);`. That is Salemi's reset strategy: **reset is just another command.** The tester's first `put` carries a `rst_op` transaction; the `driver` `get`s it like any other; the BFM's `send_op` task branches — `if (iop == rst_op)` it toggles `reset_n`, else it drives a normal operation. The tester never touches the interface and never waits on `reset_n` — it *causes* reset by making it transaction zero.

Elegant, but it has a **precondition: the command type must have a spare opcode.** Salemi's `operation_t` carries dedicated `rst_op` and `no_op` members alongside the real ALU ops. If your command enum is packed and fully populated — e.g. a 2-bit enum holding exactly `{ADD, AND, XOR, MUL}` — there is no slot for `rst_op`. Adding one means widening the enum to 3 bits, which ripples into the `command_t` struct width, the coverage covergroup (now needs an `ignore_bins` for the synthetic non-DUT opcode), and the scoreboard predictor (must skip it). That ripple is frequently not worth paying.

**No spare opcode → reset belongs in the driver, not the tester.**

The tester is transactional: post-ch.18 it holds no virtual interface and has no concept of clocks, reset, or pins. The `driver` owns the vif, so pin-level synchronisation — reset included — is the driver's job. The reset wait goes at the top of the driver's `run_phase`, before its `forever get` loop:

```
driver run_phase:
    @(vif.cb iff vif.cb.reset_n);   ← driver owns the vif; reset wait lives here
    forever begin
        command_port.get(cmd);
        vif.send_op(cmd);
    end
```

The tester still begins `put`ting at time 0; it does not wait on reset *explicitly*. The `uvm_tlm_fifo` backpressures it instead — the fifo fills (default depth 1), the tester blocks on its next `put`, and stays blocked until the driver clears reset and starts draining. No command reaches the DUT during reset, and none are lost. See `[[uvm_put_get_tlm_fifo]]` for the backpressure timeline.

| Reset strategy | Use when | Cost |
|---|---|---|
| `rst_op` command (Salemi) | the command enum has a free opcode slot | covergroup + scoreboard must tolerate the synthetic op |
| Driver-side `@(cb iff reset_n)` | the command enum is packed/full, or you want the tester strictly reset-agnostic | one wait line in the driver; tester untouched |

Either way the invariant holds: **the tester never waits on `reset_n` itself.** It encodes reset as a transaction, or it lets the driver absorb it.

## Common gotchas

- **Forgetting `virtual` on the abstract base** — a class with a `pure virtual` method must be `virtual`, or it will not compile.
- **Constructing the abstract base** — `base_tester::type_id::create(...)` on the abstract class fails. Only concrete subclasses are created; the test factory-overrides `base_tester` → a concrete one.
- **Re-implementing an inherited hook for nothing** — `add_tester` correctly inherits `get_operand()` from `random_tester`. Extend the nearest class that already gives you what you need.
- **Raising the objection in both tester and test** — pick one owner. Salemi's tester owns it; if the test also raises one, the phase end logic gets muddier than it needs to be.
- **Constructing the `uvm_put_port` with the factory** — ports use `new()`, never `type_id::create`. See `[[uvm_put_get_tlm_fifo]]`.
- **Making the tester wait on `reset_n`** — post-ch.18 the tester holds no virtual interface; it *cannot* `@(cb iff reset_n)`. Reset is either encoded as a `rst_op` command or absorbed by the driver — see "Reset handling" above.

## Reading

- Salemi *The UVM Primer* ch.18 (Put and Get Ports in Action), pp. 123–129 — the `base_tester`/`random_tester`/`add_tester` split and the put-port wiring (Figures 127–128).
- Salemi *The UVM Primer* ch.11 (UVM Tests), pp. 67–75 — the factory override that selects the concrete tester per test.
- Salemi *The UVM Primer* ch.23 (UVM Sequences) — the production replacement for the tester component.
- IEEE 1800.2-2020 §F — `uvm_component`; §16 — `uvm_sequence`.

## Cross-links

- `[[uvm_put_get_tlm_fifo]]` — the `uvm_put_port` + `uvm_tlm_fifo` the tester pushes into.
- `[[uvm_driver]]` — the get-side consumer of the tester's commands.
- `[[uvm_test]]` — `random_test`/`add_test` select the concrete tester via factory override.
- `[[uvm_factory_config_db]]` — `set_type_override` mechanics.
- `[[uvm_sequences_sequencers]]` · `[[uvm_sequence_item]]` — the production successor pattern.
- `[[uvm_env]]` — owns the tester, the driver, and the fifo joining them.
- `[[uvm_run_workflow]]` — objection ownership in the tester/driver split.
