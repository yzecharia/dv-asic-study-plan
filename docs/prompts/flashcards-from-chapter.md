# Prompt — Generate Flashcards from a Chapter

Use when: you've read a chapter and want spaced-repetition cards. AI
drafts them, you correct.

---

## Template (paste into chat)

```
Generate 15 spaced-repetition flashcards from the following content.

Source: [BOOK TITLE — CHAPTER + SECTION] (e.g. "Spear ch.5 §5.2 OOP
basics in SystemVerilog")

Topic constraint: focus on facts a junior DV engineer would need to
recall in an interview, not memorisation of full code blocks. No
trivia.

Format each card as:

Q: <one-sentence question>
A: <one-sentence answer, ≤ 25 words>

Avoid:
- Yes/no questions.
- Questions whose answer is just a SystemVerilog keyword without
  context.
- Cards that test memorisation of arbitrary numerical limits (e.g.
  "max array size") — those are reference-doc lookups, not
  understanding.

Mix card types:
- 5 cards on terminology / definitions.
- 5 cards on cause/effect / mechanism (e.g. "why does X happen
  when Y").
- 5 cards on trade-offs (e.g. "when do you prefer X over Y").

Output as Markdown.
```

## What to do with the answer

1. Read each card. Mark errors:
   - Wrong fact → strike through, write correction inline.
   - Missing nuance → expand the answer.
   - Too easy → drop.
   - Too hard / niche → drop.
2. Aim for ~10 keepers per chapter. Quality over quantity.
3. Import keepers into Anki, RemNote, or paper.
4. Schedule: review next day, +3 days, +1 week, +1 month.

## Topic-specific templates

### UVM-heavy chapters
Add this constraint at the top: "Be explicit about UVM version. If
syntax changed between UVM 1.1d / 1.2 / IEEE 1800.2, say so."

### Cummings paper
Add: "Cite paper page numbers in the answer where the claim is
non-obvious."

### CDC / metastability
Add: "Include one card on MTBF reasoning (back-of-envelope numbers
acceptable)."
