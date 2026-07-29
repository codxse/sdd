# SDD

**Spec-driven development** as two agent plugins for **Claude Code**, **OpenAI Codex**, and
**Kimi Code** — same skills, any host.

| Plugin | Skills | Purpose |
|--------|--------|---------|
| `sdd` | `/specify`, `/refine`, `/board`, `/solve`, `/validate`, `/orchestrate` | bd-backed, parallel coding workflow: author stories/epics → solve in worktrees → review & merge, or automate a whole epic behind one PR |
| `writing-claude-md` | `/writing-claude-md` | Write lean, high-signal CLAUDE.md / AGENTS.md context files |

## Why I built this

I don't trust AI to one-shot a big app. I don't think that's where it's good — and I don't think
that's the point.

What today's AI *is* good at is **following instructions**. So my job changed. It's no longer to write
the code; it's to write the **instruction the AI will follow**. The hard part moved up a level.

The unit of that instruction is a **story**: a bounded, unambiguous primitive of work. This isn't a
new idea — it's the same "story" agile has always meant: one small, testable outcome. I lean on it
here for a specific reason about how models behave.

**Cheap models follow bounded, unambiguous instructions reliably, but degrade as a task grows in
ambiguity and scope.** It isn't about context window size — many cheap models have huge ones. It's
**reasoning capacity under ambiguity**: hand a budget model a large, vague, multi-step goal and it
drifts; hand it a tight, well-bounded story and it executes. So the fix is never "use a smaller
prompt" — it's "shrink the ambiguity." A story *is* that shrinking.

But writing a good story is its own hard problem. Often **I don't actually know what I want** until
something forces me to say it precisely. That's the job of a **frontier model**: not to write code,
but to run a **Socratic loop** on me — one question at a time, each carrying its own recommended
answer, pushing on every vague word ("fast", "handles errors") until nothing in the contract is left
to interpret. It looks up whatever the codebase already answers instead of asking me, and it stops
when the only unknowns left are ones the solver can settle without changing *what* gets built.
Authoring is a feedback loop, human-steered. I stay in it because only I know what I actually want.

A story says **WHAT and WHY — never HOW**. It states the outcome and why it matters; it bounds the
search space (what to look at, what's out of scope). It does **not** dictate the mechanism — which
function, which pattern, which file. The frontier model isn't remote-controlling the budget model.
It's handing it a clear primitive and getting out of the way.

Because a story is a *testable* outcome, the solver proves it the way I would — **red, green,
refactor.** Write the failing test that encodes the story's acceptance criteria (red), make it pass
with the simplest thing that works (green), then clean it up (refactor). The test is the contract
made executable: it's how I know the bounded outcome was actually met, not just claimed.

When a goal is too big for one story, I break it into an **epic** — a graph of stories — the same way
agile does.

And I stay in the loop at the **end**, too. As an engineer I need to know what I shipped: to learn
from it, and to reject what isn't right or isn't to my taste. AI doesn't get to approve its own work
into `main`.

So three roles fall out, each matched to the model that's actually good at it:

- **Frontier model — the architect.** Grills me into a clear story (WHAT/WHY), and drives a whole
  epic when I'm not watching. `/specify`, `/refine`, `/orchestrate`.
- **Any tier — the solver.** Executes one bounded story (HOW), on whatever rung the story's own
  complexity call asks for. `/solve`.
- **Me — the validator.** Reviews and merges. `/validate`.

Using a frontier model for *everything* is economically silly. This split is the sweet spot: pay for
the expensive model only where judgment is needed, let the cheap model do the bounded work, and keep
the human where the human is irreplaceable.

**This is not vibe coding.** Vibe coding lets the model run and accepts output you didn't read. This
is the opposite: I follow every change. It's closer to pairing with a real engineer — except I can
run several in parallel, each on its own bounded story. The thing that scales here isn't the app or
the model's output; it's the **code I can actually keep up with**. Throughput is bounded by how many
stories I can follow and evaluate at once — and that's deliberate, not a limitation. The human stays
the bottleneck on purpose. Which means **this isn't for everyone**: if you'd rather not look at the
code, this isn't your tool.

The stories live in [**bd** (Beads)](https://github.com/steveyegge/beads) so I can record them and
solve many in parallel — but you never type a `bd` command. The skills keep it hidden.

## Install

Same two plugins on Claude Code and Codex (one combined plugin on Kimi Code — see below). Add the
marketplace once, then install what you want.

**Claude Code**

```
/plugin marketplace add codxse/sdd
/plugin install sdd@sdd
/plugin install writing-claude-md@sdd
```

Type the commands in a Claude Code session (not your shell). `/plugin` on its own opens the plugin
browser if you'd rather click. Verify with `/help` — the new commands appear in the list.

**Codex**

```
codex plugin marketplace add codxse/sdd
codex plugin add sdd@sdd
codex plugin add writing-claude-md@sdd
```

These run in your shell, not in a Codex session, and need a Codex CLI new enough to have the plugin
subcommand — check with `codex plugin --help`. Verify the install with `codex plugin list`.

On Codex, `/solve` and `/validate` are **slash-only** — they bake work into a branch, so they never
auto-fire mid-conversation. `/specify`, `/refine`, `/board`, and `/orchestrate` also answer plain
English (for example, "run the epic" or "show the board"). Invoke any plugin skill explicitly with
its qualified name, such as `$sdd:orchestrate <epic-id>`.

**Kimi Code**

```
/plugins install https://github.com/codxse/sdd
```

Type it in a Kimi Code session (not your shell), then run `/reload` (or `/new`) — plugin changes
don't apply to the current session. Kimi's GitHub install reads the manifest at the repository
root, so both marketplace plugins ship as **one** Kimi plugin named `sdd` carrying all
seven skills; there is no per-plugin pick on this host. Verify with `/plugins list`, or open the
manager with `/plugins`.

Invoke the skills as `/skill:specify`, `/skill:solve`, …, or in plain English — Kimi doesn't register
`/specify`-style slash commands for plugin skills. The session primer hook (`SessionStart` /
`PreCompact`) is ported and active. One host gap to know: there is no per-skill
implicit-invocation gate (no equivalent of Codex's `agents/openai.yaml`), so `/solve` and
`/validate` rely on their own prose to stay slash-only. Plugins also can't ship subagent
definitions on this host — for `/validate`'s reviewer, see the copy step under *Reviewer agents*
below.

**Requirements:** the `bd` CLI on your `PATH` for `sdd` — see
[the command reference below](#sdd--bd-backed-parallel-coding-workflow). `/orchestrate`
additionally needs the `gh` CLI, authenticated, for opening its final PR. `writing-claude-md` has no
dependencies.

**Reviewer agents (recommended):** the plugin ships two review-and-apply agent definitions —
`story-reviewer` (medium rung) and `story-reviewer-strong` (frontier rung) — that `/validate`
prefers when spawning its review pass, so the reviewer's model pin is enforced by the agent
definition instead of prose. On **Claude Code** they load automatically with the plugin. On
**Codex**, plugins don't auto-load agents yet — copy the TOML templates into your project once:

```sh
cp ~/.codex/plugins/cache/sdd/sdd/<version>/agents/*.toml .codex/agents/
```

Without them, `/validate` falls back to pinning the model explicitly on a general subagent — same
behavior, just enforced by prose rather than the harness. On **Kimi Code**, plugins can't carry
agent definitions either, but Kimi's agent loader reads the Claude-format `.md` files verbatim (it
ignores the `model:` pin and accepts the comma-separated `tools`), so copy them into your user
agents directory once:

```sh
mkdir -p ~/.agents/agents
cp ~/.kimi-code/plugins/managed/sdd/plugins/sdd/agents/*.md ~/.agents/agents/
```

(If you set `KIMI_CODE_HOME`, the managed copy lives under it instead; re-copy after a plugin
update.) With them, `/validate` spawns `story-reviewer` — the reviewer prompt and narrowed tools
come from the definition — but the model pin can't: Kimi ignores the `model:` field, so the
reviewer runs on the session's own model. One rung on this host either way: the
review pass needs a frontier (K3-class) session, and on a budget session
(`kimi-for-coding`, K2-class) it stops rather than review on a budget model.

**Custom models (a router / custom host):** the plugin also runs on Claude Code pointed at a
non-Anthropic model — a router or gateway. The tier map (`shared/model-tiers.md`) classifies such a
model as **frontier** when its ID matches a frontier marker (e.g. `qwen3.8-max-preview`), so `/specify`,
`/refine`, and `/orchestrate` work on it. For `/validate`'s reviewer pin, set
**`CLAUDE_CODE_SUBAGENT_MODEL`** to your frontier model's ID — Claude Code applies it to every
subagent and it **overrides** the reviewer agents' `model:` frontmatter, so the review pass runs on
the model you name:

```sh
export CLAUDE_CODE_SUBAGENT_MODEL=qwen3.8-max-preview
```

⚠️ This variable is **global and single-valued**: it sets the model for *all* subagents (solvers and
reviewers alike) and overrides every per-agent pin. Set it to a **frontier** model — point it at a
budget model to save on `/solve` and the reviewer runs on that budget model too, which is exactly the
failure the frontier pin exists to prevent. Leave it unset and `/validate` falls back to pinning the
reviewer to the session's own model ID (the custom-host branch of the Reviewer-pinning map).

**Gating:** `/specify`, `/refine`, and `/orchestrate` require a **frontier model**; `/solve` runs on any
tier. Each checks its own model ID and stops with a message telling you to switch, so a wrong tier
costs you a line of output, never a bad story.

### Updating

**Claude Code**

```
/plugin update sdd
```

**Codex** — refresh the Git marketplace snapshot, then install the new plugin version:

```sh
codex plugin marketplace upgrade sdd
codex plugin add sdd@sdd
```

For the context-writing plugin, substitute its name in the second command:

```sh
codex plugin add writing-claude-md@sdd
```

These run in your shell. Confirm the installed version with `codex plugin list`, then start a new
Codex session so it reloads the updated skills. Both hosts key updates off the plugin's `version`
and install each version into its own directory.

**Kimi Code** — repeat the install in a session (it fetches the latest default branch), then
`/reload`:

```
/plugins install https://github.com/codxse/sdd
```

### Migrating from `case-solvers`

`3.0.0` renamed the project, the marketplace, and the plugin from `case-solvers` to `sdd`, and
renamed two commands:

| Was | Now |
|---|---|
| `/case <description>` | `/specify <description>` |
| `/evaluate <id>` | `/validate <id>` |

`/refine`, `/board`, `/solve`, and `/orchestrate` are unchanged, and **your bd backlog is
untouched** — stories, labels, and dependencies all carry over. The transient authoring draft moved
from `.case.md` to `.spec.md`; if your project's `.gitignore` lists the old name, update it.

Two behavior changes ship with it. **The authoring gate is now frontier-only:** `/specify`,
`/refine`, and `/orchestrate` require a frontier model and refuse a mid-tier one — Sonnet-class
models cleared the old gate and no longer do (see *Model tiers* above). And the reviewer agents were
renamed `case-reviewer` → `story-reviewer`, `case-reviewer-strong` → `story-reviewer-strong`.

An in-place update won't reach you: the plugin now installs under a new id, so remove the old one and
install fresh.

**Claude Code**

```
/plugin uninstall case-solvers@case-solvers
/plugin marketplace remove case-solvers
/plugin marketplace add codxse/sdd
/plugin install sdd@sdd
```

**Codex**

```sh
codex plugin remove case-solvers@case-solvers
codex plugin marketplace remove case-solvers
codex plugin marketplace add codxse/sdd
codex plugin add sdd@sdd
```

**Kimi Code** — remove the old plugin via `/plugins`, then install
`https://github.com/codxse/sdd` and `/reload`.

Repeat the plugin step for `writing-claude-md` if you use it. On Codex and Kimi Code, re-copy the
reviewer agent files from the new path (see *Reviewer agents* above) — the old copies name a
plugin that no longer exists. The GitHub repo redirects from the old name, so an unchanged
marketplace entry keeps resolving, but it will keep serving you the old plugin id.

---

## `sdd` — bd-backed, parallel coding workflow

The [three roles](#why-i-built-this) as commands: the **architect** (`/specify`, `/refine`, `/orchestrate`), the
**solver** (`/solve`), and you, the **validator** (`/validate`). Work lives in
[**bd** (Beads)](https://github.com/steveyegge/beads) — a git-backed, dependency-aware issue tracker
— so you can stockpile many stories and solve any of them anytime, in parallel. **bd stays hidden**:
you only ever type the slash commands, never `bd`.

**Requirements:** the `bd` CLI on your `PATH` — `brew install beads` (or `npm i -g @beads/bd`, or
`go install github.com/steveyegge/beads@latest`). The skills assume it's present and run `bd init` on
first use.

<details>
<summary>To skip permission prompts, add this to <code>.claude/settings.json</code></summary>

```json
{
  "allowedTools": ["Bash(bd *)", "Bash(code *)"],
  "permissions": {
    "allow": [
      "Bash(cat *)", "Bash(ls)", "Bash(ls *)", "Bash(find *)", "Bash(grep *)",
      "Bash(head *)", "Bash(tail *)", "Bash(wc *)", "Bash(file *)", "Bash(stat *)",
      "Bash(pwd)", "Bash(echo *)", "Bash(which *)", "Bash(type *)",
      "Bash(git log*)", "Bash(git diff*)", "Bash(git status*)", "Bash(git show*)", "Bash(git branch*)",
      "Bash(bd show*)", "Bash(bd list*)", "Bash(bd ready*)", "Bash(bd blocked*)", "Bash(bd stats*)",
      "Read"
    ]
  }
}
```

This allows `bd`/`code` plus read-only shell (file inspection, grep, git reads, bd queries) so the
skills never prompt for codebase exploration.

</details>

### The commands

On a **frontier model** (Opus / Fable / Mythos / `gpt-5.6-sol` / Qwen3.8-Max-class / Kimi-K3-class)
— author the *what*:

- **`/specify <description>`** → one **story** (a precise, verifiable contract), or a big goal decomposed
  into an **epic** (a dependency graph of stories) for you to review *before* anything is created. Each
  story also gets a **Complexity** call — the cheapest solver tier (budget/medium/frontier) and effort
  likely to succeed — so you know which model to run `/solve` on.
- **`/refine <id>`** → revises an existing story's contract from a `/solve` spec-gap, an `/validate`
  change-request, or your own ask — stays WHAT-only, returns it to ready.
- **`/orchestrate <epic-id>`** → automates the `/solve` → review → land loop across a whole epic's
  stories, landing each on an integration branch instead of one at a time by hand, and stops at a
  single pull request for you to review and merge — the one human gate for the epic. Stories run one
  at a time by default (a `--parallel` flag opts into dispatching a ready wave concurrently, at the
  cost of cross-story merge conflicts on epics whose stories touch the same files). It runs
  unsupervised for most of the epic, which is why it needs the same tier as `/specify`/`/refine`.

On **any rung** — budget (Haiku / Gemini Flash / MiniMax-M3 / Kimi-K2-class incl. `kimi-for-coding`),
medium (Sonnet / `gpt-5.5` / `gpt-5.6-terra` / Gemini Pro-class), or frontier — do the *how*, on
whatever rung the story's own complexity call asks for:

- **`/solve <id>`** → refuses if the story is blocked; otherwise claims it, works test-first in its
  own git **worktree+branch**, and stops at *done · review*. Never merges.

On **any model**:

- **`/board`** → backlog, in progress, awaiting merge, blocked. `/board <id>` shows one story.
- **`/validate [<id>]`** → runs a code-review pass over the branch (effort `high`) and applies its
  fixes in the worktree, then enacts your verdict: **approve** lands it on the branch it was forked
  from, closes the story, unblocks dependents; or another pass; or a wrong contract routes to
  `/refine`. `--approve` lands with no review pass, `--review <effort>` picks a different effort,
  `--note <text>` steers the review or annotates the story.

### Typical flow

You're the scheduler; the loop is **author → solve → validate**, `/board` to look any time.

```
/specify add a forgot-password reset email flow
```

`/specify` drafts the contract to a transient `.spec.md`, asks one or two scoping questions, then waits.
On your *"looks good"* it creates the story and hands you the next step (`/solve <id>`). For a goal
too big for one pass — `/specify ship SSO across the whole app` — it switches to epic mode and shows you
the full decomposition + dependency graph *before* creating anything.

Then `/solve <id>` each story, on the rung its `solver-*` label asks for — run several in parallel, each in its own
worktree+branch. `/validate <id>` reviews and merges, unblocking dependents. If a story comes back
`needs-refinement`, `/refine <id>` rewrites the *contract* (not the code) and returns it to ready.
`bd` enforces dependencies throughout, so a blocked story is always refused with a reason.

For an epic, `/orchestrate <epic-id>` automates that whole solve-review-land cycle instead of you
running it story by story — it works on an integration branch, reviews every story itself at the
effort its Complexity call recommends, and only asks for you once, at the end, on the one PR that
merges the epic.

### Runtime artifacts

Stored in **your working project** (not this repo):

| What | Where | Purpose |
|------|-------|---------|
| Stories / epics | `.beads/` (git-committed) | The durable backlog + dependency graph. |
| Feedback / refine notes | bd comments on a story | Per-story review feedback (refine notes + your verdicts). |
| Work under review | git worktrees on `bd/<id>` | Isolated branch per story awaiting `/validate`. |

Read them via `/board` and `/board <id>` — you never need `bd` commands directly.

---

## `writing-claude-md` — Write lean project context

Helps you write `CLAUDE.md` and `AGENTS.md` that only include what can't be derived from the code. Teaches the litmus test: *"Can an LLM learn this by reading the code?"* — if yes, omit it.

### Usage

```
/writing-claude-md
```

---

## License

MIT © 2026 nadiar
