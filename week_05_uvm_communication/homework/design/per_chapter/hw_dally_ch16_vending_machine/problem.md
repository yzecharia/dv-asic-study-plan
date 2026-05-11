# Drill — Vending Machine (Dally & Harting ch.16 §16.3)

> **Reference:** Dally & Harting, *Digital Design: A Systems Approach*,
> ch.16 §16.3 — the soft-drink vending-machine case study (Figures 16.22
> through 16.26). Do **not** open
> `week_05_uvm_communication/learning/dally/VendingMachine*.sv` until
> you have a working FSM sketch of your own. That folder is the
> reference solution.

---

## 1. Spec (in your own words first)

Before writing a single line of SV, write four bullets in `notes.md`
answering:

1. What are the **inputs** the machine reacts to, and which of them
   are *pulses* (1-cycle) versus *levels* held by the outside world?
2. What are the **outputs**, and which of them must be 1-cycle pulses
   regardless of how long an external handshake takes?
3. What **internal state** must persist between cycles?
4. Where in your design does that state live — control, datapath, or
   both?

If you can't answer (4) crisply, stop and reread §16.3. The whole
point of this chapter is the control/datapath partition.

---

## 2. Functional spec

A soft-drink vending machine accepts coins, dispenses one drink when
the customer has paid at least `price` and presses `dispense`, and
returns any overpayment as nickels.

**Currency unit:** everything is counted in *nickels*. A nickel = 1, a
dime = 2, a quarter = 5. `price` is also in nickels and is a
configuration input (not a constant).

**Inputs**

| Signal     | Width  | Meaning                                         |
|------------|--------|-------------------------------------------------|
| `clk`      | 1      | clock                                            |
| `rst`      | 1      | synchronous reset, active high                   |
| `nickel`   | 1      | 1-cycle pulse: a nickel was inserted             |
| `dime`     | 1      | 1-cycle pulse: a dime was inserted               |
| `quarter`  | 1      | 1-cycle pulse: a quarter was inserted            |
| `dispense` | 1      | 1-cycle pulse: customer pressed *Dispense*       |
| `done`     | 1      | from external dispenser / coin-return mechanism: rises when the mechanical action just commanded has finished, falls when it is ready for the next command |
| `price`    | `N`    | drink price, in nickels (parametrise — do **not** hard-code 6 bits) |

**Outputs**

| Signal   | Width | Meaning                                                    |
|----------|-------|------------------------------------------------------------|
| `serve`  | 1     | **1-cycle pulse** that commands the soda dispenser to drop one can |
| `change` | 1     | **1-cycle pulse** that commands the coin return to eject one nickel |

**Behaviour**

1. After reset, the running `amount` is 0 and the machine is idle.
2. Each coin pulse (`nickel`/`dime`/`quarter`) adds its value to
   `amount`.
3. When the customer asserts `dispense`:
   - If `amount < price`, ignore the press and keep accepting coins.
   - If `amount ≥ price`, deduct `price` from `amount`, then run the
     dispense handshake, then return change.
4. **Dispense handshake.** Pulse `serve` for exactly one cycle, then
   wait for `done` to rise (the dispenser is busy) and fall again
   (the dispenser is ready) before doing anything else.
5. **Change handshake.** While `amount > 0`, pulse `change` for one
   cycle, subtract one nickel from `amount`, wait for `done` to rise
   and fall, and repeat. When `amount == 0`, return to idle.
6. While dispensing or returning change, coin and `dispense` inputs
   are ignored.

The "rise-then-fall of `done`" pattern is the same valid/ready-style
handshake you drilled in `hw_dally_ch24_handshake/` — that's why this
problem lives in week 5.

---

## 3. Interface

Top-level module (Figure 16.22). **You design the internal
partition.**

```systemverilog
module vending_machine #(
    parameter int N = 6                 // amount/price width, in bits
) (
    input  logic         clk,
    input  logic         rst,
    input  logic         nickel,
    input  logic         dime,
    input  logic         quarter,
    input  logic         dispense,
    input  logic         done,
    input  logic [N-1:0] price,
    output logic         serve,
    output logic         change
);
    // your code
endmodule
```

You **must** keep two distinct internal blocks: one combinational+
sequential **control FSM**, one **datapath** that owns the `amount`
register. The top module is wiring only — no logic of its own. If you
collapse control and datapath into one always_ff, you've missed the
chapter.

Use only synthesisable SV-2012. No `time`, no `$random` inside the
DUT, no behavioural arithmetic shortcuts that hide a mux.

---

## 4. Files to produce

```
hw_dally_ch16_vending_machine/
├── problem.md                    ← (this file)
├── vending_machine.sv            ← top wrapper (instantiates control + data)
├── vending_machine_control.sv    ← FSM
├── vending_machine_data.sv       ← datapath (owns `amount`)
└── vending_machine_tb.sv         ← gold testbench (see §5)
```

Lint-clean under:

```bash
verilator --lint-only -Wall \
    vending_machine.sv \
    vending_machine_control.sv \
    vending_machine_data.sv
```

---

## 5. Acceptance criteria (the gold testbench)

Write `vending_machine_tb.sv` so it tests, at minimum:

- [ ] **T1 — Exact change.** `price = 10`, customer inserts a dime and
      a nickel and a nickel, presses dispense.
      Expect: `serve` pulses once, `change` never pulses.
- [ ] **T2 — Overpayment.** `price = 11`, customer inserts a quarter,
      a dime, presses dispense.
      Expect: `serve` pulses once, then `change` pulses exactly **4**
      times (4 nickels = 20¢ back).
- [ ] **T3 — Premature press.** `price = 10`, customer presses
      dispense after inserting only a nickel.
      Expect: `serve` never pulses; subsequent coins still add to
      `amount`.
- [ ] **T4 — `done` stretched.** External dispenser holds `done` high
      for 5 cycles, then drops it. `serve` / `change` must still be
      1-cycle pulses and must not re-fire.
- [ ] **T5 — Back-to-back transactions.** Run T1, then immediately
      run T2, with no reset between. Both must pass.

Print a single deterministic line on success:

```
[VENDING] PASS  T1=ok T2=ok T3=ok T4=ok T5=ok
```

Capture the run to `sim/vending_machine_pass.log`:

```bash
iverilog -g2012 -o /tmp/vmsim \
    vending_machine_tb.sv \
    vending_machine.sv \
    vending_machine_control.sv \
    vending_machine_data.sv
vvp /tmp/vmsim | tee ../../../sim/vending_machine_pass.log
```

Iron-rule (a) + (b) for this drill are satisfied when:
- the three RTL files are lint-clean, and
- `sim/vending_machine_pass.log` contains the PASS line above.

---

## 6. Mentor probes (answer in `notes.md` *after* you pass)

1. Your FSM has how many states? Why not fewer? Why not more?
2. The `serve` and `change` outputs are 1-cycle pulses, but the FSM
   sits in the corresponding state for multiple cycles waiting on
   `done`. What mechanism in *your* implementation guarantees the
   pulse width is exactly one cycle? (If your answer is "I use a
   `done` edge detector," reread Dally Fig 16.24 — there is a
   simpler trick.)
3. Where does `amount` get reset to 0 *between* transactions, without
   asserting `rst`? Trace the signal path.
4. If `price` changes mid-transaction (after a `dispense` press but
   before `done`), what does your design do? What *should* it do?
5. If you had to add a "coin return without buying" button, where
   would it slot in — new state, new datapath op, or both?

---

## 7. Stretch (optional)

- **S1.** Replace the 4:1 + 3:1 one-hot muxes with conventional
  `case` statements. Does Yosys produce the same gate count?
  (`bash ../../../../run_yosys_rtl.sh vending_machine.sv` and read
  the cell report.)
- **S2.** Re-encode the FSM as one-hot. Compare Yosys area and the
  critical-path report.
- **S3.** Write an SVA property that says "every `serve` is followed
  by exactly the right number of `change` pulses before the next
  `serve` can occur." Bind it to the DUT.

---

## 8. Reading reminder

- Dally & Harting ch.16 §16.3 — vending-machine case study, Figs
  16.22 (top), 16.23–16.24 (control), 16.25 (datapath), 16.26 (TB).
- The general control/datapath split is §16.1–16.2 — skim that first
  if §16.3 feels dense.

You have everything you need. Don't open the `learning/dally/` copy
until your TB prints PASS.
