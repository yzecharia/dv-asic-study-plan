# UVM Reset Synchronisation in Stimulus Tasks

**Category**: UVM · **Used in**: any UVM TB driving a DUT with a real reset
· **Type**: authored

## Why this matters

UVM phases (`build → connect → end_of_elaboration → start_of_simulation
→ run`) all begin at simulation time `0`. The `run_phase` of a tester /
driver therefore starts firing at `t=0`, **the same instant the
testbench top is asserting reset**.

If the tester's first action is to drive a single-cycle handshake pulse
(`valid_in <= 1` for one clock, then `<= 0`, then wait for
`valid_out`), the entire pulse can land **inside the reset window**.
The DUT is held in its reset branch and never registers the request, so
the wait for `valid_out` blocks forever and the test hangs.

Concretely, in the W4 connector ALU TB:

```
t=0   : initial { rst_n = 0; #20 rst_n = 1; }
t=0   : run_phase starts -> @(driver_cb) waits for first posedge
t=5   : posedge clk    -> driver drives valid_in<=1, ops<=...
t=15  : posedge clk    -> driver drops valid_in<=0  (DUT still in reset)
t=20  : rst_n -> 1
t=25  : posedge clk    -> DUT exits reset, sees valid_in=0
                          (the pulse is gone, valid_out never asserts)
t=...: HANG forever on @(driver_cb iff driver_cb.valid_out)
```

## The fix

Gate the stimulus loop on reset deassertion before the first drive:

```systemverilog
task run_phase(uvm_phase phase);
    phase.raise_objection(this);
        wait (aluif.rst_n === 1'b1);   // block until reset is released
        @(aluif.driver_cb);            // align to the next clocking edge
        repeat (NUM_TXN) drive_in(...);
    phase.drop_objection(this);
endtask
```

Two pieces:

1. **`wait (rst_n === 1'b1)`** — level-sensitive. Returns immediately
   if reset is already deasserted (reusable across resume / mid-test
   re-resets), and blocks otherwise. `===` so an `X` initial value does
   not falsely satisfy the wait.
2. **`@(aluif.driver_cb)`** — re-synchronises to the clocking block so
   the first non-blocking assignment to a `driver_cb` output is timed
   against a clean clocking event, not against the asynchronous reset
   release.

## Why not just `@(posedge rst_n)`?

`@(posedge rst_n)` fires only on the 0→1 transition. If the run task is
spawned **after** the transition (e.g. a phase that starts mid-test, a
sequence relaunched after a soft reset), it waits forever for an edge
that will never come. `wait()` is idempotent on the value, so it's the
right primitive for "reset is deasserted now or eventually".

## When this rule applies

- Any UVM driver / tester that emits handshake protocols.
- Any sequence that issues its first transaction in `pre_body` /
  `body`.
- Any RAL frontdoor sequence — RAL transactions are dropped silently
  during reset.

## When it does **not** apply

- Passive monitors / scoreboards / coverage collectors. They `forever
  @(monitor_cb)` and gate on `valid_out`, which stays `0` during reset
  by construction. They do not need an explicit reset wait.
- Reset-injection sequences. Those are exactly the agents that should
  be running inside the reset window.

## Cross-reference

- Spear ch.10 §10.4 (clocking blocks and synchronisation).
- Salemi ch.13 (UVM environments — phase ordering).
- Local: `docs/concepts/clocking_resets.md` — RTL-side reset
  strategies; this note is the verification-side counterpart.
