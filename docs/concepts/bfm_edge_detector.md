# BFM Rising-Edge Detector (`new_command` Pattern)

**Category**: Verification · **Used in**: W5 (anchor — Salemi ch.16 Figure 105), W7+ (any analysis-path BFM with multi-cycle holds) · **Type**: authored

When a Bus Functional Model inside an SV `interface` exposes "I saw a new transaction" events to the rest of the testbench, the naive form has a critical bug:

```systemverilog
always @(posedge clk) begin
    if (start) command_monitor_h.write_to_monitor(cmd);   // ← wrong
end
```

If `start` is held high for N cycles (the protocol contract in most handshake designs — start stays high until `done` arrives), this fires `write_to_monitor` **N times per command**. The downstream FIFO accumulates N copies; only one result arrives per command; mismatches forever.

The fix is a **one-shot latch** keyed on a falling-then-rising transition of `start`. Salemi calls it `new_command`; the pattern is universal.

## The canonical form

```systemverilog
// Declared at interface scope (NOT inside the always block — see "lifetime trap")
bit new_command;

always @(posedge clk) begin
    if (!start)
        new_command = 1'b1;          // arm while start is low
    else begin
        if (new_command) begin
            command_monitor_h.write_to_monitor(cmd);
            new_command = 1'b0;      // disarm after firing
        end
    end
end
```

Read the state machine line by line:

| `start` (this edge) | `new_command` before | Branch taken | Action | `new_command` after |
|---|---|---|---|---|
| 0 | 0 | `if (!start)` | arm | 1 |
| 0 | 1 | `if (!start)` | (already armed) | 1 |
| 1 | 1 | `else / if (new_command)` | **fire** | 0 |
| 1 | 0 | `else / if (new_command)` false | nothing | 0 |
| 0 | 0 | `if (!start)` | re-arm after deassert | 1 |

Net effect: `write_to_monitor` fires **exactly once per rising edge of `start`**, regardless of how many cycles start is held.

## Where to declare `new_command`

**Inside the always block** (Salemi shows it this way in *The UVM Primer* ch.16 Figure 105):

```systemverilog
always @(posedge clk) begin
    bit new_command;             // declared HERE
    if (!start) new_command = 1'b1;
    ...
end
```

Procedural variables in always blocks have **static lifetime by default** (per SV LRM 1800-2017 §6.21) — they persist across activations, exactly like an implicit register. So Salemi's form is correct on paper.

**BUT** — some simulators (or some `automatic`-keyword settings) treat in-block variables as automatic, which re-initializes to 0 every activation. The latch then breaks silently: `new_command` is always 0 at the top of the block; the `if (new_command)` branch never fires; `write_to_monitor` is called zero times; coverage stays at 0%.

**Defensive pattern: declare at interface scope.**

```systemverilog
interface alu_if (input logic clk, reset_n);
    ...
    bit new_command;        // module-level scope → unambiguously static
    bit new_result;

    always @(posedge clk) begin
        if (!start) new_command = 1'b1;
        ...
    end

    always @(posedge clk) begin
        if (!done) new_result = 1'b1;
        ...
    end
endinterface
```

Interface/module-level variables are static across the board — no tool-dependence, no ambiguity.

## The first-cycle trap — uninitialized trigger signals

If `start` defaults to `X` (which it does when declared as `logic`), the BFM's `if (!start)` evaluates to `!X = X` — falsy in `if` context. The arming branch never fires. The first command is missed silently.

**Fix:** initialize `start` to a defined value at time 0:

```systemverilog
interface alu_if (input logic clk, reset_n);
    ...
    logic start, done;
    initial start = 1'b0;       // forces arming branch to evaluate cleanly
endinterface
```

After this, the very first cycle's `!start` is true (because `0 → !0 = 1`), `new_command` arms, and the first rising edge of start fires `write_to_monitor`.

## Symmetric pattern for the result side

The result_monitor BFM mirrors the command form, triggering on `done` instead of `start`:

```systemverilog
always @(posedge clk) begin
    if (!done) new_result = 1'b1;
    else begin
        if (new_result) begin
            result_monitor_h.write_to_monitor(res);
            new_result = 1'b0;
        end
    end
end
```

`done` is driven by the DUT (combinational from a state register), so it typically toggles cleanly without needing explicit init — but the same `bit new_result` static-lifetime concerns apply.

## Stimulus-side companion — the tester's `start` deassertion

The edge detector requires `start` to actually return to 0 between commands. If the tester drives `start = 0` then immediately loops to `start = 1` **in the same simulation step**, both non-blocking writes schedule for the same clock edge — and the **last one wins**. `start` never goes back to 0; the BFM never sees a rising edge; nothing fires after the first command.

```systemverilog
repeat (N) begin
    aluif.cb_tb.cmd <= cmd;
    aluif.cb_tb.start <= 1'b1;
    @(aluif.cb_tb iff aluif.cb_tb.done);
    aluif.cb_tb.start <= 1'b0;
    @(aluif.cb_tb);              // ← REQUIRED: lets start=0 actually apply
end
```

The trailing `@(aluif.cb_tb);` advances one clock cycle so the `start = 0` drive applies before the next iteration's `start = 1` overwrites it. Without this wait, the BFM observes start stuck at 1 forever.

## When you also need it

This pattern shows up wherever a control signal (valid, start, request) can be held high across multiple cycles but the receiver wants to observe **once per assertion**:

- Bus monitors watching valid/ready handshakes.
- Coverage samplers triggered on protocol events.
- Logger taps that record one entry per transaction.

Variants:
- **Explicit edge via flop-and-compare:** `start_prev <= start; if (start && !start_prev) ...`. Functionally identical, two-flop instead of one-flop. More verbose but easier to read.
- **`@(posedge start)` event control:** works in tasks but not in `always @(posedge clk)` (you can only have one edge in the sensitivity list there).

For BFMs in analysis-path testbenches, the `new_command` latch form is the conventional choice.

## Reading anchor

Salemi *The UVM Primer* ch.16 Figure 105 ("Command Monitor in BFM") and Figure 106 ("Result Monitor in BFM").

Note: Salemi's version has an extra line at the end:
```
new_command = (op == 3'b000); // handle no_op
```
This is **specific to his ALU** which has a no_op opcode at value 0. The line re-arms immediately if the broadcast was a no-op (so the next real cmd can fire). If your DUT has no no_op (like Yuval's `alu_op_e` with only ADD/AND/XOR/MUL), **delete that line** — otherwise every op_add (which has opcode 0) will look like a no-op and the BFM will fire on every cycle that start is high.
