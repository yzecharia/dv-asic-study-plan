# STAR Stories Template

**Category**: Soft skills · **Used in**: weekly (rotated), W14/W19/W20 mocks · **Type**: authored

The STAR format is what every behavioural interview question expects
unless the interviewer says otherwise. Practise enough that you
*default* to it under pressure.

## Template

```
Situation:  Where, when. (1-2 sentences)
Task:       What YOU were asked / expected to do. ("I", not "we".)
Action:     What you did. The interviewer wants the *how* and *why*.
            (3-5 sentences. Tools, decisions, trade-offs.)
Result:     The outcome. Quantify if you can.
            (1-2 sentences. Acknowledge what didn't work too.)
```

## Worked example — UVM debug story

```
Situation: In W4 of my self-study, I built a UVM testbench for a
           TinyALU using Salemi's UVM Primer factory pattern. The
           test compiled and ran but produced no UVM_INFO output and
           exited cleanly with 0 phase objections.
Task:      Figure out why no test sequence was actually running.
Action:    I added a UVM_INFO at start_of_simulation_phase to confirm
           the env was constructed. It wasn't — the uvm_config_db
           lookup in my env's build_phase had a typo in the field
           path ("alu_seq_cfg" vs "alu_seq_config"). I used
           uvm_config_db::dump() to print the actual config DB
           contents and saw the mismatch. Fixed the path, then added
           a self-check assertion that fails if the config retrieval
           returns 0.
Result:    The test ran end-to-end. The bigger lesson — that
           uvm_config_db lookups fail silently — got a permanent
           guard in my env builder. I now wrap every config_db get
           with `if (!uvm_config_db::get(...))
           uvm_fatal(...)`, and that pattern is now in my
           cheatsheets/salemi_uvm_ch9-13.sv reference.
```

## Story bank to draft (8 stories by W20)

See `docs/POWER_SKILLS.md` §1 for the full list. For each story,
write three versions:

- **30-second** version: Situation + Task + Action + Result, no
  detail.
- **2-minute** version (default): full STAR, technical depth.
- **5-minute** version: includes alternatives considered, what
  didn't work, what you'd do differently.

## Anti-patterns to avoid

- **"We" instead of "I"**. The interviewer wants to know what *you*
  did. If you must talk about a team, isolate your contribution.
- **Action without Why**. "I added an assertion" → why? "I added an
  assertion because ad-hoc `if/$error` checks don't catch the
  protocol's temporal property."
- **Result without Lesson**. End on what changed in your process,
  not just "we shipped it."
- **Defensive Result**. "It worked, but the spec was unclear"
  shifts blame. Better: "It worked. I'd next time write the
  spec as an SVA bundle before any RTL."

## Reading

- Any decent interview-prep book has STAR examples; Cracking the
  Coding Interview, while CS-focused, has the right structure.
- LinkedIn Learning has 30-min courses on behavioural interviews.

## Cross-links

- `[[mock_interview_questions_rtl]]`
- `[[elevator_pitch_template]]`
- `docs/POWER_SKILLS.md` — story bank list.
