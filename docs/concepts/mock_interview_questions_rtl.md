# Mock Interview — RTL/DV Question Curation

**Category**: Soft skills · **Used in**: W14, W19, W20 (mocks) · **Type**: authored

`docs/INTERVIEW_PREP.md` is the full bank, organised by topic. This
note is the **curation strategy** — which questions to pick for
each mock, and how to run the mock itself.

## Three mocks across the curriculum

| Mock | Week | Focus | Source |
|---|---|---|---|
| 1 | W14 | UVM (RAL, factory, sequences, scoreboard) | INTERVIEW_PREP.md §6 |
| 2 | W19 | Design depth (CDC, async FIFO, timing, FSM) | INTERVIEW_PREP.md §2, §5 |
| 3 | W20 | Full portfolio walkthrough | INTERVIEW_PREP.md §11, §12 + your STAR stories |

## Question count and mix per mock

Aim for **5 questions × 8 minutes each = 40 minutes**. Mix:

- 1 conceptual ("what is X")
- 2 mechanism ("walk me through how Y works")
- 1 trade-off ("when would you prefer X over Y")
- 1 behavioural ("tell me about a time you …")

40 minutes is interview-realistic. Longer is exhausting; shorter
doesn't surface gaps.

## Self-mock procedure

If you don't have a friend to mock with:

1. Pick 5 questions from `INTERVIEW_PREP.md` matching the mock's focus.
2. Write each question on a separate card (or in a single Obsidian
   file).
3. Set a timer for 8 minutes per card.
4. Answer aloud, recording yourself with phone or QuickTime.
5. After all 5: listen back at 1.5× speed.
6. For each:
   - Where did you ramble? Cut.
   - Where did you say "uhm" or stall? Note the topic — you don't
     know it well enough.
   - Where did you give a weak answer? Open the relevant concept
     note and re-read.
7. Re-record the worst-performing question once. Compare.

Total time: ~90 minutes per mock. Schedule it on a Friday afternoon
of W14 / W19 / W20.

## With a friend / industry mentor

Better than self-mock if available. Constraints:

- Send them the question list 24h ahead so they can prepare.
- Tell them: **interrupt with follow-up questions**. The interview
  signal is in how you handle "but what if X?"
- Ask for written feedback after — specific moments where they
  thought you were weak.

## Common patterns juniors fall into (and how to avoid)

| Pattern | Antidote |
|---|---|
| Memorising one phrasing | Practise the same question with 3 different word choices. |
| Saying "I think" / "I'm not sure" repeatedly | Replace with "My understanding is X — happy to be corrected." |
| Listing without structure | Always state the structure before listing: "There are three reasons. First, …" |
| Over-explaining the easy parts | Watch the interviewer; if they nod fast, accelerate. |
| Under-explaining when stuck | Verbalise the dead-end: "I'd start by checking X. If that didn't show anything, I'd move to Y." Buys time. |

## Sample mock structure

```
Mock 1 — W14 — UVM focus (40 min)
─────────────────────────────────
[8 min]  Q1: Walk through UVM phases — build → connect → run.
[8 min]  Q2: How does the factory let a test override a driver?
[8 min]  Q3: When do you backdoor a register vs frontdoor it?
[8 min]  Q4: When would you prefer a virtual sequencer over a single sequencer?
[8 min]  Q5: STAR — tell me about a UVM bug that took >2h to find.
─────────────────────────────────
Followed by 30 min self-review (recording playback + notes update).
```

## Reading

- `docs/INTERVIEW_PREP.md` — the question bank.
- `docs/POWER_SKILLS.md` §5 — mock-interview cadence.
- `[[star_stories_template]]` — for the behavioural slot.

## Cross-links

- `[[star_stories_template]]`
- `[[elevator_pitch_template]]`
- `docs/INTERVIEW_PREP.md`
