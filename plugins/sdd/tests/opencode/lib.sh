#!/usr/bin/env bash
#
# opencode/lib.sh — opencode host specifics for the test harness.
#
# The other hosts install through a plugin manager, so their helpers overlay this
# working tree onto an existing install. opencode has no manager: it reads a config
# directory. That makes staging *better* here, not worse — instead of mutating the
# operator's real setup, `stage_plugin` builds a throwaway config directory holding
# the working tree's skills, agents, and plugin, and points OPENCODE_CONFIG_DIR at it.
# Nothing under ~/.config/opencode is touched, so a harness run can't leave the
# operator's own install half-updated.
#
# The staged directory still needs *model access*, which lives in the operator's own
# config (providers, baseURL, keys) — so their opencode.json/jsonc is copied in first
# and the working-tree files are layered on top. Auth lives in the data directory, not
# the config directory, so it is inherited untouched via $HOME.

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"

OPENCODE_STAGE=""

opencode_bin() {
  if [ -x "$HOME/.opencode/bin/opencode" ]; then
    printf '%s\n' "$HOME/.opencode/bin/opencode"
    return 0
  fi
  command -v opencode 2>/dev/null && return 0
  return 1
}

# The operator's real config dir — the source of provider/model settings, and what
# OPENCODE_CONFIG_DIR would otherwise point at.
opencode_user_config_dir() {
  printf '%s\n' "${SDD_OPENCODE_USER_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/opencode}"
}

# Build the throwaway config dir and export OPENCODE_CONFIG_DIR. Call once at the top
# of a test; the directory is removed on exit.
stage_plugin() {
  local user_dir staged found=0
  user_dir="$(opencode_user_config_dir)"
  staged=$(mktemp -d) || return 1

  local name
  for name in opencode.json opencode.jsonc; do
    if [ -f "$user_dir/$name" ]; then
      cp "$user_dir/$name" "$staged/$name" || return 1
      found=1
    fi
  done
  if [ "$found" -eq 0 ]; then
    echo "stage_plugin: no opencode.json in $user_dir — the staged session would have no" >&2
    echo "  provider configured and every trial would score ERROR. Configure opencode first," >&2
    echo "  or point SDD_OPENCODE_USER_CONFIG at the directory holding your config." >&2
    rm -rf "$staged"
    return 1
  fi

  "$PLUGIN_ROOT/hosts/opencode/install.sh" --dest "$staged" >/dev/null || {
    echo "stage_plugin: install.sh failed" >&2
    rm -rf "$staged"
    return 1
  }

  OPENCODE_STAGE="$staged"
  export OPENCODE_CONFIG_DIR="$staged"
  # shellcheck disable=SC2064
  trap "rm -rf '$staged'" EXIT
  echo "staged working tree → $staged (config from $user_dir)"
}

# A config that reads its key with `{env:VAR}` substitutes an *empty string* when the
# variable is unset — opencode does not error. That turns a forgotten export into an
# auth failure on every trial, which the harness would report as inconclusive infra
# errors rather than the setup mistake it is. Say so up front instead.
warn_unforwarded_env_keys() {
  local dir cfg names name
  dir="$(opencode_user_config_dir)"
  for cfg in "$dir/opencode.json" "$dir/opencode.jsonc"; do
    [ -f "$cfg" ] || continue
    names=$(grep -oE '\{env:[A-Za-z_][A-Za-z0-9_]*\}' "$cfg" | sed 's/^{env://; s/}$//' | sort -u)
    for name in $names; do
      if [ -z "${!name:-}" ]; then
        echo "warning: $cfg reads \$$name, which is unset — opencode will substitute an empty" >&2
        echo "  string and every trial will fail to authenticate. Export it before running." >&2
      elif ! printf '%s\n' ${SDD_TEST_ENV:-} | grep -qxF "$name"; then
        echo "warning: \$$name is set but not forwarded into the clean test environment." >&2
        echo "  Re-run with SDD_TEST_ENV=\"$name\" so the trials can authenticate." >&2
      fi
    done
  done
}
