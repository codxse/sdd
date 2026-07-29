# Model Tiers — shared by all sdd skills

The model-tier classification for the whole plugin: which model IDs are **budget** vs **planning**.
Every skill classifies its own model from its ID by the rules below — the rules are identical across
skills, so they are written once, here. (Reviewer pinning — how `/evaluate` picks a frontier
reviewer — has a single consumer and lives natively in `skills/evaluate/SKILL.md`, not here.)

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
