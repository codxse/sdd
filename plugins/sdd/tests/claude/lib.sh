#!/usr/bin/env bash
#
# claude/lib.sh — Claude Code host specifics for the test harness.
#
# Headless `claude -p` loads the *installed* plugin copy (under
# ~/.claude/plugins/cache/...), never this working tree. Rather than make the
# operator remember to `cp` each edited SKILL.md into the cache, the harness
# syncs the whole working-tree plugin into the active install before every run.
# That is what `sync_plugin` does — call it once at the top of a test.

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"

# Resolve the install path that `claude -p` actually loads for this plugin, from
# the user's plugin registry. Falls back to the highest version dir in the cache.
resolve_install_path() {
  local reg="$HOME/.claude/plugins/installed_plugins.json"
  local p=""
  if [ -f "$reg" ] && command -v jq >/dev/null 2>&1; then
    p=$(jq -r '.plugins["sdd@sdd"][0].installPath // empty' "$reg" 2>/dev/null)
  fi
  if [ -z "$p" ]; then
    p=$(ls -d "$HOME"/.claude/plugins/cache/sdd/sdd/*/ 2>/dev/null | sort -V | tail -1)
  fi
  printf '%s' "${p%/}"
}

# Overlay the working tree onto the active install so the next `claude -p` run
# exercises the edits in this checkout. Overlay (no --delete) keeps Claude's own
# .in_use bookkeeping intact; every current skill/shared file is overwritten.
sync_plugin() {
  local dst
  dst="$(resolve_install_path)"
  if [ -z "$dst" ] || [ ! -d "$dst" ]; then
    echo "sync_plugin: cannot find an installed sdd copy to sync into." >&2
    echo "  install it once with the Claude plugin manager, then re-run." >&2
    return 1
  fi
  rsync -a --exclude='.in_use' --exclude='.git' "$PLUGIN_ROOT/" "$dst/" || return 1
  echo "synced working tree → $dst"
}
