# UVM Sequence Item / Transaction (`uvm_sequence_item`)

**Category**: UVM · **Used in**: W4+, every UVM week · **Type**: authored

A `uvm_sequence_item` is the **transaction class** — one ALU
operation, one AXI burst, one UART byte. It travels from sequence
through sequencer to driver, then back through monitor's analysis
port to scoreboard / coverage. Get this class right and the rest
of the env follows; get it wrong and every component downstream
suffers.

## Position

```
      sequence ── creates ──→ seq_item ──→ sequencer ──→ driver  (drives DUT)
                                    │
                  monitor ←── reconstructs ──── DUT (response observed)
                                    │
                                    ▼
                              ap.write(seq_item)
                                    │
                                    ▼
                           scoreboard / coverage
```

## Mandatory skeleton

```systemverilog
typedef enum {READ, WRITE} kind_e;

class my_seq_item extends uvm_sequence_item;
    `uvm_object_utils(my_seq_item)         // _object_utils — NOT _component_utils

    rand bit [31:0] addr;
    rand bit [31:0] data;
    rand kind_e     kind;

    constraint c_addr_aligned { addr[1:0] == 2'b00; }

    function new(string name = "my_seq_item");
        super.new(name);
    endfunction

    // for log readability — always implement
    function string convert2string();
        return $sformatf("kind=%s addr=%08h data=%08h",
                         kind.name(), addr, data);
    endfunction
endclass
```

## What goes where

| Override | Purpose |
|---|---|
| `new(string name = "...")` | super only — note default name argument |
| `convert2string()` | for log readability — always implement |
| `do_copy(uvm_object rhs)` | when you clone items between sequence/scoreboard |
| `do_compare(uvm_object rhs)` | when scoreboard compares actual to expected |
| `do_pack` / `do_unpack` | only if you serialise (DPI, file replay) |
| constraints | inline `constraint c_xxx { ... }` blocks for legal stimulus |

## `uvm_object_utils` vs `uvm_component_utils`

- **`uvm_object_utils`** — for transactions, sequences, config
  objects. They're created and destroyed dynamically; they don't
  live in the component tree.
- **`uvm_component_utils`** — for driver, monitor, env, test.
  They have a parent and live in the static hierarchy.

Mixing them up is the #1 factory error juniors hit. The compiler
doesn't always catch it — at runtime you see `create()` returns
null with a confusing UVM error. Burn the rule in.

## Constraints discipline

Constraints belong on the seq_item (or its child class), **never
hard-coded inside the driver**. The driver should be able to send
any legal item without knowing the test's intent.

```systemverilog
class read_only_item extends my_seq_item;
    `uvm_object_utils(read_only_item)
    constraint c_kind { kind == READ; }
endclass
```

A test then uses factory override to substitute `read_only_item`
for `my_seq_item` — driver and env stay unchanged:

```systemverilog
my_seq_item::type_id::set_type_override(read_only_item::get_type());
```

## `do_compare` for scoreboard reuse

When the scoreboard compares actual vs expected, default
`compare()` walks declared `rand`-class fields automatically *if*
you use `uvm_field_*` macros, but those macros are slow and noisy.
The senior pattern is to override `do_compare` explicitly:

```systemverilog
function bit my_seq_item::do_compare(uvm_object rhs, uvm_comparer comparer);
    my_seq_item rhs_;
    if (!$cast(rhs_, rhs)) return 0;
    return (kind == rhs_.kind) && (addr == rhs_.addr) && (data == rhs_.data);
endfunction
```

## Common gotchas

- **Using `uvm_component_utils` on a transaction** → factory
  registration goes to wrong table → `create()` returns null.
- **Forgetting the default name argument** in the constructor →
  factory `create("name")` fails to compile.
- **Mutating the seq_item after `ap.write()`** — every subscriber
  holds a reference; mutation corrupts their copy. Always create
  a fresh item per transaction.
- **Constraints on the parent class but `set_type_override` to
  child** — child constraints add to (don't replace) parent's
  unless the parent constraint is `disabled`.

## Reading

- Salemi *UVM Primer* ch.21 (UVM Transactions), pp. 143–153.
- Salemi ch.20 (Class Hierarchies and Deep Operations — `do_copy`,
  `do_compare`), pp. 135–142.
- Rosenberg & Meade ch.6 — transaction design patterns.
- IEEE 1800.2-2020 §F.3 — `uvm_sequence_item` class.

## Cross-links

- `[[uvm_sequences_sequencers]]` · `[[uvm_driver]]` · `[[uvm_monitor]]`
  · `[[uvm_factory_config_db]]` · `[[uvm_testbench_skeleton]]`
