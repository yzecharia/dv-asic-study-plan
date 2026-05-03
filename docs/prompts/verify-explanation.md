# Prompt — Verify an AI Explanation Against the Book

Use when: AI gave you an explanation of a concept, and you want to
audit it against your local book before trusting it.

---

## Template (paste into chat)

```
You are helping me audit an explanation. Here is the explanation I'm
evaluating:

[PASTE EXPLANATION HERE — could be from a previous chat,
ChatGPT, Gemini, a YouTube transcript, Wikipedia, etc.]

I have access to this book locally:

[BOOK TITLE, AUTHOR, EDITION — e.g. Spear & Tumbush "SystemVerilog for
Verification" 3rd ed]

Please:

1. List 3 specific claims in the explanation that I should
   double-check by opening the book to a specific page.
2. For each claim, name the chapter and section number where the
   topic is most likely covered (give your best guess of the page
   range; I'll verify).
3. Flag any claim where you suspect the explanation is wrong,
   oversimplified, or version-specific (e.g. UVM 1.1d vs 1.2 vs IEEE
   1800.2).
4. Suggest one follow-up question I should ask the book that the
   explanation does not answer.

Be skeptical. The point is to find errors, not to confirm the
explanation.
```

## What to do with the answer

1. Open the book to each cited chapter/section.
2. For every "verify by reading X-Y" claim — actually read it.
3. Note any genuine error in your week's `notes.md` under
   `## AI corrections`.
4. If AI was right but the book covers it more deeply, copy a
   key sentence or formula into the relevant `docs/concepts/` note.

## When this prompt is overkill

For a one-line factual lookup ("what does `solve…before` do?"), just
ask the book. This prompt is for multi-paragraph explanations where
you want a structured audit.
