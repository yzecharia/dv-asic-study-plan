# Abstract Classes (`virtual class`) in SystemVerilog

**Category**: SystemVerilog OOP · **Used in**: W1, W4 (Salemi ch.9 factory drill anchor), W4–W7 (every UVM base class), W12, W14, W20 · **Type**: authored

A `virtual class` in SystemVerilog is an **abstract class** — a class that cannot be instantiated directly. It exists to define a contract that subclasses must implement. The keyword `virtual` is unfortunately overloaded in SV (four distinct meanings — see table below), so beginners conflate them. Sort them out early or you'll spend interview time fumbling.

## The compile-time rule

If a class contains **any** `pure virtual` method (a method declared with no body), the class itself **must** be declared `virtual class`. The compiler enforces this. The reason is contract-level: a pure virtual method says "subclasses must implement this," which is contradictory if the class itself can be instantiated.

```systemverilog
class animal;                                    // ← compile error
    pure virtual function void make_sound();      //   pure virtual not allowed in concrete class
endclass

virtual class animal;                             // ← correct
    pure virtual function void make_sound();
endclass
```

**The rule both ways:**

- A class with `pure virtual` methods → MUST be `virtual class`.
- A `virtual class` is allowed to contain `virtual`, `pure virtual`, or even plain non-virtual methods. It's just abstract regardless.

## What `virtual class` prevents

You cannot call `new` on a virtual class:

```systemverilog
virtual class animal;
    pure virtual function void make_sound();
endclass

animal a = new();      // ← compile error: cannot instantiate a virtual class
```

Instead, you instantiate **concrete subclasses** that fill in every pure virtual method. The base-class handle then holds the subclass instance and dispatches polymorphically:

```systemverilog
animal a;
a = new lion(0, "Leo");      // OK — concrete subclass
a.make_sound();              // polymorphic dispatch → lion::make_sound
```

If a subclass doesn't override every pure virtual method, **it is itself implicitly abstract** and the compiler refuses to let you `new` it either:

```systemverilog
class chicken extends animal;
    // forgot to implement make_sound() — compile error
endclass

chicken c = new();   // ← compile error: chicken still has unimplemented pure virtual
```

That early failure is the leverage. Junior bugs caught at compile time don't ship.

## The four meanings of `virtual` in SV

This is where SV trips juniors. Same keyword, four distinct uses:

| Construct | Meaning | Example |
|---|---|---|
| `virtual class` | abstract class — cannot be instantiated | `virtual class animal;` |
| `virtual function` | polymorphic — subclass *can* override; dispatch resolved at runtime | `virtual function void draw();` |
| `pure virtual function` | abstract method — subclass *must* override; no body | `pure virtual function void make_sound();` |
| `virtual <iface> vif;` | handle to a SystemVerilog `interface` (not a class at all) | `virtual alu_if vif;` |

The first three are class-related; the fourth is the unrelated "virtual interface" used to pass `interface` handles into UVM tests via `uvm_config_db`. Don't conflate them. The simple read is: look at the neighbour token. `virtual class X` is abstract-class. `virtual X vif` (where `X` is an interface name) is interface-handle.

## Pattern: abstract base + concrete subclasses

```systemverilog
virtual class shape;
    pure virtual function void   draw();
    pure virtual function string name();
    virtual function int area();         // virtual with default body
        return 0;
    endfunction
endclass

class rectangle extends shape;
    int w, h;
    function void   draw();   $display("[%0dx%0d]", w, h); endfunction
    function string name();   return "rectangle";          endfunction
    function int    area();   return w * h;                endfunction   // override default
endclass

class circle extends shape;
    int r;
    function void   draw();   $display("(r=%0d)", r);      endfunction
    function string name();   return "circle";             endfunction
    // area() inherits the default 0 — usually you'd override it; shown here for illustration
endclass
```

`shape` cannot be `new`'d. `rectangle` and `circle` can. `area()` has a default in the base, so subclasses can choose to override; `draw()` and `name()` are pure virtual, so every subclass *must* override or refuses to compile.

## Where this shows up in the curriculum

- **Salemi ch.9 factory drill (W4)** — `animal` is `virtual class`; `lion` and `chicken` are concrete.
- **Salemi ch.13 abstract base_tester (W4)** — `base_tester` is `virtual class`; `random_tester` and `add_tester` are concrete and selected via factory override.
- **Every UVM base class** — `uvm_component`, `uvm_driver`, `uvm_monitor`, `uvm_sequence_item`, `uvm_scoreboard`, etc. are all `virtual class`. You never `new` them directly; you extend them.
- **Reference models in a scoreboard** — typically a `virtual class predictor` with one pure virtual `predict(input_txn)` so each protocol's predictor must implement it.

## Common gotchas

- **Forgetting `virtual` on the base class** when adding `pure virtual` methods → compile error. (Good — fail loud.)
- **Forgetting `virtual` on a non-pure base method** → polymorphism dies silently. Subclass overrides are bypassed when the call goes through a base handle. Mark every method polymorphic from day one — there is no runtime cost in SV that warrants leaving it off.
- **Trying to instantiate a `virtual class`** → compile error; instantiate the concrete subclass instead, then assign to a base handle.
- **Confusing `virtual class` with `virtual interface`** → completely different concepts. `virtual class animal;` (abstract class) vs `virtual alu_if vif;` (handle to an interface instance).
- **Subclass that forgets one pure virtual method** → the subclass is implicitly abstract too. The error you'll see is at the first `new <subclass>()` call site, which can be far from the missing method. Read the error: it tells you which pure virtual is unimplemented.

## Reading

- Salemi *UVM Primer* ch.6 (Polymorphism — `virtual` methods, base-class handles), pp. 35–41.
- Salemi ch.9 (The Factory Pattern — uses `virtual class` for the abstract base), pp. 53–58.
- Spear *SystemVerilog for Verification* (3e) ch.8 — OOP, virtual methods, abstract classes.
- IEEE 1800-2017 §8.20 — class scope and `virtual class` semantics.
- IEEE 1800-2017 §8.21 — virtual methods, including `pure virtual`.

## Cross-links

- `[[factory_pattern_sv]]` — abstract base + concrete subclasses is the structural foundation the factory pattern dispatches across.
- `[[uvm_test]]` · `[[uvm_env]]` · `[[uvm_driver]]` · `[[uvm_monitor]]` · `[[uvm_sequence_item]]` — every UVM base class is a `virtual class`.
- `[[interfaces_modports]]` — `virtual interface` (the fourth, unrelated meaning of `virtual`).
