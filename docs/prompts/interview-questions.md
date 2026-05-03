# Prompt — Generate Interview Questions

Use when: you want to pressure-test what you really know after
finishing a week's material.

---

## Template (paste into chat)

```
Generate 10 interview questions a senior verification engineer might
ask a junior DV/RTL candidate on the topic below. Mix question
difficulty and type.

Topic: [E.G. UVM SEQUENCES AND SEQUENCERS]

Required mix:
- 2 conceptual ("what is X / why does X exist") — warm-up.
- 3 mechanism ("how does X work / walk me through Y") — depth.
- 2 trade-off ("when would you prefer X over Y") — judgement.
- 2 debug ("here's a symptom; what would you check first") —
  practical.
- 1 STAR-format behavioural ("tell me about a time you …") —
  bridge to my projects.

Constraints:
- Avoid trivia. Every question should be answerable in ≤ 2 minutes.
- Be specific — "explain UVM phases" is too broad; "walk through what
  happens between build_phase and run_phase, including connect_phase
  and end_of_elaboration" is good.
- Where relevant, anchor questions to: Salemi UVM Primer chapters,
  Cummings papers, Spear "SV for Verification", Harris & Harris
  RISC-V, ARM AMBA AXI.

Output: numbered list, no answers.
```

## What to do with the answer

1. **Write your own answer first** in `notes.md`, with the timer set
   to 2 minutes per question. Speak aloud or write — don't just think.
2. Only after you've answered all 10, ask AI for its suggested
   answers ("Now give a senior-engineer-quality 1-paragraph answer to
   each question.").
3. Compare — for each question, was your answer:
   - **Equivalent** ✅ — keep moving.
   - **Missing key point** 🟡 — note the gap, link to the relevant
     concept note or book chapter.
   - **Wrong** ❌ — that's the point of this exercise. Update your
     mental model. Add to `notes.md` under `## AI corrections`.

## Topic-specific tweaks

### For W14 / W19 / W20 mocks
Add: "At least 2 questions should require me to draw a diagram on
the whiteboard. Specify what the diagram should show."

### For STAR-style preparation
Add: "Make the behavioural question specifically about one of these
projects: [LIST YOUR 3-5 PORTFOLIO REPOS]. The interviewer wants to
hear *me* tell my own story."

### For company-specific prep (post-graduation)
Add: "Bias the questions toward [COMPANY NAME]'s known interview
themes — e.g. for NVIDIA expect heavy CDC + verification methodology;
for Apple Silicon expect ISA-level + low-power + interconnect."

## Don't fall into

- Asking AI to grade your answers numerically. The grade is your own
  judgement; AI grading creates a false sense of certainty.
- Memorising AI's answer phrasing. If you do, you'll sound rehearsed
  in a real interview. Use the *substance*, write your own *phrasing*.
