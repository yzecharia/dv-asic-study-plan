# AI Learning Guide

How to use Claude / Gemini / ChatGPT in this curriculum without
cheating yourself out of the learning.

---

## 1. The principle

**AI assists understanding; AI does not write the homework.**

The reason is selfish: a junior at NVIDIA who can't independently
debug a CDC bug or write a UVM scoreboard will fail their first
on-call. Pasting AI-generated RTL into the repo and committing it
without understanding the structure is the fastest way to graduate
this curriculum and bomb the first technical screen.

The Iron Rule corollary: AI may help you understand a chapter, may
critique your RTL, may generate flashcards — but the SystemVerilog,
testbench, and verification report you commit must be yours. (See
`CLAUDE.md` §5.)

---

## 2. The five weekly task types

Each week's `learning_assignment.md` rotates through one of these.
Pick the type that matches what's hardest about the week's content —
the rotation is a default, not a rule.

### Type 1 — Verify

Ask the AI to explain a concept. Then **check it against the book**
page-by-page. Note any place the AI got it wrong or oversimplified.

> **Why it works:** AI explanations sound confident even when they're
> subtly wrong. Forcing yourself to cross-check the book page builds
> the habit of treating AI output as a hypothesis, not an answer.

Template prompt: [`prompts/verify-explanation.md`](prompts/verify-explanation.md)

### Type 2 — Flashcards

Ask the AI to generate ~15 flashcards from a chapter. Manually correct
factual errors. Use the corrected set with Anki or paper.

> **Why it works:** Generating flashcards is tedious; correcting them
> is fast. You see what the model got wrong, which is precisely what
> *you* might also misremember.

Template prompt: [`prompts/flashcards-from-chapter.md`](prompts/flashcards-from-chapter.md)

### Type 3 — RTL style review

Paste **your own** RTL into the chat. Ask AI to critique style,
synthesisability, naming, reset strategy, FSM encoding — but **do not
ask it to rewrite**. Read the critique with skepticism.

> **Why it works:** A senior would tear apart your code in a PR
> review. AI is a competent (if generic) stand-in for that PR review
> when you're studying alone.

Template prompt: [`prompts/rtl-style-review.md`](prompts/rtl-style-review.md)

### Type 4 — Interview Qs

Ask AI to generate 10 interview questions on the week's topic.
**Write your own answers first** in `notes.md`. Only then read AI's
suggested answers and compare.

> **Why it works:** Generating questions is a low-cost way to surface
> what you don't know. Writing your own answer first ensures you
> learn from the gap, not from the model's text.

Template prompt: [`prompts/interview-questions.md`](prompts/interview-questions.md)

### Type 5 — Waveform / debug summary

After a long debug session, paste the waveform observation (signal
names, time markers, what surprised you) into chat and ask AI to
articulate what it implies. Use the answer to write the
`verification_report.md` self-critique paragraph.

> **Why it works:** Articulating bugs is a senior skill. AI helps you
> practise the verbal phrasing so by interview-time you can talk
> through a debug clearly.

Template prompt: [`prompts/waveform-debug-summary.md`](prompts/waveform-debug-summary.md)

---

## 3. Default weekly rotation

| Wk | Task type | Topic | Output goes to |
|---|---|---|---|
| 1 | Verify | OOP terminology | `notes.md` + ai-verify-log section |
| 2 | Flashcards | CRV operators (`solve…before`, `dist`, etc.) | Anki deck or printed cards |
| 3 | RTL style review | Your W3 traffic-light FSM | `notes.md` |
| 4 | Interview Qs | UVM phases, factory, `uvm_config_db` | `notes.md` |
| 5 | Waveform | TLM analysis-port broadcast trace | `verification_report.md` |
| 6 | Verify | UVM sequence vs sequencer | `notes.md` |
| 7 | RTL style review | Your async FIFO RTL | `notes.md` |
| 8 | Flashcards | RV32I instruction encodings | Anki deck |
| 9 | Interview Qs | Pipeline hazards | `notes.md` |
| 10 | Waveform | UART framing-error injection trace | `verification_report.md` |
| 11 | RTL style review | SPI master FSM | `notes.md` |
| 12 | Verify | UVM coverage closure methodology | `notes.md` |
| 13 | Interview Qs | "Walk me through your FIFO/CPU project" | `notes.md` |
| 14 | Waveform | RAL backdoor vs frontdoor access | `verification_report.md` |
| 15 | RTL style review | A synthesis-flagged RTL block | `notes.md` |
| 16 | Verify | Q-format saturation/rounding semantics | `notes.md` |
| 17 | Flashcards | FIR filter design parameters | Anki deck |
| 18 | Waveform | 2D conv edge-padding behaviour | `verification_report.md` |
| 19 | RTL style review | Your CDC handshake RTL | `notes.md` |
| 20 | Interview Qs | Capstone walkthrough — every layer | `notes.md` |

This is the default. Override per week if you have something more
urgent — but always do **one** AI task per week, and always do it
*after* you've made an honest first attempt without AI.

---

## 4. Verification rules (don't trust the AI silently)

### Rule 1 — Cite the book

If AI says "Salemi explains X in chapter 12," open the book and check
page-by-page. If it cites a page number, verify that page actually
covers X.

### Rule 2 — Be suspicious of UVM specifics

UVM versions matter. AI mixes UVM 1.1d / 1.2 / IEEE-1800.2 syntax
freely. When in doubt, check the
[Verification Academy UVM Cookbook](https://verificationacademy.com/cookbook).

### Rule 3 — Be doubly suspicious of timing/CDC claims

MTBF math, metastability propagation, gray-code distance — these are
where AI confidently invents reasoning. Cross-check against Cummings
SNUG-2008.

### Rule 4 — Save the prompt + the response

Keep a chat log per week in `<week>/ai-log/` (gitignored unless
useful). When AI is wrong and you discover it later, you'll want to
know what you originally asked.

### Rule 5 — Never paste secrets or recruiter chats into chat

Obvious but worth saying. Recruiter conversations and any company
internals stay out of model context.

---

## 5. Anti-dependence checks

Once a quarter, ask yourself:

- Could I have written this RTL without AI in the room?
- Could I explain my W4 UVM env to a senior with my notes only —
  no chat history?
- If my internet went down for a week, could I keep making progress?

If any answer is "no," dial AI back. The 30-min/week budget is a
ceiling, not a target.

---

## 6. When AI is genuinely helpful

- **Stuck on a syntax error** at 11pm — fast unblock.
- **Comparing methodology trade-offs** (atomic transactions vs
  sequence layering) — fast survey of the design space, then verify.
- **Generating boilerplate** (`uvm_component_utils` macros,
  `always_ff` skeletons) you've written 50 times — saves time.
- **Writing the elevator pitch** for your portfolio repo — phrasing
  is genuinely hard and AI often nails it.
- **Reviewing your interview answer** for clarity — it surfaces
  rambles.

When in doubt, the test is: "is the *thinking* mine, or is the
*output* mine but the thinking belongs to a model?"

---

## 7. Prompt templates

Six reusable templates in [`prompts/`](prompts/):

- [`prompts/verify-explanation.md`](prompts/verify-explanation.md)
- [`prompts/flashcards-from-chapter.md`](prompts/flashcards-from-chapter.md)
- [`prompts/rtl-style-review.md`](prompts/rtl-style-review.md)
- [`prompts/interview-questions.md`](prompts/interview-questions.md)
- [`prompts/waveform-debug-summary.md`](prompts/waveform-debug-summary.md)
- [`prompts/concept-explainer.md`](prompts/concept-explainer.md) — when
  you need a concept explained against your *current* mental model.

Copy a template, fill the bracketed slots, paste into your AI of
choice. Save the chat log if it was insightful.
