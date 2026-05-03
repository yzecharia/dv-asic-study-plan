# Using `study_plan_2.0` as an Obsidian Vault

The repo is structured so it doubles as an Obsidian vault. You don't
have to use Obsidian — every file is plain Markdown and works in any
viewer — but if you do, the `[[wikilinks]]` resolve and the graph view
becomes a powerful map of the curriculum.

---

## 1. Open the vault

1. Install [Obsidian](https://obsidian.md) (free).
2. Open Vault → **Open folder as vault** → pick
   `/Users/yuval/sv_projects/study_plan_2.0/`.
3. When Obsidian asks about trust, **enable community plugins** (we'll
   install a couple below).

That's it. The repo root *is* the vault root. No special config files
needed beyond what Obsidian creates in `.obsidian/` (already
`.gitignore`-friendly, but check before committing).

---

## 2. Recommended plugins

Settings → Community plugins → Browse:

| Plugin | Why |
|---|---|
| **Dataview** | Auto-tabulate progress across week files. Useful for queries like "show me all weeks where Iron Rule (c) is unchecked." |
| **Templater** | Auto-fill new week files using a template. |
| **Excalidraw** | Hand-drawn waveform/state-diagram sketches embedded as `.excalidraw.md` files. |
| **Outliner** | Tab/shift-tab to indent sub-checkboxes — handy for `checklist.md` daily breakdown. |

Optional but nice:

- **Advanced Tables** — keeps the matrix tables in `SYLLABUS_COVERAGE.md` aligned.
- **Git** — commit straight from Obsidian. Not necessary if you're at the terminal anyway.

---

## 3. Wikilink conventions used here

| Pattern | Resolves to |
|---|---|
| `[[concepts/sva_assertions]]` | `docs/concepts/sva_assertions.md` |
| `[[week_04_uvm_architecture]]` | `week_04_uvm_architecture/README.md` |
| `[[week_04_uvm_architecture/homework]]` | `week_04_uvm_architecture/homework.md` |
| `[[POWER_SKILLS#STAR]]` | `docs/POWER_SKILLS.md` heading "STAR" |
| `[[BOOKS_AND_RESOURCES]]` | `docs/BOOKS_AND_RESOURCES.md` |

Obsidian does not require leading paths if filenames are unique. To
keep links portable, **use the path-prefixed form**
(`[[concepts/<slug>]]`) — that way a renamed root file doesn't
silently break links across 20 weeks.

---

## 4. Daily-driver workflow

Each week's folder has five files designed to be opened in this order:

1. `README.md` — orient: what this week proves, prereqs, time budget.
2. `learning_assignment.md` — read the books, watch any videos, run AI
   task.
3. `homework.md` — do the exercises.
4. `checklist.md` — tick boxes as you go. End of week: confirm Iron
   Rules (a)/(b)/(c).
5. `notes.md` — jot questions, aha moments, things to ask Claude later.

In Obsidian's **Pinned tabs**, pin the four canonical docs:
`PROGRESS.md`, `BOOKS_AND_RESOURCES.md`, `INTERVIEW_PREP.md`, current
week's `README.md`. Use **Workspace** to save this layout per phase.

---

## 5. Graph view tips

- **Filter** to `path:concepts/` — see how concept notes cluster
  (combinational ↔ sequential ↔ FSM ↔ FIFO ↔ CDC ↔ UVM ↔ DSP).
- **Filter** to `path:week_` — see week→concept dependency edges.
- **Group color** by tag: `#phase1`, `#phase2`, `#phase3`, `#phase4`
  added to the top of each week's `README.md` for visual grouping.

---

## 6. Excalidraw for waveforms

When you see a confusing waveform, sketch it as an Excalidraw embed in
the relevant week's `notes.md`:

```
![[notes/wave_sketch_001.excalidraw]]
```

Excalidraw saves to `<week>/notes/`. Check in if it captures real
insight; otherwise gitignore via the per-folder `.gitignore`.

---

## 7. Dataview snippets

In `docs/PROGRESS.md` (or any dashboard you build), Dataview can
auto-list:

```dataview
TABLE WITHOUT ID
  file.link AS "Week",
  status AS "Status"
FROM "week_"
WHERE contains(file.path, "/README.md")
```

Add a `status:` YAML frontmatter to each week's `README.md` to power
this query.

---

## 8. Don't commit `.obsidian/` blindly

Obsidian writes plugin settings, workspace state, and graph layout to
`.obsidian/`. Some of that is per-machine cruft (window size, recent
files), some is portable (plugin list, hotkeys).

Recommended: add a top-level `.gitignore` rule once you've configured
plugins:

```
.obsidian/workspace*.json
.obsidian/cache
.obsidian/snippets/.unused.css
```

Keep `.obsidian/community-plugins.json` and
`.obsidian/plugins/*/data.json` if you want plugin choices to follow
the repo. Otherwise gitignore the whole `.obsidian/` folder.

---

## 9. When wikilinks break

After a rename:

```
# Find broken links from terminal
grep -rn "\\[\\[" --include="*.md" docs/ week_*/ | grep -v "\\[\\["
```

Or use Obsidian's **Outgoing links** sidebar — broken links highlight
in red. Fix in the source file, not by renaming back.

---

## 10. The minimum bar

Even without Obsidian, the repo is fully usable as plain Markdown in
VS Code. The only thing you lose is the graph view and the
auto-resolution of `[[wikilinks]]` (they'll display as raw text).

If you mainly use VS Code, install the **Markdown All in One**
extension and the **wikilinks** preview extension to get most of the
value back.
