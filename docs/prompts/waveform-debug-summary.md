# Prompt — Waveform / Debug Summary

Use when: you've spent time debugging, you understand the bug, and
you want help articulating it for `verification_report.md` or for a
future interview answer.

---

## Template (paste into chat)

```
Help me articulate a debug observation clearly. Here are the facts:

Setup:
- DUT: [E.G. ASYNC FIFO, 8x32, GRAY-CODE POINTERS]
- Testbench: [E.G. SV CLASS-BASED TB WITH TWO INDEPENDENT CLOCK
   GENERATORS AT 100 MHZ AND 33 MHZ]
- Clocks: [LIST ALL CLOCKS AND THEIR PERIODS]

What I expected:
[1-2 SENTENCES — THE GOLDEN BEHAVIOUR]

What I observed (waveform):
- Time T1 = ...: [SIGNAL X went 0→1]
- Time T2 = ...: [SIGNAL Y did NOT respond as expected]
- Time T3 = ...: [SIGNAL Z transitioned ahead of clock edge by 200ps]

Hypothesis I'm testing:
[YOUR CURRENT BEST EXPLANATION — could be wrong, that's fine]

What I want from you:

1. Restate the observation in one short paragraph that a senior would
   put in a verification report — terse, technically precise, no
   speculation beyond what the waveform shows.
2. Suggest 2 alternative hypotheses for the root cause that I should
   rule out before committing to mine.
3. For each alternative hypothesis, name one signal I should add to
   the waveform OR one assertion I should add to the TB to
   distinguish it from my current hypothesis.
4. Suggest the one paragraph of self-critique I should add to
   verification_report.md once the bug is fixed (i.e. what does this
   bug imply about my methodology going forward).

Do not invent waveform values I didn't give you.
```

## What to do with the answer

1. Take section 1 (the restated observation) and paste it directly
   into `<week>/verification_report.md` under the bug section. Edit
   for accuracy.
2. For each alternative hypothesis (section 2), genuinely consider
   it — even if you're 90% sure of yours. Senior engineers eliminate
   alternatives, not confirm preferred answers.
3. Add the suggested signals/assertions (section 3) to the TB. They
   become permanent regression assets.
4. Keep section 4 in `notes.md` under `## Methodology lessons` so the
   self-critique compounds across weeks.

## When this prompt earns its keep

- After a >1-hour debug session where the bug was non-obvious.
- When you find a bug at the interface between two domains
  (CDC, multi-clock, multi-UVC).
- When the bug was caused by a subtle TB problem, not a DUT problem
  — these are the most embarrassing and the most worth documenting.

## When NOT to use it

- For straightforward typos (config_db field name mismatch, port
  width mismatch). Just fix and move on.
- Before you've done your own root-cause analysis. AI is for
  articulation, not investigation.
