# Coverage — Functional vs Code

**Category**: UVM · **Used in**: W3 (anchor), W7, W12 · **Type**: authored

Coverage is what tells you "we have actually tested this." Three
flavours; each catches a different class of holes.

## Code coverage

What the simulator gives you for free: line, branch, toggle, FSM
state, FSM transition coverage. Tells you what RTL was *executed*.

- **Cheap to enable.**
- **Necessary but not sufficient** — 100% code coverage with no
  scoreboard means you ran code without checking it.

## Functional coverage

User-defined `covergroup` + `coverpoint` + `cross`. Tells you what
*scenarios* the test reached.

```systemverilog
covergroup cg_fifo @(posedge clk);
    cp_state:  coverpoint {empty, full} {
        bins emp_only = {2'b10};
        bins ful_only = {2'b01};
        bins neither  = {2'b00};
        illegal_bins both = {2'b11};   // both empty and full simultaneously
    }
    cp_op:     coverpoint {wr_en, rd_en} {
        bins idle      = {2'b00};
        bins write     = {2'b10};
        bins read      = {2'b01};
        bins concurrent = {2'b11};
    }
    cross_state_op: cross cp_state, cp_op;
endgroup
```

This catches "we never tested concurrent rd+wr at the empty boundary"
in a way no code-coverage tool can.

## Assertion coverage

Each `cover property` clause records how many times the property
*matched*. Pairs naturally with `assert property` to confirm the
protocol scenario actually occurred during the run.

```systemverilog
cover property (@(posedge clk) $rose(empty));   // empty was reached
cover property (@(posedge clk) $rose(full));    // full was reached
cover property (@(posedge clk) wr_en && rd_en && !empty && !full);  // mid-occupancy concurrent
```

## What each catches that the others miss

| Hole | Code | Functional | Assertion |
|---|---|---|---|
| RTL line never executed | ✅ | ❌ | ❌ |
| Two flags never co-asserted | ❌ | ✅ | ✅ |
| Specific protocol sequence (X then Y within 5 cycles) | ❌ | hard | ✅ |
| Test ran but scoreboard didn't check anything | ❌ (still 100%) | ❌ | ❌ |

## Coverage closure methodology (W12)

1. Define the functional model **before** writing tests.
2. Run the smoke + a small directed regression. Look at coverage.
3. Identify holes — bins not hit. For each, decide:
   - **Add a directed test** if the bin is interesting.
   - **Add a constraint to the random seq** if the bin is reachable
     but rare.
   - **Mark `illegal_bins`** if the bin should be unreachable.
   - **Mark `ignore_bins`** if the bin is reachable but unimportant.
4. Re-run. Loop until 100% (or 100% minus documented `ignore_bins`).

Don't just inflate coverage by adding bins until 100% with the same
tests. That's lying to yourself.

## Reading

- Spear *SV for Verification* ch.9 (coverage), pp. TBD.
- Rosenberg ch.7 (CDV in practice).

## Cross-links

- `[[sva_assertions]]` — SVA pairs with cover property.
- `[[uvm_scoreboard]]` — scoreboard updates coverage on each
  observed item.
