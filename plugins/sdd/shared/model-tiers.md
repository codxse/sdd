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

Classify by **exact model ID, never self-assessed capability** — "I can handle this" is not a reason
to reclassify. Read the ID from the session environment / system prompt (it states one, e.g.
`The exact model ID is claude-haiku-4-5`). Rungs are ordered; each is defined by what the model can
hold, and the markers are how you recognize it.

| Rung | What it holds | ID markers |
|---|---|---|
| `budget` | Bounded, fully-specified work. Thin reasoning, small effective attention — drifts as ambiguity or scope grows. | `haiku` `*-flash` `*-mini` `*-lite` `small` `nano` `luna` `kimi-k2` `kimi-for-coding`; MiniMax-M / Gemini Flash class |
| `medium` | One real difficulty signal, contained to a single well-understood area. Larger working set; not for high-blast-radius subtlety. | `sonnet` `gpt-5.5` `gpt-5.6-terra` `glm-5.2` `qwen3.7-plus` `deepseek-v4-pro`; Gemini Pro class |
| `frontier` | Work where being subtly wrong is expensive, or the correct approach itself takes judgment. | `opus` `fable` `mythos` `gpt-5.6-sol` `k3` `qwen3.7-max`; Qwen3.8-Max / Kimi-K3 class, or equivalent top tier |
| `unsure` | Anything not positively placed above. | — |

A plain marker matches anywhere in the ID; a `*-` marker matches only as a hyphen-delimited
suffix segment, so `gpt-5-mini` is budget and `minimax-m3` is not matched by `*-mini`.

**A budget marker outranks any higher one** — `qwen3.8-max-lite` is budget, not frontier. Unsure
between medium and frontier → **medium**; for a gated skill that means stopping, which is the safe
direction: a false stop costs a line of output, a false pass costs a bad contract.

**The gate.** `/specify`, `/refine`, `/orchestrate` proceed only on `frontier` and stop on `medium`,
`budget`, **or** `unsure` — they author the WHAT, where a subtly wrong contract is paid for by every
later solve. `/solve` reports its rung and continues on any. `/board` and `/validate` are ungated.

<!-- END SHARED -->
