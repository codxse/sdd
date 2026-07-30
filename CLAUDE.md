# SDD — a Claude Code, Codex & Kimi Code plugin marketplace

This repo ships agent **plugins**, not an application. The "source" is prompt files (`SKILL.md`), so
there is no unit-test suite — verifying a change usually means reading the prompt and the
`CHANGELOG.md`, then running the skill.

**Four hosts, one `skills/` tree.** The skill bodies are shared verbatim between Claude Code,
OpenAI Codex, Kimi Code, and opencode — the Claude Code and Codex plugin layouts mirror each other, so each
plugin carries two manifests
(`.claude-plugin/plugin.json` and `.codex-plugin/plugin.json`) over the *same* `skills/<name>/SKILL.md`
files, and the repo carries two marketplaces (`.claude-plugin/marketplace.json`,
`.agents/plugins/marketplace.json`). Never fork the skill prose per host — edit the one SKILL.md.
The same dual-manifest pattern covers **subagent definitions**: `plugins/sdd/agents/` ships
each reviewer agent twice — `<name>.md` (Claude Code format, auto-discovered from `agents/` and
listed namespaced as `sdd:<name>`; do **not** add an `agents` key to the manifest — Claude
Code rejects the whole plugin on unknown manifest keys) and `<name>.toml` (Codex format; Codex
plugins don't auto-load agents, so
users copy the TOMLs into `.codex/agents/`, per the README). On Kimi Code the same `<name>.md`
doubles as the agent definition — Kimi's loader ignores the Claude `model:` field and accepts the
comma-separated `tools`, so users copy the `.md` files into `~/.agents/agents/`. The two files of a pair carry the same
`developer_instructions`/body verbatim — edit them together, fork only the host-native pin fields.
Codex's per-skill `agents/openai.yaml` opts a skill out of implicit invocation
(`policy.allow_implicit_invocation: false`); omit it when the skill should be model-invocable.
Shared frontmatter must keep `disable-model-invocation: false` so Codex accepts and discovers the
skill. The exception is behavioral guards that must hold on a budget model:
`plugins/sdd/tests/{claude,codex,kimi}/model-guard.sh` run `/specify`, `/refine`, and
`/orchestrate` headless across multiple trials (including override-injection descriptions) and
assert each Model Guard stops it. They assert **both directions and the classification itself**: a
below-frontier model (`-m`, `--below-tier budget|medium`) must stop, a frontier model (`-M`) must
classify `frontier` and continue, and every
trial must show the guard's `model-guard: id=<exact-id> tier=<tier>` line (`guard_line`, in
`tests/lib.sh`). Refusal-only assertions cannot fail — a host that never states its model ID
classifies `unsure`, and `unsure` refuses in the same words as `budget` — which is exactly how
Kimi's missing model identity went unnoticed. Claude uses Haiku and `/specify`; Codex uses `gpt-5.6-luna` plus
explicit `$sdd:specify` mentions; Kimi uses `kimi-code/kimi-for-coding` plus `/skill:specify`; opencode
uses `anthropic/claude-haiku-4-5-20251001` plus `opencode run --command specify` (a bare `/specify` in
the message is sent verbatim and never resolves), and **stages a throwaway config dir** rather than
mutating `~/.config/opencode` — the operator's `opencode.json` copied in for provider access, the
working tree layered on top. Because `run_clean_env` strips the environment, a host whose provider key
comes from `{env:VAR}` must name it in `SDD_TEST_ENV` or every trial fails to authenticate and scores
as inconclusive infra rather than the setup mistake it is; `tests/opencode/lib.sh` warns about that up
front, since opencode substitutes an *empty string* for an unset `{env:}` var instead of erroring.
Codex's generic base prompt names only GPT-5, so its default plugin hook reads the host-provided
`model` field and injects the exact slug. The harnesses call the real model, so they're slow and
probabilistic — run them when changing any Model Guard. All three run model CLIs through the shared minimal environment
allowlist, so a guard slip cannot expose unrelated caller credentials. Host-specific install/sync
helpers live under each host directory; `tests/lib.sh` keeps only the host-agnostic helpers.

**Kimi Code breaks the per-plugin manifest pattern.** Its GitHub install reads the manifest at the
*repository* root only, so instead of per-plugin `.kimi-plugin/` dirs there is a single root
`kimi.plugin.json` declaring every `skills/` tree — all three marketplace plugins ship to Kimi as one
plugin named `sdd`. Its root `version` therefore tracks the *bundle*, not the `sdd` plugin: adding or
removing a skill tree bumps it even when `plugins/sdd/` itself is untouched (`3.1.0` added
`code-review-quality` while `sdd` stayed `3.0.0`). The manifest also ports the session-primer hook (`SessionStart` +
`PreCompact`) via its `hooks` field, with `$KIMI_PLUGIN_ROOT` in place of `${CLAUDE_PLUGIN_ROOT}`.
It carries a third hook the other hosts don't need: **`UserPromptSubmit` →
`hooks/kimi-model-context.sh`**, which supplies the model ID Kimi never states. No Kimi hook payload
has a `model` field and its system prompt names only "Kimi Code CLI", so without this every gated
skill classifies `unsure` — or worse, guesses ("Kimi Code CLI runs on k3, k3 is frontier") and
authors on a budget model. `UserPromptSubmit` is used because it is the only Kimi hook documented to
append its output to context, and the only event whose payload carries the `session_id`; the hook
reads `modelAlias` from the session's own record under `$KIMI_CODE_HOME/sessions/*/`, last
occurrence winning so an interactive `/model` switch is picked up, and fails closed (silence →
`unsure` → the gated skills stop). Two wrong sources are documented in the hook so they are not
`simplified` back in: the launching process's argv (kimi overwrites its own argv, erasing `-m`) and
`default_model` from config.toml (stale under a `-m` override — it tells a budget session it is
frontier).
Two Kimi gaps are accepted and documented in the README: plugins can't ship subagent definitions —
worked around, not solved: Kimi's agent loader reads the Claude-format `agents/*.md` verbatim
(ignoring the `model:` pin), so users copy them into `~/.agents/agents/` and the reviewer pin keeps
one frontier rung, the session's own model (the Kimi branch in `skills/validate/SKILL.md`'s
*Reviewer pinning by host*) — and there
is no implicit-invocation gate equivalent to Codex's `agents/openai.yaml`, so slash-only-ness on
Kimi rests on skill prose.

**opencode has no manifest at all — its install surface is the config directory.** There is no plugin
manager to publish to, so the host port is a *script*: `plugins/sdd/hosts/opencode/install.sh` copies
into `~/.config/opencode` (or `$OPENCODE_CONFIG_DIR`, or a project `.opencode`) — `skill/<name>/SKILL.md`,
`agent/*.md`, `plugin/sdd-model-context.js`, and a generated `command/<name>.md` per skill. It records
its file list in `.sdd-installed` and removes that set before rewriting, so re-running it is the
update and a renamed skill can't linger as a duplicate. `plugins/sdd/hosts/<host>/` is the home for
anything a host needs that isn't a manifest; the source layout deliberately mirrors the destination
so the installer stays a copy. Details, including the flags, live in `OPENCODE.md` — the one host doc
big enough not to fit in the README.
Four things make this host different, none of them a reason to fork skill prose:
- **Slash commands are generated, not committed.** The installer builds each `command/<name>.md` from
  that skill's own frontmatter (copying the `description:` line *verbatim* — it is already a valid
  single-line YAML scalar, and re-quoting it is how you break a description containing quotes). Don't
  commit command files; a second copy of a description is a second thing to drift.
- **Skill frontmatter is lenient, agent frontmatter is not.** opencode's skill loader requires only
  `name` + `description` and ignores unknown keys, so `version`/`argument-hint`/`user-invocable` ride
  along inert. Its *agent* loader is stricter and hard-fails the config: `tools` must be a
  `Record<string, boolean>`, so the Claude format's comma-separated `tools: Read, Grep, …` throws, and
  `model:` is split on `/`, so a bare `sonnet` yields an empty model ID. That's why
  `hosts/opencode/agent/*.md` is a third agent format rather than a copy of the Claude `.md` — same
  body verbatim, host-native pin fields only, exactly like the `.toml` pair.
- **`plugin/sdd-model-context.js` is load-bearing, and injects at two seams.** opencode's built-in
  system context is cwd, project root, git, platform, and date — no model ID, so every gated skill
  classifies `unsure` and stops on *any* model. The plugin appends the host-resolved ID via
  `experimental.chat.system.transform` (the only hook onto the system prompt; its input carries the
  resolved model, so unlike Kimi's hook nothing is reconstructed from session files or argv) **and** via
  `tool.execute.after` on the `skill` tool, onto the loaded skill body. The second is not duplication —
  it is the fix. opencode delivers a skill as a *tool result*, so the tier rubric lands far from the
  system prompt, and a budget model doesn't look back: with seam 1 alone and the right ID in the system
  prompt, `claude-haiku-4-5` emitted `model-guard: id=claude-opus-4-1 tier=frontier` — a confabulated ID
  — and authored a story. Don't "simplify" either seam away. Same fail-closed rule as Kimi's: no ID →
  emit nothing → `unsure` → stop. Never read `model` from `opencode.json` instead — that's the session's
  model only when the user didn't override it with `-m` or `/models`, and asserting it tells a budget
  session it is frontier. Verified on a live host across all three rungs and both providers
  (Anthropic-native and OpenAI-compatible); test both directions, since `unsure` refuses in `budget`'s
  words.
- **Reviewer pinning needs no new branch.** opencode honors a subagent's `model:` pin, so it lands in
  the existing *native host* bucket of `skills/validate/SKILL.md`'s *Reviewer pinning by host* — both
  rungs, cost-keyed, no skill edit. This is the capability-keyed map paying off; don't add a host name
  to it. The one accepted gap is the Kimi one: no per-skill implicit-invocation gate, so `/solve` and
  `/validate` rely on `permission.skill: ask` in the user's config plus their own prose.

## What this is

`.claude-plugin/marketplace.json` (Claude Code) and `.agents/plugins/marketplace.json` (Codex)
publish the same three plugins under `plugins/`:

- **sdd** — `/specify`, `/refine`, `/board`, `/solve`, `/validate`, `/orchestrate`: a
  bd-backed, parallel-capable coding workflow.
- **code-review-quality** — `/code-review-quality`: multi-axis review of a change before merge.
  Standalone — no bd, no worktrees, no model gate. Report-only by default; `--fix true` applies the
  findings and leaves them uncommitted. Deliberately *not* an `sdd` skill: it shares none of that
  plugin's bd machinery. `sdd`'s own review path reaches it the other way round: `/validate`'s reviewer
  agents prefer `/code-review-quality` and fall back to the host's `/code-review` when this plugin
  isn't installed — a preference, never a dependency.
- **writing-claude-md** — `/writing-claude-md`: authoring lean, high-signal context files.

## Philosophy (this drives how every skill is worded)

- **One three-rung ladder; one command per job.** `budget` / `medium` / `frontier` is the *only*
  tier vocabulary — the same rungs serve the authoring gate (a threshold on the ladder) and the
  `solver-<tier>` complexity call (a rung on it). There is no separate "planning" tier; "planning" is
  the *job* `/specify` does, never a rung. The **frontier** rung authors the **WHAT** (requirement,
  boundary, contract): `/specify` writes a *new* story/epic, `/refine` revises an *existing* story —
  both gated to `frontier` and sharing one set of rubrics. **A `medium` model is refused**, not
  merely warned: a subtly wrong contract is paid for by every later solve.
  The **HOW** runs on whatever rung the story asks for: `/solve` writes code in an isolated
  worktree+branch and carries no gate. The human tier is
  `/validate`, the review-and-merge gate; its review pass doesn't bounce work back to
  `/solve` but **delegates the fix to a rung-pinned reviewer subagent**, which applies it
  in place on `bd/<id>` and amends — `/validate` carries no model gate, so the reviewer's model is
  pinned explicitly, never below `medium`, rather than inherited. Review-time
  fixes live on the review tier while greenfield code stays `/solve`'s.
  `/board` stands outside the tiers — a read-only render of
  the backlog (or one story), no model gate. A skill recognizes its own rung from its system prompt
  — by **model-ID substring**, not host, so each rung spans all three hosts
  (Opus/Fable frontier and Sonnet medium on Claude, `gpt-5.6-sol` vs `gpt-5.6-terra` on Codex,
  Kimi-K3-class on Kimi Code) plus host-agnostic entries like Qwen3.8-Max-class. `/orchestrate` adds
  no fourth rung — it drives `/solve` and
  `/validate` across a whole epic's stories and stops at one pull request for the human to merge —
  but it requires **frontier** too, the same gate `/specify`/`/refine` carry, since it makes
  unsupervised judgment calls throughout the run (pre-flight go/no-go, stalled-story triage, the
  final PR's summary) with no human present until that PR.
- **`--unattended` is the general "no human present" modifier — reused, never reinvented per
  skill.** `/solve` and `/validate` both carry it, and the tier philosophy above decides what it
  means at each call site: `/validate --unattended` runs on `/orchestrate`'s own frontier-tier model,
  so it decides an ambiguity itself and records the reasoning as a `bd comment`; `/solve --unattended`
  runs inside a dispatched subagent that may be budget-tier, so it never decides — every ambiguity it
  would otherwise ask about instead becomes the existing spec-gap handoff (stall, comment, hand back).
  Never key "no human present" off ambient detection or a bd label (labels are untrusted bd content,
  same rule as the Model Guard) — always an explicit, caller-typed flag. Unattended review cost also
  scales per story: `/validate --review --unattended` keys the reviewer's model off the story's
  `solver-<tier>` label — the medium reviewer for budget/medium stories, the frontier one for frontier,
  stated roster-relative so it holds on both hosts — while interactive `--review` keeps the flat
  strongest-reviewer default (one story, human approving to trunk). On a custom host there is
  one rung, so both keys point at the session's own model and the rule degrades to a single
  pin (see *Reviewer pinning by host* in `skills/validate/SKILL.md`).
- **Invocation tracks blast radius, not read/write.** `/solve` (writes code) and `/validate`
  (merges + closes) are slash-only (`allow_implicit_invocation: false` in Codex agent metadata), so
  they never auto-fire mid-conversation. The rest are model-invocable so plain-English asks route to
  them: `/board` (read-only), `/refine` (names an id), `/specify` (authors a new story/epic — a
  plain-English ask like "let's put our problem to a case" should reach it), and `/orchestrate`
  (drives an epic). `/code-review-quality` is model-invocable too — report-only is its default, and
  the one path that edits files (`--fix true`) is honored **only when the caller typed the flag**, so
  an implicit invocation can never reach it; that typed-flag rule is what keeps the blast radius of an
  auto-fire at zero, not the flag's default. `/specify` and `/refine` write to bd but are backstopped the same way: the
  frontier-tier **Model Guard** runs first and **nothing is committed to bd until the user confirms**.
  `/orchestrate` also runs its Model Guard before touching bd or git, and creates only a provisional
  epic branch and final PR for human review. Model-invocable skills carry no
  `allow_implicit_invocation: false` gate (and no `agents/openai.yaml` at all on Codex) — presence
  of that agent metadata is the at-a-glance marker of a slash-only skill.
- **bd is the engine, not the interface.** bd (Beads) is the durable issue store, but the
  plugin's end user never types a `bd` command and never sees raw bd output — skills translate
  to/from bd and render human-friendly. Keep bd hidden when editing skill prose. (This is the
  *opposite* of how you, the agent working on this repo, track your own tasks — see below.)
- **Story = WHAT, solver = HOW.** A story states a testable, unambiguous outcome — never the
  mechanism. "Specific ≠ prescriptive."

## Editing skills

- Bump the skill's frontmatter `version` and add a `CHANGELOG.md` entry in the same change. The
  marketplace/plugin `version` tracks the published plugin, not the per-skill frontmatter versions —
  bump it in **all five** manifests (`.claude-plugin/plugin.json`, `.codex-plugin/plugin.json`,
  both marketplaces, and the repo-root `kimi.plugin.json`) so the three hosts stay in lockstep. For a
  plugin other than `sdd`, the same rule reads: its own two `plugin.json`s, its entry in both
  marketplaces, and the kimi root (which versions the whole bundle — see above).
- `/specify` and `/refine` share the contract rubrics in `plugins/sdd/shared/contract-rubrics.md`
  (Atomicity Gate, AC Quality Rubric, Pre-write Guard, Output Format). That file is
  the single source, but it is **not read at runtime**: everything below its `BEGIN SHARED` marker is
  inlined verbatim into the `Contract Rubrics` section at the end of both SKILL.md files. Edit the
  rubrics **there**, then run `plugins/sdd/tests/rubrics-sync.sh --write`; never hand-edit a
  skill's generated block. The script with no flag verifies both copies and fails on drift — pure text
  comparison, so unlike the other tests it's fast, deterministic, and needs no model. That's why both
  sync scripts are wired into CI (`.github/workflows/checks.yml`, on push + PR): both hosts install
  this plugin by copying the repo, with no build step between a commit and a user, so drift on
  `master` is drift that ships. CI is the only gate there is.
  - **`--write` only propagates the shared block.** If a rubric edit renames a *token* that other
    skills cite in their own prose — e.g. a `Verification` value like `auto+human`, which `/solve` and
    `/validate` reference *outside* the generated block — those call sites won't move with the sync.
    `grep` the whole plugin for the old token and fix them by hand, or the skills drift out of step
    with the rubric while `rubrics-sync.sh` still reports green.
  - **Why inlined, not read.** The rubrics are a hard gate — every `/specify` and `/refine` invocation
    needs them — so a runtime read saves no context and costs a path that can't resolve reliably: a
    relative path in skill prose resolves against the *user's* CWD, not the plugin dir, and
    `${CLAUDE_PLUGIN_ROOT}` is substituted inline in skill content by Claude Code but **not** by Codex,
    so it would fork the prose per host. Inlined text needs neither, which is why the skills carry no
    path-resolution instructions at all. Don't reintroduce a runtime read.
- All five skills share the model-tier map in `plugins/sdd/shared/model-tiers.md` (Tier
  classification — the budget/medium/frontier/unsure rungs). Same pattern as
  the contract rubrics: single source, **not read at runtime**, inlined verbatim into a `Model Tiers`
  section of every SKILL.md. Edit the map **there**, then run
  `plugins/sdd/tests/model-tiers-sync.sh --write`; never hand-edit a skill's generated block.
  The script with no flag verifies all five copies and fails on drift — pure text comparison, wired
  into CI like `rubrics-sync.sh`. Adding a model (or a host) is a one-file edit here, not five.
  - **`code-review-quality` is intentionally outside that set** — it lives in another plugin and gates
    on nothing, so it carries **no tier block and no tier vocabulary at all**. Don't add one: syncing
    it would make one plugin's generated content depend on another plugin's file, and there is nothing
    in it for a rung to decide.
  - **Reviewer pinning lives natively in `skills/validate/SKILL.md`** (moved there in 2.24.1 —
    `/validate` is its sole consumer — so it is *not* part of the synced block) and keys off host
    *capability*, not a host list. A native Claude/Codex host
    uses the shipped reviewer agents (medium + frontier rungs, cost-keyed, with the same-rung
    step-up); a native Kimi Code
    host can't receive shipped agents from a plugin, but loads the same `.md` files when the user
    copies them into `~/.agents/agents/` — the `model:` pin is ignored there, so like a custom
    host it gets one rung, the session's own model ID (K3-class only; a budget session
    stops); a custom
    host (session model classifies as `frontier` or `medium`, e.g. `qwen3.8-max-preview`) pins a
    general subagent to
    the session's own model ID; anything else stops rather than falling back to a budget reviewer. New
    hosts fall into one of these buckets with no code change — don't reintroduce an enumerated
    `if claude … elif codex …`.
- `AGENTS.md` is a symlink to this file — edit `CLAUDE.md`.

> If the code contradicts anything above, the code wins — update this file in the same change.
