# SystemVerilog Packages (`package`)

**Category**: SystemVerilog · **Used in**: W4 (anchor — Salemi ch.10/11/13 drills), W5+, W12, W14, W20 · **Type**: authored

A `package` is a named scope that holds reusable types, parameters, functions, classes, and constants. It's SystemVerilog's answer to header files: instead of `` `include `` everywhere and hoping declarations don't collide, you put them in a package and `import pkg::*;` (or `pkg::name`) only where you need them. Every UVC, every test environment, every reference model in this curriculum lives inside a package.

## Minimal skeleton

```systemverilog
package alu_pkg;

    typedef enum bit [2:0] {
        ADD_OP = 3'b001,
        AND_OP = 3'b010,
        XOR_OP = 3'b011
    } operation_t;

    parameter int OP_WIDTH = 3;

    function automatic int op_to_int(operation_t op);
        return int'(op);
    endfunction

    `include "alu_driver.svh"
    `include "alu_monitor.svh"

endpackage : alu_pkg
```

## Why packages, not bare `` `include ``

Three reasons stack up:

1. **Namespacing.** Two packages can both define `data_t` without collision. Bare `` `include `` flattens everything into one global namespace and you get redefinition errors at scale.
2. **Compile-once, import-many.** A package compiles once; importers reference its elaborated symbols. `` `include `` re-parses the file each time it's pulled in.
3. **Class registration.** UVM's factory and config_db rely on classes being inside a known package so `import` resolves them.

## Importing — three styles

| Form | Effect | Use when |
|---|---|---|
| `import alu_pkg::*;` | wildcard — every name in the package becomes visible | test code, where convenience > rigour |
| `import alu_pkg::operation_t;` | selective — only the named symbols | production RTL, to avoid name pollution |
| `alu_pkg::ADD_OP` (no import) | fully-qualified reference | one-off use, or to disambiguate two packages |

A `module`, `interface`, or another `package` may declare imports at its top:

```systemverilog
module alu_top;
    import alu_pkg::*;
    operation_t op;
endmodule
```

Imports inside a `module` or `interface` do **not** propagate to instances — every consumer imports for itself.

## The `.svh` file convention

`.svh` ("SystemVerilog header") files contain class declarations and are `` `include ``'d **inside** a package — never compiled standalone. This is the *only* place an `` `include `` belongs in a class-heavy codebase:

```systemverilog
package my_pkg;
    `include "tester.svh"
    `include "scoreboard.svh"
    `include "testbench.svh"
endpackage
```

The class files themselves omit the `package`/`endpackage` wrappers — they're chunks of code spliced into the parent package. The `.svh` extension is purely a convention; the compiler doesn't care, but every reader does (it signals "include me into a package, don't compile me directly"). `.sv` files, by contrast, are top-level compilation units.

## Order matters inside a package

Symbols must be declared before they're used. If `alu_scoreboard` references `alu_seq_item`, the include order must be:

```systemverilog
`include "alu_seq_item.svh"   // first — others depend on it
`include "alu_driver.svh"
`include "alu_monitor.svh"
`include "alu_scoreboard.svh"
```

Forward references inside a single package are not generally permitted. Get the topological order right, or the package fails to compile with a confusing "undefined identifier" error far from the offending file.

## Common gotchas

- **Wildcard import in production RTL** brings in every symbol, which can shadow local names. Use selective imports for non-test code.
- **Re-importing the same package** is harmless (idempotent) — packages are compiled once.
- **Circular package dependencies** are not allowed. If `pkg_a::*` imports from `pkg_b::*` and vice versa, you have a design problem — split the shared bits into a third package both can import from.
- **Putting class instances at package scope** is illegal. A package holds *types* and *static functions*, not live objects. Object construction belongs in `initial` blocks inside modules.
- **`include` paths** — make sure the simulator's `+incdir+` flag (or equivalent) points at the directory holding the `.svh` files, or use relative paths the package file can resolve.

## Reading

- IEEE 1800-2017 §26 — package declarations and import semantics.
- Sutherland *SystemVerilog for Design* — packages chapter.
- Spear *SV for Verification* (3e) ch.5 — packages and namespacing.

## Cross-links

- `[[uvm_testbench_skeleton]]` — every UVC's package shape (`<name>_pkg.sv` containing `` `include "*.svh" ``).
- `[[interfaces_modports]]` — interfaces are NOT packages; they're a separate compilation unit type that can `import` from packages.
- `[[uvm_sequence_item]]` · `[[uvm_driver]]` · `[[uvm_monitor]]` — every UVM class lives inside a package via `.svh` include.
- `[[testbench_top]]` — the top imports the package via `import pkg::*;`.
