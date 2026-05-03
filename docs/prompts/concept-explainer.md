# Prompt — Concept Explainer (Aligned to My Mental Model)

Use when: you don't understand a concept and need it explained
*against what you already know*, not from scratch.

---

## Template (paste into chat)

```
Explain a concept to me, anchored to what I already understand.

Concept I'm trying to grasp:
[E.G. UVM REGISTER ABSTRACTION LAYER (RAL)]

What I already know (don't repeat this — build on it):
- [ANALOGY OR PRIOR CONCEPT 1, E.G. "I UNDERSTAND A REGISTER FILE IN
   RTL — A BANK OF FLIPS WITH A WRITE/READ INTERFACE"]
- [ANALOGY OR PRIOR CONCEPT 2, E.G. "I UNDERSTAND OOP IN
   SYSTEMVERILOG — CLASSES, INHERITANCE, FACTORY"]
- [ANALOGY OR PRIOR CONCEPT 3, E.G. "I UNDERSTAND A UVM TESTBENCH
   ARCHITECTURE — DRIVER, MONITOR, AGENT, ENV, TEST"]

What I'm confused about:
[ONE SPECIFIC QUESTION, E.G. "WHY DOES RAL EXIST IF I CAN ALREADY
WRITE A SEQUENCE THAT POKES THE REGISTERS DIRECTLY?"]

Explain in 3 layers:

1. The 1-sentence intuition. (Bridge from what I know.)
2. The mechanism. How does it actually work? (Code patterns or
   pseudocode acceptable, but no full implementation.)
3. The trade-off. When does this mechanism win vs simpler
   alternatives? When does it lose?

Constraints:
- Don't define terms I already named in the "I know" list.
- Cite a specific book chapter or paper where the canonical
  explanation lives.
- If your explanation depends on a tool/methodology version (e.g.
  UVM 1.2 vs IEEE 1800.2), state which one.
- End with one follow-up question I should be able to answer if I
  understood your explanation.
```

## What to do with the answer

1. Read all 3 layers. Try to predict the follow-up question's answer
   without looking it up. If you can, you understood it. If you
   can't, identify which layer (1/2/3) had the gap and re-ask
   focused on that layer.
2. Add a paragraph to the relevant `docs/concepts/<slug>.md` note
   capturing the intuition and the trade-off in your own words.
   **Do not** copy the AI's wording verbatim — paraphrase.
3. Cite the book chapter the AI named in the concept note's
   "Reading" section. Verify it covers what AI claims it covers.

## When this prompt is the right tool

- When a concept feels surrounded by jargon and you can't get
  traction with the book.
- When you understand the mechanics but not the *why*.
- Right before writing a concept note — the prompt's structure
  matches the concept-note template.

## When it isn't

- When you haven't tried reading the book yet. AI is faster, but you
  retain less. Read the book first, fall back to this if stuck.
- For things you can verify by running a 5-line testbench. Just run
  the testbench.
