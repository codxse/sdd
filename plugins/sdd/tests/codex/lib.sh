#!/usr/bin/env bash
#
# codex/lib.sh — Codex host specifics for the test harness.
#
# Headless `codex exec` loads the installed plugin cache, not this working tree.
# Resolve the cache entry reported as active by `codex plugin list`, then overlay
# this checkout before a test run so the trial exercises the pending edits.

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"

resolve_install_path() {
  local codex_home_dir version p=""
  codex_home_dir="${CODEX_HOME:-$HOME/.codex}"
  version=$(codex plugin list 2>/dev/null | awk '$1 == "sdd@sdd" && $2 ~ /^installed/ { print $3; exit }')
  if [ -n "$version" ]; then
    p="$codex_home_dir/plugins/cache/sdd/sdd/$version"
  fi
  if [ ! -d "$p" ]; then
    p=$(ls -d "$codex_home_dir"/plugins/cache/sdd/sdd/*/ 2>/dev/null | sort -V | tail -1)
  fi
  printf '%s' "${p%/}"
}

sync_plugin() {
  local dst
  dst="$(resolve_install_path)"
  if [ -z "$dst" ] || [ ! -d "$dst" ]; then
    echo "sync_plugin: cannot find an installed sdd copy to sync into." >&2
    echo "  install it once with the Codex plugin manager, then re-run." >&2
    return 1
  fi
  rsync -a --exclude='.git' "$PLUGIN_ROOT/" "$dst/" || return 1
  echo "synced working tree → $dst"
}
