---
name: code-review-quality
description: 'Multi-axis code review of a change before it merges — correctness, readability, architecture, security, performance — reported as severity-labelled findings and a verdict. Reviews the working diff by default; takes a commit, branch, tag, path, or PR number. --effort <low|high|max> sets depth (default high); --fix true also applies the fixes in place and leaves them uncommitted. Use when the user asks to review a change, a branch, a PR, or asks whether code is ready to merge.'
version: 1.0.0
argument-hint: '[<ref|path|#PR>] [--effort <low|high|max>] [--fix <true|false>]'
disable-model-invocation: false
user-invocable: true
---

# Code Review Quality Skill

Review a change the way a good engineer does: **approve what demonstrably improves the health of the
codebase, even when it isn't perfect.** Nothing merges on personal taste, and nothing is blocked on
personal taste either — a finding names a defect, a rule, or a measurement, or it isn't a finding.

Output is a **findings report with a verdict**. This skill does not merge, commit, push, or open a
PR. It edits files only under `--fix true`, and even then leaves the work uncommitted for the human.

## Argument dispatch — before anything else

| Argument | Meaning |
|---|---|
| none | Resolve the target with the ladder below |
| `<commit>` / `<branch>` / `<tag>` | `git diff <ref>...HEAD` — the change since that point |
| `<a>...<b>` | Exactly that range, no inference |
| `<path>` (file or dir) | Review the current content of those files, not a diff |
| `#<n>` or a PR URL | `gh pr diff <n>` plus `gh pr view <n>` for the stated intent |
| `--effort <low\|high\|max>` | Review depth. Default `high` |
| `--fix <true\|false>` | Apply the findings in place. Default `false`. Bare `--fix` means `true` |

**Default target ladder** (no argument — take the first that applies):

1. Uncommitted work exists (`git status --porcelain` non-empty) → review it: `git diff HEAD` plus
   the untracked files, named individually.
2. The current branch is ahead of the trunk → `git diff $(git merge-base HEAD <trunk>)..HEAD`, where
   `<trunk>` is the remote's default branch.
3. Otherwise → the last commit, `git show HEAD`.

State which step of the ladder you took in the header. Never review a target the caller didn't ask
for and didn't get told about.

**Another checkout.** If the caller names a worktree or repo path to review in (`.worktree/<id>`, a
sibling clone), run every git command with `-C <path>` and review *there* — never silently review the
current directory instead. A named target plus a named checkout is an instruction, not a hint.

**`--fix` is honored only when the caller typed it.** If this skill was invoked implicitly (the user
described a review in plain English rather than typing the command), the run is report-only no matter
what — offer the fix pass at the end instead of taking it.

### Effort

| Effort | Depth |
|---|---|
| `low` | The diff alone. Correctness and security axes only. No file reading beyond the hunks |
| `high` | All five axes. Read each changed file whole, plus the callers/callees the change touches. Read the tests |
| `max` | `high`, plus: trace every call site of a changed signature, run the test suite and linter if the repo makes that cheap, and review dependency and lockfile diffs package by package |

## Scope guard — run first

- Not a git repo and no path argument → say so, ask what to review, stop.
- Target resolves to an empty diff → report that there is nothing to review; don't invent a target.
- Diff exceeds ~1000 changed lines → **say it before reviewing.** A change that large can't be
  reviewed honestly in one pass. Name the split you'd make (see *Change sizing*), and ask whether to
  review it anyway or review one slice. Proceeding without saying this is the failure.

## 1. Establish what the change was supposed to do

A review with no contract is a style opinion. Before reading the implementation, get the intent from
the commit messages, the PR body, the linked issue, or the caller — and if none of those state it,
**ask what this change is supposed to accomplish**. Write the intent into the report header in one
line. Every correctness finding is measured against that line.

## 2. Read the tests before the implementation

- Is there a test for the behavior that changed? A bug fix with no regression test is a `Required`
  finding, not a nit.
- Do the tests assert the *behavior* or just re-state the implementation? A test that would pass
  against a stub asserts nothing.
- Are the edge cases covered — empty, boundary, error path, concurrent, unauthorized?
- Do the test names say what they guarantee?
- Was a test **weakened or deleted** to make the change pass? Always a `Critical` finding.

## 3. The five axes

Apply every axis at `high` and `max`; correctness and security only at `low`.

| Axis | What to look for |
|---|---|
| **Correctness** | Does it do what step 1 says? Off-by-one, boundary, null/empty, error paths that swallow, race conditions and shared mutable state, transaction boundaries, retries without idempotency, silently changed defaults |
| **Readability** | Names that say what the thing is, control flow that reads top-to-bottom, no dead code or commented-out blocks, no cleverness that needs a comment to survive, conditionals that have quietly become a state machine |
| **Architecture** | Fits the patterns already in this repo, module boundaries respected, dependency direction unchanged, duplication of something that already exists, abstraction earned by more than one caller, business logic not tangled with orchestration or I/O, types making illegal states unrepresentable at the boundary |
| **Security** | Untrusted input validated at the boundary, no secret in source or log, authorization checked on every new path (not just the happy one), parameterized queries, output encoded for its sink, path/redirect/deserialization inputs constrained, new dependency trustworthy |
| **Performance** | Query in a loop (N+1), unbounded fetch or unpaginated list, work in a hot path that could be hoisted, blocking call on the request path, allocation per element where one per batch would do, re-render or recompute on unchanged input |

**Quantify.** "This adds a query per row — 200 rows is 200 round trips, roughly 2 seconds" is a
finding. "This could be slow" is a feeling. If you can't put a number or a mechanism on it, file it
as `Consider` and say what would confirm it.

## 4. Structural remedies — name the move, not the discomfort

When the problem is shape rather than a bug, say which move fixes it:

- A chain of conditionals on a string or flag → a typed model (enum, sum type, polymorphism).
- Two branches that differ only in a value → one flow parameterized by that value.
- A function doing orchestration *and* business logic → split; the caller orchestrates, the callee decides.
- A bespoke helper next to a canonical one → delete the bespoke one, use the canonical.
- A wrapper that only forwards → delete it.
- A file that grew past what a reader can hold → decompose it **before** the feature lands in it, not after.

## 5. Change sizing and description

- ~100 changed lines is the comfortable size; up to ~300 is fine for one logical unit; past ~1000 the
  review isn't real (see the scope guard).
- Ways to split, in the order to prefer them: stacked dependent changes; separate by file group;
  layer horizontally (schema, then service, then UI); slice vertically (one narrow feature end to end).
- The change description is part of the change. First line imperative and specific ("Delete the
  unused invoice RPC", not "Fix bug" or "Phase 1"); body says why, what was considered, and what is
  knowingly left undone; links the issue or the benchmark. A vague description is a `Required`
  finding on a change that ships to a shared history.

## 6. Dependency changes

Whenever the diff touches a manifest or lockfile:

- New dependency: does the repo or the stdlib already do this? What does it add transitively? Is it
  maintained, licensed compatibly, free of known advisories?
- Upgrade: read the changelog for the version range crossed — semver is a promise, not a guarantee.
  One package per change, so a regression has one suspect.
- Lockfile: the diff is reviewed, never hand-edited. A lockfile change with no manifest change needs
  an explanation.

## 7. Severity, then report

Label every finding. Order the report by leverage — correctness and security first, taste last.

| Label | Meaning |
|---|---|
| **Critical** | Blocks the merge: data loss, security hole, breaks a documented behavior, weakened test |
| **Required** | Must change before merge, but nothing is on fire |
| **Consider** | A real improvement the author may reasonably decline |
| **Nit** | Cosmetic. Never blocks anything |
| **FYI** | Context the author should have; no action asked |

Render exactly this shape:

```
## Review — <target> · effort <effort>

**Intent:** <the one line from step 1>
**Verdict:** Request changes | Approve with comments | Approve

### Critical
- `path/file.ext:42` — <what breaks, and when> → <the move that fixes it>

### Required
- `path/file.ext:118` — <finding> → <fix>

### Consider · Nit · FYI
- ...

**Verification:** tests <green | red | not run> · build <ok | not run> · <what a human still has to exercise by hand>
```

Empty severity sections are omitted, not printed empty. If nothing was found on an axis you actually
examined, say which axes came back clean — a review that lists no findings and no coverage is
indistinguishable from no review.

**No "LGTM" without evidence.** The verdict is earned by naming what you checked.

## 8. `--fix true` → apply, leave it uncommitted

Only when the caller typed the flag. Then, after presenting the report:

1. Apply **Critical** and **Required** findings. Apply a `Consider`/`Nit` only if it is mechanical and
   you already named it in the report.
2. Fix the finding, nothing else. No opportunistic renames, no drive-by reformatting, no refactor the
   report didn't call for.
3. **Never fix by weakening the check** — not by deleting or loosening a test, widening a type to
   `any`, catching and swallowing, or disabling a lint rule. If that's the only way, leave the
   finding unfixed and say why.
4. Re-run whatever the repo makes cheap (tests, linter, type check) and report the result.
5. **Leave everything unstaged and uncommitted.** Never `git add`, `commit`, `amend`, `push`, or
   branch. Print `git diff` for the human and list what you applied, what you skipped, and why.

A finding you can't verify is a finding you don't apply. Say it stayed unfixed.

## Dead code hygiene

After a refactor, list what the change orphaned — unreferenced functions, obsolete flags, config keys
with no reader, tests for deleted behavior. **Ask before removing any of it**; a reflection-based or
cross-language caller doesn't show up in a grep. Never delete silently, not even under `--fix`.

## Rationalizations to refuse

| Claim | Reality |
|---|---|
| "It works, so it's fine" | Working is the floor, not the bar. The cost lands on the next reader |
| "We'll clean it up later" | Nothing scheduled after a merge happens. Now, or filed with an owner |
| "It's consistent with the existing code" | Fine if the existing code is healthy. Not a licence to spread a known problem |
| "Tests are hard to write here" | Usually the design's report card, not the test framework's |
| "It's just a small change" | Blast radius isn't measured in lines |
| "The reviewer didn't understand it" | Code a competent reviewer can't follow is a readability finding |

## Red flags

- A refactor that moves complexity instead of removing it.
- A bug fix with no test that would have caught the bug.
- Scattered conditionals on the same value in three places — a missing abstraction, not three nits.
- A file growing past readable while a new feature is added to it.
- Unlabelled review comments, so the author can't tell a blocker from a preference.
- A verification story that says "tested locally" with nothing shown.
- Several dependencies bumped in one change, or a hand-edited lockfile.
- Findings deferred to a follow-up that nobody owns.

## Before finishing

Confirm, out loud, in the report: every `Critical` is resolved or explicitly accepted by the human;
every `Required` is resolved or deferred with a stated reason; the verification line reflects what
actually ran, not what should have; and under `--fix`, that the working tree is left uncommitted with
the applied and skipped findings both named.

Defer gracefully where the author holds context you don't — say what you'd need to see to be
convinced, then let it go.
