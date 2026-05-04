# UVM RAL (Register Abstraction Layer)

**Category**: UVM · **Used in**: W14 (anchor), W20 (capstone) · **Type**: authored

RAL is the abstraction that lets a sequence write `regfile.CTRL.write(1)`
instead of crafting an AXI-Lite transaction by hand. It centralises
the register description, supports backdoor and frontdoor access,
keeps a shadow model of register state, and surfaces protocol-aware
sequences (`uvm_reg_hw_reset_seq`, `uvm_reg_bit_bash_seq`, etc.).

## The model hierarchy

```
uvm_reg_block          (top level — your DUT's register map)
 ├── uvm_reg            (one register)
 │    └── uvm_reg_field  (one field within a register)
 ├── uvm_reg
 └── uvm_mem            (memory regions)
```

Hand-written example (W14):

```systemverilog
class ctrl_reg extends uvm_reg;
    `uvm_object_utils(ctrl_reg)
    rand uvm_reg_field enable;
    rand uvm_reg_field mode;

    function new(string name = "ctrl_reg");
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
        enable = uvm_reg_field::type_id::create("enable");
        mode   = uvm_reg_field::type_id::create("mode");
        enable.configure(this, 1, 0,  "RW", 0, 1'b0, 1, 1, 0);
        mode  .configure(this, 2, 1,  "RW", 0, 2'b0, 1, 1, 0);
    endfunction
endclass

class my_reg_block extends uvm_reg_block;
    `uvm_object_utils(my_reg_block)
    rand ctrl_reg ctrl;
    rand stat_reg stat;
    uvm_reg_map map;

    virtual function void build();
        ctrl = ctrl_reg::type_id::create("ctrl"); ctrl.configure(this); ctrl.build();
        stat = stat_reg::type_id::create("stat"); stat.configure(this); stat.build();
        map = create_map("map", 0, 4, UVM_LITTLE_ENDIAN);
        map.add_reg(ctrl, 'h00, "RW");
        map.add_reg(stat, 'h04, "RO");
    endfunction
endclass
```

For W20 we **auto-generate** this from a YAML description via a
small Python script — that's both more realistic and a better
portfolio piece than hand-typing.

## Adapter

The model talks `uvm_reg_bus_op`; the bus driver talks
`axi_lite_seq_item`. The `uvm_reg_adapter` translates. See the SV
example in [`[[axi_lite]]`](axi_lite.md).

## Frontdoor vs backdoor

| Access | Path | Speed | Use when |
|---|---|---|---|
| **Frontdoor** | through bus driver, real protocol cycles | slow (real cycles) | reset/init sequences, real software-flow stimulus |
| **Backdoor** | direct hierarchical reference into RTL register | instant | scoreboard checks, fast init, register reset checks |

Backdoor requires `add_hdl_path` calls that name the SV path to the
register. Worth setting up for big register maps; skip for tiny W14
HW.

## Built-in sequences

UVM provides ready-made sequences that exercise registers:

- `uvm_reg_hw_reset_seq` — reset, then read every reg, expect reset value.
- `uvm_reg_bit_bash_seq` — write all-0 then all-1 to each writable bit.
- `uvm_reg_access_seq` — write/read every reg, expect what you wrote.

Run them in your test's `body()`:

```systemverilog
uvm_reg_bit_bash_seq bb_seq = uvm_reg_bit_bash_seq::type_id::create("bb");
bb_seq.model = my_env.regmodel;
bb_seq.start(null);
```

## Reading

- Rosenberg *Practical Guide to Adopting the UVM* — RAL chapter.
- UVM Cookbook RAL section — patterns and adapter examples
  (https://verificationacademy.com/cookbook/registers).
- IEEE 1800.2-2020 §18 (uvm_reg).

## Cross-links

- `[[axi_lite]]` — typical bus the adapter targets.
- `[[uvm_factory_config_db]]` — RAL model is built in the env's
  `build_phase`.
