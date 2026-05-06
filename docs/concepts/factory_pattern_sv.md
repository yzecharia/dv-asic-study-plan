# Factory Pattern (Plain SystemVerilog)

**Category**: SystemVerilog OOP · **Used in**: W4 (anchor — Salemi ch.9 drill), W4–W7 (UVM factory built on top), W12, W14, W20 · **Type**: authored

The factory pattern decouples **what gets created** from **who creates it**. The caller asks for an object by a **runtime name** (enum or string), not by a compile-time class type. That single move — turning a class identity into data — is the foundation UVM later wraps in `` `uvm_component_utils `` and `type_id::create`. Until you've felt the plain-SV version, the UVM macros look magical; after, they look like syntactic sugar.

## Why not just call `new` directly?

Plain `new` ties the caller to a specific class at compile time:

```systemverilog
// Caller knows about every concrete shape — bad.
shape s;
case (kind)
    RECTANGLE: s = new rectangle(...);
    CIRCLE:    s = new circle(...);
endcase
```

Now imagine the caller is a test, and `kind` comes from a `+plusarg`. Every time someone adds a new `shape` subclass (`triangle`), every test has to be edited to add a new case branch. The factory pattern centralises that dispatch in **one place** — the factory class — so callers stay untouched.

## The three SV constructs that make it work

| Construct | Role |
|---|---|
| `virtual class` + `pure virtual function` | abstract base + polymorphic dispatch |
| `case` on a runtime enum | runtime dispatch into the right `new` |
| `$cast` | runtime-checked downcast (base → subclass) |

## Block diagram

```
   caller                          factory                          concrete classes
   ──────                          ───────                          ────────────────
   kind = CIRCLE   ─────►   case (kind)                ─────►   new rectangle()
                              RECTANGLE: new rectangle               new circle()
                              CIRCLE:    new circle                  new triangle()
                              ...                                         │
                                                                          │ all upcast to base
                                                                          ▼
   shape s     ◄──────────  return shape (base handle)  ◄────────────  shape
   s.draw()    → polymorphic dispatch via virtual function on the actual subclass
```

## Skeleton (illustrative — NOT a homework solution)

```systemverilog
package shape_factory_pkg;

    typedef enum {RECTANGLE, CIRCLE, TRIANGLE} shape_kind_e;

    virtual class shape;                       // abstract base
        pure virtual function void draw();
    endclass

    class rectangle extends shape;
        function void draw(); $display("[]"); endfunction
    endclass

    class circle extends shape;
        function void draw(); $display("()"); endfunction
    endclass

    class shape_factory;
        function shape create(shape_kind_e kind);
            shape s;
            case (kind)
                RECTANGLE: s = new rectangle();
                CIRCLE:    s = new circle();
                default:   $fatal(1, "unknown shape kind");
            endcase
            return s;            // implicit upcast subclass -> shape
        endfunction
    endclass

endpackage
```

Caller side:

```systemverilog
shape_factory_pkg::shape_factory f = new();
shape_factory_pkg::shape         s = f.create(shape_factory_pkg::CIRCLE);
s.draw();   // polymorphic — runs circle::draw
```

## Where `$cast` actually shows up

The skeleton above doesn't need `$cast` at the call site — `s.draw()` is virtual and dispatches polymorphically. `$cast` becomes essential when the caller wants to invoke a **subclass-specific method** that doesn't exist on the base:

```systemverilog
rectangle r;
if (!$cast(r, s))
    $fatal(1, "expected a rectangle, got %s", s.get_type_name());
r.set_width(8);   // set_width is only on rectangle
```

| Direction | Requires `$cast`? |
|---|---|
| subclass → base (upcast) | **No** — implicit, always safe |
| base → subclass (downcast) | **Yes** — runtime-checked, returns 0 on failure |

`$cast` returns 1 on success, 0 on failure. Wrapping it in `if (!$cast(...))` is the SV equivalent of C++/Java's "checked downcast" — drop the check and a wrong assignment silently corrupts state. The IEEE 1800 spec is explicit: `$cast` performs a runtime type compatibility check; the assignment only happens if the check passes.

## Why an enum, not a string?

Salemi's plain-SV factory uses an **enum** for the dispatch selector, not a string. Reasons:

- **Compile-time exhaustiveness** — `case (kind)` with an enum can be flagged when a branch is missing (Verilator `-Wall`, certain commercial tools).
- **No string-comparison overhead** in the run loop.
- **No typo class** — `RECTANGEL` is a compile error; `"Rectangel"` falls silently to `default` and you discover it at 3 a.m.

A string-keyed associative array — `factory.create("rectangle")` — is what UVM later does internally, but only because UVM must register classes from independently-compiled files. A hand-rolled plain-SV factory should stay in enum-land.

## Common gotchas

- **Forgetting `virtual` on the base method.** `s.draw()` then dispatches statically to the base's empty body, ignoring the subclass override. The factory works but polymorphism is dead and every shape draws nothing.
- **Non-pure virtual with an empty body** in the base — same trap, more subtle: the subclass override is bypassed any time the static type at the call site happens to be base. Use `pure virtual` so the compiler refuses to instantiate any subclass that didn't override.
- **`$cast` without checking the return** — `$cast(r, s)` as a bare statement silently succeeds-or-fails. Always `if (!$cast(...)) $fatal(...)`.
- **Returning the wrong handle scope.** Always store the result in a function-scope `shape s; ... return s;` — declaring a fresh handle inside each `case` branch and returning it works in SV but reads worse and trips juniors who think it leaks.

## How this maps to the UVM factory

| Plain-SV (this note) | UVM factory |
|---|---|
| hand-rolled `case` dispatch | `` `uvm_component_utils `` registers the class in a global string-keyed registry |
| enum input to `create()` | string input — usually the class name |
| `$cast` at the caller for subclass methods | same — UVM still uses `$cast`, the macros just hide the boilerplate |
| swap subclass: edit the `case` | swap subclass: `set_type_override` from a test, **zero env edits** |

The last row is the leverage. Once you've written the plain-SV version once, `set_type_override` reads as "the case statement is replaceable at runtime, from outside the factory." That's the whole show.

## Reading

- Salemi *UVM Primer* ch.9 (The Factory Pattern), pp. 53–58.
- Salemi ch.6 (Polymorphism — `virtual` methods), pp. 35–41 (prerequisite if rusty).
- IEEE 1800-2017 §8.16 — `$cast` semantics.
- Spear *SystemVerilog for Verification* (3e) ch.8 — OOP and polymorphism reference.

## Cross-links

- `[[uvm_factory_config_db]]` — the UVM factory IS this pattern, wrapped in `` `uvm_object_utils `` macros with a string-keyed registry instead of a hand-rolled `case`. The leverage point (type substitution from outside) is identical.
- `[[uvm_sequence_item]]` — registered with the UVM factory via `` `uvm_object_utils ``.
- `[[uvm_test]]` · `[[uvm_env]]` · `[[uvm_agent]]` — all rely on factory `create()` for child instantiation.
- `[[uvm_testbench_skeleton]]` — see "the seven non-negotiable boilerplate lines" for the modern UVM-side equivalent.
