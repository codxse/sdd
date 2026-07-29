#!/usr/bin/env bash
#
# kimi/lib.sh — Kimi Code host specifics for the test harness.
#
# Headless `kimi -p` loads the *installed* plugin copy, never this working tree.
# Kimi's GitHub install copies the whole repository (its manifest lives at the
# repo root) into ~/.kimi-code/plugins/managed/sdd/, so the sync target
# is the repo-root copy, not just the plugin dir. `sync_plugin` overlays this
# checkout onto that install before every run — call it once at the top of a test.

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"

# The managed Kimi install is a fixed path (one plugin per repo, named after the
# plugin). Verify it is really our install by checking for the root manifest.
resolve_install_path() {
  local p="$HOME/.kimi-code/plugins/managed/sdd"
  [ -f "$p/kimi.plugin.json" ] && printf '%s' "$p"
}

# Overlay the working tree onto the active install so the next `kimi -p` run
# exercises the edits in this checkout. Overlay (no --delete) mirrors the Claude
# harness; local-only state (.git, .beads, worktrees) is excluded.
sync_plugin() {
  local dst
  dst="$(resolve_install_path)"
  if [ -z "$dst" ] || [ ! -d "$dst" ]; then
    echo "sync_plugin: cannot find an installed sdd copy to sync into." >&2
    echo "  install it once in Kimi Code (/plugins install <repo-url>), then re-run." >&2
    return 1
  fi
  rsync -a --exclude='.git' --exclude='.beads' --exclude='.worktree' "$REPO_ROOT/" "$dst/" || return 1
  echo "synced working tree → $dst"
}
