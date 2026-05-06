# BFM Pattern (Procedural BFM via SV Interface)

**Category**: Verification · **Used in**: W4 (anchor — Salemi ch.10–13 drills), W5–W7, W11 (SPI/AXI BFMs in plain SV before UVM), W12, W14 · **Type**: authored

A **Bus Functional Model (BFM)** is an abstraction that lets test code drive and observe a DUT through **high-level transactions** (`send_op`, `read_register`, `expect_response`) instead of cycle-by-cycle pin twiddling. Salemi-style BFMs are a specific implementation: a SystemVerilog `interface` that bundles the pin signals **and** declares procedural `task`s wrapping each protocol-level operation. Test classes call those tasks; the BFM does the bus-cycle work.

## Why a BFM is the right abstraction

Without one, every tester must repeat the protocol-level dance:

```systemverilog
@(negedge clk);
A      = 8'h05;
B      = 8'h03;
op_set = ADD_OP;
start  = 1'b1;
do @(negedge clk); while (done == 1'b0);
start  = 1'b0;
result_value = result;
```

Bury that pattern in the BFM and the tester becomes:

```systemverilog
bfm.send_op(8'h05, 8'h03, ADD_OP, result_value);
```

The bus protocol stays in one file. Every change to timing (skew, handshake protocol, reset polarity) updates one place — every test inherits the fix automatically.

## Skeleton (Salemi tinyalu shape)

```systemverilog
interface tinyalu_bfm;
    import oo_tb_pkg::*;

    bit            clk;
    bit            reset_n;
    byte unsigned  A, B;
    operation_t    op_set;
    wire [2:0]     op;
    bit            start;
    wire           done;
    wire [15:0]    result;

    assign op = op_set;

    initial begin
        clk = 1'b0;
        forever #10 clk = ~clk;
    end

    task reset_alu();
        reset_n = 1'b0;
        start   = 1'b0;
        @(negedge clk);
        @(negedge clk);
        reset_n = 1'b1;
    endtask : reset_alu

    task send_op(input  byte unsigned iA,
                 input  byte unsigned iB,
                 input  operation_t   iop,
                 output shortint      alu_result);
        @(negedge clk);
        A = iA; B = iB; op_set = iop;
        start = 1'b1;
        do @(negedge clk); while (done == 1'b0);
        start = 1'b0;
        alu_result = result;
    endtask : send_op
endinterface : tinyalu_bfm
```

## Anatomy

| Section | What lives here |
|---|---|
| Pin signals | `logic` / `wire` / `bit` declarations matching the DUT's port list |
| Clock generator | A single `initial` block driving `clk` (Salemi convention; some shops put it in the top) |
| Procedural tasks | `reset_alu()`, `send_op(...)`, `read_register(...)` — one per protocol-level operation |
| Observation tasks (optional) | `wait_for_response(...)` — used by passive monitors, mirror image of `send_op` |

## How a test class accesses the BFM

In Salemi-OO style (no UVM yet):

```systemverilog
class tester;
    virtual tinyalu_bfm bfm;

    function new(virtual tinyalu_bfm bfm);
        this.bfm = bfm;
    endfunction

    task execute();
        shortint r;
        bfm.reset_alu();
        bfm.send_op(8'h12, 8'h34, ADD_OP, r);
    endtask
endclass
```

The TB top instantiates the BFM, passes it to the testbench's constructor, which passes it to children. Every class that needs bus access stores a `virtual tinyalu_bfm` handle.

## BFM vs UVM driver/monitor

The BFM pattern and the UVM driver/monitor pattern solve the same problem with different tradeoffs:

| Aspect | BFM (this note) | UVM driver/monitor |
|---|---|---|
| Where bus logic lives | inside the `interface`'s `task`s | inside `uvm_driver::run_phase` |
| Stimulus source | tester class calls `bfm.send_op()` directly | sequence → sequencer → driver via TLM |
| Monitoring | tester polls or BFM provides observation tasks | dedicated `uvm_monitor` with analysis port |
| Reusability across protocols | low — BFM is monolithic | high — driver swaps via factory override |
| Verbosity | low — fewer files | high — sequence_item, sequence, sequencer, driver |
| Use when | small testbench, learning OOP, one-off bring-up | production, multiple test scenarios |

Salemi's W4 drills use the BFM style first (ch.10–13), *then* migrate to driver/monitor in ch.16+ to make the upgrade path explicit. Don't skip the BFM stage — it's how the trade-off becomes visible.

## Common gotchas

- **Driving signals at the wrong clock edge.** Drive on `negedge` (or via a `clocking` block with output skew); sample on `posedge` minus a step. Mixing the two causes races between BFM and DUT.
- **No timeout on the `do … while (done)` loop.** If the DUT hangs, the BFM hangs forever. Wrap with a `fork ... join_any` watchdog: a timer task that `$fatal`s after N cycles.
- **Putting the clock gen in two places.** Either the BFM owns `clk` or the top owns it — never both. Two `initial clk = 0; forever ...` blocks fight each other.
- **Tasks that block for an unbounded time** without telling the caller why. Always log entry/exit at high verbosity so a stuck test is visible.
- **Forgetting `virtual` on the interface handle in the test class.** `tinyalu_bfm bfm` (without `virtual`) is a static interface ref — won't compile in a class. Must be `virtual tinyalu_bfm bfm`.
- **Stuffing protocol logic into the tester** instead of the BFM — drops the abstraction. If the same `@(negedge clk); start = 1; ...` snippet appears in two test classes, lift it into a BFM task.

## Reading

- Salemi *UVM Primer* ch.10 (OO Testbench — first BFM), pp. 59–66.
- Salemi ch.11 (UVM Tests — BFM accessed via factory/config), pp. 67–75.
- Sutherland *SystemVerilog for Design* ch.10 — interfaces (BFM-style is one application).
- Verification Academy — Bus Functional Models cookbook entry: https://verificationacademy.com/cookbook/bus-functional-model

## Cross-links

- `[[interfaces_modports]]` — the underlying language feature; this note is the *pattern* applied to verification.
- `[[uvm_driver]]` · `[[uvm_monitor]]` — the UVM way of doing what a BFM does, more decoupled.
- `[[ready_valid_handshake]]` — the protocol shape `send_op` typically wraps.
- `[[testbench_top]]` — where the BFM and DUT are instantiated together.
- `[[clocking_resets]]` — for the timing-skew details inside BFM tasks.
