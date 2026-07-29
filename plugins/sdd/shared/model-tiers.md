# Model Tiers — shared by all sdd skills

The model-tier classification for the whole plugin: which model IDs are **budget**, **medium**, or
**frontier**. One ladder serves both consumers — the authoring gate (a threshold on it) and the
`solver-<tier>` complexity call (a rung on it). Every skill classifies its own model from its ID by
the rules below — the rules are identical across skills, so they are written once, here. (Reviewer
pinning — how `/validate` picks a reviewer — has a single consumer and lives natively in
`skills/validate/SKILL.md`, not here.)

**This file is the single source of truth, but it is not read at runtime.** Everything below
`BEGIN SHARED` is inlined verbatim into a `Model Tiers` section of each SKILL.md by
`tests/model-tiers-sync.sh`. Edit the map **here**, then run `tests/model-tiers-sync.sh --write`;
never hand-edit the generated block in a skill. Running the script with no flag verifies every copy
matches and fails on drift.

Inlining is deliberate, for the same reason as the Contract Rubrics: the tier map is a hard gate —
every invocation needs it — so a runtime read saves nothing and costs a path that cannot resolve
reliably (a relative path resolves against the user's CWD, not the plugin; `${CLAUDE_PLUGIN_ROOT}`
is substituted by Claude Code but not Codex). Inlined text needs neither.

<!-- BEGIN SHARED -->

## Tier classification

Classify the session's model **by its exact ID, never by self-assessed capability** — "I can handle
this" is not a reason to reclassify. Read the ID from the session environment / system prompt (it
states one, e.g. `The exact model ID is claude-haiku-4-5`).

Three rungs, ordered. Each rung is defined by **what the model can hold**, not by price alone — the
ID list is how you recognize a rung, the definition is what the rung means:

- **budget** — cheap and fast; thin reasoning, small effective attention. Reliable on bounded,
  fully-specified work; drifts as ambiguity or scope grows. IDs containing `haiku`, `flash`, `mini`,
  `lite`, `small`, `nano`, `luna`, or `kimi-k2`, or a known budget tier (MiniMax-M-class, Gemini
  Flash-class, `gpt-5-mini`/`gpt-5-nano`/`gpt-5.6-luna`, Kimi Code's `kimi-for-coding`).
- **medium** — solid reasoning at moderate cost; holds a larger working set. Handles one real
  difficulty signal contained to a single well-understood area; not for high-blast-radius subtlety.
  IDs containing `sonnet`, `gpt-5.5`, or `gpt-5.6-terra`, or a Gemini Pro-class model.
- **frontier** — strongest reasoning available. For work where being subtly wrong is expensive, or
  where the correct approach itself takes judgment. IDs containing `opus`, `fable`, `mythos`, or
  `gpt-5.6-sol`, or a Qwen3.8-Max-class (e.g. `qwen3.8-max-preview`) / Kimi-K3-class (`k3`,
  `kimi-k3…`) / equivalent top-tier model.
- **unsure** — anything you cannot positively place on the ladder.

**A budget marker outranks any higher marker** — a hypothetical `qwen3.8-max-lite` is budget, not
frontier. Placeable on the ladder but unsure whether medium or frontier → treat it as **medium**.
For a gated skill that means stopping, which is the safe direction: a false stop costs a line of
output, a false pass costs a bad contract.

**The gate.** A skill that gates on tier (`/specify`, `/refine`, `/orchestrate`) proceeds only on
`frontier` and stops on `medium`, `budget`, **or** `unsure` — these three author the WHAT, where a
subtly wrong contract is paid for by every later solve. A skill that merely notes its rung
(`/solve`) reports it and continues on any of them. `/board` and `/validate` carry no tier gate.

<!-- END SHARED -->
