# Randomization in SystemVerilog — `rand`, `randc`, and Constraints

**Category**: SV · **Used in**: W2 (anchor — Spear ch.6), W4–W7 (UVM stimulus), W9–W11 (RTL self-check), W14+ (RAL & multi-UVC) · **Type**: authored

Constrained-random verification (CRV) is the lever that makes UVM worth the boilerplate. Directed tests scale linearly with the number of bugs you can imagine; CRV scales with simulation cycles, and the simulator finds the bugs you didn't imagine. The mechanics live in three primitives — the `rand`/`randc` modifiers, the `constraint` block, and the `randomize()` call — plus a handful of secondary tools (`with`, `dist`, `solve…before`, `pre_/post_randomize`, `rand_mode`, `constraint_mode`). Get these right and your stimulus is reproducible, biasable, and debuggable. Get them wrong and you ship "random" tests that hit the same five corners every seed.

## The two random modifiers

```systemverilog
class packet;
    rand  bit [7:0]  payload;     // uniform, with replacement
    randc bit [2:0]  opcode;      // cyclic — every value of [0:7] before any repeat
endclass
```

| Modifier | Distribution | When to use |
|---|---|---|
| `rand`  | Uniform across the legal value set, **with replacement**. Repeats are normal. | Default. Use for almost everything: data payloads, addresses, delays. |
| `randc` | Cyclic — the solver enumerates the entire legal set, shuffles it, and emits each value exactly once before any repeat. | Small, exhaustively-testable sets where you want guaranteed coverage *within* a single sequence: opcodes, register IDs, FSM next-state stimuli. |

`randc` allocates a permutation table over the **declared** type's full range, *before* constraints prune it. A naked `randc bit [31:0]` reserves a 4-billion-entry state — most simulators will refuse or thrash. **Cap `randc` to ≤ 8 bits in practice.** If you need cyclic behaviour on a wider field, declare a narrow `randc` index and use it as a lookup into a wider value table.

`randc` is also per-instance: two `randc` fields in the same class advance independently, and creating a new object resets the cycle.

## `randomize()` — the call

`std::randomize()` (or, more commonly, `obj.randomize()`) is a function that invokes the constraint solver. It returns 1 on success, 0 on failure (no value satisfies the active constraints). **Always check the return.**

```systemverilog
packet p = new();
if (!p.randomize()) `uvm_fatal("RAND", "packet.randomize() failed")
```

A silent failure leaves the rand fields at their previous values — usually zero — and your test runs with degenerate stimulus. This is one of the most common reasons "my random test only ever sees address 0".

### Inline `with` constraints

`with { … }` adds constraints *for this call only*, layered on top of any class-level constraints:

```systemverilog
if (!p.randomize() with { payload inside {[8'h10:8'h7F]}; opcode != 3'b111; })
    `uvm_fatal("RAND", "constrained packet.randomize() failed")
```

Industry pattern: the class declares the **always-true** invariants (`addr % 4 == 0`, `length > 0`); the test or sequence layers per-scenario tightenings via `with`. This keeps the class reusable and the test legible.

### Randomizing only some fields

`p.randomize(payload)` re-solves only `payload`; all other rand fields are treated as state and held at their current values. Useful when you want to keep a header constant while varying the body across calls.

## Constraint blocks

```systemverilog
class memory_op;
    rand bit [31:0] addr;
    rand bit [10:0] length;
    rand bit        is_write;

    constraint c_align     { addr[1:0] == 2'b00; }
    constraint c_length    { length inside {[1:1024]}; }
    constraint c_no_wrap   { addr + length < 32'hFFFF_FFFF; }
endclass
```

- **Solver semantics**: all active constraints are solved *simultaneously*. Order of declaration doesn't change the result; the solver picks any assignment that satisfies them all.
- **Naming**: every constraint is named so it can be toggled at runtime via `constraint_mode()`. Name them by intent (`c_align`, `c_no_wrap`) — never `c1`, `c2`.
- **Implication** (`->`) lets one decision gate another:
  ```systemverilog
  constraint c_burst { is_write -> length <= 16; }   // only writes are short
  ```
- **`if`/`else`** is an alternative form for the same shape:
  ```systemverilog
  constraint c_burst {
      if (is_write) length <= 16;
      else          length <= 1024;
  }
  ```
- **`inside { … }`** for set membership:
  ```systemverilog
  constraint c_legal_op { opcode inside {ADD, SUB, AND, OR, XOR}; }
  ```
- **`dist` for weighted distributions** — see below.

### `solve … before …` — controlling solve order

The solver is free to pick any consistent assignment. With dependent fields, that "freedom" produces lopsided distributions:

```systemverilog
rand bit       small;
rand bit [7:0] value;
constraint c_dep { small -> value < 8'h10; }
```

Without help, the solver picks `value` first across its full 256-entry range, then `small` is forced to 0 in the 240/256 cases where `value ≥ 16`. Result: `small == 1` is exercised in only ~6 % of seeds.

```systemverilog
constraint c_order { solve small before value; }
```

Now the solver picks `small` first (uniformly 50/50), *then* `value` constrained by it. **Use `solve…before` whenever a Boolean or narrow field gates a wide one** — without it, the wide field's range will swamp the narrow one's distribution.

### `dist` — weighted distributions

```systemverilog
constraint c_addr_bias {
    addr dist {
        32'h0000_0000           := 5,    // exact value, weight 5
        [32'h0000_0004:32'hFFFC] :/ 90,  // range, weight split across the range
        32'hFFFF_FFFC           := 5
    };
}
```

- `:=` assigns the weight to **each** value in the set/range.
- `:/` splits the weight **across** the range.

Use `dist` to bias toward boundary values without forbidding the bulk of the range.

## Hooks: `pre_randomize` / `post_randomize`

Two virtual functions automatically called by `randomize()`:

```systemverilog
class frame;
    rand bit [7:0] data[];
    rand int       len;
    bit [15:0]     crc;

    constraint c_size { len inside {[1:64]}; data.size() == len; }

    function void pre_randomize();
        // tighten or relax constraints based on prior state
        if (force_jumbo) c_size.constraint_mode(0);
    endfunction

    function void post_randomize();
        crc = compute_crc(data);   // derive non-rand fields from the solved values
    endfunction
endclass
```

- **`pre_randomize`** runs *before* the solver fires. Use it to enable/disable constraints based on outside state, or to capture seed-dependent setup.
- **`post_randomize`** runs *after* a successful solve. Use it to compute derived non-`rand` fields (CRCs, parity, ECC) from the solved values. Do **not** use it to "fix up" constraint violations — write a constraint instead.

## Runtime toggles

| API | Effect |
|---|---|
| `obj.rand_mode(0)` / `obj.field.rand_mode(0)` | Disable randomization on an entire object or a single field; the field becomes state for subsequent `randomize()` calls. |
| `obj.c_xxx.constraint_mode(0)` | Disable a single named constraint. Returns to the solver-only-considers-active-constraints state. |
| `obj.rand_mode(1)` / `obj.c_xxx.constraint_mode(1)` | Re-enable. |

Useful when a single test wants two phases (warm-up with tight constraints, stress with wide-open) without rewriting the class.

## Reproducibility — seeds and stability

Random value selection is deterministic given a seed. For UVM:

- The simulator-level seed comes from `+ntb_random_seed=N` (Synopsys), `-svseed N` (Vivado xsim), `-seed N` (Cadence). UVM also exposes `+UVM_RANDOM_SEED=N`.
- **Each thread/object gets its own RNG stream**, derived from the master seed plus a per-instance hash. Adding a new component or changing object construction order will perturb downstream streams — your "same seed" rerun won't reproduce. Industry term: **random stability**. Spear ch.6 covers this trap in detail.
- For repro debugging, capture the seed from the run log and re-supply it. For regression triage, vary the seed (`-svseed random`) so a flaky bug surfaces.

## `rand` on aggregates

| Type | Behaviour |
|---|---|
| `rand` packed array (`rand bit [31:0] x;`) | Each bit is randomized; constraints apply to the whole word. |
| `rand` unpacked array (`rand byte buf[64];`) | Each element is randomized independently. |
| `rand` dynamic array (`rand byte buf[];`) | Both `.size()` and contents are random. Constrain `buf.size()` explicitly or it can resolve to 0 or huge. |
| `rand` queue / associative array | Same — must constrain size. |
| `rand` object handle (`rand pkt_t p;`) | The handle is **not** rerouted; instead, `randomize()` recurses into the existing object pointed to by `p`. The handle must be non-null at randomize-time. |
| `rand enum` | One of the legal labels, uniformly. |

## Industry-standard idioms

### Test-controlled knobs via `uvm_config_db`
The class declares default constraints; the test pushes knobs (`min_len`, `max_len`, weights) via `uvm_config_db`, the sequence reads them in `pre_body`, and applies them via `with { … }`. Don't hand-edit the class for each scenario.

### Layered constraints (base → derived)
A base transaction class declares protocol invariants. Derived classes extend it for specific stimulus modes (`error_pkt extends pkt; constraint c_bad_crc { … }`). The factory swaps base for derived per test — no `if/else` chains in the sequencer.

### Negative testing
To deliberately violate a constraint, disable it with `constraint_mode(0)` rather than rewriting the class. The disabled-constraint set is the test's signature and shows up in coverage.

### Coverage-driven feedback
The sequencer reads coverage hole reports and biases subsequent calls — `randomize() with { addr inside {hole_set}; }`. Build this in W3+ once the covergroup is real.

## Pitfalls

| Pitfall | Symptom |
|---|---|
| Not checking `randomize()` return | Silent reuse of stale (often zero) values; "random" test stuck on one corner |
| `randc` on a wide type | Memory blow-up or simulator refusal |
| Missing `solve…before` on a narrow-gates-wide constraint | Narrow field's distribution is collapsed (e.g. boolean stuck near 0 / 1) |
| Overlapping `inside` ranges in `dist` | Implicit double-weighting; check the resulting distribution explicitly |
| Mutating `rand` fields outside `randomize()` and expecting reproducibility | Random stability broken; reseeding won't repro the bug |
| Adding a new component mid-regression | Downstream RNG streams shift; "same-seed" reruns diverge — must capture & freeze the build |
| `post_randomize` used to "fix" a violation | Means a real constraint is missing; the silent fix-up hides bugs from coverage |
| Dynamic array without size constraint | Solver resolves `.size() == 0` half the time; payload is empty |

## Worked example — the dice roller (W5 ch.15 anchor)

```systemverilog
class dice;
    rand bit [2:0] d1, d2;
    constraint c_face1 { d1 inside {[1:6]}; }
    constraint c_face2 { d2 inside {[1:6]}; }
endclass

dice roll = new();
repeat (20) begin
    if (!roll.randomize()) `uvm_fatal("RAND", "dice randomize failed")
    ap.write(roll.d1 + roll.d2);    // sum is a random variable in [2:12]
end
```

`rand` (not `randc`) is the right choice here: a dice simulator *should* repeat — that's how you build a histogram and discover the bell curve. `randc` would force every sum to be exhausted before any repeat, killing the experiment.

## Reading

- Spear *SystemVerilog for Verification* (3rd ed.) ch.6 — Randomization. Anchor reading. §6.2 (`rand`/`randc`), §6.4 (constraint blocks), §6.4.5 (implication), §6.4.6 (`solve…before`), §6.5 (`dist`), §6.7 (inline `with`), §6.8 (`pre_/post_randomize`), §6.9 (RNG functions), §6.10 (constraint tips). Page numbers vary by printing — cite the section.
- Sutherland *SystemVerilog for Design* (2nd ed.) ch.12 — randomization for design-level testbench writers; lighter than Spear.
- IEEE 1800-2017 §18 — *Constrained random value generation*. Authoritative reference for solver semantics, random stability, and `solve…before` ordering.
- Mentor Verification Academy — CRV / Constraints cookbook:
  https://verificationacademy.com/cookbook/coverage/constraint-random-stimulus
- Doulos — Random Stability white paper:
  https://www.doulos.com/knowhow/systemverilog/

## Cross-links

- `[[coverage_functional_vs_code]]` — coverage closes the loop on what CRV actually exercised.
- `[[covergroup_crosses_filters]]` — the consumer of CRV stimulus.
- `[[uvm_sequence_item]]` — UVM's `rand`-bearing transaction container.
- `[[uvm_sequences_sequencers]]` — where sequence-level `randomize() with` calls live.
- `[[factory_pattern_sv]]` — base→derived swap that pairs with layered constraints.
- `[[uvm_factory_config_db]]` — how tests inject randomization knobs without editing classes.
