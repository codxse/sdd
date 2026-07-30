#!/usr/bin/env bash
#
# install.sh — install the sdd marketplace into an opencode config directory.
#
# opencode is the one host with no plugin manager to install from: Claude Code and
# Codex each read a plugin manifest, Kimi Code reads one at the repo root, but
# opencode's extension surface *is* the config directory — `skill/`, `agent/`,
# `command/`, `plugin/` under ~/.config/opencode. So the install is a copy, and this
# script is it. Re-running it is also the update: the previous install's file list is
# recorded in a manifest and removed first, so a renamed or dropped skill leaves
# nothing stale behind.
#
# Four things get installed, each independently skippable:
#   skill/    all nine SKILL.md files, from every plugin in this repo
#   agent/    opencode-native reviewer agents for /validate's review pass
#   plugin/   sdd-model-context.js, which tells the session its own model ID
#   command/  one slash command per skill, generated from the skill's own frontmatter
#
# The commands are generated rather than committed so their descriptions cannot drift
# from the SKILL.md they invoke — there is one source for each description, and it is
# the skill.

set -euo pipefail

HOST_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$HOST_ROOT/../../../.." && pwd)
MANIFEST_NAME=".sdd-installed"

dest=${OPENCODE_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/opencode}
want_skills=1
want_agents=1
want_plugin=1
want_commands=1
dry_run=0
uninstall=0

usage() {
  cat <<'EOF'
Usage: install.sh [options]

Installs the sdd skills, reviewer agents, model-identity plugin, and slash commands
into an opencode config directory. Re-run it to update.

Options:
  --dest DIR       Config directory to install into.
                   Default: $OPENCODE_CONFIG_DIR, else $XDG_CONFIG_HOME/opencode,
                   else ~/.config/opencode. Pass a project's .opencode to scope the
                   install to one repo instead of the whole user.
  --no-skills      Skip the SKILL.md files.
  --no-agents      Skip the /validate reviewer agents.
  --no-plugin      Skip sdd-model-context.js. Only do this if something else already
                   tells the session its model ID — without one, /specify, /refine,
                   and /orchestrate stop on every model.
  --no-commands    Skip the generated slash commands (skills stay reachable by name).
  --uninstall      Remove everything a previous run of this script installed.
  --dry-run        Print what would change; write nothing.
  -h, --help       Show this help.
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --dest) [ $# -ge 2 ] || { echo "install.sh: --dest needs a directory" >&2; exit 2; }; dest=$2; shift 2 ;;
    --no-skills) want_skills=0; shift ;;
    --no-agents) want_agents=0; shift ;;
    --no-plugin) want_plugin=0; shift ;;
    --no-commands) want_commands=0; shift ;;
    --uninstall) uninstall=1; shift ;;
    --dry-run) dry_run=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "install.sh: unknown option '$1' (see --help)" >&2; exit 2 ;;
  esac
done

manifest="$dest/$MANIFEST_NAME"
installed=()

say() { printf '%s\n' "$*"; }

# Frontmatter readers. The description line is copied *verbatim* rather than
# re-quoted: it is already a valid single-line YAML scalar in the SKILL.md, in
# whatever quoting style that file chose, and re-quoting it is how you introduce a
# parse error in a description containing quotes.
skill_field() { sed -n "s/^$2: *//p" "$1" | head -1; }
skill_description_line() { grep -m1 '^description:' "$1" || true; }

record() { installed+=("$1"); }

copy_into() {
  local src=$1 rel=$2 abs="$dest/$2"
  record "$rel"
  if [ "$dry_run" -eq 1 ]; then
    say "  would write $rel"
    return
  fi
  mkdir -p "$(dirname "$abs")"
  cp "$src" "$abs"
  say "  $rel"
}

# Takes content as an argument rather than on stdin: a pipe would run this in a
# subshell and the manifest entry recorded there would be lost.
write_into() {
  local rel=$1 content=$2 abs="$dest/$1"
  record "$rel"
  if [ "$dry_run" -eq 1 ]; then
    say "  would write $rel"
    return
  fi
  mkdir -p "$(dirname "$abs")"
  printf '%s\n' "$content" >"$abs"
  say "  $rel"
}

# Drop directories emptied by a removal, walking up but stopping at $dest — never
# `rmdir -p`, which keeps climbing and would happily take ~/.config with it.
prune_empty_dirs() {
  local dir=$1
  while [ "$dir" != "$dest" ] && [ "$dir" != "/" ]; do
    rmdir "$dir" 2>/dev/null || return 0
    dir=$(dirname "$dir")
  done
}

# Remove what the previous run installed, so an update cannot leave a renamed skill
# behind as a duplicate. Only manifest-listed relative paths under $dest are touched.
remove_previous() {
  [ -f "$manifest" ] || return 0
  local rel abs removed=0
  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    case "$rel" in /*|*..*) say "  skipping suspicious manifest entry: $rel"; continue ;; esac
    abs="$dest/$rel"
    [ -e "$abs" ] || continue
    if [ "$dry_run" -eq 1 ]; then
      say "  would remove $rel"
    else
      rm -f "$abs"
      prune_empty_dirs "$(dirname "$abs")"
    fi
    removed=$((removed + 1))
  done <"$manifest"
  [ "$removed" -eq 0 ] || say "  (removed $removed file(s) from the previous install)"
  [ "$dry_run" -eq 1 ] || rm -f "$manifest"
}

if [ "$uninstall" -eq 1 ]; then
  if [ ! -f "$manifest" ]; then
    say "Nothing to uninstall: no $MANIFEST_NAME in $dest"
    exit 0
  fi
  say "Uninstalling from $dest"
  remove_previous
  say "Done. Your opencode.json is untouched — drop any sdd entries from it by hand."
  exit 0
fi

[ -d "$REPO_ROOT/plugins" ] || { echo "install.sh: cannot find plugins/ under $REPO_ROOT" >&2; exit 1; }

say "Installing sdd into $dest"
[ "$dry_run" -eq 1 ] && say "(dry run — nothing will be written)"
remove_previous

skills=()
for skill_file in "$REPO_ROOT"/plugins/*/skills/*/SKILL.md; do
  [ -f "$skill_file" ] || continue
  name=$(skill_field "$skill_file" name)
  [ -n "$name" ] || { say "  skipping $skill_file — no name in frontmatter"; continue; }
  skills+=("$name:$skill_file")
done

if [ "${#skills[@]}" -eq 0 ]; then
  echo "install.sh: found no skills under $REPO_ROOT/plugins" >&2
  exit 1
fi

if [ "$want_skills" -eq 1 ]; then
  say "Skills:"
  for entry in "${skills[@]}"; do
    name=${entry%%:*}
    copy_into "${entry#*:}" "skill/$name/SKILL.md"
  done
fi

if [ "$want_commands" -eq 1 ]; then
  say "Commands:"
  for entry in "${skills[@]}"; do
    name=${entry%%:*}
    file=${entry#*:}
    description_line=$(skill_description_line "$file")
    write_into "command/$name.md" "$(cat <<EOF
---
${description_line:-description: Run the $name skill.}
---

Load the \`$name\` skill with the skill tool — \`skill({ name: "$name" })\` — and follow it
exactly for this request. The skill owns the procedure; do not improvise around it.

Arguments: \$ARGUMENTS
EOF
)"
  done
fi

if [ "$want_agents" -eq 1 ]; then
  say "Agents:"
  for agent_file in "$HOST_ROOT"/agent/*.md; do
    [ -f "$agent_file" ] || continue
    copy_into "$agent_file" "agent/$(basename "$agent_file")"
  done
fi

if [ "$want_plugin" -eq 1 ]; then
  say "Plugin:"
  copy_into "$HOST_ROOT/plugin/sdd-model-context.js" "plugin/sdd-model-context.js"
fi

if [ "$dry_run" -eq 0 ]; then
  printf '%s\n' "${installed[@]}" >"$manifest"
fi

# The reviewer pins name Anthropic slugs. opencode resolves models against its own
# provider catalog, so on a different provider the pin is simply unresolvable — warn
# now rather than let /validate fail at review time.
if [ "$want_agents" -eq 1 ] && command -v opencode >/dev/null 2>&1; then
  catalog=$(opencode models 2>/dev/null || true)
  if [ -n "$catalog" ]; then
    for agent_file in "$HOST_ROOT"/agent/*.md; do
      pin=$(skill_field "$agent_file" model)
      [ -n "$pin" ] || continue
      printf '%s\n' "$catalog" | grep -qxF "$pin" || {
        say ""
        say "! $(basename "$agent_file") pins '$pin', which this host's catalog doesn't list."
        say "  Edit the 'model:' line in $dest/agent/$(basename "$agent_file") to a slug from"
        say "  'opencode models'. Keep the rungs: story-reviewer medium, story-reviewer-strong frontier."
      }
    done
  fi
fi

say ""
say "Installed ${#installed[@]} file(s). Start a new opencode session to pick them up."
say ""
say "To keep /solve and /validate from firing on their own — they bake work into a"
say "branch — add this to your opencode.json:"
say ""
say '  { "permission": { "skill": { "*": "allow", "solve": "ask", "validate": "ask" } } }'
