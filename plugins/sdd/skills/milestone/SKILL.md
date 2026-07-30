---
name: milestone
description: 'Create, show, update, or sync the local-only project milestone stored in .milestone.md. Uses a lightweight Socratic loop to clarify the outcome, then tracks done conditions, current epic, bd epic progress, and milestone work not yet represented by an epic. Use when the user asks to set a milestone, show milestone progress, change the current epic, mark an epic complete, or sync milestone state from bd.'
version: 1.2.0
argument-hint: '[--sync|<description|update>]'
disable-model-invocation: false
user-invocable: true
---

# Milestone Skill

Maintain one lightweight project milestone in `.milestone.md`. The file remembers **where the project
is going and where it is now**; it is not a story contract, an epic decomposition, a roadmap, or an
implementation plan.

This skill is deliberately independent from `/specify`. It never creates or edits stories or epics,
never writes to bd, and never changes `/specify` behavior. The user maintains milestone intent here;
`--sync` only reconciles epic existence and progress from bd into the file.

## File Location

Store `.milestone.md` in the **main checkout root**, never in a linked worktree. Resolve the root as
the first worktree entry from `git worktree list --porcelain`. If the current directory is not in a
Git repository, stop and ask the user to run the command from the project repository.

The file is **local-only project memory and must never be committed**. At the start of every mode:

1. From the resolved main root, check whether `.milestone.md` is tracked or staged with
   `git -C <main-root> ... -- .milestone.md`. If it is, stop and explain that the user must
   remove it from version control/index before this skill can preserve the local-only guarantee.
   Never untrack, unstage, delete, or rewrite it while tracked/staged.
2. Resolve the repository-local exclude file with
   `git -C <main-root> rev-parse --git-path info/exclude`. Ensure it
   contains the exact root rule `/.milestone.md`, adding it once when absent. This local git metadata
   is the only file besides `.milestone.md` this skill may modify.
3. Verify `git -C <main-root> check-ignore -- .milestone.md` succeeds after the rule exists. Failure
   stops the mode. Never add the rule to the committed `.gitignore`.

One repository has one current milestone. Do not create milestone files in subdirectories.

## Modes

### No argument: show

- `.milestone.md` exists -> read it and render the current milestone concisely: status, outcome,
  current epic, epic progress, Todo items not yet represented in bd, and remaining Done When
  conditions. Do not rewrite the file.
- `.milestone.md` absent -> say there is no current milestone and show:
  > `/milestone <description>` creates the project's current milestone.

### Description: create through a Socratic loop

Treat the description as the human's opening intent, not a finished milestone. People usually start
with a solution, a vague aspiration, or several goals mixed together. Ask until the milestone says
what meaningful state must become true, without designing how to build it.

Ask **one question at a time**, each with a recommended answer and a short reason. Ask only what can
change one of these milestone-level fields:

1. **Outcome** - who benefits, what becomes possible or materially different, and why it matters.
2. **Done When** - the few observable conditions that prove the outcome, usually 2-5.
3. **Todo** - the broad capabilities or result areas likely needed but not yet represented by bd
   epics. These are candidate epic-sized headings, not decompositions.

Push on vague words such as "ready", "better", "complete", "fast", or "production-grade" only far
enough to make the milestone observable. If the user names an implementation as the goal, ask what
user or business outcome that implementation enables.

Stop when the Outcome is concrete, Done When is observable, and the initial Todo list is sufficient
to reveal what still lacks an epic. Then show the proposed title, Outcome, Done When, and Todo and ask
for confirmation before writing `.milestone.md`.

**Do not descend into implementation detail.** Do not ask about architecture, libraries, APIs,
schemas, files, classes, story acceptance criteria, dependency edges, estimates, or task order. Those
belong to later epic/story authoring and solving. A milestone is allowed to leave the HOW unknown.

### Natural-language update: write

Treat the whole argument and the user's surrounding request as the intended change.

- No file yet -> use the Socratic creation flow above.
- Existing file -> update only what the user asked for; preserve every unmentioned field and epic.
- A new, unrelated milestone would replace an existing active one -> show the proposed replacement
  and run the Socratic loop before asking for confirmation to overwrite. Never archive or rename the
  old file on your own.
- An update is unclear -> ask one milestone-level question with a recommended answer before writing.
  Do not invent scope or epics.

Natural-language updates are the interface. Examples: "make Payments beta the current milestone",
"add epic sdd-42 Checkout", "set sdd-42 as current", "mark sdd-42 complete", and "complete this
milestone". `--sync` is the only flag; do not introduce a second state file.

### `--sync`: reconcile from bd

`--sync` must be the whole argument. It reads bd and updates `.milestone.md`; it never writes to bd.
`/orchestrate --finalize` invokes this mode once after it verifies a merged PR/MR and closes every
selected epic whose live children are complete. That does not grant `/orchestrate` write ownership:
this skill still performs the file reconciliation and title-link confirmation.

Guards:

- `.milestone.md` absent -> tell the user to create the milestone first. Stop.
- `.beads/` absent or `bd` unavailable -> report that there is no backlog to sync. Leave the file
  unchanged. Stop.

Run every bd command in read-only mode. Pull all epics with
`bd list --type epic --all --json --limit 0 --readonly`, then pull each linked epic's children with
`bd children <id> --json --readonly`. If a command shape differs on the installed bd version, inspect
its `--help`; never fall back to a write command.

Reconcile in this order:

1. **Linked Epics by id.** For every id in Epics, find that exact bd epic. Refresh its title, status,
   and child progress suffix. Count children whose stored status is `closed`; do not treat
   `needs-review` as closed. A bd-closed epic becomes checked. A bd-open epic preserves its existing
   checkbox: sync never reverses a completion the user recorded. A missing id stays unchanged and is
   reported as stale.
2. **Title-only Epics and Todo.** Compare each title-only Epic and unchecked Todo item with bd epic
   titles after trimming whitespace and case-folding, but otherwise require an exact full-title
   match. Never use fuzzy or semantic matching. No match -> leave it unchanged. Multiple matches ->
   leave it unchanged and report the ambiguity. One unique match -> report the proposed id link and
   ask the user to confirm before changing the file; title equality discovers a candidate but does
   not prove that a historical or unrelated epic belongs to this milestone. On confirmation, add the
   id/progress to a title-only Epic, or move a Todo item to Epics. If Current Epic has that same
   title-only reference, update it to the confirmed id too. A declined match stays unchanged.
3. **Current Epic.** Refresh its title when its id resolves. If that epic is now closed, set Current
   Epic to `None`; never choose the next epic automatically.
4. **Unrelated bd epics.** Ignore them. Presence in bd alone does not make an epic part of this
   milestone.

Sync only epic representation and progress. It never checks Done When, changes milestone Status,
creates Todo items, or decides that the milestone is complete. Epic completion is evidence, not the
milestone outcome itself.

Collect all unique title-match proposals and ask once which links to accept. Before writing, re-read
`.milestone.md` and compare it with the exact content initially read. If it changed while bd was being
queried or proposals were being confirmed, recompute the reconciliation once from the newest content.
Re-read immediately before that write; if it changed again, stop and report a concurrent edit rather
than overwrite it. Then rewrite `.milestone.md` once, and only when something changed. Report
refreshed epics, confirmed Todo promotions/title-only links, declined matches, stale/ambiguous
references, and how many Todo items still have no bd epic.

## File Format

Keep this exact structure and section order:

```markdown
# <Milestone title>

Status: active

## Outcome

<One short statement of what becomes true.>

## Done When

- [ ] <Observable milestone-level condition>

## Todo

- [ ] <Broad capability not yet represented by a bd epic>

## Current Epic

`<epic-id>`: <epic title>

## Epics

- [ ] `<epic-id>`: <epic title> - <closed>/<total> stories closed (<bd-status>)
```

Rules:

- `Status` is `active` or `complete`.
- Keep Outcome to one short paragraph.
- Done When contains milestone-level outcomes, not story acceptance criteria or engineering tasks.
- Todo contains broad capability/result headings that are intended for this milestone but do not yet
  have a linked bd epic. Use `None` when empty. An unchecked item still needs an epic; a checked item
  means the user intentionally completed or dropped it without one. `--sync` only matches unchecked
  items.
- Current Epic contains exactly one epic reference on one line, or `None` when no epic is current.
- Epics is `None` until the first epic is added, then a checklist. A manually added epic has no
  progress suffix until the first sync. `--sync` writes the canonical suffix
  `<closed>/<total> stories closed (<bd-status>)`. Check an epic only when the user marks it complete
  or `--sync` observes that its bd status is `closed`.
- An epic may be referenced by bd id or title alone. Use `<bd-id>: <title>` when the bd id is known
  and the title alone when it is not. Do not store another tracker's id: `--sync` treats every stored
  id as a bd id. Never fabricate an id.
- Setting an epic as current also adds it unchecked to Epics when it is not already listed. Never
  duplicate an epic. Reuse the title from Epics when the id is already listed; otherwise ask for the
  title before adding an id-only reference.
- Completing the current epic sets Current Epic to `None` unless the user names the next epic.
- Set `Status: complete` only when every Done When item is checked. If the user asks to complete the
  milestone while conditions remain unchecked, ask whether those conditions are now satisfied.
  Keep a completed file in place as the current project memory.
- On the next write or sync, add `## Todo` with `None` when reading an older `.milestone.md` that does
  not yet have the section.
- Do not add dates, owners, risks, dependencies, technical designs, story lists, or extra sections
  unless the user explicitly asks to expand the format in a later change.

## Boundaries

- `.milestone.md` is the only project-content file this skill may write. It may also idempotently add
  `/.milestone.md` to the repository-local git exclude file resolved by
  `git -C <main-root> rev-parse --git-path info/exclude`.
- Never run a bd write command or edit `.beads/`; `--sync` is strictly read-only toward bd.
- Never edit `.spec.md`, source code, tests, manifests, or documentation.
- Never invoke or alter `/specify`; the user adds an epic to the milestone through `/milestone`.
- Outside `--sync`, never infer epic completion from code or bd. Even during sync, never infer Done
  When or milestone Status from bd. The user controls milestone completion.
- Never stage, commit, push, untrack, or unstage the file. Never modify the committed `.gitignore`.

## Response

After a write, report only what changed and the file path. Include a compact progress count such as
`2/5 epics complete - 3 Todo items not yet in bd` when applicable. Do not print the whole file unless
the user asks.
