# Changelog

All notable changes to the **sdd** marketplace (published as **case-solvers** through `2.25.1`) are
documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
Versions track the published plugin/marketplace, not the skills' internal frontmatter
versions (shown in parentheses where relevant). Entries below `3.0.0` name the project as it
shipped at the time — `case-solvers` — and are left as written.

## [Unreleased]

**BREAKING: renamed the project, the marketplace, and the workflow plugin from `case-solvers` to
`sdd`.** The repo is now `codxse/sdd`, the marketplace id and plugin id are both `sdd`, the plugin
directory moved `plugins/case-solvers/` → `plugins/sdd/`, and qualified invocations follow:
`$case-solvers:orchestrate` → `$sdd:orchestrate`, agent `case-solvers:case-reviewer` →
`sdd:story-reviewer`. The name now describes what the plugin is — spec-driven development — rather
than one of its six commands.

**BREAKING: `/case` → `/specify` and `/evaluate` → `/validate`.** Two of the six commands are renamed
for the same reason as the project: they now say what they do. `/refine`, `/board`, `/solve`, and
`/orchestrate` are unchanged, and **bd backlogs carry over untouched** — stories, labels, and
dependencies are unaffected. The transient authoring draft moved `.case.md` → `.spec.md`, and the
reviewer agents became `story-reviewer` / `story-reviewer-strong` — named for what they review (one
story branch) rather than for the command that spawns them. In the README's three-roles framing the
human role follows its command: the **evaluator** is now the **validator**, and `/orchestrate` joins
the architect, since it is frontier-gated and stands in for the human when nobody is watching.

**BREAKING: one three-rung model ladder, and the authoring gate is now frontier-only.** The plugin
ran two tier vocabularies that shared words — a binary `budget`/`planning` gate in
`shared/model-tiers.md`, and a ternary `budget`/`medium`/`frontier` complexity call in
`shared/contract-rubrics.md` that becomes the `solver-<tier>` label. Same top rung, two names, and no
middle rung on the gate, which left Sonnet-class models with nowhere to sit. There is now **one
ladder** — `budget` / `medium` / `frontier` — serving both consumers, with each rung defined by what
the model can hold rather than by price alone, and `planning` retired as a tier name (it describes the
*job* `/specify` does, never a rung).

The gate is a threshold on that ladder: `/specify`, `/refine`, and `/orchestrate` require
**`frontier`** and refuse `medium`. **This is a real tightening** — `sonnet`, `gpt-5.5`,
`gpt-5.6-terra`, and Gemini Pro-class models cleared the old `planning` gate and no longer do.
Authoring the WHAT is where a subtle error is paid for by every later solve. `/solve` carries no gate
and reports its rung; `/board` and `/validate` are ungated as before. Reviewer pinning retiered with
the ladder: `story-reviewer` is the **medium** rung (Claude `sonnet`, Codex `gpt-5.6-terra`),
`story-reviewer-strong` the **frontier** rung (`opus`, `gpt-5.6-sol`), and the binding floor is now
stated as "never below medium" — the never-a-budget-reviewer rule is unchanged.

**`Budget-Solver Fit` → `Atomicity Gate`.** The rubric was never about model cost — its own text said
it applies "regardless of which model runs `/solve`". It is a story-shape invariant, so it is now
named for the property it enforces and leads with why it exists: a vague story does not fail fast, it
gets *interpreted*, and every model interprets differently. That is the **ambiguity tax** —
hallucinated APIs, invented data models, rework cycles — and it is cheaper to pay once at authoring
time. *Atomic* is defined explicitly as **bounded** + **settled**, with a model-independent test:
two different models reading the contract would build the same thing; wherever their answers would
diverge, the story is not atomic yet.

Skill versions: `/specify` (`2.11.0` → `2.12.0`, and `skills/case/` → `skills/specify/`), `/validate`
(`1.15.1` → `1.16.0`, `skills/evaluate/` → `skills/validate/`), `/refine` (`1.10.0` → `1.11.0`),
`/solve` (`1.8.0` → `1.9.0`), `/orchestrate` (`1.6.0` → `1.7.0`), `/board` (`1.1.0` → `1.1.1`). The
three `model-guard.sh` harnesses now assert the refusal on `frontier model` rather than
`planning model`, and the Codex twin takes an `EXPECT_TIER` override so the guard can also be trialled
against a medium-rung model, not only a budget one.

**It is breaking for installs, not for usage.** Plugin id, marketplace id, and the host cache paths
all move, so an in-place `/plugin update` won't reach the new plugin — remove the old marketplace
and plugin and install fresh. GitHub redirects the old repo name, so an untouched marketplace entry
still resolves, but keeps serving the old id. See *Migrating from `case-solvers`* in the README.
Codex and Kimi Code users must also re-copy the reviewer agent files from their new paths.

Plugin & marketplace entry `2.25.1` → `3.0.0`, in all five manifests. `writing-claude-md` stays
`1.1.0` — only its `homepage`/`repository` URLs moved. The three host test libs
(`tests/{claude,codex,kimi}/lib.sh`) now resolve the `sdd` install; `tests/codex/model-guard.sh`
invokes `$sdd:<skill>`; CI runs the sync checks from `plugins/sdd/tests/`.

**Added Codex Model Guard coverage and host-authenticated model identity.**
`plugins/case-solvers/tests/codex/model-guard.sh` is now the third host twin: it runs `/case`,
`/refine`, and `/orchestrate` through explicit `$case-solvers:<skill>` mentions on the budget
`gpt-5.6-luna` model, asserts the exact `model-guard` classification as well as the refusal, and
checks that no contract, backlog, or epic branch was authored. The new Codex host helper resolves
and overlays the active installed cache before each run. A failing-first probe exposed the real
host gap: Codex's model-visible base prompt said only `GPT-5`, so Luna classified itself as planning
and authored. The default plugin `SessionStart` / `PreCompact` hook now reads Codex's
host-provided `model` field and injects that exact slug beside the existing workflow primer.

**Hardened all real-model test environments.** All three guard harnesses now launch their model CLI
through a minimal environment allowlist: this closes the diagnostic leak found when a failed Kimi
trial printed unrelated caller credentials while searching for its model ID. Kimi's existing host
limitation remains: its hook payload does not expose the active `-m` override, so occasional
misclassification from a mismatched `default_model` is reported as a probabilistic test failure.

Plugin & marketplace entry `case-solvers` `2.25.0` → `2.25.1`; no skill prose changed.

**New: `plugins/case-solvers/tests/kimi/model-guard.sh` — the Model Guard harness now covers Kimi
Code, and the tests tree is reorganized per host.** The Kimi twin asserts the same property as the
Claude harness (`/case`, `/refine`, `/orchestrate` must stop on a budget model, including the
override-injection descriptions) with the same trial protocol, on `kimi-code/kimi-for-coding`. Two
host differences are handled in the harness: under `kimi -p` a bare `/case` is sent to the model
verbatim (skills are only resolved via the explicit `/skill:<name>` form), and a budget Kimi session
will read a leftover `ANTHROPIC_MODEL` env var as its own ID — the harness strips the `ANTHROPIC_*`
vars so the tier classification rests on the Kimi session's own model. Sync target differs too:
Kimi's managed install is a whole-repo copy at `~/.kimi-code/plugins/managed/case-solvers/`, so
`tests/kimi/lib.sh` rsyncs the repo root there. The tests tree now groups by host:
`tests/claude/{model-guard,authoring-format}.sh` (moved, unchanged behavior) and
`tests/kimi/model-guard.sh` (new), with host-specific install/sync helpers in each host's `lib.sh`
and the host-agnostic pieces (`PLUGIN_ROOT`, `infra_error`) kept in `tests/lib.sh`. The sync scripts
(`tests/rubrics-sync.sh`, `tests/model-tiers-sync.sh`) are host-agnostic and stay put — CI paths
unchanged.

## [2.25.0] - 2026-07-23

Plugin & marketplace entry `case-solvers` `2.24.1` → `2.25.0`. `/case` (`2.10.1` → `2.11.0`),
`/refine` (`1.9.1` → `1.10.0`), `/orchestrate` (`1.5.1` → `1.6.0`), `/solve` (`1.7.1` → `1.8.0`),
`/evaluate` (`1.14.1` → `1.15.0`). New plugin component: `kimi.plugin.json` (repo root).

**Added: Kimi Code as a third host.** One manifest at the repository root, `kimi.plugin.json`,
makes the whole repo installable in Kimi Code CLI with a single
`/plugins install https://github.com/codxse/case-solvers`. Kimi's GitHub install reads the manifest
at the repo root only — there is no per-plugin granularity — so the root manifest declares both
skills trees (`plugins/case-solvers/skills/`, `plugins/writing-claude-md/skills/`) and ships both
marketplace plugins as one Kimi plugin named `case-solvers`. The skill bodies are unchanged: the
same shared `skills/` tree now serves three hosts. The Claude session-primer hook is ported into
the manifest's `hooks` (`SessionStart` + `PreCompact`, both supported by Kimi) using
`$KIMI_PLUGIN_ROOT`, which Kimi exports to plugin hooks.

**`shared/model-tiers.md`: Kimi K3-class joins the planning tier, K2-class / `kimi-for-coding` are
budget — and `/evaluate`'s reviewer-pinning branch list gets a Kimi branch.** `k3` / `kimi-k3…` IDs
classify as **planning**, so `/case`, `/refine`, and `/orchestrate` run on a K3 session; `kimi-k2`
joins the budget substring markers and Kimi Code's `kimi-for-coding` is named a budget tier, so
K2-class sessions (K2.5, K2.7) solve. The reviewer-pinning rules live natively in
`skills/evaluate/SKILL.md` since 2.24.1 (its sole consumer); there, native Kimi Code joins the
custom-frontier-host branch: on a planning (K3-class) session the reviewer runs on the session's
own model ID — one frontier rung, the same degradation a custom host already had — spawned as the
copied `case-reviewer` agent when the user has installed it (see below), else as a general
subagent; on a budget session there is no frontier model to pin, so the request-changes path stops
rather than review on a budget model. The tier markers sync into all five skills by
`tests/model-tiers-sync.sh --write`; no hand-edited blocks.

**Reviewer agents on Kimi Code via `~/.agents/agents/`.** Kimi plugins can't ship subagent
definitions, but Kimi's agent loader reads the Claude-format `agents/*.md` verbatim — it ignores
the `model:` pin and accepts the comma-separated `tools` string — so the README has Kimi users copy
the two reviewer `.md` files into `~/.agents/agents/` once, the same pattern as the Codex TOML
copy. With them listed, `/evaluate` spawns `case-reviewer` (reviewer prompt + narrowed tools from
the definition); the model is still the session's own, since Kimi has no per-agent model field, so
the K3-class requirement is unchanged.

Known host gaps, documented in the README: Kimi has no per-skill implicit-invocation gate (no
equivalent of Codex's `agents/openai.yaml`), so the slash-only rule for `/solve` and `/evaluate`
rests on the skills' own prose; and skills are invoked as `/skill:<name>` or in plain English —
there are no `/case`-style slash commands on this host.

## [2.24.1] - 2026-07-20

Plugin & marketplace entry `case-solvers` `2.24.0` → `2.24.1`. `/case` (`2.10.0` → `2.10.1`),
`/refine` (`1.9.0` → `1.9.1`), `/orchestrate` (`1.5.0` → `1.5.1`), `/solve` (`1.7.0` → `1.7.1`),
`/evaluate` (`1.14.0` → `1.14.1`).

**Changed: the shared model-tiers map no longer inlines reviewer-pinning into skills that never use
it.** `shared/model-tiers.md` bundled two things — **Tier classification** (needed by all five
skills, which each classify their own model) and **Reviewer pinning by host** (consumed only by
`/evaluate`) — and inlined the whole bundle into every skill. That put ~30 lines of `/evaluate`-voiced
reviewer-pinning instructions ("`/evaluate`'s request-changes path must…") into `/case`, `/refine`,
`/solve`, and `/orchestrate`, where they were both dead weight and addressed to the wrong skill.

The shared block now carries **Tier classification only**, still synced into all five skills by
`tests/model-tiers-sync.sh`. **Reviewer pinning by host** moved into `skills/evaluate/SKILL.md` as
native prose — `/evaluate` is its sole consumer, and its step 4b.1 already points at it — and the
redundant host table was dropped in favor of the capability-keyed branch list it duplicated. No
behavior change: the pinning logic is identical, just relocated and de-duplicated.

## [2.24.0] - 2026-07-20

Plugin & marketplace entry `case-solvers` `2.23.1` → `2.24.0`. `/case` (`2.9.1` → `2.10.0`),
`/refine` (`1.8.1` → `1.9.0`), `/orchestrate` (`1.4.1` → `1.5.0`), `/solve` (`1.6.0` → `1.7.0`),
`/evaluate` (`1.13.1` → `1.14.0`). New plugin component: `shared/model-tiers.md`.

**Added: support for Claude Code on a custom model (e.g. a router), and a single source of truth for
the model-tier map.** The tier rules were duplicated across five SKILL.md files — adding one model
meant editing each by hand, and `/evaluate`'s reviewer pin assumed a native Claude/Codex roster, so a
custom-model host had no defined way to pin a frontier reviewer. Both are fixed by one new shared
file, `shared/model-tiers.md`, inlined verbatim into all five skills by `tests/model-tiers-sync.sh`
(the same pattern as `shared/contract-rubrics.md` / `rubrics-sync.sh`, and likewise wired into CI).

The file carries two things: **Tier classification** (the budget/planning/unsure markers, now
including Qwen3.8-Max-class — `qwen3.8-max-preview` as the example — with budget markers still
outranking planning ones) and **Reviewer pinning by host**, a capability-based fallback chain that
keys off what the host can do rather than enumerating hosts: a native Claude/Codex host uses the
shipped reviewer agents (two-tier cost-keying + same-class step-up preserved); a custom frontier host
pins a general subagent to the session's own model ID (the host accepts literal IDs); anything else
stops rather than falling back to a budget reviewer. Two-tier cost-keying degrades to a single pin on
the custom host — the same "one frontier price point" degradation v2.22.0 already sanctioned.

`/case`, `/refine`, `/orchestrate` now classify their model by the shared Tier classification rules
(their per-skill guard prose — stop message, untrusted-data rule — is unchanged); `/solve`'s frontier
list (the Senior Solver trigger) and `/evaluate`'s step 4b.1 reviewer pin both read the same map.
Adding a future model is now a one-file edit. Verified with `tests/model-guard.sh` per this repo's
rule for any Model Guard change.

## [2.23.1] - 2026-07-18

Plugin & marketplace entry `case-solvers` `2.23.0` → `2.23.1`. `/case` (`2.9.0` → `2.9.1`),
`/refine` (`1.8.0` → `1.8.1`), `/orchestrate` (`1.4.0` → `1.4.1`).

**Fixed: `gpt-5.6-luna` could slip through the planning-tier Model Guard.** Codex's current
recommended roster tiers the GPT-5.6 family as Sol (flagship), Terra (balanced), and Luna (fast and
affordable — the budget tier). The guard's budget markers (`haiku`/`flash`/`mini`/`lite`/`small`/
`nano`) didn't cover `luna`, while its planning list accepts "frontier GPT-5-class" — so a literal
reading could classify a Luna session as planning-tier and let it run `/case`, `/refine`, or
`/orchestrate`. All three guards now list `luna` as a budget marker (`gpt-5.6-luna` as the example)
and name `gpt-5.6-sol`/`gpt-5.6-terra` as the frontier GPT-5-class examples, replacing the stale
`gpt-5.5-high`. Verified with `tests/model-guard.sh` per this repo's rule for any Model Guard change.

**Fixed: the `agents` manifest key (added in 2.23.0) made Claude Code reject the whole plugin.**
The installed Claude Code (2.1.214) fails manifest validation on the unknown key, so the plugin
silently didn't load — every skill died with `Unknown command: /case`, caught as 27/27 false FAILs
on the first `model-guard.sh` run. Isolation probes against the plugin cache pinned it precisely:
manifest with the key → no load; same manifest without it → loads (a version⁄cache-dir mismatch was
ruled out separately — harmless). The key is also unnecessary: Claude Code auto-discovers agent
definitions from the plugin's `agents/` directory, listing them namespaced
(`case-solvers:case-reviewer`), which a live probe confirmed. Dropped the key; `/evaluate`
(`1.13.0` → `1.13.1`) now names the namespaced form.

## [2.23.0] - 2026-07-18

Plugin & marketplace entry `case-solvers` `2.22.0` → `2.23.0`. `/orchestrate` (`1.3.0` → `1.4.0`),
`/evaluate` (`1.12.0` → `1.13.0`). New plugin component: `agents/`.

**Changed: `/orchestrate`'s mandatory review pass moved out of the per-story subagent into the
orchestrator's own control flow (step 5.3, alongside landing).** The dispatched subagent now runs
`/solve <id> --unattended` and nothing else — its job ends at `needs-review` or a stall. Previously
the subagent also ran `/evaluate --review --unattended`, whose reviewer spawn made the run's spawn
graph two levels deep — which fails outright on Codex (`agents.max_depth` defaults to `1`) and
already tripped Claude Code's flat-roster rule in a real run (a dispatched teammate tried to spawn
the reviewer as a named teammate and had to retry anonymously). Every spawn in a run is now depth
one on both hosts. Under `--parallel`, reviews queue in the orchestrator one at a time exactly like
landings already did — in the default serial mode nothing is lost at all.

**Added: shipped reviewer agent definitions, dual-format — the model pin moves from prose to the
harness.** `plugins/case-solvers/agents/` now carries `case-reviewer` (cheapest-frontier pin;
Claude: Sonnet / Codex: base GPT-5-class) and `case-reviewer-strong` (strongest; Claude: Opus /
Codex: its strongest GPT-5-class), each twice: `<name>.md` (Claude Code agent format, auto-discovered
from the plugin's `agents/` directory) and `<name>.toml` (Codex agent format — Codex plugins
don't auto-load agents yet, so the TOMLs are copy-installed into `.codex/agents/`, documented in the
README). Both formats carry the same instructions verbatim, mirroring the repo's two-manifests-one-
content pattern. `/evaluate` step 4b.1 now prefers these agents when the host lists them — the
frontier pin is then enforced by the agent definition rather than by prose exhortation ("pinning is
mandatory") aimed at whatever model happens to be running — and its `--unattended` tier-keyed rule
(v2.22.0) now selects *which agent* to spawn (`case-reviewer` for budget/medium, `-strong` for
frontier and same-class step-ups) instead of naming raw model ids. The prose pin survives as an
explicit fallback for installs without the agents, so nothing breaks on an older or partial setup.
Reviewer spawns are also now explicitly **anonymous** (never pass `name`): named teammates can't be
spawned from inside another agent — the flat-roster error observed in practice — and nothing needs
to address a one-shot reviewer after it reports.

## [2.22.0] - 2026-07-18

Plugin & marketplace entry `case-solvers` `2.21.0` → `2.22.0`. `/evaluate` (`1.11.0` → `1.12.0`),
`/orchestrate` (`1.2.0` → `1.3.0`).

**Changed: under `--unattended`, `/evaluate --review`'s reviewer model is tier-keyed to the story's
own `solver-<tier>` label instead of a flat strongest-model default.** An orchestrated ten-story epic
previously paid the strongest frontier reviewer (Opus on Claude) ten times, regardless of what each
story actually warranted — even though every story already carries a per-story cost call from the
Complexity Tier rubric. Review cost now keys off that same call twice, with no orchestrator judgment
in either dimension: **effort** (already wired — the `## Complexity` line's recommendation) picks the
review's depth, and **tier** now picks the reviewer's model — `solver-budget`/`solver-medium` →
the cheapest model on the host's frontier roster (Claude: Sonnet; Codex: its base GPT-5-class tier),
`solver-frontier` or unlabelled → the strongest (Claude: Opus; Codex: its strongest GPT-5-class).
Two guardrails: if the recorded assignee (the model class `/solve` wrote at claim time) is the same
class as the chosen reviewer, the pin steps up one — a model never reviews its own class's work —
and the frontier floor never moves: every choice stays on the frontier roster, so the existing
never-pin-a-budget-ID rule binds unattended runs identically. The rule is stated roster-relative,
never as hardcoded model names, matching the Complexity rubric's own "no model-ID pinning" principle
— so it holds on both hosts unchanged, and a host whose roster offers only one frontier price point
degrades to the old behavior rather than erroring. Interactive `--review` (a human approving one
story straight to trunk) keeps the flat strongest-reviewer default: the savings case is the
many-story unattended epic, not the single supervised review. Alternatives considered and rejected:
one big end-of-epic review instead of per-story (a bug landed early gets built on by every later
story — the same cascade economics the serial-dispatch change exists to avoid), and skipping review
for simple stories (a judgment call with no rubric, which the mandatory-review rule exists to keep
out of the orchestrator). The rule was validated behaviorally before landing — six dry-run trials
(mostly on Haiku, the worst case for instruction-following, per `model-guard.sh`'s philosophy) fed
agents the real SKILL.md plus fixture stories and checked which model they pinned: budget→Sonnet,
frontier→Opus, medium-solved-by-Sonnet→Opus step-up, and the no-`--unattended` control all held; the
one miss was a frontier trial misreading the step-up clause's "that same class" referent, and the
clause was reworded (explicit referent + an explicit budget-assignee-never-steps-up sentence) in
response.

## [2.21.0] - 2026-07-18

Plugin & marketplace entry `case-solvers` `2.20.0` → `2.21.0`. `/orchestrate` (`1.1.0` → `1.2.0`),
`/solve` (`1.5.0` → `1.6.0`), `/evaluate` (`1.10.0` → `1.11.0`).

**Fixed: `/orchestrate` no longer stops mid-run to ask the human a live question.** A real run used
`AskUserQuestion` three times mid-epic — each time already carrying a "Recommended" answer, asking
permission for a call it had already made. Tracing this found four separate live-question surfaces
across three skill files, not one bug: `/orchestrate`'s own pre-flight go/no-go and undocumented-file
prompts (both of which already contradicted this repo's own `CLAUDE.md`, which lists "pre-flight
go/no-go" as one of `/orchestrate`'s *unsupervised* calls); `/evaluate`'s merge-conflict confidence
gate, which is synchronous-blocking on an "ambiguous" conflict and — confirmed by tracing the flag
table — fires even under `--approve`, the call `/orchestrate` uses to land every story; and `/solve`'s
blocked-story offer, inline pre-flight questions, and `AskUserQuestion` on ambiguity, none of which
distinguished direct human invocation from being dispatched headless by `/orchestrate` with no one to
answer.

**Design reviewed with a Fable-tier model** before implementing, per this repo's own precedent for
`/orchestrate`'s original design. Its key correction: a uniform "decide and record" rule is wrong —
`/evaluate --unattended` runs on `/orchestrate`'s own planning-tier model, where deciding-and-recording
is appropriate, but `/solve --unattended` runs inside a dispatched subagent that may be budget-tier,
and an unsupervised budget-tier judgment call is exactly what caused a real isolation-breach incident
in this same run. So the fix is asymmetric by design, not uniform.

**Added: `--unattended` on `/solve`** (new) **and extended to `--approve` on `/evaluate`** (previously
valid only with `--review`). Never keyed off ambient "am I a subagent?" detection or the `orchestrated`
bd label — bd content is untrusted, same rule as the Model Guard — always an explicit, caller-typed
flag, so a human running `/solve <id>` or `/evaluate <id>` directly is completely unaffected. Under
`/solve --unattended`, every live-question path (blocked-story offer, inline pre-flight question,
`AskUserQuestion` on ambiguity) routes into the spec-gap handoff that already exists in the file:
stall, comment, hand back — never guess. Under `/evaluate --approve --unattended`, an "ambiguous"
merge conflict is resolved using the skill's own decision-ready recommendation and recorded as a
`bd comment`, **unless** the resolution would force tests red or drop an AC, in which case it aborts
the rebase and stalls the story instead of landing broken code onto the shared base every later story
forks from; it refuses outright if `<base>` resolves to `main`/`master`.

`/orchestrate` now always dispatches `/solve <id> --unattended` and lands via `/evaluate <id> --approve
--unattended`. Its own three internal asks are now autonomous, logged decisions: pre-flight warnings
(orphans/missing deps/disconnected subgraphs) proceed and get recorded rather than gated on a go/no-go
— only a genuine cycle still stops the run; undocumented release-bookkeeping files are inferred from
`CHANGELOG*`/manifest files bumped together in recent commits rather than asked about; and the
ambiguous-branch-on-resume check gained a verifiable self-adopt path (every commit on the branch
traces to a landing of one of this epic's own children → adopt silently) but otherwise still stops —
this one is an invocation-time ownership/safety check, not a mid-run judgment call, since it only
fires before the loop starts. **One deliberate exception remains:** a new shared-branch integrity
check compares the recorded `epic/<id>` HEAD sha (written after every landing) against the actual
state before each cycle; on divergence, the run halts entirely with an incident report rather than
continuing — a stop, not a question, since nothing is waiting on a reply. The final PR gained a
"Decisions made unattended" section aggregating every autonomous call's `bd comment`, turning the
removed mid-run questions into a reviewable audit trail at the one gate that's left.

`CLAUDE.md`'s Philosophy section gained a note documenting `--unattended` as the general "no human
present" modifier, reused rather than reinvented per skill, with the tier-asymmetric meaning above.

## [2.20.0] - 2026-07-18

Plugin & marketplace entry `case-solvers` `2.19.1` → `2.20.0`. `/orchestrate` (`1.0.1` → `1.1.0`).

**Changed: `/orchestrate`'s readiness loop dispatches one story at a time by default; a new
`--parallel` flag opts back into the previous behavior of dispatching a whole ready wave at once.**
Running an epic's independent-looking stories concurrently sounded like the obvious win, but in
practice two stories solved from the same `epic/<id>` snapshot routinely touched the same files;
landing them one after another (still serialized through `merge-slot`, per the design) then forced
the second to conflict against the first's own fix of that same conflict, and so on — a cascade that
burned more tokens resolving conflicts than the stories cost to run one at a time in wall-clock time.
Serial-by-default removes the mechanical cause: the next story is only dispatched after the previous
one has landed, so its worktree always forks from a snapshot that already has the prior story's
changes on it, never one that's about to go stale underneath it. `--parallel` stays available for
epics whose stories are known to touch disjoint files/modules, where the wall-clock win is real and
the conflict risk this default exists to avoid doesn't apply. Pre-flight's reported ready
fronts/estimated worker-sessions/max parallelism are unchanged — still shown so the user can judge
whether `--parallel` is worth passing for a given epic, just no longer acted on automatically.

## [2.19.1] - 2026-07-18

Plugin & marketplace entry `case-solvers` `2.19.0` → `2.19.1`. `/orchestrate`
(`1.0.0` → `1.0.1`) is now model-invocable in Codex as well as explicitly invocable. Its Codex
`agents/openai.yaml` explicit-only override was removed; the planning-tier Model Guard and the
provisional-branch/final-PR human gate remain unchanged. The README now documents explicit
namespaced invocation and the two-step Codex plugin upgrade command.

## [2.19.0] - 2026-07-18

Plugin & marketplace entry `case-solvers` `2.18.0` → `2.19.0`. New skill **`/orchestrate`**
(`1.0.0`). `/evaluate` (`1.9.0` → `1.10.0`).

**Added: `/orchestrate <epic-id>` automates the story-by-story `/solve` → review → land loop for
one epic, collapsing today's manual "solve one, evaluate one, repeat" cycle into a single run with
exactly one human gate at the end.** It checks out (or resumes) an integration branch `epic/<id>` —
forked from whatever's checked out in the main worktree, never a hardcoded trunk, the same rule
`/solve`/`/evaluate` already follow — and keeps the main worktree on it for the whole run, so every
dispatched `/solve` naturally forks from it and every landed story naturally merges back onto it,
with zero changes to `/solve` or `/evaluate`'s own base-branch logic. Each cycle it reads the
epic's live readiness (`bd swarm status`) and dispatches `/solve` in parallel across every ready
story, model-pinned per story to its own `solver-<tier>` label — the first place the Complexity
Tier recommendation is actually acted on automatically, not just displayed for a human to read.
Once a story reaches `needs-review` it always goes through a mandatory, orchestrator-judgment-free
review pass at the effort its own `## Complexity` section recommends, then lands one at a time
through bd's own `merge-slot` primitive — the lock bd ships specifically to stop concurrent landers
from cascading conflicts into each other. A spec-gap or scope observation surfaced mid-run is never
acted on by `/orchestrate` itself — authoring or revising a contract stays the human's call via
`/case`/`/refine`; the run queues it for the final report instead. `/orchestrate` itself now also
requires a **planning model**, the same Model Guard `/case` and `/refine` carry — it runs
unsupervised for most of an epic (pre-flight go/no-go, stalled-story triage, the final PR's
summary), which is exactly the kind of judgment this workflow otherwise reserves for a frontier
tier. To keep the near-certain class of
conflict this repo's own history is full of (virtually every skill-editing story touches the same
four version manifests and `CHANGELOG.md`) out of the merge-slot machinery entirely,
`/orchestrate` tells every dispatched story to leave those files alone and performs the one
epic-level version bump + changelog entry itself, once, at the end. The run finishes by opening
**one PR, `epic/<id>` → the branch it was forked from** — each story already its own single commit
(`--approve`'s existing one-commit rule), so the PR reads story-by-story rather than as one
rubber-stampable diff — and that PR is the **only** real human-loop gate: everything on `epic/<id>`
before it is provisional until it merges. `/orchestrate` is slash-only (`agents/openai.yaml`,
`allow_implicit_invocation: false`), the same classification as `/solve` and `/evaluate` — it
transitively fires both, so it inherits their blast radius.

**Added: `/evaluate --review [effort] --unattended`.** The existing `--review` fast path still
hard-stops at step 4b.3 for a human "amend these into `bd/<id>`?" confirm — exactly the per-story
pause `/orchestrate` exists to remove from its own loop. Rather than fork the review-and-apply
mechanism into `/orchestrate` too, `/evaluate` gains one modifier: `--unattended` still spawns the
frontier-pinned subagent, runs `/code-review <effort> --fix`, and shows what changed — it just
replaces the human go-ahead with an automatic one. The name is deliberately explicit rather than a
terse `--auto`: this flag skips `/evaluate`'s own core safety property, so its use is meant to be
provisional (an epic integration branch, not `master`/`main`) with a real human review still coming
later, at the epic's final PR — never for a human approving straight to trunk.

This design was reviewed twice by a Fable-tier model before implementation. The first pass caught
that autonomously running `/evaluate --approve` per story contradicts the repo's own human-loop
principle unless landings happen on a reversible branch with a real gate at the end, that "judge
whether review is needed" has no rubric and is exactly the judgment `/evaluate` exists to keep
human, and that autonomous `/case` mid-loop breaks the "nothing commits to bd until the user
confirms" guard. The second pass, after the user pushed back on blanket serialization (bd already
tracks dependencies — independent stories should run in parallel), found that `/evaluate`'s own
step 4a.4 already implements the exact conflict-handling pattern the design was about to reinvent,
and proposed removing the mechanical conflict class by construction instead of auto-resolving it.
Planning research on top of both reviews then found that bd itself already ships the
`swarm`/`merge-slot` primitives this design needs, letting `/orchestrate` end up thinner than any
draft that preceded it. The Model Guard requirement was added after implementation, at the user's
own direction, for parity with `/case`/`/refine`'s existing gate.

## [2.18.0] - 2026-07-18

Plugin & marketplace entry `case-solvers` `2.17.1` → `2.18.0`. `/case` (2.8.1 → 2.9.0), `/refine`
(1.7.1 → 1.8.0), `/board` (1.0.0 → 1.1.0), `/solve` (1.4.1 → 1.5.0), `/evaluate` (1.8.0 → 1.9.0).

**Added: a `Complexity Tier` rubric judges story difficulty and recommends a solver tier.**
`Budget-Solver Fit` already gates *scope and ambiguity* — every story reaching bd fits a budget
solver's working set, or it's decomposed/settled until it does. But a story can pass that gate and
still call for more reasoning capability than raw execution — auth/crypto surfaces, concurrency,
non-obvious algorithms, subtle library semantics, a refactor across an unfamiliar pattern. The new
rubric is a separate axis, judged only after Budget-Solver Fit passes: it recommends the cheapest
tier + effort combination likely to succeed (`budget`/`medium`/`frontier` × `low`/`medium`/`high`/
`max`), recorded as a `## Complexity` section in the story body and a `solver-<tier>` bd label for
board-table visibility. `medium` is a relative call, not a new Model Guard bucket — it means the
cheaper end of the planning roster (e.g. Sonnet over Opus) or the strongest end of the budget roster,
whichever middle option a given setup offers; the existing budget/planning classification in `/case`
and `/refine` is untouched. Escalation follows the signal: a *volume* signal (long AC list, wide file
surface) raises effort within the current tier; a *subtlety/blast-radius* signal (the difficulty
signals above) raises tier instead — more effort on a weaker model doesn't close a capability gap.
Purely informational — nothing enforces the recommendation; the human still picks which model runs
`/solve <id>`.

**Fixed: `/solve`'s frontier-cost warning no longer contradicts a story's own recommendation.** The
warning previously fired on any frontier-tier run regardless of the story, which meant a story
correctly labelled `solver-frontier`, solved deliberately on a frontier model, still got told "you're
expensive, consider downgrading" — two advisories disagreeing on the same decision. The check now
runs once the story is resolved (`/solve` step 1) and reads its `solver-*` label first; it's silent
when the label already says `frontier`, unchanged otherwise.

**Added: an optional calibration note at `/evaluate`.** Nothing previously checked whether a tier
recommendation was actually right — `/refine` only re-grades after a hard failure (a `/solve`
spec-gap bounce). On the full interactive approve flow (not the `--approve`/`--review` fast paths),
`/evaluate` now optionally asks whether the recommended tier matched how the story actually went and
records the answer as a `bd comment` — a data point for judging the rubric's accuracy over time, not
a gate.

This design was reviewed by a Fable-tier model before implementation, which caught that the original
draft's `medium` tier had no concrete referent, that its effort-before-tier escalation rule was
backwards for the exact signals the rubric names, and the `/solve` warning contradiction above — all
three are reflected in the final rubric rather than the first draft.

## [2.17.1] - 2026-07-17

Plugin & marketplace entry `case-solvers` `2.17.0` → `2.17.1`. `/case` (2.8.0 → 2.8.1), `/refine`
(1.7.0 → 1.7.1).

**Changed: the `Budget-Solver Fit` rubric now splits its signals along two labeled axes.** The
section's checklist was headed "Too-large signals", but two of its bullets — an AC that forces an
unsettled design decision, and a bugfix whose root cause isn't reproduced — are not size signals at
all; they are *ambiguity* signals (a gap in the middle of an otherwise-small story). Filed under a
"too-large" heading, an author sizing a small-but-ambiguous story could correctly conclude "not too
large" and skip past exactly the two checks that most reliably make a budget solver drift. The
signals are now two groups — **Too big (scope)** (→ decompose or split) and **Unsettled middle
(ambiguity)** (→ settle in the contract or split out) — under an opening line that names both axes as
co-equal ("scope is bounded *and* nothing inside is left undecided"). The INVEST line's mapping is
corrected to match: **E**stimable now carries the ambiguity axis, **S**mall the scope axis. Rubric
wording only — the section name is unchanged, so nothing else references break.

**Changed: the `both` Verification mode is renamed `auto+human`, and its definition now states the
action, not just the composition.** `both` is relational — it means nothing until the other two modes
are memorized — and the token travels into a story body, where the budget solver reading it never sees
the rubric that defines it. `auto+human` names its own constituents, so it reads clearly wherever it
appears. Its definition moves from "has a machine-assertable part AND an experiential part" to the
resulting split: the solver auto-verifies the assertable part and spells out the experiential part for
a person to exercise at `/evaluate`. Unlike the rename-free change above, `/solve` and `/evaluate`
cite the mode by name *outside* the shared rubric block, so their `` `human`/`both` `` call sites were
updated by hand to `` `human`/`auto+human` ``.

**Docs: `CLAUDE.md` gains the caveat those hand-edits taught.** `rubrics-sync.sh --write` propagates
only the shared block, so a rubric edit that renames a token other skills cite in their own prose (the
`auto+human` rename is the worked example) needs those call sites fixed by hand — the sync still
reports green while the skills drift out of step with the rubric.

## [2.17.0] - 2026-07-17

Plugin & marketplace entry `case-solvers` `2.16.0` → `2.17.0`. `/case` (2.7.1 → 2.8.0), `/refine`
(1.6.1 → 1.7.0).

**Fixed: the shared rubrics are now inlined, not read at runtime.** `/case` and `/refine` pointed at
`shared/contract-rubrics.md` by relative path (`../../shared/...`). That path can never resolve: the
Read tool resolves a relative path against the **user's working directory**, not the SKILL.md's own
directory, so in any real project it became `<parent-of-project>/shared/contract-rubrics.md` and
errored with `File does not exist`. The skills' own fallback ladder then sent the model to a Bash
`find` across the plugin cache — which is what produced a permission prompt on every `/case`, and, on
a bad run, authoring from memory of the rubrics instead of the file.

Everything below the `BEGIN SHARED` marker in `shared/contract-rubrics.md` is now inlined verbatim
into a `Contract Rubrics` section at the end of both SKILL.md files. All path-resolution prose and the
`find` fallback are gone; there is no file to locate, so nothing can mis-resolve and nothing prompts.

The rubrics are a hard gate — every invocation loads them — so a separate file never saved context;
it only bought a fragile path. `${CLAUDE_PLUGIN_ROOT}`, which Claude Code substitutes inline in skill
content, would have fixed this on Claude Code alone, but Codex does not substitute it and the repo's
rule is one skill body per host. Inlined text needs no host contract at all.

**New: `tests/rubrics-sync.sh`** keeps the two inlined copies byte-identical to the source. No flag
verifies and exits non-zero on drift; `--write` regenerates. It never calls a model — a pure text
comparison, fast and deterministic.

**New: CI (`.github/workflows/checks.yml`)**, the repo's first. It runs `rubrics-sync.sh` on push to
`master` and on every PR. Inlining moved the failure mode from loud to silent: the old bug prompted on
every `/case`, whereas stale inlined rubrics would look completely normal while the skills authored
against out-of-date bars. Both hosts install this plugin by copying the repo — there is no build step
between a commit and a user's machine — so drift on `master` is drift that ships, and CI is the only
place a gate can stand. The model-calling tests (`model-guard.sh`, `authoring-format.sh`) stay manual:
slow, probabilistic, credentialed.

**Changed: the story line in the Output Format template is now a fenced code block.** `As a / I want /
so that` previously relied on blank lines between the three lines to keep them apart; they now sit in
a fence, the same device the `gherkin` block already uses, for the same reason — bare lines collapse
into one paragraph when rendered.

**Removed: `tests/rubric-read.sh`.** It existed solely to assert the model achieved a non-error Read
of `contract-rubrics.md` — a slow, probabilistic test of the very mechanism this release deletes.

**Docs.** `README.md` install section now covers both hosts properly: verified Codex syntax
(`codex plugin list`, `codex plugin marketplace upgrade` — not `update`), how to check the install on
each host, updating, and which commands are slash-only on Codex. Dropped the "install the plugin, not
loose skill folders" warning — with the rubrics inlined, a `skills/<name>/` copy no longer breaks
`/case` and `/refine`.

## [2.16.0] - 2026-07-17

Plugin & marketplace entry `case-solvers` `2.15.2` → `2.16.0`.

**New: session-start / pre-compact primer hook.** `plugins/case-solvers/hooks/hooks.json` now ships
with the plugin (Claude Code only — hooks aren't part of the shared `skills/` tree) and fires on
`SessionStart` and `PreCompact`, printing `hooks/session-primer.md`: a one-screen cheat sheet of
when to reach for `/case`, `/refine`, `/solve`, `/evaluate`, and `/board`. Keeps the workflow
top-of-mind across long sessions and survives context compaction, without querying live `bd` state.

## [2.15.2] - 2026-07-17

Plugin & marketplace entry `case-solvers` `2.15.1` → `2.15.2`. (`/case` `2.7.0` → `2.7.1`, `/refine`
`1.6.0` → `1.6.1`.)

**Story-line template now breaks across three lines.** The shared `Output Format` template in
`contract-rubrics.md` renders the opening `As a / I want / so that` statement as three one-line
paragraphs (blank-line separated) instead of one run-on sentence, for readability — still compliant
with the existing "no hard-wrap, one paragraph per line" rule since each clause is its own unbroken
paragraph.

## [2.15.1] - 2026-07-13

Plugin & marketplace entry `case-solvers` `2.15.0` → `2.15.1`. (`/solve` `1.4.0` → `1.4.1`.)

**Senior Solver exploration now selects for role fit, not lowest price.** The shared `/solve` prose
now tells both hosts how to keep codebase paging out of the senior solver's decision context:
Claude Code dispatches its `Explore` agent on Haiku, while Codex dispatches its built-in `explorer`
agent; a host without named roles may give the same bounded brief to a general subagent. The task is
explicitly read-only — search, inspect, and report, with no edits, implementation, or mechanism
decisions — and uses the model suited to read-heavy exploration rather than whichever model is
merely cheapest. A host with no subagents still explores inline from Files of Interest.

## [2.15.0] - 2026-07-13

Plugin & marketplace entry `case-solvers` `2.14.0` → `2.15.0`. (`/solve` `1.3.0` → `1.4.0`.)

**`/solve` now adapts to the model running it without ever growing the ticket.** The Cost Guard
becomes a **Model Check** that derives two things from the system prompt's model ID: the solver's
short class name (`haiku`, `opus`, `fable`, `gpt-5.6-sol`, …) — now used as the bd assignee at claim
time instead of the hardcoded `claude`, so the story records which model picked it up — and the
tier. A frontier tier still gets the one-time cost warning, but continuing now puts the new
**Senior Solver rules** in effect: same scope, better craft (extra capability goes into quality
*within* the AC, never into features or abstractions the contract doesn't ask for — the junior's
ticket doesn't grow for the senior); exploration is delegated to a read-only subagent on the
cheapest tier the host offers (Claude Code: `Explore` on Haiku), seeded with Files of Interest and
the concrete questions to answer, rather than paging through the codebase on frontier tokens; and
out-of-scope observations — adjacent bugs, contract ambiguities, worthwhile refactors — are
reported, never fixed. The step-6 review handoff gains an optional **Recommendations** section
(one line each, explicitly *not implemented*) so the reviewer can address each item at `/evaluate`
or file it as a separate story.

## [2.14.0] - 2026-07-13

Plugin & marketplace entry `case-solvers` `2.13.0` → `2.14.0`. (`/case` `2.6.0` → `2.7.0`,
`/refine` `1.5.0` → `1.6.0`.)

**AC steps are now declarative and third person, per Cucumber's Better Gherkin guidance.** The AC
Quality Rubric gains a **Declarative** bar: steps state business-level actions naming the story
line's actor — never "I", never UI mechanics ("clicks the button", "types into the field") — with
the litmus test *wording that must change when the implementation changes → rework*. Specific
values deliberately stay (a divergence from Cucumber's fully-declarative style, which relies on
step definitions to hold the details; these scenarios have none — a budget solver derives tests
directly from them, so hiding values would force it to invent them). The Pre-write Guard checks the
new bar. Also fixed the Codex marketplace (`.agents/plugins/marketplace.json`): its plugin entries
carried no `version` field, so Codex installs couldn't be tied to a release — both entries now
version in lockstep with the other three manifests.

## [2.13.0] - 2026-07-13

Plugin & marketplace entry `case-solvers` `2.12.0` → `2.13.0`. (`/case` `2.5.0` → `2.6.0`,
`/refine` `1.4.0` → `1.5.0`.)

**Stories now carry the Cucumber user-story Who/What/Why, and AC blocks open with a `Feature:`
title.** The shared contract rubrics gain two authoring principles: **Who, What, Why** — the Problem
Statement must open with the story line `As a <actor>, I want <what>, so that <why>` (actor by
problem type: Feature/Design — who gets the capability; Bugfix — who the failure blocks; Refactor —
who maintains the code; Investigation — who the findings inform) — and **INVEST** (Independent,
Negotiable, Valuable, Estimable, Small, Testable), each letter mapped to the rubric section that
enforces it. The AC `gherkin` block now opens with a `Feature:` line titling the behavior under
test, also named by problem type (Bugfix titles the behavior being *restored*, never the bug;
Refactor the behavior preserved; Investigation the question answered); related scenarios may group
under `Rule:` lines and repeated steps over many values become a `Scenario Outline` with an
`Examples` table. The Pre-write Guard checks both additions (missing/vague story line → name the who
and why; missing `Feature:` title → add it), and `tests/authoring-format.sh` asserts a drafted story
contains the story line and the `Feature:` title. Goal: any reader — human or budget model — parses
the same who, what, and why from every story.

## [2.12.0] - 2026-07-12

Plugin & marketplace entry `case-solvers` `2.11.0` → `2.12.0`. (`/solve` `1.2.0` → `1.3.0`,
`/evaluate` `1.7.0` → `1.8.0`.)

Fixed Codex discovery of the explicit-only `/solve` and `/evaluate` skills. Their shared
frontmatter now uses the Codex-compatible `disable-model-invocation: false`, while their
`agents/openai.yaml` files continue to enforce explicit invocation with
`policy.allow_implicit_invocation: false` and now provide the required short descriptions. The
Codex plugin manifest also includes the required long description, default prompt, and capability
metadata.

## [2.11.0] - 2026-06-26

Plugin & marketplace entry `case-solvers` `2.10.0` → `2.11.0`. (`/solve` `1.1.0` → `1.2.0`,
`/evaluate` `1.6.0` → `1.7.0`.)

**Story worktrees now live inside the repo at `.worktree/<id>`, not at the sibling
`../<repo>-worktrees/<id>`.** The sibling location put each worktree outside the project root —
often on a different filesystem or permission scope (or under `/tmp`), which is what produced the
recurring permission errors during `/evaluate`. `/solve` now creates the worktree at `.worktree/<id>`
under the repo root, so it shares the project's filesystem and permissions, and `/evaluate` reads,
reviews, amends, and cleans up at the same path. To keep the main worktree's `git status` clean,
`/solve` appends `.worktree/` to `.git/info/exclude` before creating the worktree — local and
idempotent, leaving the tracked `.gitignore` untouched (no stray uncommitted change on the base
branch). Existing sibling worktrees from older runs are unaffected; the new path applies to
worktrees created from this version on.

## [2.10.0] - 2026-06-26

Plugin & marketplace entry `case-solvers` `2.9.0` → `2.10.0`. (`/case` `2.4.0` → `2.5.0`, `/refine`
`1.3.0` → `1.4.0`.)

**The shared-rubrics read is now a fail-loud gate, not a silently-skippable hint.** `/case` and
`/refine` pointed at `shared/contract-rubrics.md` by relative path (`../../shared/...`); a planning
model would often miscount the `..` levels, Read `skills/shared/contract-rubrics.md` (which does not
exist), get *File does not exist*, and then author the contract from memory — the rubric effectively
skipped with no visible error. Both skills now spell out the path explicitly (two levels up: out of the
skill folder, out of `skills/`, into `shared/`) and make the read a **hard gate**: on a Read error the
skill must re-resolve or `find` the file and retry — never fall back to memory. New regression harness
`plugins/case-solvers/tests/rubric-read.sh` runs `/case` on a planning model and, by inspecting the
tool stream, asserts a **non-error** Read of `contract-rubrics.md` actually happened (the existing
`authoring-format.sh` only graded output shape, which a model can fake from memory).

## [2.9.0] - 2026-06-24

Plugin & marketplace entry `case-solvers` `2.8.0` → `2.9.0`.

**`/evaluate` now always runs `bd show <id>` before making any claim about a story's state.** The previous wording of step 1 let the agent substitute session context or the bd status field for an actual story read — it would see an `in_progress` bd status (which is normal for a story `/solve` has finished) and incorrectly stop with "story is not done." The fix makes `bd show <id>` mandatory with no skip condition, and explicitly separates bd status from labels: `needs-review` is a label, and `in_progress` status alongside a `needs-review` label is the expected output of a finished `/solve` run in a separate session.

### Changed
- `/evaluate` (`v1.5.0` → `v1.6.0`): step 1 rewritten — `bd show <id>` is mandatory before any verdict; `needs-review` check is now explicitly on the **labels** field, not the bd status; story with status `in_progress` + label `needs-review` is documented as normal.

## [2.8.0] - 2026-06-19

Plugin & marketplace entry `case-solvers` `2.7.0` → `2.8.0`. (`/case` `2.3.0` → `2.4.0`, `/refine`
`1.2.0` → `1.3.0`.)

**Contract prose is now written unwrapped — one line per paragraph.** Authored stories used to hard-wrap
Problem Statement / Context / Constraints prose at a column width. That reads fine in a text editor but
leaves stray line breaks when the contract is pasted into a tool that soft-wraps (Basecamp, Linear,
GitHub), forcing manual cleanup. The shared **Output Format** now requires each prose paragraph to be a
single unbroken line, and the **Pre-write Guard** flags hard-wrapped prose so the self-audit joins it
before commit. Markdown and `bd show` already soft-wrap a long line, so nothing changes on screen. The
fenced `gherkin` AC block is the sole exception — its internal line breaks are still preserved verbatim.
Affects both `/case` and `/refine`, which share `shared/contract-rubrics.md`.

## [2.7.0] - 2026-06-19

Plugin & marketplace entry `case-solvers` `2.6.0` → `2.7.0`. (`/case` `2.2.0` → `2.3.0`, `/refine`
`1.1.1` → `1.2.0`.)

**A story must now state WHY, not just WHAT.** The contract template always asked the Problem
Statement for "why it must be solved," but nothing enforced it — a story could pass the whole rubric
with only problem + outcome. The shared **Pre-write Guard** now flags a Problem Statement missing the
why and requires it added, so the authored contract matches how the workflow is described: a story is
**WHAT and WHY**, never HOW. Affects both `/case` (new stories) and `/refine` (revisions), which share
`shared/contract-rubrics.md`.

## [2.6.0] - 2026-06-18

Plugin & marketplace entry `case-solvers` `2.5.0` → `2.6.0`.

**`/case` is now model-invocable — a plain-English ask reaches it, not just the slash command.** Saying
something like "let's put our problem to a case" now routes to `/case` instead of requiring you to type
`/case`. It stays safely backstopped: the planning-tier **Model Guard** still runs first and nothing is
written to bd until you confirm, the same guards that let `/refine` be model-invocable. The
description gained trigger phrasing so the model knows when to fire. This moves `/case` out of the
slash-only group (now just `/solve` and `/evaluate`, which bake work into a branch) and the philosophy
note in CLAUDE.md was updated to match.

### Changed
- `/case` (`v2.1.1` → `v2.2.0`): dropped `disable-model-invocation` (Claude) and removed its
  `agents/openai.yaml` (`allow_implicit_invocation: false`, Codex), so it's implicitly invocable on
  both hosts; description now carries invocation triggers.
- `CLAUDE.md`: "Invocation tracks blast radius" bullet rewritten — slash-only is now `/solve` +
  `/evaluate`; `/case` joins `/board`/`/refine` as model-invocable, backstopped by Model Guard +
  confirm-before-write.

## [2.5.0] - 2026-06-18

Plugin & marketplace entry `case-solvers` `2.4.0` → `2.5.0`.

**A story now lands back on the branch it was forked from — not hardcoded `main`.** `/solve` used to
fork every worktree off `main` and `/evaluate --approve` merged it back to `main`, so work started on a
feature branch like `my-branch` still landed on the trunk. Now `/solve` forks `bd/<id>` off the repo's
**current active branch** (`<base>` — `main`, `master`, or a feature branch, whatever is checked out)
and records that base in its review handoff; `/evaluate --approve` reads `<base>`, checks the main
worktree out to it, and rebases + fast-forward-lands the story there. Older stories with no recorded
base fall back to the branch currently checked out in the main worktree. (`--note` to skip landing is
unchanged.)

### Changed
- `/solve` (`v1.0.2` → `v1.1.0`): forks the worktree off the current active branch instead of
  hardcoded `main`, and records **Base branch:** in the review handoff comment.
- `/evaluate` (`v1.4.0` → `v1.5.0`): approve path resolves the story's base branch (recorded handoff,
  or the main worktree's current branch) and lands on it; description, step 4a, and bd/git map updated.

## [2.4.0] - 2026-06-18

Plugin & marketplace entry `case-solvers` `2.3.2` → `2.4.0`.

**`/evaluate --approve` now lands the story as one linear commit — no merge commit.** Approving a
story used to run a plain `git merge bd/<id>`, which produced a second "Merge bd/<id>" commit on the
target branch whenever the branch had fallen behind. Step 4a now **rebases `bd/<id>` onto the target
and fast-forwards it in** (`git merge --ff-only`), so the story's own commit is the only thing that
lands. The conflict confidence gate now fires on *rebase* conflicts (same clear-vs-ambiguous logic),
and `--ff-only` is the guardrail against silently falling back to a merge commit.

### Changed
- `/evaluate` (`v1.3.1` → `v1.4.0`): approve path rebases then fast-forward-merges instead of a plain
  merge; bd/git map and conflict gate updated to match.

## [2.3.2] - 2026-06-17

Plugin & marketplace entry `case-solvers` `2.3.1` → `2.3.2`.

**Fix: `/case` and `/refine` now properly include the shared contract rubrics in agent context.**
The shared rubric file (`contract-rubrics.md`) was referenced in the skill instructions but without
the `@` prefix required by the plugin harness for file inclusion. Agents were instructed to read it
but the harness wasn't providing its contents, preventing them from following the rubrics.

### Changed
- `/case` (`v2.1.0` → `v2.1.1`): added `@` prefix to shared rubric reference to enable file inclusion.
- `/refine` (`v1.1.0` → `v1.1.1`): added `@` prefix to shared rubric reference to enable file inclusion.

## [2.3.1] - 2026-06-17

Plugin & marketplace entry `case-solvers` `2.3.0` → `2.3.1`.

**Fix: `/evaluate --review` now reliably dispatches the reviewer on a frontier model (Opus by
default) instead of inheriting `/evaluate`'s ambient model.** When `/evaluate` itself ran on a budget
model (e.g. Haiku), the request-changes subagent was inheriting that budget model — the `/code-review`
pass ran on Haiku despite the intent to pin it. The instruction offered a vague "`sonnet` or `opus`"
choice with no concrete spawn shape, so the model argument was often left unset.

### Changed
- `/evaluate` (`v1.3.0` → `v1.3.1`): the request-changes (and `--review [effort]`) path now makes
  frontier pinning **mandatory and concrete** — the subagent spawn must set its `model` argument
  explicitly, defaulting to **`opus`** (`Agent(subagent_type: …, model: "opus", …)` on Claude Code;
  frontier GPT-5-class on Codex), with `sonnet` only as a fallback when Opus is unavailable. Inheriting
  the ambient model or running the review inline on `/evaluate`'s own model is now explicitly
  prohibited; a budget ID is never pinned. Effort still passes through to `/code-review` (default
  `high`).

## [2.3.0] - 2026-06-16

Plugin & marketplace entry `case-solvers` `2.2.0` → `2.3.0`.

**`/evaluate` request-changes now fixes in place via a frontier-pinned `/code-review` subagent
instead of bouncing work back to `/solve`.** When the implementation needs work but the contract is
sound, `/evaluate` spawns a subagent **with its model pinned to a frontier tier** (Sonnet/Opus on
Claude, GPT-5-class on Codex — the same IDs the `/case` Model Guard treats as planning), runs
`/code-review <effort> --fix` against the story's worktree inside it, then **shows the human the
reviewer's applied diff and amends `bd/<id>` only after an explicit confirm** — and re-opens the diff
for another verdict. The story never leaves `needs-review`. The reviewer is frontier regardless of
what model `/evaluate` itself runs on; the amend is mechanical and stays in `/evaluate`, gated on the
human's go-ahead. A wrong *contract* still routes to `/refine`. This shifts review-time code
fixes onto the review tier; greenfield implementation stays `/solve`'s job (CLAUDE.md single-writer
discipline updated to match).

### Changed
- `/evaluate` (`v1.2.0` → `v1.3.0`): **replaced** the `--request-changes` /
  `--request-changes --note <text>` flags with **`--review [effort]`** — a fast-path that runs the
  `/code-review` pass straight away at `effort` (default `high`; any `/code-review` level), applies
  fixes in place, shows the applied diff, and amends the branch **only after the human confirms**.
  The review-and-apply runs in a subagent **pinned to a frontier model** (`/evaluate` has no model
  gate of its own, so the reviewer's tier is pinned explicitly, never inherited); if no frontier model
  is available to pin, it stops rather than review on a budget model. `--review` always takes the implementation path; a wrong *contract* still routes
  to `/refine` via the interactive flow. `--note <text>` now steers the reviewer (e.g. "focus on …")
  in addition to annotating the story. `--approve` / `--approve --note <text>` and the interactive
  flow are unchanged. A **Host note** documents the Codex equivalent (run that host's review-and-apply
  command in the same pinned-frontier subagent against the same worktree, then amend identically).
- `/solve` (`v1.0.1` → `v1.0.2`): the "resuming" note now covers an existing `bd/<id>` branch in
  general (a contract sent back via `/refine`, or earlier in-progress work) and clarifies that
  implementation-only review fixes no longer return here — `/evaluate` applies those in place.

## [2.2.0] - 2026-06-14

Plugin & marketplace entry `case-solvers` `2.1.0` → `2.2.0`; `writing-claude-md` `1.0.0` → `1.1.0`.

**Dual-host: the same skills now run on OpenAI Codex as well as Claude Code.** Codex's plugin layout
mirrors Claude's, so the `skills/<name>/SKILL.md` tree is shared verbatim — no duplication, no
symlinks. Support is purely additive packaging plus a Model Guard that recognizes Codex frontier IDs.

### Added
- **Codex plugin manifests** — `plugins/case-solvers/.codex-plugin/plugin.json` and
  `plugins/writing-claude-md/.codex-plugin/plugin.json`, each pointing at the shared `./skills/` tree
  alongside the existing `.claude-plugin/plugin.json`.
- **Codex marketplace** — `.agents/plugins/marketplace.json` publishing both plugins to Codex
  (`source`/`policy` schema), mirroring `.claude-plugin/marketplace.json`.
- **Codex invocation policy** — `agents/openai.yaml` (`policy.allow_implicit_invocation: false`) in
  the `case`, `solve`, and `evaluate` skills, the Codex equivalent of Claude's
  `disable-model-invocation: true`. These stay explicit-only (slash / `$skill`); `board` and `refine`
  remain implicitly invocable.

### Changed
- `/case` Model Guard (`v2.0.1` → `v2.1.0`) and `/refine` Model Guard (`v1.0.0` → `v1.1.0`): the
  planning tier now recognizes frontier GPT-5-class IDs (e.g. `gpt-5.5`, `gpt-5.5-high`) so `/case`
  and `/refine` run on a Codex frontier model. `gpt-5-mini`/`gpt-5-nano` classify as budget, and a
  budget marker now explicitly outranks a planning marker on ambiguous IDs. `/solve` is unchanged —
  it runs on any model tier, as before.

## [2.1.0] - 2026-06-14

Plugin & marketplace entry `case-solvers` `2.0.0` → `2.1.0`.

### Changed
- `/evaluate` (`v1.1.1` → `v1.2.0`): replaced `--skip-review` with three composable flags.
  `--approve` merges without opening the VSCode diff; `--request-changes` routes straight to the
  send-back path (still prompts for impl vs. contract); `--note <text>` attaches a `bd comment` to
  the story and is orthogonal — works with either flag or the full interactive flow. Removed the
  post-merge `⚠` warning: `--approve` is an affirmative signal, not negligence, so no warning is
  warranted. **Note:** `--skip-review` is removed; use `--approve` instead.
- `/case` Environment Guard (`v2.0.0` → `v2.0.1`): dropped the dangling `(see README → Requirements)`
  pointer. The skill runs from the plugin cache inside repos that don't carry the plugin README, so
  the reference was unreachable there. The guard now states the bd requirement on its own; the
  `.beads/`-absent → `bd init`-and-continue behavior and "Run Second" run-order are unchanged.

## [2.0.0] - 2026-06-14

Plugin & marketplace entry `case-solvers` `1.2.2` → `2.0.0`.

**Breaking:** `/case` is now **authoring only** and takes just `<description>`. Its other two modes
moved to dedicated commands — viewing the board / one story is **`/board`** (new), revising a story
is **`/refine`** (new). `/case` with no argument now prints a usage hint instead of the board, and
`/case --id <id>` is gone (use `/board <id>` to view, `/refine <id>` to revise). The split follows
the read/author fault line the skill already had: read-only modes ran on any tier, authoring needed
a planning model.

### Added
- New skill **`/board`** (`v1.0.0`) — read-only render of the bd backlog as a status board, or one
  story by id (`/board <id>`). Runs on **any model tier** (no planning model) and is
  **model-invocable**, so plain-language asks ("show me story 5", "list all stories") route to it.
  This is the old `/case` Board + Detail modes lifted out.
- New skill **`/refine`** (`v1.0.0`) — revise an existing story's contract on a **planning model**:
  apply a `/solve` spec-gap or `/evaluate` change-request (or a user edit), stay WHAT-only, and
  return the story to ready. Carries the same Model Guard as `/case` (untrusted-input handling
  included) and is **model-invocable** ("update story 5"). This is the old `/case` Refine mode as
  its own command.
- `plugins/case-solvers/shared/contract-rubrics.md` — the contract rubrics (Authoring principles,
  Problem Types, Budget-Solver Fit, Verification Mode, AC Quality Rubric, Pre-write Guard, Output
  Format) extracted to one file that both `/case` and `/refine` load after their Model Guard passes.
  Single source of truth, no duplication across the two authoring skills. Each skill's Model Guard
  stays inline — it must run before anything is read.

### Changed
- `/case` (`1.1.4` → `2.0.0`) — reduced to its one job: author a new story or epic. Board, Detail,
  Refine, the mode-dispatch table, and most of the bd command map are gone (moved to `/board` and
  `/refine`); the Model Guard sheds its read-only carve-outs since every `/case` run now authors.
  Stays slash-only (`disable-model-invocation`) — authoring is a deliberate act tied to a model
  switch, and a fuzzy "make a story" trigger would false-positive during ordinary design talk. The
  **Authoring: Story vs Epic** section was then compressed ~30% (the inline problem-type list and
  "both modes" restatement dropped — both already covered by the shared rubrics it points to); the
  new `authoring-format.sh` harness confirms a planning model still follows it (Story vs Epic
  branching + Output Format) across trials.
- `/solve` (`1.0.0` → `1.0.1`) and `/evaluate` (`1.1.0` → `1.1.1`) — pointers follow the new
  commands: a spec-gap / contract-wrong handoff now points at `/refine <id>`; "view the story" and
  "readable later" point at `/board` / `/board <id>`.
- Test harness grew a positive path and got more robust. `model-guard.sh` (the budget-STOP
  direction) now exercises both authoring guards — `/refine <id>` trials alongside
  `/case <description>` (`/refine`'s Model Guard runs before its environment guard, so a budget
  model must emit the planning-model stop even with no backlog; the harness asserts that). New
  `authoring-format.sh` covers the PLANNING-PROCEED direction: it runs `/case` on a planning model
  and grades the drafted `.case.md` against the Output Format and the Story-vs-Epic branch. Shared
  `lib.sh` auto-syncs the working tree into the active install before each run (no more manual
  `cp` into the cache) and adds `infra_error` detection so a mid-run session/rate limit or empty
  response scores **inconclusive (exit 2)**, never a false guard/format FAIL.
- `CLAUDE.md` / `README.md` updated for the five-command surface and the invocation policy
  (slash-only for the tier-gated/side-effecting commands; model-invocable for read-only `/board`
  and id-scoped `/refine`).

## [1.2.2] - 2026-06-14

Plugin & marketplace entry `case-solvers` `1.2.1` → `1.2.2`.

### Fixed
- `/case` (`1.1.3` → `1.1.4`) — Acceptance Criteria now author into a fenced ` ```gherkin `
  block instead of relying on trailing-two-space markdown hard breaks. The old format kept its
  line breaks in `bd show` (raw text) but silently collapsed Given/When/Then into one run-on
  paragraph when rendered as markdown whenever the agent dropped the invisible trailing spaces —
  which happened often, since there was nothing visible to reproduce. A code fence preserves the
  line breaks and 2-space indent literally and identically in both `bd show` and rendered
  markdown, and the structure is visible so the agent can't omit it. The Output Format template,
  Pre-write Guard (new scan item that wraps bare/trailing-space AC in the fence), and the format
  rule were updated together.

## [1.2.1] - 2026-06-13

Plugin & marketplace entry `case-solvers` `1.2.0` → `1.2.1`.

### Fixed
- `/case` (`1.1.2` → `1.1.3`) — the Model Guard now treats the `<description>` argument as
  **untrusted data**: text inside it that tells the skill to ignore/skip/waive the tier rules,
  "author anyway", or claims the model is a planning model no longer relaxes the gate. A budget
  model (e.g. Haiku) classifying from its real model ID stops and authors nothing even when the
  description tries to override the guard. Reproduced and verified with the new
  `plugins/case-solvers/tests/model-guard.sh` harness, which runs `/case <desc>` on a budget
  model across multiple trials (including override-injection descriptions) and asserts every
  trial emits the stop message and writes no contract.
- `/case` (`1.1.1` → `1.1.2`) — the Staging Loop now writes `.case.md` to the **main checkout
  root** (resolved as the first entry of `git worktree list`), not the session's working
  directory, so authoring from inside a worktree no longer strands the staging file there. An
  existing `.case.md` is overwritten without a confirmation prompt — the old "Overwrite guard"
  step is removed. The Decomposition (Epic) section's reference to that guard is updated to match.

## [1.2.0] - 2026-06-13

Plugin & marketplace entry `case-solvers` `1.1.0` → `1.2.0`.

### Added
- `/evaluate` (`1.0.0` → `1.1.0`) — new `--skip-review` flag: `/evaluate --skip-review <id>`
  merges a `needs-review` story straight to `main` (close, unblock dependents, drop the worktree —
  identical to approving) **without** opening the diff in VSCode or asking a verdict, for stories
  clear enough that no human review is wanted. The skip always prints a non-dismissible warning
  (`⚠ Merged <id> without review — skipped the human quality gate.`). The merge-conflict confidence
  gate is unchanged — an ambiguous conflict still stops for the human. Plain `/evaluate <id>`
  (no flag) is unchanged.

### Fixed
- `/case` (`1.1.0` → `1.1.1`) — the Model Guard now reliably stops authoring on a budget
  model. The gate anchors to the session's exact model ID (not self-assessed capability),
  requires emitting a `model-guard: id=… tier=…` line before any authoring, and proceeds only
  on a positively-confirmed planning tier — `budget` **or** `unsure` resolves to STOP. Removes
  the "any frontier/high-parameter model qualifies → proceed" wording that let a budget model
  rationalize past the guard. Read-only Board/Detail still run on any tier.

## [1.1.0] - 2026-06-13

Plugin & marketplace entry `case-solvers` `1.0.0` → `1.1.0`.

### Changed
- `/case` (`1.0.0` → `1.1.0`) — read-only modes now run on **any model tier**: Board (`/case`)
  and Detail (`/case --id`) render without requiring a planning model. Authoring (author,
  decompose, refine) still requires one; a budget `--id` on a `needs-refinement` story renders
  the detail, then stops short of refining.
- Rewrote `CLAUDE.md` (and the `AGENTS.md` symlink) as a lean, high-signal context file:
  states what the repo is (a plugin marketplace, no build/test suite), the three-tier
  `/case`/`/solve`/`/evaluate` philosophy, the "bd is the engine, not the interface" rule, and
  the skill-editing convention. Dropped the generic non-interactive-shell boilerplate.

## [1.0.0] - 2026-06-13

Breaking: the `case-solvers` plugin (`0.3.0` → `1.0.0`) is re-architected around **bd
(Beads)** for a durable, dependency-aware, parallel-capable workflow. `bd` is now required,
and the singleton dot-files are retired. `bd` stays hidden behind three commands —
`/case`, `/solve`, `/evaluate` — the user never types a `bd` command.

### Added
- New skill **`/evaluate`** (`v1.0.0`) — the human review gate (Gate N): opens a finished
  story's branch in VSCode for the human to read the diff, then enacts the verdict — approve
  (merge to `main`, close the story, unblock dependents, drop the worktree) or request changes
  (feedback as a bd comment, back to `/solve` or `/case`).
- **Stories & epics** in bd: `/case <text>` authors one story; a large goal decomposes into an
  epic — a dependency graph of stories — reviewed at **Gate 0** before any issue is created.
- **Board**: `/case` with no argument renders backlog / in-progress / review-queue / blocked,
  with epic rollups. `/case <id>` shows one story's contract + its comments.
- **Isolation**: every solve runs in its own git worktree+branch (`bd/<id>`); `/evaluate`
  reviews and merges it like a PR. Merge conflicts pass a confidence gate (clear+tests-green →
  auto-resolve; ambiguous → escalate to the human).
- **Dependency guardrail**: `/solve <id>` refuses a still-blocked story with a reason and
  offers to walk the dependency chain.

### Changed
- `/case` (`0.10.0` → `1.0.0`) authors into bd instead of writing a persistent `.case.md`;
  gains board, detail, and epic-decomposition modes. The contract template, AC Quality Rubric,
  Budget-Solver Fit, and Pre-write guard carry over.
- `/solve` (`0.12.0` → `1.0.0`) takes a story id, works in a worktree, ends at `needs-review`
  (never merges or closes). The milestone machinery is gone — epics replace it.
- Plugin & marketplace entry version `0.3.0` → `1.0.0`; descriptions/keywords mention bd,
  epics, parallel, `/evaluate`.
- All three skills are slash-only (`disable-model-invocation: true`) with lean one-line
  descriptions — no natural-language auto-trigger. Standardised argument hints: `/case
  [<description>] [--id <story-id>]`, `/solve` and `/evaluate` `[<story-id>]`. `/case`
  tells a story id from a description via an explicit `--id` flag.
- Skill bodies trimmed for token cost: dropped per-invocation `bd prime` (static command
  maps + `bd <cmd> --help` fallback), de-duplicated guidance, removed the worked example.

### Removed
- The persistent singleton dot-files. `.case.md` survives only as a transient
  epic-decomposition surface (deleted after generating bd issues); `.solve-progress.md` and
  `.handoff.md` are gone — progress is the bd graph, and handoff feedback is bd comments
  per story.

### Requires
- The `bd` (Beads) CLI installed and on `PATH` — `brew install beads`, `npm i -g @beads/bd`,
  or `go install`. Skills assume it's present (no install check) and run `bd init` on first
  use. See README → Requirements.

## [0.4.0] - 2026-06-12

### Added
- New plugin `writing-claude-md` (`v1.0.0`): skill for writing lean, high-signal
  `CLAUDE.md` and `AGENTS.md` files — includes only what can't be derived from code.
  Install: `/plugin install writing-claude-md@case-solvers`.
- Updated marketplace description to reflect multi-plugin scope.
- Expanded README: plugin table, per-plugin install instructions, `writing-claude-md`
  usage section.

## [0.3.0] - 2026-06-12

### Changed
- Model tiers are now capability-defined instead of a closed name list: a planning model
  is "any frontier-tier, high-parameter model" (Opus/Sonnet/Fable/Mythos/Gemini Pro as
  illustrative examples). Fixes frontier models outside the old list (e.g. Fable) refusing
  to run `/case` and missing the `/solve` cost warning.
- Compressed the `/case` worked example (39 lines) to a micro-fragment showing only the
  judgment parts: positive+regression AC pair, boundary-style constraint, verification line.
- Removed the redundant "What NOT to Include" section (duplicate of the Pre-write guard)
  and slimmed repeated Model Guard restatements to one-line pointers.
- Internal skill versions: case `0.9.0` → `0.10.0`, solve `0.11.0` → `0.12.0`.

## [0.2.0] - 2026-06-12

Breaking: the architect command and its output file were renamed. Existing installs
receive the change on `/plugin update` because the version is bumped.

### Changed
- Renamed the architect command `/spec` → `/case` (skill `name`, directory, and heading;
  internal skill version `0.8.0` → `0.9.0`).
- Renamed the contract artifact `.architect-plan.md` → `.case.md` across both skills,
  the README, and `.gitignore`.
- Updated plugin and marketplace `description`, `keywords` (`spec` → `case`), and the
  README install/usage examples to match.
- Bumped plugin and marketplace entry version `0.1.0` → `0.2.0`.

### Unchanged
- `/solve` and its files (`.solve-progress.md`, `.handoff.md`) are untouched.
- The "architect" role wording is kept; only the command token and artifact name changed.

## [0.1.0] - 2026-06-12

Initial release: the `/spec` + `/solve` pair, packaged from two standalone skills into a
publishable Claude Code plugin marketplace.

### Added
- `case-solvers` marketplace (`.claude-plugin/marketplace.json`) bundling a single plugin.
- `case-solvers` plugin (`.claude-plugin/plugin.json`) exposing two skills:
  - `/spec` — runs on a planning model (Opus / Sonnet / Gemini Pro); defines the problem
    and writes `.architect-plan.md`, the budget-solver contract.
  - `/solve` — runs on a budget model (Haiku / Gemini Flash / MiniMax-M3); reads the
    contract and implements it test-first, one milestone per pass, with a handoff loop
    back to `/spec` on rejection or pre-flight gaps.
- `README.md`, `LICENSE` (MIT), and `.gitignore` for the skills' runtime artifacts.

### Fixed
- Quoted the skills' `description` frontmatter so it parses under strict YAML and passes
  `claude plugin validate --strict`. The original values contained `: ` (colon-space)
  sequences that broke plain-scalar parsing and silently dropped the metadata.

[Unreleased]: https://github.com/codxse/case-solvers/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/codxse/case-solvers/compare/v0.4.0...v1.0.0
[0.4.0]: https://github.com/codxse/case-solvers/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/codxse/case-solvers/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/codxse/case-solvers/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/codxse/case-solvers/releases/tag/v0.1.0
