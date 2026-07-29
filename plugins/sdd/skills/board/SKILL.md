---
name: board
description: 'Show the bd backlog as a status board, or one story by its id. Read-only and runs on any model tier. Use when the user asks to see/list/view their stories or cases, "show the board", or "show story <id>".'
version: 1.1.0
argument-hint: '[<story-id>]'
user-invocable: true
---

# Board Skill

Render the user's **bd** (Beads) work human-friendly. **Read-only** — this skill shows; it never
authors, claims, edits, or merges. It runs on **any model tier** (no planning model needed). The
user typed `/board` / `/board <id>`, or asked to see their stories.

**bd is the engine, not the interface.** Never show raw `bd` commands or output — pull data with bd
and render as Markdown. If a flag is uncertain or a command errors, run `bd <cmd> --help`.

## Environment Guard — Run First

- `.beads/` absent in this project → there's no backlog yet. Tell the user to author a story with
  `/case <description>` first. Stop.

## No argument → the board

Render the user's work as a status board. Pull data with `bd list --json`, `bd ready --json`,
`bd blocked` and render as a Markdown table:

```
| # | Title | Status | Solver | Notes |
|---|---|---|---|---|
| 12 | <title> | READY | budget | |
| 19 | <title> | READY | frontier | |
| 8 | <title> | IN PROGRESS | medium | |
| 5 | <title> | ✅ DONE | budget | bd/5 |
| 9 | <title> | ✅ DONE | | bd/9 |
| 14 | <title> | BLOCKED | budget | waits #5 |

Epic "<name>": 3/7 done · 2 in-progress · 1 review · 1 blocked
```

- **READY** = `bd ready` (no open blockers). **IN PROGRESS** = claimed/`in_progress`. **✅ DONE** =
  label `needs-review`; Notes shows the branch `bd/<id>`. **BLOCKED** = has open blockers; Notes
  shows `waits #<blocker-id>`.
- **Solver** = the story's recommended tier (`budget`/`medium`/`frontier`) read from its `solver-*`
  label — the cost-effective call `/case` made at authoring time. Blank if unset (a story authored
  before this existed).
- If the board is empty, emit the table header row and a single body row:
  `| | (no stories yet) | | | |`.
- For each epic, one rollup line below the table: `done/total` plus a breakdown.
- Close with the next actions: `/solve <id>` to work a READY story, `/evaluate <id>` to review a
  DONE one, `/refine <id>` if a story is back for refinement.

## `<id>` → one story (detail)

Render one story: its contract (Problem Statement … Out of Scope), current state, blockers, and
**comments** — where refine notes (solver spec-gap) and reviewer feedback live. Read with
`bd show <id>`. Present it readable; no bd syntax. Close with the right next step for its state:
`/solve <id>` if READY, `/evaluate <id>` if DONE, `/refine <id>` if it carries `needs-refinement`.

## bd command map (confirm flags via `--help`)

| Intent | Command |
|---|---|
| board data | `bd list --json`, `bd ready --json`, `bd blocked` |
| show one | `bd show <id>` |

Read-only discipline: `/board` never writes to bd. Authoring is `/case` (new) and `/refine`
(revise); solving is `/solve`; merging is `/evaluate`.
