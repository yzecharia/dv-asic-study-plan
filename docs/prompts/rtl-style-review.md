# Prompt — RTL Style Review

Use when: you've written RTL and want a senior-PR-review-style
critique. **Paste your own code** — never ask AI to write it.

---

## Template (paste into chat)

```
You are reviewing this SystemVerilog RTL the way a senior at NVIDIA
would review a junior's PR. Be direct, technically uncompromising,
and specific. Do NOT rewrite the code — give critique as bullet
points referencing line numbers.

Module purpose:
[ONE-LINE DESCRIPTION OF WHAT THIS BLOCK IS SUPPOSED TO DO]

Constraints:
- Target: synthesisable RTL.
- Style guide: SystemVerilog 1800-2017, `always_comb`/`always_ff`
  preferred, `logic` not `reg`/`wire`, named ends (`endmodule :
  foo`), parameterized where it makes sense.
- Reset strategy: [SYNC | ASYNC | NONE — say which].
- Clock strategy: [SINGLE | MULTI — say which].

Code:

[PASTE YOUR RTL HERE]

Critique categories I want addressed (in this order):

1. Correctness — anything that won't synthesise correctly or
   simulates differently than synthesises.
2. Reset behaviour — anything that's not deterministic on reset.
3. FSM / sequential logic — encoding choice, glitch risk, output
   registration.
4. Naming — clarity, consistency, anything ambiguous.
5. Parameterization — anything hard-coded that should be a
   parameter.
6. Lint — anything Verilator or xvlog would flag.
7. Style nits (lowest priority).

Be specific: cite line numbers. If you flag something, name the rule
or paper that justifies the critique (e.g. Cummings FSM SNUG-2003,
or "Sutherland RTL Modeling §X").

End with: a one-sentence summary of the most important change to
make.
```

## What to do with the answer

1. Read each bullet. For each, decide:
   - **Agree** → fix the code, note in `notes.md` what you learnt.
   - **Disagree** → write down why (forces you to articulate the
     trade-off you made).
   - **Not sure** → look up the cited rule/paper. Most "lint" findings
     are real; most "style nit" findings are taste.
2. Re-run lint (`verilator --lint-only -Wall`) after fixes.
3. Re-run the testbench. The TB should still pass; if not, your fix
   broke functionality.
4. If the answer included a rewritten code block, **delete it** and
   re-implement the changes yourself. The point is for you to do the
   thinking.

## Anti-pattern

DO NOT ask: "Can you rewrite this to be cleaner?" That moves the
thinking to the model. Ask only for **critique**.
