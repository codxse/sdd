# sdd on opencode

[opencode](https://opencode.ai) is the fourth host for this marketplace, and the only one you
install by running a script instead of adding a marketplace. That is not a shortcut — opencode has no
plugin manager to install from. Its extension surface *is* the config directory: `skill/`, `agent/`,
`command/`, and `plugin/` under `~/.config/opencode`. So the install is a copy, and
`plugins/sdd/hosts/opencode/install.sh` is it.

The skills themselves are the same files Claude Code, Codex, and Kimi Code load — one `skills/` tree,
never forked per host. Everything below is about the four things around them: where they go, how
`/validate`'s reviewer subagents get their model pins, and the one plugin without which every gated
skill refuses to run.

---

## Install

```sh
git clone https://github.com/codxse/sdd
sdd/plugins/sdd/hosts/opencode/install.sh
```

Run it in your shell, then start a new opencode session — it reads the config directory at startup.
`--dry-run` first if you want to see the file list before anything is written.

By default it installs into `$OPENCODE_CONFIG_DIR`, else `$XDG_CONFIG_HOME/opencode`, else
`~/.config/opencode`. To scope the install to a single repository instead of your whole user, point
it at that project's `.opencode`:

```sh
sdd/plugins/sdd/hosts/opencode/install.sh --dest /path/to/project/.opencode
```

Verify with `opencode` in a session: the skills appear in the `skill` tool's list, and `/specify`,
`/solve`, `/board`, … appear in the slash menu.

### What lands where

| Path under the config dir | What it is |
|---|---|
| `skill/<name>/SKILL.md` | All nine skills, from every plugin in the repo — `milestone`, `specify`, `refine`, `board`, `solve`, `validate`, `orchestrate`, `code-review-quality`, `writing-claude-md` |
| `command/<name>.md` | One slash command per skill, so `/specify` works and not just "use the specify skill" |
| `agent/story-reviewer{,-strong}.md` | The two review-and-apply subagents `/validate` spawns |
| `plugin/sdd-model-context.js` | Tells the session its own model ID (see [Model identity](#model-identity-required)) |
| `.sdd-installed` | The file list, so the next run can update cleanly. Don't edit it |

The commands are **generated** from each skill's own frontmatter rather than committed to the repo,
so a command's description cannot drift from the skill it invokes — there is one source for each
description, and it is the `SKILL.md`.

### Options

| Flag | Effect |
|---|---|
| `--dest DIR` | Install into `DIR` instead of the default config directory |
| `--dry-run` | Print what would change, write nothing |
| `--no-skills` / `--no-commands` / `--no-agents` / `--no-plugin` | Skip that part |
| `--uninstall` | Remove everything a previous run installed |

---

## Configure

### Keep `/solve` and `/validate` from firing on their own

On opencode every skill is model-invocable through the `skill` tool, and the frontmatter that makes a
skill slash-only on Claude Code and Codex (`disable-model-invocation`) is simply ignored here. `/solve`
writes code to a branch and `/validate` merges and closes stories, so put them behind an approval
prompt in your `opencode.json`:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "permission": {
    "skill": {
      "*": "allow",
      "solve": "ask",
      "validate": "ask"
    }
  }
}
```

`ask` prompts you before the skill loads; `deny` hides it from the model entirely. This is a blast-radius
control, not true slash-only-ness — see [Host gaps](#host-gaps).

### Keeping a provider key out of the config file

If your provider needs an API key — a local proxy, a router, a gateway — opencode substitutes
`{env:VAR}` anywhere in `opencode.json`, so the key never has to sit in the file:

```json
{ "provider": { "myprovider": { "options": { "apiKey": "{env:MY_API_KEY}" } } } }
```

Two things to know. An **unset** variable substitutes the empty string rather than erroring, so a
forgotten export surfaces as `Unauthorized: Missing API key` at request time, not as a config problem.
And if you export it from a shell rc file, remember that `~/.zshrc` and `~/.bashrc` are usually
world-readable (`644`) — a secret is better off in its own `600` file that the rc sources:

```sh
printf "export MY_API_KEY='…'\n" > ~/.config/myprovider/env && chmod 600 ~/.config/myprovider/env
echo '[ -f "$HOME/.config/myprovider/env" ] && . "$HOME/.config/myprovider/env"' >> ~/.zshrc
```

### Developing on this repo: skip the copy

If you're editing the skills rather than just using them, don't copy them at all. opencode takes
directories to discover skills from, scanned recursively for `**/SKILL.md`, so one entry points it at
your working tree and every edit is live on the next session:

```json
{ "skills": { "paths": ["~/Workspace/projects/sdd/plugins"] } }
```

Install with `--no-skills` alongside this so the copied set doesn't shadow your checkout. The agents
and the plugin still need copying — those directories aren't configurable.

Two other discovery paths work without any config at all, because opencode reads Claude- and
agents-format skills natively: `~/.claude/skills/<name>/SKILL.md` and `~/.agents/skills/<name>/SKILL.md`,
plus the same directories walked up from your working directory to the repo root. Useful to know if a
skill shows up that you don't remember installing.

---

## Model identity (required)

opencode tells a session its working directory, project root, git status, platform, and the date —
and never its own model ID. Every sdd skill classifies its own tier from that ID, so with nothing to
read, `/specify`, `/refine`, and `/orchestrate` classify `unsure` and stop. On *every* model,
frontier ones included.

`plugin/sdd-model-context.js` closes that, at two seams: it appends the host-resolved model ID to the
system prompt on each request (main session and subagents alike), **and** to the body of any skill the
`skill` tool loads. The second is not redundancy. opencode delivers a skill as a tool result
mid-conversation, so the tier rubric arrives far from the system prompt — and asked to classify itself,
a budget model doesn't look back. With the system-prompt injection alone and the correct ID sitting in
it, `claude-haiku-4-5` was observed emitting `model-guard: id=claude-opus-4-1 tier=frontier` — an ID it
invented — and authoring a story. Putting the ID next to the rubric that reads it is what stops that.

It needs no configuration, but it does need a new session after install, and it must not be skipped
unless something else in your setup already states the model ID.

It **fails closed** — if no ID can be established it emits nothing, leaving the session `unsure`,
which the gated skills already handle by stopping. A confident wrong answer would be worse: telling a
budget session it is frontier turns "stop" into "author a contract".

To check it's working, run `/specify` on a budget model and on a frontier one; each prints its own
verdict line before doing anything else:

```
model-guard: id=anthropic/claude-haiku-4-5-20251001 tier=budget    → stops
model-guard: id=anthropic/claude-opus-5 tier=frontier              → proceeds
```

Check **both** directions. A refusal on its own proves nothing: with no ID the session classifies
`unsure`, and `unsure` refuses in exactly the same words as `budget`, so a broken plugin looks like a
working one from the stopping side. Don't test it by asking the session what model it is
conversationally — models hedge that question ("I can't verify my own model ID") even when the line is
present, which tells you nothing.

**Gating**, for reference: `/specify`, `/refine`, and `/orchestrate` require a frontier model.
`/milestone` (including its read-only `--sync`), `/solve`, `/board`, `/validate`, and
`/code-review-quality` run on any tier.

---

## Subagents — `/validate`'s reviewer

`/validate` doesn't bounce work back to `/solve`. It delegates the fix to a **rung-pinned reviewer
subagent**, which reviews the story's diff against its contract, applies the fixes in place in the
worktree, and leaves them uncommitted for you. Two ship, differing only in rung:

| Agent | Rung | Used for |
|---|---|---|
| `story-reviewer` | medium | `solver-budget` and `solver-medium` stories under `--unattended` |
| `story-reviewer-strong` | frontier | `solver-frontier` stories, same-rung step-ups, and any time a human is present |

opencode is a native host for this: it honors a subagent's `model:` pin, so the rungs are enforced by
the agent definitions rather than by prose. That's better than Kimi Code, which ignores the pin and
collapses to one rung.

### Set the model pins to your provider

The shipped pins name Anthropic slugs — `anthropic/claude-sonnet-5` and `anthropic/claude-opus-5`.
opencode resolves models against its own provider catalog, so on a different provider they won't
resolve. The installer warns when a pin isn't in `opencode models`; fix it by editing one line in each
file:

```sh
opencode models | less                                    # find your slugs
$EDITOR ~/.config/opencode/agent/story-reviewer-strong.md  # edit the model: line
```

Keep the rung relationship — `story-reviewer` medium, `story-reviewer-strong` frontier — and keep both
at or above medium. A budget reviewer is the exact failure the frontier pin exists to prevent: review
is where a subtly wrong change gets caught, and the cheapest place to fail is before the merge.

If you run a single-model setup (one router, one slug), point both files at it. That degrades to
opencode's one-rung behavior, which is fine as long as the slug is frontier-class; the review pass
stops rather than review on a budget model.

### Reasoning effort

opencode calls reasoning effort a **model variant**, and it is the only lever that works here — the
`effort:` field the other hosts read is accepted by opencode's agent schema but swept into `options`,
where it never reaches the API. So both shipped agents carry a `variant` alongside their `model` pin:
`high` for `story-reviewer-strong`, `medium` for `story-reviewer`.

An agent-level `variant` **only applies when the agent also pins `model`** and that model is the one in
use; without a model pin it is silently ignored. Both agents pin one, so this holds as shipped — but if
you repoint them at a provider whose models expose different variant names, check the names with
`opencode models <provider> --verbose`. An unknown variant is **silently dropped**, not rejected, so a
typo costs you the effort you asked for and says nothing.

### Tools and permissions

The definitions deliberately **don't** grant themselves permissions. They deny `task` (no nested
spawning), `webfetch`, and `websearch`, and inherit your session's posture for everything else — so a
reviewer that needs to run `git diff` or the test suite asks exactly like you'd expect in your own
setup. If you've globally set `"bash": "allow"` the review pass runs uninterrupted; if you haven't,
you'll approve its commands. Nothing in the review path needs network access.

You can also verify what got installed with `opencode agent`, and invoke a reviewer directly with
`@story-reviewer-strong` if you want to hand it a diff outside of `/validate`.

---

## Update

Re-run the installer. It records what it wrote and removes the previous set first, so a renamed or
dropped skill leaves nothing stale behind:

```sh
cd sdd && git pull
plugins/sdd/hosts/opencode/install.sh
```

Then start a new opencode session. If you edited the reviewer `model:` pins, re-apply that edit —
the update overwrites `agent/*.md` with the shipped pins. (Nothing touches your `opencode.json`, ever;
that stays yours.)

Using the `skills.paths` setup instead? Then `git pull` *is* the update for the skills, and you only
re-run the installer when the agents or the plugin change.

## Uninstall

```sh
sdd/plugins/sdd/hosts/opencode/install.sh --uninstall
```

Removes exactly the files it installed, then prunes the directories it emptied. Your `opencode.json`
is left alone — drop any `permission.skill` or `skills.paths` entries you added by hand.

---

## Testing the guard

`plugins/sdd/tests/opencode/model-guard.sh` is the opencode twin of the Claude, Codex, and Kimi
harnesses: it runs `/specify`, `/refine`, and `/orchestrate` headless across trials and asserts each
Model Guard both ways — a below-frontier model must stop, a frontier model must classify `frontier` and
continue, and every trial must show the `model-guard: id=<exact-id> tier=<tier>` line.

```sh
export MY_API_KEY=…   # only if your config reads its key via {env:}
SDD_TEST_ENV="MY_API_KEY" plugins/sdd/tests/opencode/model-guard.sh -n 1
```

It calls the real model, so it's slow and probabilistic — run it when changing anything the guard
touches. Two host specifics:

- It **stages** a throwaway config directory (your `opencode.json` copied in, the working tree layered
  on top) and points `OPENCODE_CONFIG_DIR` at it, so a run never mutates `~/.config/opencode`. Auth
  comes from the data directory via `$HOME`, untouched. `--no-stage` tests an existing config dir
  instead.
- Trials run in a minimal environment so a guard slip can't inspect unrelated credentials. That strips
  your provider key too, hence `SDD_TEST_ENV` to name what gets forwarded. The harness warns when a
  `{env:}` variable in your config is unset or unforwarded, because otherwise every trial would fail to
  authenticate and be scored as an inconclusive infra error rather than a setup mistake.

## Host gaps

Two things this host can't do that the others can. Both are documented rather than worked around,
because the workarounds would be worse than the gaps:

- **Slash-only-ness isn't enforceable.** `/solve` and `/validate` are slash-only on Codex via agent
  metadata, and opencode has no equivalent that ships with a skill. `permission.skill: "ask"` (above)
  is the honest substitute: the model can still reach for them, but you approve first. Same gap Kimi
  Code has. opencode's newer skill loader does parse a `slash` frontmatter flag with no consumer yet,
  which looks like the first-class answer arriving later.
- **The model-identity hook is `experimental.`-prefixed.** `experimental.chat.system.transform` is
  opencode's only seam onto the system prompt, and the prefix is their signal that it may change. If
  an opencode upgrade breaks `/specify` with a tier refusal on a frontier model, that hook is the
  first place to look.

---

## Requirements

`/milestone` create/show/update needs only git and keeps `.milestone.md` local through
`.git/info/exclude`. `/milestone --sync` and the story/epic workflow need the `bd`
([Beads](https://github.com/steveyegge/beads)) CLI on your `PATH`. `/orchestrate` uses authenticated
`gh` for GitHub or `glab` for GitLab; if the matching CLI is missing, it asks before work starts
whether to stop or publish the branch with git only. Post-merge `--finalize` still needs the matching
CLI to verify the merge. `code-review-quality` needs only `git`, plus `gh` if you point it at a
GitHub PR number. `writing-claude-md` has no dependencies.

For what the commands actually do, see the [README](README.md).
