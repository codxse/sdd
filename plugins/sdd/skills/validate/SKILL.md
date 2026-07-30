---
name: validate
description: 'Human review gate for a needs-review story by id: runs a review pass at effort high via a rung-pinned reviewer subagent that applies fixes in place on bd/<id>, then enacts your verdict — approve (land it on the branch it was forked from, close, unblock dependents), another pass, or a wrong contract routed to /refine. --approve lands with no review pass; --review [effort] picks a different effort; --note <text> steers the review or annotates the story. --unattended is for /orchestrate landing onto a provisional run branch — never for a human approving straight to master/main.'
version: 1.18.1
argument-hint: '[<story-id>] [--approve [--unattended]] [--review [effort] [--unattended]] [--note <text>]'
disable-model-invocation: false
user-invocable: true
---

# Validate Skill

The human review gate. A story finished by `/solve` sits in **`needs-review`** on branch `bd/<id>`. You run a review-and-apply pass over the branch, then put its findings in front of the **human**, who decides what happens to the story — **you never judge the code yourself.** Never show raw `bd`/`git` output; translate and render human-friendly. Use the map below; if a flag is uncertain or a command errors, run `bd <cmd> --help`.

## Model Tiers

`/validate` carries no model gate — it runs on any tier — but its review pass must pin a reviewer at
**medium or better**, never budget. Read the session's model ID and use the map below to pick the
pin (step 4b.1).

<!-- BEGIN GENERATED FROM shared/model-tiers.md — edit there, then run tests/model-tiers-sync.sh --write -->

## Tier classification

Classify by **exact model ID, never self-assessed capability** — "I can handle this" is not a reason
to reclassify. Read the ID from the session environment / system prompt (it states one, e.g.
`The exact model ID is claude-haiku-4-5`). Rungs are ordered; each is defined by what the model can
hold, and the markers are how you recognize it.

| Rung | What it holds | ID markers |
|---|---|---|
| `budget` | Bounded, fully-specified work. Thin reasoning, small effective attention — drifts as ambiguity or scope grows. | `haiku` `flash` `mini` `lite` `small` `nano` `luna` `kimi-k2` `kimi-for-coding`; MiniMax-M / Gemini Flash class |
| `medium` | One real difficulty signal, contained to a single well-understood area. Larger working set; not for high-blast-radius subtlety. | `sonnet` `gpt-5.5` `gpt-5.6-terra`; Gemini Pro class |
| `frontier` | Work where being subtly wrong is expensive, or the correct approach itself takes judgment. | `opus` `fable` `mythos` `gpt-5.6-sol` `k3`; Qwen3.8-Max / Kimi-K3 class, or equivalent top tier |
| `unsure` | Anything not positively placed above. | — |

**A budget marker outranks any higher one** — `qwen3.8-max-lite` is budget, not frontier. Unsure
between medium and frontier → **medium**; for a gated skill that means stopping, which is the safe
direction: a false stop costs a line of output, a false pass costs a bad contract.

**The gate.** `/specify`, `/refine`, `/orchestrate` proceed only on `frontier` and stop on `medium`,
`budget`, **or** `unsure` — they author the WHAT, where a subtly wrong contract is paid for by every
later solve. `/solve` reports its rung and continues on any. `/board` and `/validate` are ungated.

<!-- END SHARED -->

<!-- END GENERATED -->

## Reviewer pinning by host

`/validate`'s review pass must run on a reviewer at **medium or better**, regardless of what model
`/validate` itself runs on (it carries no model gate). How the reviewer is pinned keys off what the
host can do — not an enumerated host list. Take the first branch that applies:

1. **Native host that lists the shipped reviewer agents** (the host lists
   `story-reviewer`/`story-reviewer-strong`) → use the agents; the pin lives in the definition and is
   enforced by the harness, not by this prose. Two rungs are available: **medium** is
   `story-reviewer`, **frontier** is `story-reviewer-strong`. Step 4b.1 picks between them.
2. **Else the session model classifies as `frontier` or `medium`** → one rung only: the **session's
   own model ID**. Spawn a general subagent pinned to it — the host accepts literal IDs — except on
   Kimi Code when the user has copied the reviewer `.md` files into `~/.agents/agents/` (per the
   README) and the host lists `story-reviewer`: spawn that agent instead (same reviewer prompt,
   narrowed tools) — its `model:` field is ignored by this host, so it still runs on the session
   model.
3. **Else** (budget / `unsure`, no usable native agents) → **stop** and tell the user no reviewer at
   medium or better can be pinned.

Rules that bind every branch:
- **Never pin or inherit a budget ID**, and never run the review inline on `/validate`'s own model
  instead of spawning a subagent. Nothing at medium or better to pin → stop; do not fall back to a
  budget reviewer.
- **Spawn anonymously — never pass a `name`**: named teammates can't be spawned from inside another
  agent, and nothing needs to address the reviewer after it reports.

## Environment Guard — Run First

- `.beads/` absent → tell the user to `/specify <description>` first. Stop.

## Flag dispatch — check before step 1

| Flags | Action |
|---|---|
| `--approve` | Resolve story (step 1), skip the review pass entirely, go straight to 4a (merge) |
| `--approve --unattended` | Same as `--approve`; 4a step 4's conflict gate self-resolves an "ambiguous" conflict instead of asking (see step 4a.4's `--unattended` exception) — refuses outright if `<base>` resolves to `main`/`master` |
| `--review [effort]` | Same as the default flow, at `effort` instead of `high` |
| `--review [effort] --unattended` | Same as `--review [effort]` through step 4b.2; step 4b.3's human amend-confirm is replaced by an automatic go-ahead — still shows the applied diff, just doesn't block on it. `--unattended` alone, with no `--approve`, means this |
| `--approve --note <text>` | Same as `--approve`; record `<text>` as a `bd comment` before merging |
| `--review [effort] --note <text>` | Same as `--review`; pass `<text>` to the reviewer as steering ("focus on …") **and** record it as a `bd comment` |
| neither | **Default flow**: steps 1 → 2 → 4b at effort `high` → 3 → 4a |

**The default is a review pass, not a question.** Bare `/validate <id>` reviews before it asks anything, so the human's verdict at step 3 is cast over the reviewer's findings rather than over an unread diff. `--approve` is the way to land a story with no review pass at all.

`effort` is `low`, `high`, or `max`; omit it for `high`. Whatever you get is passed through to the reviewer unchanged — don't validate or rewrite it. `--note` is orthogonal: it annotates the story on any path, and additionally steers the reviewer wherever a review pass runs. `--unattended` removes the human: under a review pass it skips the amend-confirm (step 4b.3); under `--approve` it changes step 4a.4's conflict-gate behavior (below). 4a's merge-conflict confidence gate applies in all paths — fast-pathing the verdict does not bypass conflict resolution.

Story id: use the argument if supplied. If omitted but a story was mentioned earlier in this session, use that. If still unknown, go to step 1.

### 1. Resolve the story
- No id → show the review & merge queue (`bd list` filtered to `needs-review`) and ask which. Stop.
- **Always run `bd show <id>` first** — never assume the story state from session context, memory, or prior conversation. The solver may have finished in a separate session.
- Check the **labels** in the `bd show <id>` output for `needs-review`. The bd status field (`in_progress`, `open`, etc.) is **separate from labels** — a story with status `in_progress` and label `needs-review` is normal and expected; that is exactly what `/solve` produces when it finishes. Do NOT use the bd status as a proxy for the label, and do NOT interpret `in_progress` status as "story is not done."
- If the story has no `needs-review` label → report the labels and status you actually saw and stop; nothing to validate. Do not stop based on bd status alone.

### 2. Surface the handoff, then review
- Surface the solver's review comment: **what was built, how to exercise it, files changed**, and any AC that fell back to a runtime observation or needs a `human`/`auto+human` check.
- Print where the diff lives so the human can open it in whatever tool they use — the worktree path `.worktree/<id>`, the branch `bd/<id>`, and the command `git diff <base>...bd/<id>` (`<base>` = the story's base branch, read per step 4a). Never dump the diff into the terminal, and never assume a particular editor.
- For a `human`/`auto+human` Verification story, remind the user to actually exercise the running system per the solver's instructions, not just read the diff.
- Then go to **4b** and run the review pass at effort `high` (or the `--review` effort if one was given). Don't ask permission first — the pass is the point of the command.

### 3. Ask the verdict — after the review, never before
The human decides with the reviewer's findings and applied diff already in front of them (4b.3). Ask plainly, and do not push an opinion on the code:

- **Approve & merge** → 4a.
- **Another pass** → back to 4b, optionally at a different effort or with steering.
- **The contract itself is wrong** → no reviewer can fix a wrong spec. `bd label add <id> needs-refinement` + a `bd comment` with the reason (if not already recorded via `--note`), remove `needs-review`. Tell the user: `/refine <id>` to fix the contract first, then `/solve <id>`.

### 4a. Approve → merge, close, unblock
1. If `--note <text>` was supplied, record it as a `bd comment` on the story first.
2. Resolve the **base branch** `<base>` — the branch `/solve` forked this story from, which is where it lands. Read **Base branch:** `<base>` from the solver's handoff comment (`bd show <id>`). If it isn't recorded (an older story), fall back to the branch currently checked out in the main worktree (`git -C <main-worktree> branch --show-current`). `<base>` may be the trunk (`main`/`master`) or a feature branch like `my-branch` — **never assume `main`.**
3. Land `bd/<id>` on `<base>` as **one commit, no merge commit**: make sure the main worktree is on `<base>` (`git -C <main-worktree> checkout <base>`), rebase the branch onto `<base>` first, then fast-forward it in — `git -C <main-worktree> rebase <base> bd/<id>` (or rebase inside the worktree), then `git -C <main-worktree> merge --ff-only bd/<id>`. Never a plain `git merge` / `--no-ff` — that adds a second "Merge bd/<id>" commit, which is what we're avoiding. `--ff-only` is the guardrail: if it refuses, the rebase didn't complete (resolve per the gate below), not a reason to fall back to a merge commit.
4. **Conflict while rebasing?** Apply the confidence gate:
   - **Clear & safe** — purely additive/textual, both sides' intent preserved, AND the branch's tests stay green after resolving → auto-resolve and continue the rebase. The resolution is part of the merge the user just approved; show it.
   - **Ambiguous** — both sides changed the same logic/value differently, or resolving means one story's AC must lose, or tests go red → **do not guess.** Present it decision-ready: the conflict, the two intents, the options, your recommendation. Let the human decide, then apply. (A semantic conflict often means the decomposition let two stories collide — worth flagging for `/refine`.)
   - **Exception — `--unattended`:** there is no human to present this to — apply your own recommendation from the decision-ready framing above and continue the rebase, **unless** the resolution would force the branch's tests red or make one story's AC lose to the other's. In that case do not force a landing: abort the rebase, leave the story unmerged and unlanded, and stop — this becomes a stalled story for the caller to report, never a broken merge onto the shared base every later story forks from. Either way, write the conflict, the two intents, the options, and what you did (or that you aborted, and why) as a `bd comment` — an honest record for whoever reviews the eventual PR/MR. Use only for a run landing on a provisional orchestration branch (not `master`/`main`, where a human reviews the whole run later through `/orchestrate`'s final PR/MR) — refuse `--approve --unattended` outright if `<base>` resolves to `main`/`master`; tell the caller to use interactive `--approve` instead.
5. After a clean merge: `bd close <id>` (this unblocks any dependents — recompute and report which stories are now READY), remove the `needs-review` label, and remove the worktree + delete branch `bd/<id>`.
6. Report: landed on `<base>`, closed, and the newly-unblocked stories (`/solve <id>` to pick one).
7. **Calibration** (skip under `--approve` and `--unattended` — no review pass ran, or no human is present): if the story carries a `solver-*` label, ask once whether the recommended tier matched how it actually went (e.g. "solved cleanly at budget as recommended" vs "needed more than expected"). Record the answer as a `bd comment` if given; skip silently if the human has no opinion. Never blocks or delays the merge that already happened above — this is a data point for judging the Complexity Tier rubric's accuracy over time, nothing else.

### 4b. The review pass → fix in place via the reviewer subagent
If `--note <text>` was supplied, record it as a `bd comment` now (before anything else).

The story never bounces back to `/solve`; the branch is fixed in place by delegating the review to a **medium-or-better model**:
1. **Spawn the review-and-apply as a subagent with its rung pinned — never inherit the ambient model.** `/validate` carries no model gate, so an unpinned subagent inherits whatever `/validate` happens to be running on, which may be budget — exactly the failure this step exists to prevent. Pinning is **mandatory**, not best-effort. **Reviewer pinning by host** above decides *how* to pin and names the reviewer for each rung; this step decides only *which rung*:
   - **A human is present** (no `--unattended`) → the **frontier** rung.
   - **Under `--unattended`** → the rung the story's own Complexity call asks for, read from its `solver-*` label (already in step 1's `bd show`): `solver-budget` or `solver-medium` → the **medium** rung; `solver-frontier`, or no `solver-*` label → the **frontier** rung. An orchestration run may pay for many reviews, so each one costs what its own story warrants rather than a flat top rate. **Same-rung step-up:** if the recorded assignee (the claim in `bd show`) classifies at the same rung as the reviewer this would pick, go up one rung instead — a model never reviews its own class's work. A budget assignee therefore never triggers it; a medium reviewer over a budget solver's diff is the intended cheap path, not a conflict.

   Where the host offers only one rung, every choice above collapses onto it — the rule degrades to a single pin, it never errors. The floor never moves: **medium or better, always.**
2. Hand that subagent everything the review needs and let its own definition choose the reviewing command: the story id, the worktree path (`.worktree/<id>`), the **base branch `<base>`** the story was forked from (resolved per 4a.2 — the reviewer needs it to diff `<base>...bd/<id>` and must not guess `main`), the contract — the **WHAT** + Acceptance Criteria from `bd show <id>` — as what the diff must satisfy, the effort `<effort>` (the level passed on `--review`, or `high` when none was), and any `--note <text>` as steering ("focus on …"). The reviewer prefers the marketplace's own `/code-review-quality --effort <effort> --fix true` and falls back to the host's `/code-review <effort> --fix` where that plugin isn't installed — either way it reviews the `bd/<id>` diff and applies its findings to the worktree in place, **leaving them unstaged/uncommitted.**
3. **Confirm before amend — the human reviews the reviewer's work first.** Surface what the subagent changed: its findings and the **applied diff** (the worktree changes it just made, e.g. `git -C .worktree/<id> diff`), and point again at the worktree path so they can open it in their own tool. Then ask plainly: **amend these into `bd/<id>`?** Do not amend until the human says so. If they decline → don't amend; let them edit the worktree themselves, discard, or ask for another pass. Nothing is baked into the branch without this go-ahead. **Exception — `--unattended`:** still surface the findings and applied diff (there's no human present to act on them, but the record stays honest), then proceed straight to step 4 without asking — this is the one confirm this flag exists to skip. Use it only for an orchestrated run landing on a provisional branch (not `master`/`main`) where a human reviews the whole run later through its final PR/MR (`/orchestrate`); never pass it when a human is directly approving a story to trunk.
4. On the go-ahead, back in `/validate` (any model — this step is mechanical), **amend** the branch commit on `bd/<id>` with the applied fixes. The story stays on its branch and in `needs-review`; nothing changes status and the worktree is kept.
5. Point at the amended branch and go to **step 3** for the verdict. Loop until they approve (4a) — each pass is another rung-pinned reviewer, a confirm-before-amend, and the amend.
- **Host note:** the review-and-apply command is whatever the reviewer's own definition names — `/code-review-quality` from this marketplace where it's installed, otherwise the host's own review-and-apply (`/code-review` on Claude Code, its equivalent on Codex and Kimi Code). Never fork this prose per host or per command: the behavior (a reviewer at the chosen rung, fixes applied in place and left uncommitted, then amend `bd/<id>`) is what matters, not the command name.

Either way the reason lives as a durable per-story comment, readable later via `/board <id>`.

## bd / git map (confirm flags via `--help`)

| Intent | Command |
|---|---|
| read story + review comment | `bd show <id>` |
| review queue / recompute ready | `bd list` (filter `needs-review`) / `bd ready` |
| open diff for human | `code .worktree/<id>` (or `git diff <base>...bd/<id>`) |
| resolve base branch `<base>` | read **Base branch:** from `bd show <id>`; fallback `git -C <main-worktree> branch --show-current` — never assume `main` |
| merge (linear, one commit, no merge commit) | `git -C <main-worktree> checkout <base>`, `git -C <main-worktree> rebase <base> bd/<id>`, then `git -C <main-worktree> merge --ff-only bd/<id>` — lands on `<base>` (the forked-from branch, not necessarily `main`); never plain `merge`/`--no-ff` |
| ambiguous conflict, unattended | self-resolve + `bd comment` the conflict/options/choice; red-tests-or-lost-AC → abort rebase, stall instead, `bd comment` why |
| record note / feedback | `bd comment <id> "<text>"` |
| approve | `bd close <id>` + `bd label remove <id> needs-review` |
| clean up | `git worktree remove .worktree/<id>` + `git branch -d bd/<id>` |
| request impl change | spawn a **frontier** reviewer **anonymously** per the host map in step 4b.1 (native host → `story-reviewer-strong`, or tier-keyed under `--unattended`; custom frontier host → general subagent pinned to the session's own model ID; neither → stop) → hand it id + `.worktree/<id>` + `<base>` + contract + effort (from `--review`, default `high`) + note; it runs `/code-review-quality … --fix true`, else the host's `/code-review <effort> --fix` → show applied diff + **confirm before amend (skipped under `--unattended`)** → amend `bd/<id>` (keep branch + `needs-review`) |
| show reviewer's applied diff | `git -C .worktree/<id> diff` (before staging/amend) |
| contract wrong | `bd label add <id> needs-refinement` + `bd comment` + `bd label remove <id> needs-review` |

Single-writer discipline: `/validate` is the only skill that lands a story on its base branch (the branch it was forked from) and closes it, and it never edits the contract body (`/specify` / `/refine`). It does not hand-write implementation code, but its review pass **delegates** the fix to a rung-pinned reviewer subagent, which applies it in place on `bd/<id>` — review-time fixes live on the review tier (and never below medium, regardless of what model `/validate` runs on); greenfield implementation stays `/solve`'s job.
