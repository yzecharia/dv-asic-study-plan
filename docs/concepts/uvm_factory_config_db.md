# UVM Factory and `uvm_config_db`

**Category**: UVM · **Used in**: W4 (anchor), W12, W14, W20 · **Type**: authored

The factory and the config database are the two mechanisms that let
UVM environments be reused across tests without rewriting them. Both
are declarative — **all the action happens at build time**.

## Factory

The factory lets a test substitute one class for another by **type**
or by **instance path**. You register a class with the factory using
`uvm_object_utils` / `uvm_component_utils`, and you create instances
with `T::type_id::create("name", parent)` instead of `new`.

Override examples:

```systemverilog
// In a test's build_phase
function void my_test::build_phase(uvm_phase phase);
    super.build_phase(phase);
    // Replace base_packet with constrained_packet anywhere in the env
    base_packet::type_id::set_type_override(constrained_packet::get_type());

    // Replace ONLY the env.agent.driver instance with a fault-injection driver
    base_driver::type_id::set_inst_override(
        fault_inj_driver::get_type(),
        "*.agent.driver",
        this
    );

    env = my_env::type_id::create("env", this);
endfunction
```

The factory pattern lets you write `base_driver` once in the env and
swap behaviour per-test without touching env code. This is the
biggest leverage UVM gives over plain class-based TBs.

## `uvm_config_db`

The config database is a hierarchical key/value store keyed by
`(scope, field_name)`. The test sets values; components retrieve them
in `build_phase`.

```systemverilog
// Test sets a virtual interface for the env's agent
uvm_config_db#(virtual alu_if)::set(this, "env.agent.*", "vif", alu_vif);

// Test sets a config object
my_seq_cfg cfg = my_seq_cfg::type_id::create("cfg");
cfg.num_txns = 1000;
uvm_config_db#(my_seq_cfg)::set(this, "env.*", "seq_cfg", cfg);
```

In a component:

```systemverilog
function void my_agent::build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual alu_if)::get(this, "", "vif", vif))
        `uvm_fatal("VIF", "vif not set in config_db")
endfunction
```

**The `uvm_fatal` guard is non-negotiable.** Without it, a missing
config_db entry returns 0 silently and your test runs with junk
state. Yuval's W4 STAR story example in `docs/POWER_SKILLS.md`
captures exactly this bug.

## Wildcard precedence

Multiple `set` calls with wildcards (`"*"`, `"*.agent.*"`, etc.) can
match the same lookup. The rule: the **most specific match wins**;
ties broken by call order (last set wins among equally-specific).

## Reading

- Salemi ch.9 (factory built from plain SV) → ch.11 (UVM macros) → ch.14
  (factory in tests).
- Rosenberg ch.4 (config DB patterns).
- IEEE 1800.2-2020 §8 (factory and config db).

## Cross-links

- `[[uvm_phases]]`
- `[[interfaces_modports]]`
- `[[uvm_sequences_sequencers]]`
