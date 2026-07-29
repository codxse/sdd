# Contract Rubrics — shared by `/specify` and `/refine`

The quality bars for authoring or revising a story contract on a **frontier model**. The flow lives
in each skill; the bars below are identical for both, so they are written once, here.

**This file is the single source of truth, but it is not read at runtime.** Everything below
`BEGIN SHARED` is inlined verbatim into the `Contract Rubrics` section of `skills/specify/SKILL.md`
and `skills/refine/SKILL.md` by `tests/rubrics-sync.sh`. Edit the rubrics **here**, then run
`tests/rubrics-sync.sh --write`; never hand-edit the generated block in a skill. Running the script
with no flag verifies both copies match and fails on drift.

Inlining is deliberate. The rubrics are a hard gate — every `/specify` and `/refine` invocation needs
them, so a separate runtime read saves nothing and costs a path that cannot be resolved reliably: a
relative path in skill prose resolves against the *user's* working directory, not the plugin, and
`${CLAUDE_PLUGIN_ROOT}` is substituted by Claude Code but not by Codex. Inlined text needs neither.

<!-- BEGIN SHARED -->

## Authoring principles

- **Specific ≠ prescriptive.** A story states a testable, unambiguous *outcome* — never the
  mechanism or code.
- **Who, What, Why.** A story is written for an actor. The Problem Statement opens with one story line — `As a <actor>, I want <what>, so that <why>` — before anything else. A story whose actor or benefit can't be named isn't ready to author.
- **INVEST.** Every story is **I**ndependent (schedulable alone — a hard ordering belongs in an epic's dependencies), **N**egotiable (outcome, never mechanism), **V**aluable (the `so that` names a real benefit), **E**stimable (grounded and unambiguous enough to size — the Atomicity Gate's unsettled middle), **S**mall (the Atomicity Gate's too big), **T**estable (AC Quality Rubric).
- **No drift.** Don't restate the command, duplicate repo conventions, or add sections outside the
  template.
- **Diagnosed, not hypothesized.** A bug-fix premise is the *observed* failure, never an inferred
  cause.
- **Grounded names.** Every artifact a story names (file/class/method/endpoint/table/config key)
  must be verified to exist via Read/Grep before writing — a budget solver trusts names. Can't
  verify → describe its role instead.

---

## Socratic loop

Don't take the author's description at face value and write it up. It is the *opening* position; the
contract is what survives questioning. Ask until a solver reading the result has nothing left to
decide — that is the Atomicity Gate's **Settled** bar, and this is how you reach it.

- **Read before you ask.** The codebase answers it → explore, don't ask (budget ~3 Read + 2 Grep when
  the author names an artifact). Asking what you could have looked up spends their attention on your
  work.
- **Ask only what changes the contract.** Different answers must produce different boundaries, AC, or
  scope calls. Anything else is noise.
- **One question at a time, each carrying your recommended answer** and the reason for it. A bare
  question makes the author do the thinking twice.
- **Push on the vague word.** "Fast", "secure", "handles errors", "properly" — each is an unwritten
  AC. Ask for the observable: how fast, against what, which errors, checked how.
- **Follow the answer.** An answer that opens a new gap is the next question, not a stopping point.

Stop when every remaining unknown is one the solver can settle without changing *what* gets built.

---

## Atomicity Gate

A vague story does not fail fast; it gets **interpreted** — and every model interprets differently.
That is the **ambiguity tax**: hallucinated APIs, invented data models, rework cycles. Paying it
once here, at authoring time, is cheaper than paying it on every solve attempt.

A story is **atomic** when both hold:

1. **Bounded** — one capability in one subsystem; no more than ~6–8 AC scenarios; each AC one
   observable behavior.
2. **Settled** — nothing inside is left to the solver's judgment: no open design decision, no
   unconfirmed root cause, every named artifact verified to exist.

Either failure — too big, or a gap in the middle — and the solver drifts.

**The test is model-independent:** two different models reading this contract would build the same
thing. Wherever their answers would diverge, the story is not atomic yet — that divergence *is* the
per-model bias this gate exists to remove. Size and settle for the thinnest rung, regardless of
which model actually runs `/solve`.

**Too big (scope)** — any → decompose into an epic, or split the story:
- Spans multiple independent capabilities or subsystems.
- More than ~6–8 AC scenarios across unrelated behaviors.
- A single AC implies a whole subsystem, not one observable behavior.
- Cross-cutting change touching many files/layers at once.

**Unsettled middle (ambiguity)** — any → settle it in the contract, or split it out:
- An AC whose test forces a design decision the contract doesn't settle (invent an API shape, pick
  a data model, choose where state lives).
- **Bug fix whose root cause isn't reproduced and confirmed.** Diagnosing an unknown failure is what
  budget models are worst at. While the cause is a hypothesis, make diagnosis its own story for a
  frontier model (Verification: human); the budget solver gets only the mechanical fix once the
  cause is observed.

---

## Complexity Tier

The Atomicity Gate settles *scope and ambiguity* — every story reaching bd is already atomic, and so
already fits a budget solver's working set. Complexity is a separate axis, judged only after that
gate passes: an atomic story can still call for more reasoning capability than raw execution. Judge
it in addition to the Atomicity Gate, never instead of it.

Recommend the **cheapest rung + effort likely to succeed**, on the same ladder as **Tier
classification** — but judge what the *story* demands, not what you are running on, and name the
rung only (no model IDs; the roster changes, the judgment shouldn't).

| Rung | The story asks for |
|---|---|
| `budget` | Mechanical work that follows an existing pattern. |
| `medium` | Between the two. |
| `frontier` | High blast radius if subtly wrong (security, auth, money, data loss), or an approach that itself takes judgment (novel algorithm, non-obvious concurrency/ordering, constraints that look like they conflict). |

**Difficulty signals.** Count how many the story carries, then map: **none → `budget`**; **one,
contained to a single well-understood area → `medium`**; **high blast radius, or several signals
interacting → `frontier`**.

- **Security surface** — auth, crypto, permissions, secrets, money.
- **Concurrency** — ordering, races, retries, idempotency.
- **Non-obvious reasoning** — algorithmic or mathematical, where the naive version is quietly wrong.
- **Subtle external semantics** — a library or API easy to call in a way that looks correct but
  isn't.
- **Judgment-bearing refactor** — an unfamiliar or inconsistent existing pattern, where preserving
  behavior takes reading it, not mechanically translating it.

**Escalate along the axis the signal actually stresses** — don't default to raising tier for
everything:
- A signal about **volume** (long AC list, wide file surface, repetitive-but-mechanical work) →
  raise **effort** within the current tier.
- A signal about **subtlety or blast radius** (the signals above) → raise **tier**; more effort on a
  weaker model doesn't close a capability gap.

**Effort** (`low`/`high`/`max` — this workflow's own scale, never `medium`; that names a rung)
grades independently of tier.

State the call as `Recommended Solver: <tier> · <effort>` plus one line naming the driving signal(s),
or "no difficulty signal — mechanical" for budget.

---

## Verification Mode

Every story states a `Verification` mode telling downstream whether a human checkpoint is needed:
`auto`, `human`, or `auto+human`. (In this workflow every story is also reviewed at `/validate`
before merge; `Verification` is about whether the *solver* needs a person mid-slice.)

- **`human`** — acceptance observed by a person exercising the running system, or needs judgment a
  machine can't make (user-facing surface; qualitative: looks/feels right, UX, copy, layout).
- **`auto`** — fully machine-assertable, no experiential dimension (pure refactor keeps tests green;
  exact/high-volume assertions; internal contract with no surface yet).
- **`auto+human`** — the story has both a machine-assertable part and an experiential one: the
  solver auto-verifies the assertable part and spells out the experiential part for a person to
  exercise at `/validate`.
- **Default when ambiguous → `human`.**

---

## AC Quality Rubric

For each Acceptance Criteria scenario, before it goes into bd:

- **Atomic** — 1 scenario = 1 behavior. Then/And checking 2 separately-failing observables → split.
- **Self-contained** — readable standalone; if scenarios relate (regression vs new), say so in the
  title or group them under a `Rule:`.
- **Specific & verifiable** — concrete, deterministically assertable values. No judgment wording.
- **Declarative** — steps state business-level actions in third person, naming the story line's actor — never "I", never UI mechanics ("clicks the button", "types into the field"). Litmus: wording that must change when the implementation changes → rework. Specific values stay (there are no step definitions to hide them in): "When Bob logs in with password `hunter2`" is declarative *and* deterministic.
- **Observable** — assertion is about externally visible outcome (result state, system state, side
  effect, or absence). A method-call surrogate for an observable in the result = mechanism-bound,
  revise.
- **Generalizable** — representative test data, not accidental.
- **Exhaustive** — new behavior (positive) AND preserved behavior (regression): happy path +
  boundary; a bug fix also reproduces the failure.
- **Readable** — business terminology; raw identifiers with business meaning → Glossary.

---

## Pre-write Guard

Before a story enters bd, scan and strip:
- Implementation code block → remove.
- File:line edit instruction → abstract to "area to look at" or remove.
- Prescribed name for a *new* artifact → abstract to its role.
- Section outside the template → remove.
- Problem Statement narrating mechanism → rewrite to outcome.
- Problem Statement not opening with the story line (`As a <actor>, I want <what>, so that <why>`), or an actor/benefit too vague to mean anything ("the user", "better quality") → name the who and the why (a story states WHO, WHAT, *and* WHY).
- AC failing the rubric → split/add/revise.
- AC leaking a raw identifier with business meaning → lift to Glossary.
- AC scenarios **not** inside a fenced ` ```gherkin ` block (bare lines, or relying on trailing-space
  breaks) → wrap them in the fence. This is what holds the Given/When/Then formatting in rendered
  markdown; bare lines collapse to one paragraph.
- AC `gherkin` block missing its opening `Feature:` title line → add it, titled by the capability delivered (see Output Format).
- AC step written as "I" or narrating UI mechanics → rewrite declarative, third person, actor named.
- Prose paragraph hard-wrapped across lines → join to one line (see Output Format; `gherkin` block exempt).

Then self-audit: all core sections filled; a Verification mode stated; a Complexity call made and
stated; every named artifact verified to exist; solver dry-run each AC (could a budget solver write
the test from Given/When/Then + Context + Glossary without making an open design decision?). A
lurking decision → settle it or split.

---

## Output Format (story body)

Each story's bd body uses this template. Every section is mandatory unless marked optional.

**No hard wrapping in prose.** Each paragraph/list-item is **one unbroken line** — never wrap at a
column width (stray breaks survive a paste into Basecamp/Linear; markdown and `bd show` soft-wrap
anyway). Blank lines between paragraphs stay. Only the fenced `gherkin` block keeps internal breaks.

````markdown
# [Problem Title]

## Problem Statement
```
As a [actor],
I want [what — the outcome],
so that [why — the benefit].
```

[Then one paragraph: the problem, why it must be solved, the desired outcome. State the outcome, don't narrate mechanism. The actor is whoever gets the capability — for a bug fix, whoever the observed failure blocks.]

## Context
[Background, domain knowledge, classification assumptions. May name existing artifacts as pointers. For an environment-sensitive bug, state facts the solver can't infer from code (proxy/CA, OS/device, pinned versions). Empty if none.]

## Glossary
[Optional. Business terms used in AC mapped to technical artifacts. Skip if no jargon.]
- **[business term]** — [definition + artifact reference if needed.]

## Constraints
- [Boundary to preserve. E.g. "Preserve method X (used by other callers)."]
- [NOT mechanism — don't write "use AppSetting".]

## Acceptance Criteria

Put **every** scenario inside one fenced `gherkin` block that opens with a `Feature:` line titling the behavior under test. Title it by the capability delivered — for a bug fix, by the expected behavior being restored, never by the bug. The fence preserves the line breaks and indentation literally — identical in `bd show` and rendered markdown — so the Given/When/Then never collapse into a run-on line. Never use trailing-space line breaks (invisible, silently dropped). One blank line separates scenarios.

Scenarios clustering into distinct behaviors → group each cluster under a `Rule:` line (one business rule each, its scenarios indented beneath it). The same steps repeated over many values → one `Scenario Outline` with an `Examples` table, not near-duplicate scenarios.

```gherkin
Feature: [behavior under test — the capability delivered]

  Scenario: [title]
    Given [initial condition — specific value, observable state]
    When [action — business-level, third person naming the actor; a callable method or triggerable event, never UI mechanics or "I"]
    Then [result — observable state, response field, side effect]

  Scenario: [next edge case — each programmatically verifiable]
    Given [...]
    When [...]
    Then [...]
```

## Verification
Verification: [auto | human | auto+human]   — [human/auto+human: what a person checks + how to exercise it]

## Complexity
Recommended Solver: [budget | medium | frontier] · effort [low | high | max]
[One line: which difficulty signal(s) drove the tier, or "no difficulty signal — mechanical".]

## Out of Scope
- [Explicit things not done here]
- (Write "(none)" if no extra boundary.)

## Files of Interest
[Optional. Only if the user gave a pointer. Points to an artifact's role, not an instruction.]
- `path/to/file` — [one line role.]
````
