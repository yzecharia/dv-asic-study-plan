# Week 5 — Notes

## Open questions

> (none yet — add as they come up while reading or coding)

## Aha moments

### `unique case` / `priority case` — case statement modifiers

A `unique` or `priority` keyword before `case` is a contract with the simulator and the synthesizer about how the case items relate to each other.

```systemverilog
case      (sel) ...   // plain — first match wins, no checks
unique case (sel) ...  // exactly one item matches (else: sim warning)
priority case (sel) ...// at least one item matches, listed order is the priority
```

**Why it matters:**
- *Simulation*: `unique` flags zero-match OR multi-match as a runtime warning — catches upstream bugs (e.g., a non-one-hot select from a broken arbiter) instead of silently picking the first match.
- *Synthesis*: tells the tool the items are mutually exclusive → builds a flat parallel mux instead of a priority encoder. Smaller, faster gates.

**When to use which:**
| Situation | Use |
|---|---|
| One-hot signals (arbiter output, decoded enum) | `unique case` |
| Items can overlap, listed order = priority | `priority case` |
| Complete enum table, you trust the input | plain `case` |
| You want fall-through with no warning | plain `case` |

**Same idea for `if`:**
```systemverilog
unique if (rst)        next = '0;
else if (load)         next = in;
else if (up || down)   next = outpm1;
```
Promises at-most-one branch is true; sim flags overlap.

**Concrete use** — saw this in the `Mux7` for Dally's UnivShCnt: the arbiter outputs a one-hot `sel`, the mux uses `unique case (sel)` so a non-one-hot value triggers a sim warning instead of corrupting state silently. Free insurance, zero hardware cost.

## AI corrections

> Track any time AI confidently said something the book contradicted.

## Methodology lessons

> One paragraph per debug session worth remembering.
