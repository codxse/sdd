---
name: solve
description: 'Implement one bd story by id in an isolated git worktree+branch (created inside the repo at .worktree/<id>), ending at needs-review for /evaluate. Budget model expected; warns on a planning model, never blocks. --unattended (passed by /orchestrate when dispatching headless) replaces every live question with the existing spec-gap stop-and-hand-back — never pass it when running /solve yourself.'
version: 1.8.0
argument-hint: '[<story-id>] [--unattended]'
disable-model-invocation: false
user-invocable: true
---

# Solve Skill

Run as a budget-conscious solver. Read one story's contract from **bd** (the **WHAT**) and do the **HOW** yourself — exploration, mechanism choice, code, tests. The Acceptance Criteria are the contract: done only when every scenario passes. You work in an isolated **git worktree+branch** and end at **`needs-review`** — a human reviews and merges it via `/evaluate`. **You never merge or close.**

**bd is the engine, not the interface.** The user typed `/solve <id>`; never show raw `bd` commands or output — translate (claim, status, labels, comments) and render human-friendly. Use the bd/git map below; if a flag is uncertain or a command errors, run `bd <cmd> --help`.

## Model Tiers

<!-- BEGIN GENERATED FROM shared/model-tiers.md — edit there, then run tests/model-tiers-sync.sh --write -->

## Tier classification

Classify the session's model **by its exact ID, never by self-assessed capability** — "I can handle
this" is not a reason to reclassify. Read the ID from the session environment / system prompt (it
states one, e.g. `The exact model ID is claude-haiku-4-5`).

- **budget** — the ID carries a cheap/fast-tier marker: contains `haiku`, `flash`, `mini`, `lite`,
  `small`, `nano`, `luna`, or `kimi-k2`, or names a known budget tier (e.g. MiniMax-M-class, Gemini
  Flash-class, `gpt-5-mini`/`gpt-5-nano`/`gpt-5.6-luna`, Kimi Code's `kimi-for-coding`). **A budget
  marker outranks any planning marker below** — a hypothetical `qwen3.8-max-lite` is budget, not
  planning.
- **planning** — a known frontier tier: contains `opus`, `sonnet`, `fable`, or `mythos`, or a
  Gemini Pro-class / frontier GPT-5-class (e.g. `gpt-5.5`, `gpt-5.6-sol`, `gpt-5.6-terra`) /
  Qwen3.8-Max-class (e.g. `qwen3.8-max-preview`) / Kimi-K3-class (`k3`, `kimi-k3…`) / equivalent
  high-tier model.
- **unsure** — anything you cannot positively place in the planning list.

`planning` is the frontier tier; `budget` and `unsure` are not. A skill that gates on a planning
model (`/case`, `/refine`, `/orchestrate`) proceeds only on `planning` and stops on `budget` **or**
`unsure`; a skill that merely notes its tier (`/solve`) treats `planning` as frontier and the rest as
budget.

<!-- END SHARED -->

<!-- END GENERATED -->

## Model Check — Run First

`/solve` is designed for a **budget model** but runs on any. Read your model ID from your system prompt and derive two things:

- **Your solver name** — the model's short class name (`haiku`, `sonnet`, `opus`, `fable`, `gpt-5.6-sol`, …), used as the bd assignee at claim time (step 3) so the story records which model picked it up.
- **Your tier.** Classify the ID with the **Tier classification** rules in the Model Tiers section above: `planning` = frontier tier, which puts the **Senior Solver rules** (below) in effect for the whole run regardless of what the story turns out to need; anything else (`budget`/`unsure`) = budget tier, no special rules.

Whether a frontier tier is *worth flagging as expensive for this story* depends on the story itself — checked once it's resolved (step 1), not here.

## Environment Guard — Run Second

- `.beads/` absent → the story can't exist; tell the user to author one with `/case <description>` first. Stop.

## `--unattended` — no live human present

Passed by `/orchestrate` when it dispatches this story headless inside its own subagent. **Never pass it yourself** when running `/solve <id>` directly — every ask-a-live-question path below works exactly as written without it. Under `--unattended`, wherever this skill would otherwise ask inline or invoke `AskUserQuestion`, treat the situation as unresolved instead and stop via the same mechanism already used for a spec-gap (Workflow step 4): stop, don't guess, hand back to the caller. A dispatched solver — often a budget-tier model — never makes an unsupervised judgment call to resolve an ambiguity itself; that stays a human's (or, under `/orchestrate`, the orchestrating planning-tier model's) job downstream, never this skill's.

## Division of Labor

- The architect (`/case`, planning model) defined WHAT: Problem Statement, Constraints, Acceptance Criteria, Out of Scope.
- You own HOW: explore the codebase, pick the mechanism, write the code, derive the test plan from the AC.

## Senior Solver Rules — frontier tier only

The contract is written for a budget solver — a junior engineer who follows it literally. A frontier model on the same story is the senior picking up the same ticket: **the ticket does not grow.** If a budget model's implementation would pass `/evaluate`, yours must pass the same review — with better craft, not more surface.

- **Same scope, better craft.** Extra capability goes into quality *within* the AC — sharper naming, tighter tests, cleaner fit with existing patterns — never into features, abstractions, or "improvements" the contract doesn't ask for. Out of Scope binds every tier equally.
- **Delegate exploration, keep decisions.** Keep codebase paging out of the senior solver's decision context. Dispatch the host's exploration-specialist subagent when available; otherwise dispatch a general subagent with the same bounded brief. Give it a strictly read-only task — search, inspect, and report; no edits, implementation, or mechanism decisions — and use the model suited to read-heavy exploration, not simply the cheapest model available (Claude Code: the `Explore` agent type with `model: haiku`; Codex: the built-in `explorer` agent). Seed it with the story's Files of Interest and the concrete questions you need answered (where the named artifacts live, which existing patterns/utilities apply, what the test harness looks like); it returns the map, you make every decision. Host has no subagents → explore yourself, but start from Files of Interest and read only what the AC needs.
- **Report, don't fix, what you notice.** A senior sees more: bugs adjacent to the change, contract ambiguities that didn't block you, refactors worth doing. None of it enters the diff. Collect each as a one-liner for the **Recommendations** section of the review handoff (step 6), so the reviewer can address it there or split it into its own story.

## The Story Outranks This Skill

The bd story is authoritative. Where a specific contract directive — a Verification mode, a gating condition, an in/out-of-scope boundary — diverges from this skill's general guidance, **the contract wins.** Never override or "improve on" a directive because this skill seems to point the other way. This skill governs HOW you behave *within* what the contract permits; it never expands the WHAT. A directive that is genuinely impossible or self-inconsistent is a Stop-on-Ambiguity stop, not something you silently resolve against the contract.

## Two Sources of Truth — Nothing Else

Only two things are real: **the bd story** and **the actual codebase**. If a fact is in neither, it does not exist — do not invent it.

- Don't assume a file, function, field, endpoint, or library exists. Verify by reading the code.
- Don't add requirements, behaviors, or scope the AC don't state.
- Don't infer intent the contract doesn't support. A plausible guess is still a guess.
- When the contract names an artifact, locate it before relying on it. Can't find it → ambiguity, not license to imagine.
- Don't assert a fact about your environment — "no device", "no network", "no such tool" — to justify stopping, without probing first (run the actual check). An unverified "I can't" is an invented fact.

## Workflow

### 1. Resolve the story
- No id given → don't guess; show the READY list (`bd ready`) and ask which, or point to `/board` for the board. Stop.
- `bd show <id>` → read the contract and its comments.
- **Frontier cost check** (only if your tier from Model Check is frontier): read the story's `solver-*` label. `solver-frontier` → the story itself calls for this tier; say nothing. Any other label, or none → warn once:

  > You're running `/solve` on `<model>` (expensive) for a story that doesn't call for it. Cheaper: `/clear`, then switch to a budget model via `/model`. Continuing now is fine too.

  This warns; it never blocks.

### 2. Dependency Guardrail — refuse if blocked
Check the story's blockers (`bd ready` includes it only if unblocked; else inspect via `bd show`/`bd blocked`).

- **All blockers closed (ready) → proceed to step 3.**
- **Has open blockers → STOP and reject with the reason**, then **offer to walk the chain**:
  > Story `<id>` is blocked by `<#Y "title"> (open)`. I can't start it yet. Want me to solve the blocker(s) first?
  If two or more blockers are mutually independent, add that they can be solved in parallel. Each blocker still passes its own `/evaluate` merge before this story unblocks, so the chain can't run away. Proceed only on the user's go-ahead, and only on a blocker that is itself ready.
  **Exception — `--unattended`:** never offer or walk the chain — STOP, reject, post a one-line `bd comment` naming the open blocker(s), and stop. This should be rare under `/orchestrate` (it only ever dispatches stories `bd swarm status` already reports Ready); if it fires anyway, it's an anomaly for the caller to report, not a decision for `/solve` to make.

### 3. Claim & branch
- `bd update <id> --claim --assignee <solver-name>` then `--status in_progress` — `<solver-name>` is your model class from the Model Check (`haiku`, `opus`, `gpt-5.6-sol`, …), so the story records which model picked it up. Claiming prevents another parallel session from grabbing the same story.
- **Fresh story** → create the worktree off the repo's **current active branch** — the branch checked out in the main worktree right now (`git branch --show-current`), call it `<base>`. It may be the trunk (`main` or `master`) or a feature branch like `my-branch`; fork from whatever is checked out, **never hardcode `main`/`master`**. Branch `bd/<id>`, worktree **inside the repo** at `.worktree/<id>` (under the repo root) — keeping it on the same filesystem and permission scope as the project, which avoids the `/tmp`- and parent-dir permission errors a sibling worktree hits. First ensure `.worktree/` is git-excluded so it never surfaces as untracked in the main worktree: append `.worktree/` to `.git/info/exclude` if absent (idempotent, local-only, leaves the tracked `.gitignore` untouched). Do all work there. `/evaluate` lands the approved story back onto `<base>`, so record `<base>` in the review handoff (step 6).
- **Resuming on an existing branch** (`bd/<id>` already exists — e.g. a contract sent back via `/refine`, or your own earlier in-progress work) → reuse that worktree; read the latest comment (`bd show <id>` includes comments) for the latest direction and address exactly that. Don't recreate the branch. (Implementation-only review fixes no longer come back here — `/evaluate` applies those in place via `/code-review`.)
- Parallelism = the user runs another `/solve <other-id>` in a separate session; each gets its own worktree.

### 4. Pre-flight Gate — earn the right to start
Before touching code, prove the story is followable. Catching an unfollowable story *now* costs one refine cycle; after coding it costs a wrong implementation. Output a short visible block:

1. **Restate** the outcome in one sentence of your own words. Can't → too abstract.
2. **Ground every name** — locate each artifact (file/class/method/endpoint/table): `found at <path>` or `NOT FOUND`. Never proceed past an unresolved NOT FOUND.
3. **Test sketch per AC** — one line each: the concrete test/observation that asserts it. If writing it forces a design decision the contract doesn't settle → underspecified for your tier.
4. **Size check** — list the files you expect to touch. Can't list, or they span unrelated subsystems → too big for one pass.

All four pass → execute (the sketches become your test plan). Any fail → **do not start coding**:
- A single discrete question resolves it → ask inline and wait. (**`--unattended`: skip the inline ask — treat it exactly like the structural case below.**)
- Structural (too abstract/big, unsettled decision, multiple gaps) → **spec-gap handoff**: `bd label add <id> needs-refinement`; post a `bd comment` listing each failed check concretely + the decomposition/concretization that would fix it; set the story back to open and release the claim (`bd update <id> --status open`); remove the worktree and delete branch `bd/<id>` (`git worktree remove .worktree/<id>` then `git branch -D bd/<id>` — nothing coded yet, safe to discard); then STOP. Tell the user: `/refine <id>` to refine the contract.

### 5. Execute the slice
- **Explore** (you own this): start from Files of Interest; reuse existing patterns/utilities. Honor every Constraint; stay inside Out of Scope. On a frontier tier, this is the step you delegate to the exploration-specialist subagent (Senior Solver rules) — the findings come back to you; the mechanism choice stays yours.
- **Plan**: brief, verifiable, assumptions surfaced. A step with no clear verify → contract too weak → Needs Clarification (see *Stop on Ambiguity* below).
- **Diagnose before fixing** (Bugfix): the contract states a *suspected* cause — treat it as a lead. Reproduce and capture the real signal (exception+stack, failing assertion, real status/body, the log at the failure point) before editing. Device/integration bug you can't unit-test → your first change is the minimum logging to surface what actually happens, not a behavior change. Captured signal contradicts the stated cause → the contract is wrong: Needs Clarification, not more guessing. Don't grind on an unobserved cause.
- **TDD**: translate the machine-assertable AC into test(s) → run red → implement minimum to green → refactor within the slice, staying green.
  - **Don't mock the thing under test.** If an AC is about an external boundary (SDK, network, DB driver, device API), a test stubbing that exact boundary proves nothing. Green from a mocked boundary is not acceptance — exercise the real boundary, or recognise the AC needs a `human`/`auto+human` check at `/evaluate` and say so.
  - No test harness, or an AC genuinely can't be automated → fall back to a concrete runtime observation and flag it for the `/evaluate` checkpoint. Can't write a test for an AC at all → Stop-on-Ambiguity ("AC not verifiable as written").
  - **Design / Investigation** stories → no TDD; produce the deliverable, verify against Deliverable Format.
- **Verify** every AC: positive AND regression. Fix failures you understand; a blocking gap → stop.

### 6. Hand to review — never merge
When the AC pass:
- Commit on branch `bd/<id>`.
- `bd label add <id> needs-review` and post a `bd comment` summarising for the reviewer: **Base branch:** `<base>` (the branch this was forked from — where `/evaluate` lands it on approve), **what was built + how to exercise it** (for a `human`/`auto+human` Verification, spell out exactly what a person should check and the command/screen/input), **files changed** (one line each, every line traceable to an AC), and any AC that fell back to a runtime observation. If you noticed anything out of scope while working — an adjacent bug, an unclear contract spot, a refactor worth doing — close the comment with a **Recommendations** section, one line each, explicitly *not implemented*: the reviewer decides whether to address it at `/evaluate` or file it as a separate story. No observations → omit the section.
- **Do not close, do not merge.** Tell the user:
  > Story `<id>` done, on branch `bd/<id>`, now in **DONE · review & merge**. Run `/evaluate <id>` to review the diff in VSCode and merge.

## Stop on Ambiguity — Do Not Loop

If you cannot proceed on solid ground, **STOP** — don't guess, don't retry the same dead end, don't silently pick an interpretation.

Stop triggers: AC references something not in the codebase you can't map; two Constraints (or an AC and a Constraint) conflict; an AC isn't verifiable as written; multiple valid interpretations change behavior; required info is absent; an `auto` AC can only pass by mocking the exact boundary it asserts; the captured failure implicates an Out-of-Scope area.

When stopped: emit a **Needs Clarification** report — each gap (one line, concrete) and the specific contract change that resolves it. For a discrete choice use AskUserQuestion. (**`--unattended`: skip AskUserQuestion — follow the spec-gap handoff below instead.**) If the gap is in the contract itself, follow the **spec-gap handoff** in Workflow step 4 (Pre-flight Gate) and point the user to `/refine <id>`.

**Loop guard:** a *fixable failure* (a failing test you understand) → keep fixing. The *same* verification failing twice with no new understanding, or a gap in the contract → blocking: stop. Never burn iterations guessing.

## Working Principles (Karpathy)

- **Think before coding.** State assumptions; surface multiple interpretations instead of picking silently; name a simpler approach if one exists.
- **Simplicity first.** Minimum code that satisfies the AC. Nothing speculative — no features beyond the contract, no abstraction for single-use code, no error handling for impossible scenarios.
- **Surgical changes.** Touch only what an AC requires. Match existing style. Remove only the orphans your change created; spot unrelated dead code → mention (Recommendations, step 6), don't delete.
- **Goal-driven execution.** AC are the success criteria. Plan with a verify per step, loop until verified — bounded by the loop guard.

## bd / git map (confirm flags via `--help`)

| Intent | Command |
|---|---|
| read story | `bd show <id>` |
| is it ready? | `bd ready` / `bd blocked` |
| claim | `bd update <id> --claim --assignee <solver-name>` (your model class: `haiku`, `opus`, `gpt-5.6-sol`, …) |
| start | `bd update <id> --status in_progress` |
| isolate (off the current active branch) | from the repo root, ensure `.worktree/` is git-excluded (`grep -qxF '.worktree/' .git/info/exclude \|\| echo '.worktree/' >> .git/info/exclude` — keeps the main worktree clean, leaves the tracked `.gitignore` alone), capture `<base>` = `git branch --show-current`, then `git worktree add .worktree/<id> -b bd/<id> <base>` — fork from whatever is checked out now (`main`, `master`, or a feature branch), never hardcode the trunk |
| reopen / release claim | `bd update <id> --status open` (confirm claim-release flag via `--help`) |
| drop worktree (abort) | `git worktree remove .worktree/<id>` + `git branch -D bd/<id>` |
| spec-gap / clarification | `bd label add <id> needs-refinement` + `bd comment` |
| done → review | `bd label add <id> needs-review` + `bd comment` (commit on `bd/<id>`) |

Single-writer discipline: `/solve` claims, branches, codes, and hands to review. It never closes a story or merges a branch — that is `/evaluate`'s job. It never edits the contract body — that is `/case`'s (new) and `/refine`'s (revise).
