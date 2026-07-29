#!/usr/bin/env bash
#
# lib.sh — host-agnostic helpers for the sdd test harness.
#
# Host-specific pieces (where the plugin is installed, how to sync the working
# tree onto it) live in claude/lib.sh and kimi/lib.sh; each test sources the
# lib.sh next to it, which in turn sources this file.

# Absolute path to the working-tree plugin root (the dir holding skills/, shared/,
# tests/). Resolved from this file's location (tests/lib.sh) so it works from any CWD.
PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Absolute path to the working-tree repository root (the Kimi install copies the
# whole repo, not just the plugin dir). Two levels up from PLUGIN_ROOT
# (plugins/sdd), not one — resolving one level short silently rsynced
# `plugins/` into the install root, so every Kimi trial ran the stale installed copy
# while the harness printed "synced".
REPO_ROOT="$(cd "$PLUGIN_ROOT/../.." && pwd)"

# Run a model CLI with only the process state it needs for local auth, command
# discovery, and stable text output. A guard slip may cause the model to inspect
# its shell environment; do not let a probabilistic test inherit unrelated
# credentials from the operator's session.
run_clean_env() {
  local test_path
  local env_args=()
  test_path="$HOME/.local/bin:$HOME/.kimi-code/bin:/usr/local/bin:/usr/bin:/bin"
  env_args+=(
    HOME="$HOME"
    PATH="$test_path"
    USER="${USER:-model-guard}"
    LANG=C.UTF-8
    LC_ALL=C.UTF-8
    TERM=dumb
    NO_COLOR=1
    GIT_TERMINAL_PROMPT=0
  )
  [ -n "${CODEX_HOME:-}" ] && env_args+=(CODEX_HOME="$CODEX_HOME")
  [ -n "${CLAUDE_CONFIG_DIR:-}" ] && env_args+=(CLAUDE_CONFIG_DIR="$CLAUDE_CONFIG_DIR")
  env -i "${env_args[@]}" "$@"
}

# Assert the Model Guard's mandatory first line: `model-guard: id=<exact-id> tier=<tier>`.
#
# Checking the *classification* — not only the refusal prose — is what separates a
# correct tier decision from a host that never told the model its ID at all. A session
# that cannot read its own ID classifies `unsure`, and `unsure` refuses with the same
# words as `budget`, so a refusal-only assertion scores a totally blind host as a pass.
#
# The id is matched as a substring so a host *alias* (`-m haiku`) can be asserted against
# the ID the model actually reports (`claude-haiku-4-5`), and so surrounding punctuation
# the model may add (backticks, quotes) doesn't matter. The substring is used as an ERE,
# which only makes a `.` in a slug laxer — never stricter.
guard_line() {  # $1=output  $2=expected id substring  $3=expected tier
  grep -qE "model-guard:[[:space:]]*id=[^[:space:]]*$2[^[:space:]]*[[:space:]]+tier=$3" <<<"$1"
}

# Classify output that means the trial never actually reached the model — a session
# or rate limit, an overloaded/API error, or empty output. Such a run proves nothing
# about the guard or the format, so the caller scores it ERROR (inconclusive), not a
# FAIL. Without this a mid-run usage-limit turns every remaining trial into a false
# guard failure. Prints a short reason and returns 0 when it IS an infra error.
infra_error() {
  local out="$1"
  [ -z "${out//[[:space:]]/}" ] && { printf 'empty output (no model response)'; return 0; }
  local re='session limit|usage limit|rate limit|(^|[^0-9])429([^0-9]|$)|overloaded|api error|service unavailable|temporarily unavailable|invalid api key|authentication_error|credit balance'
  if grep -qiE "$re" <<<"$out"; then
    printf 'availability/infra error: %s' "$(grep -ioE "$re" <<<"$out" | head -1)"
    return 0
  fi
  return 1
}
