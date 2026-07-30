# SDD

**Spec-driven development** as three agent plugins for **Claude Code**, **OpenAI Codex**,
**Kimi Code**, and **opencode** — same skills, any host.

| Plugin | Skills | Purpose |
|--------|--------|---------|
| `sdd` | `/milestone`, `/specify`, `/refine`, `/board`, `/solve`, `/validate`, `/orchestrate` | Local-only Socratic milestone memory with optional bd sync, plus a parallel workflow: author stories/epics → solve in worktrees → review & merge, or orchestrate ordered story/epic targets behind one PR/MR |
| `code-review-quality` | `/code-review-quality` | Multi-axis review of a change before merge — severity-labelled findings and a verdict, optionally applied in place |
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

- **Frontier model — the architect.** Grills me into a clear story (WHAT/WHY), and drives an ordered
  story/epic run when I'm not watching. `/specify`, `/refine`, `/orchestrate`.
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

Same three plugins on Claude Code and Codex (one combined plugin on Kimi Code, a copy-based install on
opencode — see below). Add the marketplace once, then install what you want.

**Claude Code**

```
/plugin marketplace add codxse/sdd
/plugin install sdd@sdd
/plugin install code-review-quality@sdd
/plugin install writing-claude-md@sdd
```

Type the commands in a Claude Code session (not your shell). `/plugin` on its own opens the plugin
browser if you'd rather click. Verify with `/help` — the new commands appear in the list.

**Codex**

```
codex plugin marketplace add codxse/sdd
codex plugin add sdd@sdd
codex plugin add code-review-quality@sdd
codex plugin add writing-claude-md@sdd
```

These run in your shell, not in a Codex session, and need a Codex CLI new enough to have the plugin
subcommand — check with `codex plugin --help`. Verify the install with `codex plugin list`.

On Codex, `/solve` and `/validate` are **slash-only** — they bake work into a branch, so they never
auto-fire mid-conversation. `/milestone`, `/specify`, `/refine`, `/board`, `/orchestrate`, and
`/code-review-quality` also answer plain English (for example, "run the epic", "show the board", or
"review my changes"). Invoke any plugin skill explicitly with its qualified name, such as
`$sdd:orchestrate <epic-id> <story-id>`.

**Kimi Code**

```
/plugins install https://github.com/codxse/sdd
```

Type it in a Kimi Code session (not your shell), then run `/reload` (or `/new`) — plugin changes
don't apply to the current session. Kimi's GitHub install reads the manifest at the repository
root, so all three marketplace plugins ship as **one** Kimi plugin named `sdd` carrying all
nine skills; there is no per-plugin pick on this host. Verify with `/plugins list`, or open the
manager with `/plugins`.

Invoke the skills as `/skill:specify`, `/skill:solve`, …, or in plain English — Kimi doesn't register
`/specify`-style slash commands for plugin skills. The session primer hook (`SessionStart` /
`PreCompact`) is ported and active, alongside a Kimi-only `UserPromptSubmit` hook that tells the
session its own model ID — Kimi states one nowhere a model can read it, and without it the
frontier-gated skills (`/specify`, `/refine`, `/orchestrate`) either refuse on every model or guess
their tier. It needs no setup, but it does need the session reloaded after install like everything
else here. One host gap to know: there is no per-skill
implicit-invocation gate (no equivalent of Codex's `agents/openai.yaml`), so `/solve` and
`/validate` rely on their own prose to stay slash-only. Plugins also can't ship subagent
definitions on this host — for `/validate`'s reviewer, see the copy step under *Reviewer agents*
below.

**opencode**

```sh
git clone https://github.com/codxse/sdd
sdd/plugins/sdd/hosts/opencode/install.sh
```

Run it in your shell, then start a new opencode session. opencode has no plugin manager — its
extension surface is the config directory itself, so the install copies the skills, the reviewer
agents, a generated slash command per skill, and one small plugin into `~/.config/opencode`. Re-run the
same script to update; `--dry-run` shows the file list first, `--dest` scopes it to a single project's
`.opencode`.

That plugin is not optional: opencode never states its own model ID, so without it the frontier-gated
skills (`/specify`, `/refine`, `/orchestrate`) stop on every model, frontier ones included. Two host
gaps to know: there is no per-skill implicit-invocation gate, so keep `/solve` and `/validate` behind
`"permission": { "skill": { "solve": "ask", "validate": "ask" } }` in your `opencode.json`; and the
reviewer agents' `model:` pins name Anthropic slugs, which you'll want to edit if you're on another
provider. **[OPENCODE.md](OPENCODE.md) covers all of it** — install, update, uninstall, the reviewer
subagents, keeping a provider key out of the config with `{env:VAR}`, the no-copy setup for working on
this repo, and how to test the guard in both directions.

**Requirements:** `/milestone` create/show/update needs only git; `/milestone --sync` and the rest of
the `sdd` workflow need the `bd` CLI on your `PATH` — see
[the command reference below](#sdd--bd-backed-parallel-coding-workflow). `/orchestrate` uses
authenticated `gh` for a GitHub remote or `glab` for GitLab. If the matching CLI is unavailable, it
asks before doing any work whether to stop or use git-only publication; finalization still requires
the matching CLI to verify the merge. `code-review-quality` needs only `git`, plus `gh` if you point
it at a GitHub PR number. `writing-claude-md` has no dependencies.

**Reviewer agents (recommended):** the plugin ships two review-and-apply agent definitions —
`story-reviewer` (medium rung) and `story-reviewer-strong` (frontier rung) — that `/validate`
prefers when spawning its review pass, so the reviewer's model pin is enforced by the agent
definition instead of prose. Both prefer `/code-review-quality` (above) as the reviewing command when
that plugin is installed, and otherwise fall back to the host's own review-and-apply — a preference,
not a dependency: `sdd` works standalone. On **Claude Code** they load automatically with the plugin. On
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

On **opencode** the installer copies opencode-native versions of both agents into
`~/.config/opencode/agent/` for you, and this host *does* honor a subagent's `model:` pin — so both
rungs are enforced by the definitions rather than by prose, as on Claude Code. The pins name Anthropic
slugs; on another provider, edit the one `model:` line in each file to a slug from `opencode models`
(the installer warns you when a pin isn't in the catalog). See
[OPENCODE.md](OPENCODE.md#subagents--validates-reviewer).

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

**Gating:** `/specify`, `/refine`, and `/orchestrate` require a **frontier model**; `/milestone`,
`/solve`, `/board`, `/validate`, and `/code-review-quality` run on any tier. Each gated skill checks
its own
model ID and stops with a message telling you to switch, so a wrong tier costs you a line of output,
never a bad story.

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

For the other plugins, substitute the name in the second command:

```sh
codex plugin add code-review-quality@sdd
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

**opencode** — pull the checkout and re-run the installer, then start a new session:

```sh
cd sdd && git pull
plugins/sdd/hosts/opencode/install.sh
```

It removes the previous install's files before writing the new ones, so a renamed or dropped skill
leaves nothing stale behind. Re-apply any edit you made to the reviewer `model:` pins — the update
overwrites them. `--uninstall` removes everything it installed.

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

The current milestone sits above the execution loop as local-only project memory. The
[three roles](#why-i-built-this) remain the **architect** (`/specify`, `/refine`, `/orchestrate`), the
**solver** (`/solve`), and you, the **validator** (`/validate`). Work lives in
[**bd** (Beads)](https://github.com/steveyegge/beads) — a git-backed, dependency-aware issue tracker
— so you can stockpile many stories and solve any of them anytime, in parallel. **bd stays hidden**:
you only ever type the slash commands, never `bd`.

**Requirements:** milestone create/show/update needs only git. `/milestone --sync` and the
story/epic workflow need the `bd` CLI on your `PATH` — `brew install beads` (or
`npm i -g @beads/bd`, or `go install github.com/steveyegge/beads@latest`). The bd-backed skills run
`bd init` on first authoring use.

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

On **any model**, track the current project direction:

- **`/milestone [--sync|<description|update>]`** -> creates, shows, or updates `.milestone.md` in the
  main checkout. It keeps the file local through the repository's `.git/info/exclude` and refuses to
  edit a tracked or staged copy. Creation uses a short Socratic loop to clarify the outcome and
  observable Done When conditions without descending into implementation details. The file also
  keeps a Todo checklist for milestone capabilities that do not have a bd epic yet. `--sync` reads bd
  to refresh linked epic status/story progress. An exact unique title match proposes a
  Todo/title-only link for human confirmation; it never adopts an epic from title alone. It never
  writes to bd, and `/specify` remains unchanged.

On a **frontier model** (Opus / Fable / Mythos / `gpt-5.6-sol` / Qwen3.8-Max-class / Kimi-K3-class)
— author the *what*:

- **`/specify <description>`** → one **story** (a precise, verifiable contract), or a big goal decomposed
  into an **epic** (a dependency graph of stories) for you to review *before* anything is created. Each
  story also gets a **Complexity** call — the cheapest solver tier (budget/medium/frontier) and effort
  likely to succeed — so you know which model to run `/solve` on.
- **`/refine <id>`** → revises an existing story's contract from a `/solve` spec-gap, an `/validate`
  change-request, or your own ask — stays WHAT-only, returns it to ready.
- **`/orchestrate <id> [<id> ...]`** → accepts an ordered mix of story and epic ids, expands epics to
  their direct stories, deduplicates the combined scope, and automates `/solve` → review → land on one
  deterministic `orchestrate/<run>` branch. Input order controls serial priority, while readiness
  still wins; `--parallel` dispatches a ready wave concurrently. It opens one GitHub PR through `gh`
  or GitLab MR through `glab` for the human gate. When that positively identified forge's matching
  CLI is unavailable or unauthenticated, it can use git-only publication only after asking first.
  Unknown forges stop. After that PR/MR merges, rerun the same targets with `--finalize`: each
  selected epic whose live children are all closed is closed independently, then `/milestone --sync`
  refreshes local project memory and proposes exact-title links. Every mode requires frontier.

On **any rung** — budget (Haiku / Gemini Flash / MiniMax-M3 / Kimi-K2-class incl. `kimi-for-coding`),
medium (Sonnet / `gpt-5.5` / `gpt-5.6-terra` / Gemini Pro-class), or frontier — do the *how*, on
whatever rung the story's own complexity call asks for:

- **`/solve <id>`** → refuses if the story is blocked; otherwise claims it, works test-first in its
  own git **worktree+branch**, and stops at *done · review*. Never merges.

Also on **any model**:

- **`/board`** → backlog, in progress, awaiting merge, blocked. `/board <id>` shows one story.
- **`/validate [<id>]`** → runs a code-review pass over the branch (effort `high`) and applies its
  fixes in the worktree, then enacts your verdict: **approve** lands it on the branch it was forked
  from, closes the story, unblocks dependents; or another pass; or a wrong contract routes to
  `/refine`. `--approve` lands with no review pass, `--review <effort>` picks a different effort,
  `--note <text>` steers the review or annotates the story.

### Typical flow

You're the scheduler; the loop is **author → solve → validate**, `/board` to look any time. A
milestone is optional project memory around that loop:

```
/milestone ship a public beta where customers can complete the primary workflow
```

After the clarification loop and your confirmation, this creates local-only `.milestone.md` and adds
it to the repository-local git exclude. `/specify` remains unchanged and does not read it
automatically. Add resulting epics to the milestone yourself, or run `/milestone --sync` to propose a
link when a Todo title exactly matches a bd epic title.

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

For a larger run, `/orchestrate <id> [<id> ...]` automates that solve-review-land cycle across the
ordered selected stories and epics. It works on one integration branch, reviews every story at its
recommended effort, and gives you one final PR/MR to merge. After merge, run the same target set with
`--finalize`; complete selected epics close independently and `.milestone.md` synchronizes once.

### Runtime artifacts

Stored in **your working project** (not this repo):

| What | Where | Purpose |
|------|-------|---------|
| Current milestone | `.milestone.md` (local-only, git-excluded) | Outcome, Done When, unmatched Todo, and epic-progress memory. |
| Stories / epics | `.beads/` (git-committed) | The durable backlog + dependency graph. |
| Feedback / refine notes | bd comments on a story | Per-story review feedback (refine notes + your verdicts). |
| Work under review | git worktrees on `bd/<id>` | Isolated branch per story awaiting `/validate`. |

Read the milestone via `/milestone`; read stories and epics via `/board` and `/board <id>`. You never
need `bd` commands directly.

---

## `code-review-quality` — Multi-axis review before merge

A review that judges a change against **what it was supposed to do**, across five axes —
correctness, readability, architecture, security, performance — and reports findings the author can
act on: `Critical`, `Required`, `Consider`, `Nit`, `FYI`, plus a merge verdict. It approves what
improves the health of the codebase; it does not gate on taste.

Standalone: no bd, no worktrees, no branch conventions, and no model gate — it runs on **any tier**.

### Usage

```
/code-review-quality                                  # the working diff
/code-review-quality --effort max                     # deepest pass
/code-review-quality my-branch --fix true             # review since a ref, apply the fixes
/code-review-quality #124                             # a GitHub PR (needs gh)
/code-review-quality src/billing/                     # specific files, whole content
```

| Argument | Effect |
|---|---|
| *(none)* | Uncommitted changes if any; else the branch vs its merge-base with the trunk; else the last commit |
| `<commit>` / `<branch>` / `<tag>` | The change since that point |
| `<path>` | Reviews those files as they stand, not a diff |
| `#<n>` or a PR URL | The PR's diff and its stated intent (needs the `gh` CLI) |
| `--effort <low\|high\|max>` | `low` = diff only, correctness + security. `high` (default) = all five axes, reads the changed files and their callers. `max` = also traces call sites, runs tests/lint if cheap, and reviews dependency and lockfile diffs |
| `--fix <true\|false>` | Default `false` — report only. `true` applies the `Critical` and `Required` findings and **leaves them uncommitted** for you: never staged, committed, amended, or pushed |

Under `--fix true` it fixes the finding and nothing else — no drive-by renames, and never by
weakening a check (no deleted test, no widened type, no swallowed exception, no disabled lint rule).
A finding it can't verify stays unfixed and says so. Orphaned code after a refactor is listed and
**asked about**, never silently deleted.

It also refuses to pretend: past ~1000 changed lines it tells you the review can't be honest in one
pass and names the split it would make before going further.

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
